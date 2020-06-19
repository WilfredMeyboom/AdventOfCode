use Test_WME

SET NOCOUNT ON

CREATE TABLE #Input (Nr NVARCHAR(MAX));

BULK INSERT #Input
FROM 'C:\Source\AdventOfCode\input18.txt'
WITH (ROWTERMINATOR = '0x0A');

CREATE TABLE ##Grid (ID INT IDENTITY(1,1), x INT, y INT, val CHAR, UNIQUE(x,y))

;WITH cte_Grid AS (
    SELECT 1 AS x
    ,      ROW_NUMBER() OVER (ORDER BY(SELECT 0)) AS y
    ,      LEFT(Nr, 1) AS val
    ,      SUBSTRING(Nr, 2, LEN(Nr)) AS Rest
    FROM #Input
    UNION ALL
    SELECT X + 1
    ,      Y
    ,      LEFT(Rest, 1)
    ,      SUBSTRING(Rest, 2, LEN(Rest))
    FROM cte_Grid
    WHERE LEN(Rest) > 0
)
INSERT ##Grid(x, y, val)
SELECT x, y, val
FROM cte_Grid
WHERE val <> '#'
OPTION (MAXRECURSION 20000)

DROP TABLE #Input

--SELECT * FROM ##Grid WHERE val = '@'

CREATE TABLE ##Keys (ID INT IDENTITY(1,1), startLetter CHAR, x INT, y INT, endLetter CHAR, Dist INT, DoorsEncountered VARCHAR(26), OtherKeyEncountered VARCHAR(26))

;WITH cte_Keys AS (
    SELECT x, y, val as letter 
    FROM ##Grid WHERE ASCII(val) BETWEEN 97 AND 122
    UNION
    SELECT x, y, val as letter 
    FROM ##Grid WHERE val = '@'
)
INSERT ##Keys (startLetter, x, y, endLetter)
SELECT SL.letter, SL.x, SL.y, EL.letter
FROM cte_Keys SL
CROSS APPLY cte_Keys EL
WHERE SL.letter <> EL.letter AND EL.letter <> '@'
ORDER BY SL.letter, EL.letter


DECLARE @StartLetter CHAR
DECLARE @EndLetter CHAR
DECLARE @x INT
DECLARE @y INT
DECLARE @Dist INT
DECLARE @DestFound INT

CREATE TABLE ##Route(x INT, y INT, steps INT, doors VARCHAR(26), keys VARCHAR(26), UNIQUE(x,y))

DECLARE KeyCursor CURSOR FOR
SELECT startLetter, x, y, endLetter
FROM ##Keys

OPEN KeyCursor

FETCH NEXT FROM KeyCursor INTO @StartLetter, @x, @y, @EndLetter

