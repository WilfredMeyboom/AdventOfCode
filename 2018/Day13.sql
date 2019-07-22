use Test_WME

SET NOCOUNT ON

CREATE TABLE #Input (Name NVARCHAR(MAX));

BULK INSERT #Input
FROM 'D:\Wilfred\AdventOfCode\input13.txt'
WITH (ROWTERMINATOR = '0x0A');


--SELECT MAX(LEN(Name)) * COUNT(1) FROM #Input
--UPDATE #Input
--SET Name = REPLACE(Name, ' ', '.')

--SELECT * FROM #Input

CREATE TABLE #Rails (ID INT IDENTITY(1,1), X INT, Y INT, Rail CHAR(1))

;WITH cte_Rails AS (
    SELECT LEFT(Name, 1) AS Rail
    ,      SUBSTRING(Name, 2, LEN(Name)) AS Remainder
    ,      ROW_NUMBER() OVER (ORDER BY (SELECT 0)) - 1 AS Y
    ,      0 AS X
    FROM #Input
    UNION ALL
    SELECT LEFT(Remainder, 1)
    ,      SUBSTRING(Remainder, 2, LEN(Remainder))
    ,      Y
    ,      X + 1
    FROM cte_Rails
    WHERE LEN(Remainder) > 0
)
INSERT #Rails (X, Y, Rail)
SELECT X --ROW_NUMBER() OVER (PARTITION BY Y ORDER BY Y) AS X -- -1 AS X
,      Y
,      Rail
FROM cte_Rails 
OPTION (MAXRECURSION 25000)

--SELECT * FROM #Input
--SELECT * FROM #Rails WHERE Y = 39 ORDER BY X


CREATE TABLE #Trains (ID INT IDENTITY(1,1), X INT, Y INT, PrevX INT, PrevY INT, Direction CHAR(1), PrevDirection CHAR(1))

INSERT #Trains (X, Y, PrevX, PrevY, Direction, PrevDirection) 
SELECT x, y, x, y, Rail, 'S'
FROM #Rails
WHERE Rail IN ('^','v','<','>')

UPDATE #Rails
SET Rail = '|'
WHERE Rail IN ('^','v')

UPDATE #Rails
SET Rail = '-'
WHERE Rail IN ('<','>')


-----------------------------------------------------------

DECLARE @CollisionOccurred INT = 0
DECLARE @Time INT = 0

WHILE (@CollisionOccurred <> 1)
BEGIN

