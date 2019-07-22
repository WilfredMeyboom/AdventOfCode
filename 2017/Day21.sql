USE Test_WME

SET NOCOUNT ON

CREATE TABLE ##Input (Line NVARCHAR(MAX));

BULK INSERT ##Input
FROM 'D:\Wilfred\AdventOfCode\2017\input21.txt'
WITH (ROWTERMINATOR = '0x0A');

CREATE TABLE ##Patterns (ID INT IDENTITY(1,1), PatternNr INT, X INT, Y INT, Field INT)

;WITH cte_PatternRows AS (
    SELECT ROW_NUMBER() OVER (ORDER BY (SELECT 0)) AS PatternNr
    ,      1 AS X
    ,      1 AS Y
    ,      CASE WHEN LEFT(Line, 1) = '.' THEN 0 ELSE 1 END AS Field
    ,      SUBSTRING(Line, 2, LEN(Line)) AS Remainder
    ,      1 AS IsRelevant
    FROM ##Input 
    --WHERE LEN(Line) = 20
    UNION ALL
    SELECT PatternNr
    ,      CASE WHEN LEFT(Remainder, 1) IN ('.','#') THEN X + 1 ELSE 0 END AS X
    ,      CASE WHEN LEFT(Remainder, 1) IN ('.','#') THEN Y ELSE Y + 1 END AS Y
    ,      CASE WHEN LEFT(Remainder, 1) = '.' THEN 0 ELSE 1 END AS Field
    ,      SUBSTRING(Remainder, 2, LEN(Remainder)) AS Remainder
    ,      CASE WHEN LEFT(Remainder, 1) IN ('.','#') THEN 1 ELSE 0 END AS IsRelevant
    FROM cte_PatternRows
    WHERE LEN(Remainder) > 0
)
INSERT ##Patterns (PatternNr, X, Y, Field)
SELECT PatternNr, X, Y, Field FROM cte_PatternRows
WHERE IsRelevant = 1



CREATE TABLE ##Size2Patterns (ID INT IDENTITY(1,1), PatternNr INT, SubPatternNr INT, X INT, Y INT, Field INT, Pattern CHAR(4))
CREATE TABLE ##Size3Results (ID INT IDENTITY(1,1), PatternNr INT, X INT, Y INT, Field INT)
CREATE TABLE ##Size3Patterns (ID INT IDENTITY(1,1), PatternNr INT, SubPatternNr INT, X INT, Y INT, Field INT, Pattern CHAR(9))
CREATE TABLE ##Size4Results (ID INT IDENTITY(1,1), PatternNr INT, X INT, Y INT, Field INT)

INSERT ##Size3Results (PatternNr, X, Y, Field)
SELECT PatternNr, X, Y, Field
FROM ##Patterns
WHERE PatternNr <= 6 AND Y > 2

UPDATE ##Size3Results SET Y = Y - 5

INSERT ##Size4Results (PatternNr, X, Y, Field)
SELECT PatternNr, X, Y, Field
FROM ##Patterns
WHERE PatternNr >= 7 AND Y > 3

UPDATE ##Size4Results SET Y = Y - 6

