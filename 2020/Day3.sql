use Test_WME

SET NOCOUNT ON

CREATE TABLE #Input (Nr NVARCHAR(MAX));

BULK INSERT #Input
FROM 'C:\Source\AdventOfCode\2020\input3.txt'
WITH (ROWTERMINATOR = '0x0A');


--Create and fill the Grid table which is a map of the input
CREATE TABLE ##Grid (ID INT IDENTITY(1,1), x INT, y INT, val CHAR, UNIQUE(x,y))

;WITH cte_Grid AS (
    SELECT 0 AS x
    ,      ROW_NUMBER() OVER (ORDER BY(SELECT 0)) - 1 AS y
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
OPTION (MAXRECURSION 20000)

--SELECT * FROM ##Grid

DROP TABLE #Input

DECLARE @MaxX INT
DECLARE @MaxY INT
SELECT @MaxX = MAX(x) + 1, @Maxy = MAX(y) + 1 FROM ##Grid

DECLARE @Slope DECIMAL(5,2) = 0.5
DECLARE @Down INT = 2

;WITH cte_Path AS (
    SELECT (Y * @Slope)%@MaxX AS X
    , Y
    FROM ##Grid
    WHERE Y%@Down = 0
    GROUP BY Y
)
SELECT val, COUNT(1)
--*
FROM cte_Path G
LEFT JOIN  ##Grid P ON G.X = P.X AnD G.Y = P.Y
GROUP BY val
--ORDER BY G.Y

--DROP TABLE ##Grid


--61 is not correct for part 1
--199 is too low for part 1


/*
    Right 1, down 1. --72
    Right 3, down 1. --207
    Right 5, down 1. --90
    Right 7, down 1. --60
    Right 1, down 2. --33
*/

--SELECT CAST(72 AS BIGINT) *207*90*60*33
--3058300800 is too high

--2655892800 is correct for part 3