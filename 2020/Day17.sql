use Test_WME

SET NOCOUNT ON

CREATE TABLE ##Input (Line NVARCHAR(MAX));

BULK INSERT ##Input
FROM 'C:\Source\AdventOfCode\2020\input17.txt'
WITH (ROWTERMINATOR = '0x0A');


--Create and fill the Grid table which is a map of the input
CREATE TABLE ##Grid (ID INT IDENTITY(1,1), x INT, y INT, z INT, val INT)

ALTER TABLE ##Grid ADD CONSTRAINT uq_Grid UNIQUE (x,y,z)

;WITH cte_Grid AS (
    SELECT 0 AS x
    ,      ROW_NUMBER() OVER (ORDER BY(SELECT 0)) - 1 AS y
    ,      LEFT(Line, 1) AS val
    ,      SUBSTRING(Line, 2, LEN(Line)) AS Rest
    FROM ##Input
    UNION ALL
    SELECT x + 1
    ,      y
    ,      LEFT(Rest, 1)
    ,      SUBSTRING(Rest, 2, LEN(Rest))
    FROM cte_Grid
    WHERE LEN(Rest) > 0
)
INSERT ##Grid(x, y, z, val)
SELECT x, y, 0, CASE WHEN val = '#' THEN 1 ELSE 0 END
FROM cte_Grid
OPTION (MAXRECURSION 20000)

--SELECT * FROM ##Grid

DECLARE @Counter INT = 0

DECLARE @MaxX INT
DECLARE @MinX INT
DECLARE @MaxY INT
DECLARE @MinY INT
DECLARE @MaxZ INT
DECLARE @MinZ INT
DECLARE @MaxW INT
DECLARE @MinW INT

DECLARE @DoPart2 INT = 1

IF @DoPart2 = 0 
BEGIN

WHILE @Counter < 6
BEGIN
    
    -- Find the edges of the grid
    SELECT @MaxX = MAX(x)
    ,      @MinX = MIN(x)
    ,      @MaxY = MAX(y)
    ,      @MinY = MIN(y)
    ,      @MaxZ = MAX(z)
    ,      @MinZ = MIN(z)
    FROM ##Grid
 
    -- Add new points to the grid
    ;WITH cte_x AS (
        SELECT TOP (@MaxX - @MinX + 3) ROW_NUMBER() OVER (ORDER BY (SELECT 0)) + @MinX - 2 AS x FROM sys.messages 
    ), cte_y AS (
        SELECT TOP (@MaxY - @MinY + 3) ROW_NUMBER() OVER (ORDER BY (SELECT 0)) + @MinY - 2 AS y FROM sys.messages 
    ), cte_z AS (
        SELECT TOP (@MaxZ - @MinZ + 3) ROW_NUMBER() OVER (ORDER BY (SELECT 0)) + @MinZ - 2 AS z FROM sys.messages 
    ), cte_ExpandedGrid AS (
        SELECT x, y, z
        FROM cte_x CROSS APPLY cte_y CROSS APPLY cte_z
    )
    INSERT ##Grid (x, y, z, val)
    SELECT EG.x, EG.y, EG.z, 0
    FROM cte_ExpandedGrid EG
    LEFT JOIN ##Grid G ON EG.x = G.x AND EG.y = G.y And EG.z = G.z
    WHERE G.ID IS NULL
 
    -- Change grid
    ;WITH cte_ActiveNeighbours AS (
        SELECT G1.ID, SUM(G2.val) AS TotalActiveNeighbours
        FROM ##Grid G1
        INNER JOiN ##Grid G2 ON ABS(G1.x - G2.x) <= 1
                            AND ABS(G1.y - G2.y) <= 1
                            AND ABS(G1.z - G2.z) <= 1
                            AND G1.ID <> G2.ID
        GROUP BY G1.ID
    )
    UPDATE G
    SET val = CASE WHEN G.val = 1 AND cAN.TotalActiveNeighbours IN (2,3) THEN 1
                   WHEN G.val = 1 THEN 0
                   WHEN G.val = 0 AND cAN.TotalActiveNeighbours = 3 THEN 1
                   ELSE G.val END
    FROM ##Grid G
    INNER JOIN cte_ActiveNeighbours cAN ON G.ID = cAN.ID 
   
    --SELECT COUNT(1) FROM ##Grid WHERE val = 1

    SET @Counter = @Counter + 1