;WITH cte_Org AS (
    SELECT PatternNr, X, Y, Field, 1 AS Layout
    FROM ##Patterns
    WHERE PatternNr <= 6 AND Y <= 2
), cte_OrgAndMirror AS (
    SELECT PatternNr, X, Y, Field, Layout
    FROM cte_Org
    UNION
    SELECT PatternNr, (X % 2) + 1, Y, Field, 5 AS Layout
    FROM cte_Org
), cte_90deg AS 
(
    SELECT PatternNr, 
           CASE WHEN X = Y THEN (X % 2) + 1 ELSE X END AS X, 
           CASE WHEN X <> Y THEN (Y % 2) + 1 ELSE Y END AS Y, 
           Field, 
           Layout + 1 AS Layout
    FROM cte_OrgAndMirror
), cte_180deg AS 
(
    SELECT PatternNr, 
           CASE WHEN X = Y THEN X%2 + 1 ELSE X END AS X, 
           CASE WHEN X <> Y THEN Y%2 + 1 ELSE Y END AS Y, 
           Field, 
           Layout + 1 AS Layout
    FROM cte_90deg
), cte_270deg AS 
(
    SELECT PatternNr, 
           CASE WHEN X = Y THEN X%2 + 1 ELSE X END AS X, 
           CASE WHEN X <> Y THEN Y%2 + 1 ELSE Y END AS Y, 
           Field, 
           Layout + 1 AS Layout
    FROM cte_180deg
)
INSERT ##Size2Patterns (PatternNr, SubPatternNr, X, Y, Field)
SELECT PatternNr, Layout, X, Y, Field FROM cte_OrgAndMirror
UNION 
SELECT PatternNr, Layout, X, Y, Field FROM cte_90deg
UNION 
SELECT PatternNr, Layout, X, Y, Field FROM cte_180deg
UNION 
SELECT PatternNr, Layout, X, Y, Field FROM cte_270deg
ORDER BY PatternNr, Layout, X, Y

;WITH cte_1 AS (
SELECT PatternNr, SubPatternNr, MAX(Field) AS Field FROM ##Size2Patterns WHERE X = 1 AND Y = 1 GROUP BY PatternNr, SubPatternNr
), cte_2 AS (
SELECT PatternNr, SubPatternNr, MAX(Field) AS Field FROM ##Size2Patterns WHERE X = 2 AND Y = 1 GROUP BY PatternNr, SubPatternNr
), cte_3 AS (
SELECT PatternNr, SubPatternNr, MAX(Field) AS Field FROM ##Size2Patterns WHERE X = 1 AND Y = 2 GROUP BY PatternNr, SubPatternNr
), cte_4 AS (
SELECT PatternNr, SubPatternNr, MAX(Field) AS Field FROM ##Size2Patterns WHERE X = 2 AND Y = 2 GROUP BY PatternNr, SubPatternNr
), cte_Pattern AS (
SELECT C1.PatternNr, C2.SubPatternNr, CAST(C1.Field AS CHAR(1)) + CAST(C2.Field AS CHAR(1)) + CAST(C3.Field AS CHAR(1)) + CAST(C4.Field AS CHAR(1)) AS Pattern
FROM cte_1 C1
INNER JOIN cte_2 C2 ON C1.PatternNr = C2.PatternNr AND C1.SubPatternNr = C2.SubPatternNr
INNER JOIN cte_3 C3 ON C1.PatternNr = C3.PatternNr AND C1.SubPatternNr = C3.SubPatternNr
INNER JOIN cte_4 C4 ON C1.PatternNr = C4.PatternNr AND C1.SubPatternNr = C4.SubPatternNr
), cte_ToKeep AS (
SELECT PatternNr, MIN(SubPatternNr) AS SubPatternNr, Pattern
FROM cte_Pattern
GROUP BY PatternNr, Pattern
--ORDER BY PatternNr, 2
)
UPDATE S2P 
SET S2P.Pattern = cP.Pattern
FROM ##Size2Patterns S2P
INNER JOIN cte_ToKeep cP ON S2P.PatternNr = cP.PatternNr AND S2P.SubPatternNr = cP.SubPatternNr

DELETE FROM P 
FROM ##Size2Patterns P
WHERE P.Pattern IS NULL

--SELECT * FROM ##Size2Patterns
--------------------------------------------- En dan nu size 3