WHILE @@FETCH_STATUS = 0
BEGIN

    PRINT @StartLetter + ' with ' + @EndLetter + ' started at ' + CAST(GETDATE() AS VARCHAR(50))

    SET @Dist = 0
    SET @DestFound = 0
    DELETE FROM ##Route

    INSERT ##Route (x,y, steps, doors, keys) VALUES (@x, @y, 0, '', '')

    WHILE @DestFound = 0
    BEGIN

        INSERT ##Route (x, y, steps, doors, keys)
        SELECT DISTINCT G.x
        ,      G.y
        ,      R.steps + 1
        ,      doors = R.doors + CASE WHEN ASCII(val) BETWEEN 65 AND 90 THEN G.val ELSE '' END
        ,      keys = R.keys + CASE WHEN ASCII(val) BETWEEN 97 AND 122 THEN G.val ELSE '' END
        FROM ##Route R
        INNER JOIN ##Grid G ON (ABS(R.x - G.x) = 1 AND R.y = G.y)
                            OR (ABS(R.y - G.y) = 1 AND R.x = G.x)
        LEFT JOIN ##Route AL ON G.x = AL.x AND G.y = AL.y
        WHERE R.Steps = (SELECT MAX(steps) AS MaxSteps FROM ##Route)
          AND AL.steps IS NULL

        IF EXISTS (SELECT 1 FROM ##Route WHERE keys LIKE '%' + @EndLetter + '%') SET @DestFound = 1;
    END

    --SELECT * FROM ##Route

    ;WITH cte_Route AS (
        SELECT MAX(Steps) AS MaxSteps
        FROM ##Route
    )
    UPDATE K
    SET Dist = MaxSteps
    ,   DoorsEncountered = REPLACE(R.doors,'@','')
    ,   OtherKeyEncountered = R.keys
    FROM ##Keys K
    CROSS APPLY cte_Route cR
    INNER JOIN ##Route R ON R.steps = cR.MaxSteps AND R.keys LIKE '%' + @EndLetter
    WHERE startLetter = @StartLetter AND endLetter = @EndLetter

    FETCH NEXT FROM KeyCursor INTO @StartLetter, @x, @y, @EndLetter
END

CLOSE KeyCursor
DEALLOCATE KeyCursor

DROP TABLE ##Route


/*

DROP TABLE ##Grid
DROP TABLE ##Keys

*/

--SELECT * 
--INTO Day18_Keys
--FROM ##Keys

SELECT * FROM Day18_Keys

--UPDATE Day18_Keys
--SET OtherKeyEncountered = SUBSTRING(OtherKeyEncountered, 1, LEN(OtherKeyEncountered) -1)

--Minimale makkelijste route:
--26	@whcrqgofaltkvsjmuzbipyndxe	4402

/*
Analysis shows:

w
f
h
a
c
    o
    g
    l
    t
    k
    r
    q
    v
        j
        m
u
z
b
s
i
p
y
n
d
x
e

*/


SELECT 1 AS SeqNr , * FROM Day18_Keys WHERE startLetter='@' AND endLetter = 'w' UNION
SELECT 2 AS SeqNr , * FROM Day18_Keys WHERE startLetter='w' AND endLetter = 'f' UNION
SELECT 3 AS SeqNr , * FROM Day18_Keys WHERE startLetter='f' AND endLetter = 'r' UNION
SELECT 4 AS SeqNr , * FROM Day18_Keys WHERE startLetter='r' AND endLetter = 'q' UNION
SELECT 5 AS SeqNr , * FROM Day18_Keys WHERE startLetter='q' AND endLetter = 'h' UNION
SELECT 6 AS SeqNr , * FROM Day18_Keys WHERE startLetter='h' AND endLetter = 'a' UNION
SELECT 7 AS SeqNr , * FROM Day18_Keys WHERE startLetter='a' AND endLetter = 'c' UNION
SELECT 8 AS SeqNr , * FROM Day18_Keys WHERE startLetter='c' AND endLetter = 'v' UNION
SELECT 9 AS SeqNr , * FROM Day18_Keys WHERE startLetter='v' AND endLetter = 'j' UNION
SELECT 10 AS SeqNr , * FROM Day18_Keys WHERE startLetter='j' AND endLetter = 'm' UNION
SELECT 11 AS SeqNr , * FROM Day18_Keys WHERE startLetter='m' AND endLetter = 'z' UNION
SELECT 12 AS SeqNr , * FROM Day18_Keys WHERE startLetter='z' AND endLetter = 'u' UNION
SELECT 13 AS SeqNr , * FROM Day18_Keys WHERE startLetter='u' AND endLetter = 'k' UNION
SELECT 14 AS SeqNr , * FROM Day18_Keys WHERE startLetter='k' AND endLetter = 'l' UNION
SELECT 15 AS SeqNr , * FROM Day18_Keys WHERE startLetter='l' AND endLetter = 't' UNION
SELECT 16 AS SeqNr , * FROM Day18_Keys WHERE startLetter='t' AND endLetter = 'g' UNION
SELECT 17 AS SeqNr , * FROM Day18_Keys WHERE startLetter='g' AND endLetter = 'b' UNION
SELECT 18 AS SeqNr , * FROM Day18_Keys WHERE startLetter='b' AND endLetter = 'o' UNION
SELECT 19 AS SeqNr , * FROM Day18_Keys WHERE startLetter='o' AND endLetter = 's' UNION
SELECT 20 AS SeqNr , * FROM Day18_Keys WHERE startLetter='s' AND endLetter = 'i' UNION
SELECT 21 AS SeqNr , * FROM Day18_Keys WHERE startLetter='i' AND endLetter = 'p' UNION
SELECT 22 AS SeqNr , * FROM Day18_Keys WHERE startLetter='p' AND endLetter = 'y' UNION
SELECT 23 AS SeqNr , * FROM Day18_Keys WHERE startLetter='y' AND endLetter = 'n' UNION
SELECT 24 AS SeqNr , * FROM Day18_Keys WHERE startLetter='n' AND endLetter = 'd' UNION
SELECT 25 AS SeqNr , * FROM Day18_Keys WHERE startLetter='d' AND endLetter = 'x' UNION
SELECT 26 AS SeqNr , * FROM Day18_Keys WHERE startLetter='x' AND endLetter = 'e' 
ORDER BY SeqNr

--7622 is too high for part 1
--7162 is too high for part 1
--4402 is too high for part 1
--3954 is incorrect for part 1
--3950 is incorrect for part 1
--3872 is incorrect for part 1
--3870 is incorrect for part 1


/*

DROP TABLE ##Keys
DROP TABLE ##NextStep
DROP TABLE ##Seq

*/

--('o','g','l','t','k','r','q','v')
SELECT * FROM Day18_Keys WHERE startLetter = 'k' AND endletter IN ('v') ORDER BY Dist

--c - r - q - g - o - l - t - k - v
--SELECT 132+74+182+134+222+14+156+398 == 1312



SELECT 1 AS SeqNr , * FROM Day18_Keys WHERE startLetter='@' AND endLetter = 'q' UNION	
SELECT 2 AS SeqNr , * FROM Day18_Keys WHERE startLetter='q' AND endLetter = 'r' UNION	
SELECT 3 AS SeqNr , * FROM Day18_Keys WHERE startLetter='r' AND endLetter = 'w' UNION	
SELECT 4 AS SeqNr , * FROM Day18_Keys WHERE startLetter='w' AND endLetter = 'f' UNION	
SELECT 5 AS SeqNr , * FROM Day18_Keys WHERE startLetter='f' AND endLetter = 'j' UNION	
SELECT 6 AS SeqNr , * FROM Day18_Keys WHERE startLetter='j' AND endLetter = 'm' UNION	
SELECT 7 AS SeqNr , * FROM Day18_Keys WHERE startLetter='@' AND endLetter = 'h' UNION	
SELECT 8 AS SeqNr , * FROM Day18_Keys WHERE startLetter='h' AND endLetter = 'c' UNION	
SELECT 9 AS SeqNr , * FROM Day18_Keys WHERE startLetter='c' AND endLetter = 'a' UNION	
SELECT 10 AS SeqNr , * FROM Day18_Keys WHERE startLetter='a' AND endLetter = 'b' UNION	
SELECT 11 AS SeqNr , * FROM Day18_Keys WHERE startLetter='@' AND endLetter = 'g' UNION	
SELECT 12 AS SeqNr , * FROM Day18_Keys WHERE startLetter='g' AND endLetter = 't' UNION	
SELECT 13 AS SeqNr , * FROM Day18_Keys WHERE startLetter='t' AND endLetter = 'l' UNION	
SELECT 14 AS SeqNr , * FROM Day18_Keys WHERE startLetter='l' AND endLetter = 'k' UNION	
SELECT 15 AS SeqNr , * FROM Day18_Keys WHERE startLetter='k' AND endLetter = 'u' UNION	
SELECT 16 AS SeqNr , * FROM Day18_Keys WHERE startLetter='u' AND endLetter = 'z' UNION	
SELECT 17 AS SeqNr , * FROM Day18_Keys WHERE startLetter='@' AND endLetter = 'o' UNION	
SELECT 18 AS SeqNr , * FROM Day18_Keys WHERE startLetter='o' AND endLetter = 'v' UNION	
SELECT 19 AS SeqNr , * FROM Day18_Keys WHERE startLetter='v' AND endLetter = 's' UNION	
SELECT 20 AS SeqNr , * FROM Day18_Keys WHERE startLetter='s' AND endLetter = 'i' UNION	
SELECT 21 AS SeqNr , * FROM Day18_Keys WHERE startLetter='i' AND endLetter = 'p' UNION	
SELECT 22 AS SeqNr , * FROM Day18_Keys WHERE startLetter='p' AND endLetter = 'y' UNION	
SELECT 23 AS SeqNr , * FROM Day18_Keys WHERE startLetter='y' AND endLetter = 'n' UNION	
SELECT 24 AS SeqNr , * FROM Day18_Keys WHERE startLetter='n' AND endLetter = 'd' UNION	
SELECT 25 AS SeqNr , * FROM Day18_Keys WHERE startLetter='d' AND endLetter = 'x' UNION	
SELECT 26 AS SeqNr , * FROM Day18_Keys WHERE startLetter='x' AND endLetter = 'e' 
ORDER BY SeqNr

--2766 is too high for part 2
--2192 it too high for part 2
--2012 it too high for part 2


SELECT * FROM Day18_Keys WHERE startLetter = '@'



/*

SELECT DISTINCT startLetter
, CASE WHEN x<41 AND y<41 THEN 'NW'
       WHEN x>41 AND y<41 THEN 'NE'
       WHEN x<41 AND y>41 THEN 'SW'
       WHEN x>41 AND y>41 THEN 'SE' END AS Kwadrant
FROM Day18_Keys
ORDER BY 2,1

SELECT * FROM Day18_Keys WHERE startLetter = 'e' --AND DoorsEncountered = ''

SELECT * FROM Day18_Keys WHERE startLetter IN ('u','z','g','l','t','k') AND endLetter IN ('u','z','g','l','t','k')

;WITH cte_Letters AS (
    SELECT 'w' AS Letter
    UNION SELECT 'f'
    UNION SELECT 'r'
    UNION SELECT 'q'
)
SELECT L1.Letter, L2.Letter, L3.Letter, L4.Letter, S1.Dist, S2.Dist, S3.Dist, S4.Dist, S1.Dist+  S2.Dist + S3.Dist + S4.Dist
FROM cte_Letters L1
INNER JOIN cte_Letters L2 ON L1.Letter <> L2.Letter
INNER JOIN cte_Letters L3 ON L1.Letter <> L3.Letter AND L2.Letter <> L3.Letter
INNER JOIN cte_Letters L4 ON L1.Letter <> L4.Letter AND L2.Letter <> L4.Letter AND L3.Letter <> L4.Letter
INNER JOIN Day18_Keys S1 ON S1.startLetter = '@' AND S1.endLetter = L1.Letter
INNER JOIN Day18_Keys S2 ON S2.startLetter = L1.Letter AND S2.endLetter = L2.Letter
INNER JOIN Day18_Keys S3 ON S3.startLetter = L2.Letter AND S3.endLetter = L3.Letter
INNER JOIN Day18_Keys S4 ON S4.startLetter = L3.Letter AND S4.endLetter = L4.Letter
ORDER BY 9



;WITH cte_Letters AS (
    SELECT 'u' AS Letter
    UNION SELECT 'z'
    UNION SELECT 'g'
    UNION SELECT 'l'
    UNION SELECT 't'
    UNION SELECT 'k'
)
SELECT L1.Letter, L2.Letter, L3.Letter, L4.Letter, L5.Letter, L6.Letter, S0.Dist + S1.Dist+  S2.Dist + S3.Dist + S4.Dist + S5.Dist 
FROM cte_Letters L1
INNER JOIN cte_Letters L2 ON L1.Letter <> L2.Letter
INNER JOIN cte_Letters L3 ON L1.Letter <> L3.Letter AND L2.Letter <> L3.Letter
INNER JOIN cte_Letters L4 ON L1.Letter <> L4.Letter AND L2.Letter <> L4.Letter AND L3.Letter <> L4.Letter
INNER JOIN cte_Letters L5 ON L1.Letter <> L5.Letter AND L2.Letter <> L5.Letter AND L3.Letter <> L5.Letter AND L4.Letter <> L5.Letter 
INNER JOIN cte_Letters L6 ON L1.Letter <> L6.Letter AND L2.Letter <> L6.Letter AND L3.Letter <> L6.Letter AND L4.Letter <> L6.Letter AND L5.Letter <> L6.Letter
INNER JOIN Day18_Keys S0 ON S0.startLetter = '@' AND S0.endLetter = L1.Letter
INNER JOIN Day18_Keys S1 ON S1.startLetter = L1.Letter AND S1.endLetter = L2.Letter
INNER JOIN Day18_Keys S2 ON S2.startLetter = L2.Letter AND S2.endLetter = L3.Letter
INNER JOIN Day18_Keys S3 ON S3.startLetter = L3.Letter AND S3.endLetter = L4.Letter
INNER JOIN Day18_Keys S4 ON S4.startLetter = L4.Letter AND S4.endLetter = L5.Letter
INNER JOIN Day18_Keys S5 ON S5.startLetter = L5.Letter AND S5.endLetter = L6.Letter
ORDER BY 7



;WITH cte_Letters AS (
    SELECT 'h' AS Letter
    UNION SELECT 'a'
    UNION SELECT 'c'
    UNION SELECT 'b'
)
SELECT L1.Letter, L2.Letter, L3.Letter, L4.Letter, S1.Dist, S2.Dist, S3.Dist, S4.Dist, S1.Dist+  S2.Dist + S3.Dist + S4.Dist
FROM cte_Letters L1
INNER JOIN cte_Letters L2 ON L1.Letter <> L2.Letter
INNER JOIN cte_Letters L3 ON L1.Letter <> L3.Letter AND L2.Letter <> L3.Letter
INNER JOIN cte_Letters L4 ON L1.Letter <> L4.Letter AND L2.Letter <> L4.Letter AND L3.Letter <> L4.Letter
INNER JOIN Day18_Keys S1 ON S1.startLetter = '@' AND S1.endLetter = L1.Letter
INNER JOIN Day18_Keys S2 ON S2.startLetter = L1.Letter AND S2.endLetter = L2.Letter
INNER JOIN Day18_Keys S3 ON S3.startLetter = L2.Letter AND S3.endLetter = L3.Letter
INNER JOIN Day18_Keys S4 ON S4.startLetter = L3.Letter AND S4.endLetter = L4.Letter
ORDER BY 9




;WITH cte_Letters AS (
    SELECT 'w' AS Letter
    UNION SELECT 'f'
    UNION SELECT 'r'
    UNION SELECT 'q'
    UNION SELECT 'j'
    UNION SELECT 'm'
)
SELECT L1.Letter, L2.Letter, L3.Letter, L4.Letter, L5.Letter, L6.Letter, S0.Dist + S1.Dist+  S2.Dist + S3.Dist + S4.Dist + S5.Dist 
FROM cte_Letters L1
INNER JOIN cte_Letters L2 ON L1.Letter <> L2.Letter
INNER JOIN cte_Letters L3 ON L1.Letter <> L3.Letter AND L2.Letter <> L3.Letter
INNER JOIN cte_Letters L4 ON L1.Letter <> L4.Letter AND L2.Letter <> L4.Letter AND L3.Letter <> L4.Letter
INNER JOIN cte_Letters L5 ON L1.Letter <> L5.Letter AND L2.Letter <> L5.Letter AND L3.Letter <> L5.Letter AND L4.Letter <> L5.Letter 
INNER JOIN cte_Letters L6 ON L1.Letter <> L6.Letter AND L2.Letter <> L6.Letter AND L3.Letter <> L6.Letter AND L4.Letter <> L6.Letter AND L5.Letter <> L6.Letter
INNER JOIN Day18_Keys S0 ON S0.startLetter = '@' AND S0.endLetter = L1.Letter
INNER JOIN Day18_Keys S1 ON S1.startLetter = L1.Letter AND S1.endLetter = L2.Letter
INNER JOIN Day18_Keys S2 ON S2.startLetter = L2.Letter AND S2.endLetter = L3.Letter
INNER JOIN Day18_Keys S3 ON S3.startLetter = L3.Letter AND S3.endLetter = L4.Letter
INNER JOIN Day18_Keys S4 ON S4.startLetter = L4.Letter AND S4.endLetter = L5.Letter
INNER JOIN Day18_Keys S5 ON S5.startLetter = L5.Letter AND S5.endLetter = L6.Letter
ORDER BY 7


*/