USE Test_WME

SET NOCOUNT ON

CREATE TABLE ##Input (Line NVARCHAR(MAX));

BULK INSERT ##Input
FROM 'C:\Source\AdventOfCode\2020\input24.txt'
WITH (ROWTERMINATOR = '0x0A');

CREATE TABLE ##Steps (ID INT IDENTITY(1,1), TileNr INT, StepNr INT, Step VARCHAR(5))

;WITH cte_Steps AS (
    SELECT ROW_NUMBER() OVER (ORDER BY (SELECT 0)) AS TileNr
    ,      1 AS StepNr
    ,      CASE WHEN LEFT(Line, 1) IN ('W', 'E') THEN LEFT(Line, 1) ELSE LEFT(Line,2) END AS Step
    ,      CASE WHEN LEFT(Line, 1) IN ('W', 'E') THEN SUBSTRING(Line, 2, LEN(Line)) ELSE SUBSTRING(Line, 3, LEN(Line)) END AS LeftOver
    FROM ##Input
    
    UNION ALL 

    SELECT TileNr
    ,      StepNr + 1
    ,      CASE WHEN LEFT(LeftOver, 1) IN ('W', 'E') THEN LEFT(LeftOver, 1) ELSE LEFT(LeftOver,2) END AS Step
    ,      CASE WHEN (LEFT(LeftOver, 1) IN ('W', 'E') AND LEN(LeftOver) = 1) OR (LEFT(LeftOver, 1) IN ('N', 'S') AND LEN(LeftOver) = 2) THEN '' ELSE
                CASE WHEN LEFT(LeftOver, 1) IN ('W', 'E') THEN SUBSTRING(LeftOver, 2, LEN(LeftOver)) ELSE SUBSTRING(LeftOver, 3, LEN(LeftOver)) END END AS LeftOver
    FROM cte_Steps
    WHERE LEN(LeftOver) > 0

)
INSERT ##Steps (TileNr, StepNr, Step)
SELECT TileNr, StepNr, Step
FROM cte_Steps


CREATE TABLE ##Tiles (ID INT IDENTITY(1,1), x INT, y INT, z INT, IsBlack INT, UNIQUE (x,y,z))

;WITH cte_Coords AS (
    SELECT TileNr
    ,      SUM(CASE WHEN Step IN ('ne','e') THEN 1
                WHEN Step IN ('w','sw')  THEN -1
                ELSE 0 END) AS x
    ,      SUM(CASE WHEN Step IN ('nw','w')  THEN 1
                WHEN Step IN ('e','se')  THEN -1
                ELSE 0 END) AS y
    ,      SUM(CASE WHEN Step IN ('sw','se')  THEN 1
                WHEN Step IN ('nw','ne')  THEN -1
                ELSE 0 END) AS z
    FROM ##Steps 
    GROUP BY TileNr
)
INSERT ##Tiles (x, y, z, IsBlack)
SELECT x,y,z, COUNT(1) % 2
FROM cte_Coords
GROUP BY x,y,z
--HAVING COUNT(1) % 2 = 1 --> See part 1


--507 is too high
--455 is correct for part 1

DECLARE @Sides TABLE (x INT, y INT, z INT)

;WITH cte_Delta AS (
        SELECT TOP 3 ROW_NUMBER() OVER (ORDER BY (SELECT 0)) - 2 AS Nr
        FROM sys.messages
    )
INSERT @Sides (x, y, z)
SELECT D1.Nr x, D2.Nr y, D3.Nr z
FROM cte_Delta D1
CROSS APPLY cte_Delta D2
CROSS APPLY cte_Delta D3
WHERE D1.Nr + D2.Nr + D3.Nr = 0
  AND (D1.Nr > 0 OR D2.Nr > 0 OR D3.Nr > 0)
    
DECLARE @Counter INT = 0
DECLARE @NrOfBlackTiles INT = 0 

SELECT @NrOfBlackTiles = SUM(IsBlack) FROM ##Tiles 
PRINT @NrOfBlackTiles

WHILE @Counter < 100
BEGIN

    ;WITH cte_AdjTiles AS (
        SELECT T.x + S.x AS x, T.y + S.y AS y, T.z + S.z AS z
        FROM ##Tiles T
        CROSS APPLY @Sides S 
    )
    INSERT ##Tiles (x, y, z, IsBlack)
    SELECT cAT.x, cAT.y, cAT.z, 0
    FROM cte_AdjTiles cAT
    LEFT JOIN ##Tiles T ON cAT.x = T.x AND cAT.y = T.y AND cAT.z = T.z
    WHERE T.ID IS NULL
    GROUP BY cAT.x, cAT.y, cAT.z

    ;WITH cte_AdjBlacks AS (
        SELECT T.ID, T.x, T.y, T.z, SUM(T2.IsBlack) AS AdjBlacks
        FROM ##Tiles T
        CROSS APPLY @Sides S 
        INNER JOIN ##Tiles T2 ON T.x + S.x = T2.x AND T.y + S.y = T2.y AND T.z + S.z = T2.z 
        GROUP BY T.ID, T.x, T.y, T.z
    )
    UPDATE T
    SET IsBlack = CASE WHEN T.IsBlack = 1 AND (cAB.AdjBlacks = 0 OR cAB.AdjBlacks > 2) THEN 0 -- Flip to white
                       WHEN T.IsBlack = 0 AND cAB.AdjBlacks = 2 THEN 1 --Flip to black
                       ELSE T.IsBlack END -- Do Nothing
    FROM ##Tiles T
    INNER JOIN cte_AdjBlacks cAB ON T.ID = cAB.ID

    --Any black tile with zero or more than 2 black tiles immediately adjacent to it is flipped to white.
    --Any white tile with exactly 2 black tiles immediately adjacent to it is flipped to black.

    SELECT @NrOfBlackTiles = SUM(IsBlack) FROM ##Tiles 
    PRINT 'Round: ' + CAST(@Counter AS VARCHAR(4)) + ' has nr of black tiles: ' + CAST(@NrOfBlackTiles AS VARCHAR(10))

    SET @Counter = @Counter + 1
END


--3904 is correct for part 2

/*

DROP TABLE ##Tiles
DROP TABLE ##Steps
DROP TABLE ##Input


*/