;WITH cte_Org AS (
    SELECT PatternNr, X, Y, Field, 1 AS Layout
    FROM ##Patterns
    WHERE PatternNr > 6 AND Y <= 3
), cte_OrgAndMirror AS (
    SELECT PatternNr, X, Y, Field, Layout
    FROM cte_Org
    UNION
    SELECT PatternNr, CASE WHEN X = 1 THEN 3 
                           WHEN X = 2 THEN 2
                           WHEN X = 3 THEN 1
                           END, Y, Field, 5 AS Layout
    FROM cte_Org
), cte_90deg AS 
(
    SELECT PatternNr, 
           4-Y AS X,
           X AS Y,
           Field, 
           Layout + 1 AS Layout
    FROM cte_OrgAndMirror
), cte_180deg AS 
(
    SELECT PatternNr, 
           4-Y AS X,
           X AS Y,
           Field, 
           Layout + 1 AS Layout
    FROM cte_90deg
), cte_270deg AS 
(
    SELECT PatternNr, 
           4-Y AS X,
           X AS Y,
           Field, 
           Layout + 1 AS Layout
    FROM cte_180deg
)
INSERT ##Size3Patterns (PatternNr, SubPatternNr, X, Y, Field)
SELECT PatternNr, Layout, X, Y, Field FROM cte_OrgAndMirror
UNION 
SELECT PatternNr, Layout, X, Y, Field FROM cte_90deg
UNION 
SELECT PatternNr, Layout, X, Y, Field FROM cte_180deg
UNION 
SELECT PatternNr, Layout, X, Y, Field FROM cte_270deg
ORDER BY PatternNr, Layout, X, Y


;WITH cte_1 AS (
SELECT PatternNr, SubPatternNr, MAX(Field) AS Field FROM ##Size3Patterns WHERE X = 1 AND Y = 1 GROUP BY PatternNr, SubPatternNr
), cte_2 AS (
SELECT PatternNr, SubPatternNr, MAX(Field) AS Field FROM ##Size3Patterns WHERE X = 2 AND Y = 1 GROUP BY PatternNr, SubPatternNr
), cte_3 AS (
SELECT PatternNr, SubPatternNr, MAX(Field) AS Field FROM ##Size3Patterns WHERE X = 3 AND Y = 1 GROUP BY PatternNr, SubPatternNr
), cte_4 AS (
SELECT PatternNr, SubPatternNr, MAX(Field) AS Field FROM ##Size3Patterns WHERE X = 1 AND Y = 2 GROUP BY PatternNr, SubPatternNr
), cte_5 AS (
SELECT PatternNr, SubPatternNr, MAX(Field) AS Field FROM ##Size3Patterns WHERE X = 2 AND Y = 2 GROUP BY PatternNr, SubPatternNr
), cte_6 AS (
SELECT PatternNr, SubPatternNr, MAX(Field) AS Field FROM ##Size3Patterns WHERE X = 3 AND Y = 2 GROUP BY PatternNr, SubPatternNr
), cte_7 AS (
SELECT PatternNr, SubPatternNr, MAX(Field) AS Field FROM ##Size3Patterns WHERE X = 1 AND Y = 3 GROUP BY PatternNr, SubPatternNr
), cte_8 AS (
SELECT PatternNr, SubPatternNr, MAX(Field) AS Field FROM ##Size3Patterns WHERE X = 2 AND Y = 3 GROUP BY PatternNr, SubPatternNr
), cte_9 AS (
SELECT PatternNr, SubPatternNr, MAX(Field) AS Field FROM ##Size3Patterns WHERE X = 3 AND Y = 3 GROUP BY PatternNr, SubPatternNr
), cte_Pattern AS (
SELECT C1.PatternNr, C2.SubPatternNr, CAST(C1.Field AS CHAR(1)) + CAST(C2.Field AS CHAR(1)) + CAST(C3.Field AS CHAR(1)) + CAST(C4.Field AS CHAR(1)) +
                                      CAST(C5.Field AS CHAR(1)) + CAST(C6.Field AS CHAR(1)) + CAST(C7.Field AS CHAR(1)) + CAST(C8.Field AS CHAR(1)) +
                                      CAST(C9.Field AS CHAR(1)) AS Pattern
FROM cte_1 C1
INNER JOIN cte_2 C2 ON C1.PatternNr = C2.PatternNr AND C1.SubPatternNr = C2.SubPatternNr
INNER JOIN cte_3 C3 ON C1.PatternNr = C3.PatternNr AND C1.SubPatternNr = C3.SubPatternNr
INNER JOIN cte_4 C4 ON C1.PatternNr = C4.PatternNr AND C1.SubPatternNr = C4.SubPatternNr
INNER JOIN cte_5 C5 ON C1.PatternNr = C5.PatternNr AND C1.SubPatternNr = C5.SubPatternNr
INNER JOIN cte_6 C6 ON C1.PatternNr = C6.PatternNr AND C1.SubPatternNr = C6.SubPatternNr
INNER JOIN cte_7 C7 ON C1.PatternNr = C7.PatternNr AND C1.SubPatternNr = C7.SubPatternNr
INNER JOIN cte_8 C8 ON C1.PatternNr = C8.PatternNr AND C1.SubPatternNr = C8.SubPatternNr
INNER JOIN cte_9 C9 ON C1.PatternNr = C9.PatternNr AND C1.SubPatternNr = C9.SubPatternNr
), cte_ToKeep AS (
SELECT PatternNr, MIN(SubPatternNr) AS SubPatternNr, Pattern
FROM cte_Pattern
GROUP BY PatternNr, Pattern
--ORDER BY PatternNr, 2
)
UPDATE S3P 
SET S3P.Pattern = cP.Pattern
FROM ##Size3Patterns S3P
INNER JOIN cte_ToKeep cP ON S3P.PatternNr = cP.PatternNr AND S3P.SubPatternNr = cP.SubPatternNr

