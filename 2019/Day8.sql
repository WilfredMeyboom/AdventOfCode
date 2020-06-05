use Test_WME

CREATE TABLE #Input (Nr NVARCHAR(MAX));

BULK INSERT #Input
FROM 'C:\Source\AdventOfCode\2019\input8.txt'
WITH (ROWTERMINATOR = '0x0A');

CREATE TABLE ##Pixels (ID INT IDENTITY(1,1), x INT, y INT, Layer INT, Val INT)

;WITH cte_Pixels AS (
    SELECT 0 AS x
    ,      0 AS y
    ,      0 AS Layer
    ,      SUBSTRING(Nr, 1, 1) AS Val
    ,      SUBSTRING(Nr, 2, LEN(Nr)) AS Rest
    FROM #Input
    UNION ALL
    SELECT CASE WHEN x + 1 < 25 THEN x + 1 ELSE 0 END AS x
    ,      CASE WHEN x + 1 < 25 THEN y ELSE CASE WHEN y + 1 < 6 THEN y + 1 ELSE 0 END END AS y
    ,      CASE WHEN x + 1 < 25 OR y + 1 < 6 THEN Layer ELSE Layer + 1 END AS Layer
    ,      SUBSTRING(Rest, 1, 1) AS Val
    ,      SUBSTRING(Rest, 2, LEN(Rest)) AS Rest
    FROM cte_Pixels
    WHERE LEN(Rest) > 0
)
INSERT ##Pixels(x, y, Layer, Val)
SELECT x, y, Layer, Val
FROM cte_Pixels
OPTION (MAXRECURSION 20000)

DROP TABLE #Input


SELECT Layer, COUNT(1) FROM ##Pixels 
WHERE Val = 0
GROUP BY Layer 
ORDER BY 2
--> Layer 5 has the least 0's

SELECT Val, COUNT(1)
FROM ##Pixels
WHERE Layer = 5
GROUP BY Val

SELECT 15*131

--1965 is correct for part 1

CREATE TABLE ##Image (ID INT IDENTITY(1,1), x INT, y INT, Val INT)

;WITH cte_Layers AS (
    SELECT x, y, MIN(Layer) AS Layer
    FROM ##Pixels
    WHERE Val <> 2
    GROUP BY x, y
)
INSERT ##Image (x, y, Val)
SELECT P.x, P.y, P.Val
FROM ##Pixels P
INNER JOIN cte_Layers cL ON P.x = cL.x
                        AND P.y = cL.Y
                        AND P.Layer = cL.Layer


DECLARE @x INT = 0
DECLARE @y INT = 0
DECLARE @Line VARCHAR(150)

PRINT 'XXXXXXXXXXXXXXXXXXXXXXXXXXX'
WHILE @y < 6
BEGIN
    SET @x = 0
    SET @Line = 'X'
    WHILE @x < 25
    BEGIN
        SELECT @Line = @Line + CASE WHEN Val = 1 THEN ' ' ELSE 'X' END FROM ##Image WHERE x = @x And y = @y

        SET @x = @x + 1
    END

    PRINT @Line + 'X'
    SET @y = @y + 1
END

PRINT 'XXXXXXXXXXXXXXXXXXXXXXXXXXX'

DROP TABLE ##Image
DROP TABLE ##Pixels