END

SELECT COUNT(1) FROM ##Grid WHERE val = 1

END

--590 is too high for part 1
--333 is correct for part 1

ELSE -- DoPart2

BEGIN

ALTER TABLE ##Grid ADD w INT
UPDATE ##Grid SET w = 0

ALTER TABLE ##Grid DROP CONSTRAINT uq_Grid 
ALTER TABLE ##Grid ADD CONSTRAINT uq_Grid UNIQUE (x,y,z,w)


WHILE @Counter < 6
BEGIN
    
    -- Find the edges of the grid
    SELECT @MaxX = MAX(x)
    ,      @MinX = MIN(x)
    ,      @MaxY = MAX(y)
    ,      @MinY = MIN(y)
    ,      @MaxZ = MAX(z)
    ,      @MinZ = MIN(z)
    ,      @MaxW = MAX(w)
    ,      @MinW = MIN(w)
    FROM ##Grid
 
    -- Add new points to the grid
    ;WITH cte_x AS (
        SELECT TOP (@MaxX - @MinX + 3) ROW_NUMBER() OVER (ORDER BY (SELECT 0)) + @MinX - 2 AS x FROM sys.messages 
    ), cte_y AS (
        SELECT TOP (@MaxY - @MinY + 3) ROW_NUMBER() OVER (ORDER BY (SELECT 0)) + @MinY - 2 AS y FROM sys.messages 
    ), cte_z AS (
        SELECT TOP (@MaxZ - @MinZ + 3) ROW_NUMBER() OVER (ORDER BY (SELECT 0)) + @MinZ - 2 AS z FROM sys.messages 
    ), cte_w AS (
        SELECT TOP (@MaxW - @MinW + 3) ROW_NUMBER() OVER (ORDER BY (SELECT 0)) + @MinW - 2 AS w FROM sys.messages 
    ), cte_ExpandedGrid AS (
        SELECT x, y, z, w
        FROM cte_x CROSS APPLY cte_y CROSS APPLY cte_z CROSS APPLY cte_w
    )
    INSERT ##Grid (x, y, z, w, val)
    SELECT EG.x, EG.y, EG.z, EG.w, 0
    FROM cte_ExpandedGrid EG
    LEFT JOIN ##Grid G ON EG.x = G.x AND EG.y = G.y AND EG.z = G.z AND EG.w = G.w
    WHERE G.ID IS NULL
 
    -- Change grid
    ;WITH cte_ActiveNeighbours AS (
        SELECT G1.ID, SUM(G2.val) AS TotalActiveNeighbours
        FROM ##Grid G1
        INNER JOiN ##Grid G2 ON ABS(G1.x - G2.x) <= 1
                            AND ABS(G1.y - G2.y) <= 1
                            AND ABS(G1.z - G2.z) <= 1
                            AND ABS(G1.w - G2.w) <= 1
                            AND G1.ID <> G2.ID
        GROUP BY G1.ID
    )
    UPDATE G
    SET val = CASE WHEN G.val = 1 AND cAN.TotalActiveNeighbours IN (2,3) THEN 1
                   WHEN G.val = 1 THEN 0
                   WHEN G.val = 0 AND cAN.TotalActiveNeighbours = 3 THEN 1
                   ELSE G.val END
    FROM ##Grid G
    INNER JOIN cte_ActiveNeighbours cAN ON G.ID = cAN.ID 
   
    --SELECT COUNT(1) FROM ##Grid WHERE val = 1

    SET @Counter = @Counter + 1

    PRINT 'Iteration done ' + CAST(@Counter AS VARCHAR(10))
END

SELECT COUNT(1) FROM ##Grid WHERE val = 1

END

--2676 is correct for part 2

/*

DROP TABLE ##Input
DROP TABLE ##Grid

*/