DELETE FROM P 
FROM ##Size3Patterns P
WHERE P.Pattern IS NULL


--SELECT * FROM ##Size3Patterns

--------------------------------------------Check we hebben patterns en solutions

CREATE TABLE ##Grid (ID INT IDENTITY(1,1), X INT, Y INT, Field INT)
CREATE TABLE ##ResultGrid (ID INT IDENTITY(1,1), X INT, Y INT, Field INT)

INSERT ##Grid (X, Y, Field) VALUES 
(1,1,0), (2,1,1), (3,1,0),
(1,2,0), (2,2,0), (3,2,1),
(1,3,1), (2,3,1), (3,3,1)


DECLARE @Counter INT = 0
DECLARE @Size INT

WHILE @Counter < 18 -- 5
BEGIN

PRINT 'Iteratie: ' + CAST(@Counter AS CHAR(3))

    SELECT @Size = SQRT(COUNT(1)) FROM ##Grid

    DELETE FROM ##ResultGrid

    IF @Size % 2 = 0 
    BEGIN

    PRINT 'Size: ' + CAST(@Size AS VARCHAR(4))
        
        ;WITH cte_StartingPoints AS (
            SELECT X, Y
            FROM ##Grid
            WHERE X%2 = 1 AND Y%2 = 1
        ), cte_Patterns AS (
            SELECT cSP.X, cSP.Y, CAST(G1.Field AS CHAR(1)) + CAST(G2.Field AS CHAR(1)) + CAST(G3.Field AS CHAR(1)) + CAST(G4.Field AS CHAR(1)) AS Pattern
            FROM cte_StartingPoints cSP
            INNER JOIN ##Grid G1 ON cSP.X     = G1.X AND cSP.Y = G1.Y
            INNER JOIN ##Grid G2 ON cSP.X + 1 = G2.X AND cSP.Y = G2.Y
            INNER JOIN ##Grid G3 ON cSP.X     = G3.X AND cSP.Y + 1 = G3.Y
            INNER JOIN ##Grid G4 ON cSP.X + 1 = G4.X AND cSP.Y + 1 = G4.Y
        ), cte_PatternNrs AS (
        SELECT cP.X, cP.Y, MIN(S2P.PatternNr) AS PatternNr
        FROM cte_Patterns cP
        INNER JOIN ##Size2Patterns S2P ON cP.Pattern = S2P.Pattern
        GROUP BY cP.X, cP.Y
        )
        INSERT ##ResultGrid (X, Y, Field)
        SELECT cPN.X / 2 * 3 + S3R.X AS X
        ,      cPN.Y / 2 * 3 + S3R.Y AS Y
        ,      S3R.Field
        FROM cte_PatternNrs cPN
        INNER JOIN ##Size3Results S3R ON cPN.PatternNr = S3R.PatternNr
        
    END
    ELSE
    BEGIN

    PRINT 'Size: ' + CAST(@Size AS VARCHAR(4))
        
        ;WITH cte_StartingPoints AS (
            SELECT X, Y
            FROM ##Grid
            WHERE X%3 = 1 AND Y%3 = 1
        ), cte_Patterns AS (
            SELECT cSP.X, cSP.Y, CAST(G1.Field AS CHAR(1)) + CAST(G2.Field AS CHAR(1)) + CAST(G3.Field AS CHAR(1)) +
                                 CAST(G4.Field AS CHAR(1)) + CAST(G5.Field AS CHAR(1)) + CAST(G6.Field AS CHAR(1)) +
                                 CAST(G7.Field AS CHAR(1)) + CAST(G8.Field AS CHAR(1)) + CAST(G9.Field AS CHAR(1)) AS Pattern
            FROM cte_StartingPoints cSP
            INNER JOIN ##Grid G1 ON cSP.X     = G1.X AND cSP.Y = G1.Y
            INNER JOIN ##Grid G2 ON cSP.X + 1 = G2.X AND cSP.Y = G2.Y
            INNER JOIN ##Grid G3 ON cSP.X + 2 = G3.X AND cSP.Y = G3.Y
            INNER JOIN ##Grid G4 ON cSP.X     = G4.X AND cSP.Y + 1 = G4.Y
            INNER JOIN ##Grid G5 ON cSP.X + 1 = G5.X AND cSP.Y + 1 = G5.Y
            INNER JOIN ##Grid G6 ON cSP.X + 2 = G6.X AND cSP.Y + 1 = G6.Y
            INNER JOIN ##Grid G7 ON cSP.X     = G7.X AND cSP.Y + 2 = G7.Y
            INNER JOIN ##Grid G8 ON cSP.X + 1 = G8.X AND cSP.Y + 2 = G8.Y
            INNER JOIN ##Grid G9 ON cSP.X + 2 = G9.X AND cSP.Y + 2 = G9.Y
        ), cte_PatternNrs AS (
        SELECT cP.X, cP.Y, MIN(S3P.PatternNr) AS PatternNr
        FROM cte_Patterns cP
        INNER JOIN ##Size3Patterns S3P ON cP.Pattern = S3P.Pattern
        GROUP BY cP.X, cP.Y
        )
        INSERT ##ResultGrid (X, Y, Field)
        SELECT cPN.X / 3 * 4 + S4R.X AS X
        ,      cPN.Y / 3 * 4 + S4R.Y AS Y
        ,      S4R.Field
        FROM cte_PatternNrs cPN
        INNER JOIN ##Size4Results S4R ON cPN.PatternNr = S4R.PatternNr

    END

    DELETE FROM ##Grid
    INSERT ##Grid (X, Y, Field) SELECT X, Y, Field FROM ##ResultGrid

    SET @Counter = @Counter + 1

END


SELECT SUM(Field) FROM ##Grid 
--> 188 is correct (Part 1)
--> 2758764 is correct (Part 2)

/*

DROP TABLE ##Grid
DROP TABLE ##ResultGrid

DROP TABLE ##Size2Patterns
DROP TABLE ##Size3Results 
DROP TABLE ##Size3Patterns
DROP TABLE ##Size4Results 

DROP TABLE ##Patterns
DROP TABLE ##Input


*/




/*

DECLARE @X INT
DECLARE @Y INT = 1
DECLARE @MaxX INT 
DECLARE @Str VARCHAR(MAX) = ''
SELECT @MaxX = MAX(X) FROM ##Grid

WHILE @Y < (SELECT MAX(Y) FROM ##Grid)
BEGIN

    SELECT @X = MIN(X) FROM ##Grid
    SET @Str = ''

    WHILE @X < @MaxX
    BEGIN
        
        SELECT @Str = @Str + CAST(Field AS CHAR(1)) FROM ##Grid WHERE X = @X AND Y = @Y

        SET @X = @X + 1

    END

    PRINT @Str

    SET @Y = @Y + 1

END 


*/