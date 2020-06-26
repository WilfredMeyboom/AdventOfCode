use Test_WME

SET NOCOUNT ON

CREATE TABLE #Input (Nr NVARCHAR(MAX));

BULK INSERT #Input
FROM 'C:\Source\AdventOfCode\2019\input18.txt'
WITH (ROWTERMINATOR = '0x0A');


--Create and fill the Grid table which is a map of the input
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

 -- Create a keys table in which we're going to store the shortest distance between every key and which doors and other keys are on that path
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

--Temp table we don't need anymore
DROP TABLE ##Route


/*

DROP TABLE ##Grid
DROP TABLE ##Keys

*/

--Because creating and filling the keys table takes quite some time (approx. 150 min), we create a physical copy
--SELECT * 
--INTO Day18_Keys
--FROM ##Keys

SELECT * FROM Day18_Keys

--Remove the last key found because we already have this info in the endletter column
--UPDATE Day18_Keys
--SET OtherKeyEncountered = SUBSTRING(OtherKeyEncountered, 1, LEN(OtherKeyEncountered) -1)

--Minimale makkelijste route:
--26	@whcrqgofaltkvsjmuzbipyndxe	4402

/*
Manual analysis shows this order to be best:

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

-- Get a list of the distances
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
-- Adding the distances gives 3546

--7622 is too high for part 1
--7162 is too high for part 1
--4402 is too high for part 1
--3954 is incorrect for part 1
--3950 is incorrect for part 1
--3872 is incorrect for part 1
--3870 is incorrect for part 1
--3546 is correct for part 1

/*

DROP TABLE ##Keys
DROP TABLE ##NextStep
DROP TABLE ##Seq

*/

--('o','g','l','t','k','r','q','v')
--SELECT * FROM Day18_Keys WHERE startLetter = 'k' AND endletter IN ('v') ORDER BY Dist

--c - r - q - g - o - l - t - k - v
--SELECT 132+74+182+134+222+14+156+398 == 1312


--Manual analysis shows this order to be best:
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

-- Adding all distances gives 1996
-- Correct this value for not starting in the center but two spaces from the center (4x) -->
SELECT 1996 - 4 * 2

--2766 is too high for part 2
--2192 it too high for part 2
--2012 it too high for part 2
-- 1988 is correct for part 2

--SELECT * FROM Day18_Keys WHERE startLetter = '@'