--SELECT T.X, T.Y, T.Direction, T.PrevDirection, R.Rail FROM #Trains T INNER JOIN #Rails R ON T.X = R.X AND T.Y = R.Y WHERE T.ID = 7

    UPDATE #Trains
    SET PrevX = X
    ,   PrevY = Y

    UPDATE T
    SET T.X = CASE WHEN T.Direction = '<' THEN T.X - 1
                   WHEN T.Direction = '>' THEN T.X + 1
                   ELSE T.X
              END
    ,   T.Y = CASE WHEN T.Direction = '^' THEN T.Y - 1
                   WHEN T.Direction = 'v' THEN T.Y + 1
                   ELSE T.Y
              END
    FROM #Trains T
    INNER JOIN #Rails R ON T.X = R.X AND T.Y = R.Y

    UPDATE T
    SET T.Direction = CASE WHEN R.Rail = '\' AND T.Direction = '>' THEN 'v'
                           WHEN R.Rail = '\' AND T.Direction = '^' THEN '<'
                           WHEN R.Rail = '\' AND T.Direction = '<' THEN '^'
                           WHEN R.Rail = '\' AND T.Direction = 'v' THEN '>'
                           WHEN R.Rail = '/' AND T.Direction = '<' THEN 'v'
                           WHEN R.Rail = '/' AND T.Direction = 'v' THEN '<'
                           WHEN R.Rail = '/' AND T.Direction = '>' THEN '^'
                           WHEN R.Rail = '/' AND T.Direction = '^' THEN '>'
                      END
    FROM #Trains T
    INNER JOIN #Rails R ON T.X = R.X AND T.Y = R.Y
    WHERE R.Rail IN ('\','/')
   


    UPDATE T
    SET T.Direction = CASE WHEN T.PrevDirection = 'S' AND T.Direction = '^' THEN '<'
                           WHEN T.PrevDirection = 'L' AND T.Direction = '<' THEN '^'
                           WHEN T.PrevDirection = 'R' AND T.Direction = '>' THEN '>'

                           WHEN T.PrevDirection = 'S' AND T.Direction = 'v' THEN '>'
                           WHEN T.PrevDirection = 'L' AND T.Direction = '>' THEN 'v'
                           WHEN T.PrevDirection = 'R' AND T.Direction = '<' THEN '<'

                           WHEN T.PrevDirection = 'S' AND T.Direction = '<' THEN 'v'
                           WHEN T.PrevDirection = 'L' AND T.Direction = 'v' THEN '<'
                           WHEN T.PrevDirection = 'R' AND T.Direction = '^' THEN '^'

                           WHEN T.PrevDirection = 'S' AND T.Direction = '>' THEN '^'
                           WHEN T.PrevDirection = 'L' AND T.Direction = '^' THEN '>'
                           WHEN T.PrevDirection = 'R' AND T.Direction = 'v' THEN 'v'
                      END
    ,   T.PrevDirection = CASE WHEN T.PrevDirection = 'R' THEN 'L'
                               WHEN T.PrevDirection = 'L' THEN 'S'
                               WHEN T.PrevDirection = 'S' THEN 'R'
                          END
    FROM #Trains T
    INNER JOIN #Rails R ON T.X = R.X AND T.Y = R.Y
    WHERE R.Rail = '+'

    IF EXISTS (SELECT 1 FROM #Trains T1 INNER JOIN #Trains T2 ON (T1.X = T2.X AND T1.Y = T2.Y AND T1.ID <> T2.ID) OR (T1.X = T2.PrevX AND T1.Y = T2.PrevY AND T1.ID <> T2.ID AND (T1.Y < T2.Y OR (T1.Y = T2.Y AND T1.X < T2.X))))
        SELECT * FROM #Trains T1 INNER JOIN #Trains T2 ON (T1.X = T2.X AND T1.Y = T2.Y AND T1.ID <> T2.ID) OR (T1.X = T2.PrevX AND T1.Y = T2.PrevY AND T1.ID <> T2.ID AND (T1.Y < T2.Y OR (T1.Y = T2.Y AND T1.X < T2.X)))

    DELETE 
    FROM #Trains
    WHERE ID IN (
        SELECT T1.ID 
        FROM #Trains T1
        INNER JOIN #Trains T2 ON (T1.X = T2.X AND T1.Y = T2.Y AND T1.ID <> T2.ID) OR (T1.X = T2.PrevX AND T1.Y = T2.PrevY AND T1.ID <> T2.ID AND (T1.Y < T2.Y OR (T1.Y = T2.Y AND T1.X < T2.X)))
        UNION
        SELECT T2.ID 
        FROM #Trains T1
        INNER JOIN #Trains T2 ON (T1.X = T2.X AND T1.Y = T2.Y AND T1.ID <> T2.ID) OR (T1.X = T2.PrevX AND T1.Y = T2.PrevY AND T1.ID <> T2.ID AND (T1.Y < T2.Y OR (T1.Y = T2.Y AND T1.X < T2.X)))

    )


    PRINT 'Time: ' + CAST(@Time AS VARCHAR(10))
    SET @Time = @Time + 1

    SELECT @CollisionOccurred = 1 FROM #Trains WHERE X < 0 OR Y < 0 OR X > 150 OR Y > 150

    --SELECT @CollisionOccurred

    --SELECT * FROM #Trains

    SELECT @CollisionOccurred = COUNT(1) FROM #Trains


END

/*

SELECT * FROM #Trains ORDER BY X, Y
SELECT * FROM #Rails WHERE X = 7
SELECT * FROM #Rails WHERE Y = 39 ORDER BY X

DROP TABLE #Trains
DROP TABLE #Rails
DROP TABLE #Input


*/
--239

--29,117
--29,118
--29,119