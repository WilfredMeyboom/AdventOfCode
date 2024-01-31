USE Test_WME

SET NOCOUNT ON

DECLARE @year VARCHAR(4) = '2023'
DECLARE @day VARCHAR(2)  = '22'

EXEC dbo.GetInput @year = @year, @day = @day
EXEC dbo.ParseInput @year = @year, @day = @day, @SplitCustom = ',~' 

--SELECT TOP 10 * FROM ##Input
--SELECT TOP 10 * FROM ##InputInts
--SELECT TOP 10 * FROM ##InputNumbered
--SELECT TOP 10 * FROM ##InputGrid
--SELECT TOP 10 * FROM ##InputSplitCust

CREATE TABLE ##TowerSpace (ID INT IDENTITY(1,1), x INT, y INT, z INT, BlockNr INT)

;WITH cte_xy AS (
    SELECT TOP 10 ROW_NUMBER() OVER (ORDER BY (SELECT 0)) -1 AS Nr FROM sys.messages
), cte_z AS (
    SELECT TOP 350 ROW_NUMBER() OVER (ORDER BY (SELECT 0)) AS Nr FROM sys.messages
)
INSERT ##TowerSpace (x, y, z)
SELECT x.Nr, y.Nr, z.Nr
FROM cte_z Z
CROSS APPLY cte_xy X
CROSS APPLY cte_xy Y

;WITH cte_Bricks AS (
    SELECT RowNr, [1] AS xMin, [2] AS yMin, [3] AS zMin, [4] AS xMax, [5] AS yMax, [6] AS zMAX
    FROM (
        SELECT Rownr, PieceNr, Piece 
        FROM ##InputSplitCust
    ) Sub
    PIVOT (
        MAX(Piece)
        FOR PieceNr IN ([1],[2],[3],[4],[5],[6])
    ) Pvt
)
UPDATE TS
SET BlockNr = cB.RowNr
FROM ##TowerSpace TS
INNER JOIN cte_Bricks cB ON TS.x BETWEEN cB.xMin AND cB.xMax
                        AND TS.y BETWEEN cB.yMin AND cB.yMax
                        AND TS.z BETWEEN cB.zMin AND cB.zMax


CREATE TABLE ##BlocksList (ID INT IDENTITY(1,1), BlockNr INT, IsTopBlock INT, IsDisintegratable INT, FallingBlocks INT)
CREATE TABLE ##TempBlocks (ID INT IDENTITY(1,1), BlockNr INT, x INT, y INT, z INT)

DECLARE @Count INT = 1

WHILE @Count > 0
BEGIN

    ;WITH cte_zMin AS (
        SELECT TS.BlockNr, MIN(z) AS zMin
        FROM ##TowerSpace TS
        GROUP BY TS.BlockNr
    ), cte_zSize AS (
        SELECT TS.BlockNr, COUNT(1) AS zSize
        FROM ##TowerSpace TS 
        INNER JOIN cte_zMin cz ON cz.BlockNr = TS.BlockNr AND TS.z = cz.zMin
        GROUP BY TS.BlockNr
    ), cte_Unsupported AS (
        SELECT TS.BlockNr, COUNT(1) AS zSize
        FROM ##TowerSpace TS
        INNER JOIN ##TowerSpace TS2 ON TS.x = TS2.x AND TS.y = TS2.y AND TS.z = TS2.z + 1
        WHERE TS.BlockNr IS NOT NULL AND TS2.BlockNr IS NULL
        GROUP BY TS.BlockNr
    )
    INSERT ##BlocksList (BlockNr)
    SELECT c.BlockNr
    FROM cte_Unsupported c
    INNER JOIN cte_zSize cz ON cz.BlockNr = c.BlockNr
    WHERE cz.zSize = c.zSize

    SET @Count = @@ROWCOUNT

    INSERT ##TempBlocks(BlockNr, x, y, z)
    SELECT TS.BlockNr, x, y, z
    FROM ##TowerSpace TS
    INNER JOIN ##BlocksList UB ON UB.BlockNr = TS.BlockNr

    UPDATE TS
    SET BlockNr = NULL
    FROM ##TowerSpace TS
    INNER JOIN ##BlocksList UB ON UB.BlockNr = TS.BlockNr

    UPDATE TS
    SET BlockNr = TB.BlockNr
    FROM ##TowerSpace TS
    INNER JOIN ##TempBlocks TB ON TB.x = TS.x AND TB.y = TS.y AND TB.z = TS.z + 1
    
    DELETE FROM ##TempBlocks
    DELETE FROM ##BlocksList

END

INSERT ##BlocksList
(
    BlockNr
)
SELECT DISTINCT BlockNr FROM ##TowerSpace TS WHERE TS.BlockNr IS NOT NULL

-- Blocks without anything on top can be disintegrated
-- Blocks that are supporting blocks that are also supported by other blocks

;WITH cte_BlockTopBottom AS (
    SELECT BlockNr, MIN(z) AS zMin, MAX(z) AS zMax
    FROM ##TowerSpace TS
    GROUP BY TS.BlockNr
), cte_ThisBlockSupports AS (
    SELECT TS.BlockNr, TS2.BlockNr AS SupportedBlock
    FROM ##TowerSpace TS
    INNER JOIN cte_BlockTopBottom cB ON cB.BlockNr = TS.BlockNr AND cB.zMax = TS.z
    INNER JOIN ##TowerSpace TS2 ON TS2.x = TS.x AND TS2.y = TS.y AND TS2.z = TS.z + 1
    WHERE TS2.BlockNr IS NOT NULL
    GROUP BY TS.BlockNr, TS2.BlockNr
), cte_ThisBlockIsSupportedBy AS (
    SELECT TS.BlockNr, TS2.BlockNr AS SupportingBlock
    FROM ##TowerSpace TS
    INNER JOIN cte_BlockTopBottom cB ON cB.BlockNr = TS.BlockNr AND cB.zMin = TS.z
    INNER JOIN ##TowerSpace TS2 ON TS2.x = TS.x AND TS2.y = TS.y AND TS2.z = TS.z - 1
    WHERE TS2.BlockNr IS NOT NULL
    GROUP BY TS.BlockNr, TS2.BlockNr
), cte_BlocksNotToDisintigrate AS (
    SELECT BL.BlockNr
    FROM ##BlocksList BL
    INNER JOIN cte_ThisBlockSupports c1 ON c1.BlockNr = BL.BlockNr
    LEFT JOIN cte_ThisBlockIsSupportedBy c2 ON c1.SupportedBlock = c2.BlockNr AND c2.SupportingBlock <> BL.BlockNr
    WHERE c2.BlockNr IS NULL
    GROUP BY BL.BlockNr
), cte_BlocksWithoutAnythingOnTop AS (
    SELECT BL.BlockNr
    FROM ##BlocksList BL
    LEFT JOIN cte_ThisBlockSupports c ON c.BlockNr = BL.BlockNr
    WHERE c.BlockNr IS NULL
)
UPDATE BL
SET BL.IsTopBlock = CASE WHEN c2.BlockNr IS NOT NULL THEN 1 ELSE 0 END
,   BL.IsDisintegratable = CASE WHEN c.BlockNr IS NULL THEN 1 ELSE 0 END
FROM ##BlocksList BL
LEFT JOIN cte_BlocksNotToDisintigrate c ON BL.BlockNr = c.BlockNr
LEFT JOIN cte_BlocksWithoutAnythingOnTop c2 ON c2.BlockNr = BL.BlockNr

SELECT COUNT(1) AS Part1 FROM ##BlocksList BL WHERE BL.IsTopBlock = 1 OR BL.IsDisintegratable = 1

UPDATE BL
SET BL.FallingBlocks = 0
FROM ##BlocksList BL
WHERE BL.IsTopBlock = 1 OR BL.IsDisintegratable = 1

CREATE TABLE ##ThisBlockSupports (ID INT IDENTITY(1,1), BlockNr INT, SupportedBlock INT, IsFalling INT)
CREATE TABLE ##ThisBlockIssupportedBy (ID INT IDENTITY(1,1), BlockNr INT, SupportingBlock INT)


;WITH cte_BlockTopBottom AS (
    SELECT BlockNr, MIN(z) AS zMin, MAX(z) AS zMax
    FROM ##TowerSpace TS
    GROUP BY TS.BlockNr
)
INSERT ##ThisBlockSupports (BlockNr, SupportedBlock)
SELECT TS.BlockNr, TS2.BlockNr AS SupportedBlock
FROM ##TowerSpace TS
INNER JOIN cte_BlockTopBottom cB ON cB.BlockNr = TS.BlockNr AND cB.zMax = TS.z
INNER JOIN ##TowerSpace TS2 ON TS2.x = TS.x AND TS2.y = TS.y AND TS2.z = TS.z + 1
--WHERE TS2.BlockNr IS NOT NULL
GROUP BY TS.BlockNr, TS2.BlockNr


;WITH cte_BlockTopBottom AS (
    SELECT BlockNr, MIN(z) AS zMin, MAX(z) AS zMax
    FROM ##TowerSpace TS
    GROUP BY TS.BlockNr
)
INSERT ##ThisBlockIssupportedBy (BlockNr, SupportingBlock)
SELECT TS.BlockNr, TS2.BlockNr AS SupportingBlock
FROM ##TowerSpace TS
INNER JOIN cte_BlockTopBottom cB ON cB.BlockNr = TS.BlockNr AND cB.zMin = TS.z
INNER JOIN ##TowerSpace TS2 ON TS2.x = TS.x AND TS2.y = TS.y AND TS2.z = TS.z - 1
WHERE TS2.BlockNr IS NOT NULL
GROUP BY TS.BlockNr, TS2.BlockNr

/* declare variables */
DECLARE @BlockNr INT

DECLARE BlockCursor CURSOR FAST_FORWARD READ_ONLY FOR SELECT BlockNr FROM ##BlocksList BL WHERE BL.FallingBlocks IS NULL

OPEN BlockCursor

FETCH NEXT FROM BlockCursor INTO @BlockNr

WHILE @@FETCH_STATUS = 0
BEGIN
    
    SET @Count = 1
    UPDATE ##ThisBlockSupports
    SET IsFalling = NULL

    UPDATE ##ThisBlockSupports
    SET IsFalling = 1
    WHERE BlockNr = @BlockNr

    WHILE @Count > 0
    BEGIN

        ;WITH cte_UnableToFall AS (
            SELECT T1.BlockNr
            FROM ##ThisBlockSupports T1
            INNER JOIN ##ThisBlockSupports T2 ON T1.BlockNr = T2.SupportedBlock
            INNER JOIN ##ThisBlockIssupportedBy T3 ON T3.BlockNr = T1.BlockNr
            INNER JOIN ##ThisBlockSupports T4 ON T4.BlockNr = T3.SupportingBlock
            WHERE T2.IsFalling = 1 AND T4.IsFalling IS NULL
        )
        UPDATE T1
        SET T1.IsFalling = 1
        FROM ##ThisBlockSupports T1
        INNER JOIN ##ThisBlockSupports T2 ON T1.BlockNr = T2.SupportedBlock
        LEFT JOIN cte_UnableToFall c ON c.BlockNr = T1.BlockNr
        WHERE T2.IsFalling = 1 AND c.BlockNr IS NULL AND T1.IsFalling IS NULL

        SET @Count = @@ROWCOUNT

    END

    ;WITH cte_BlocksToFall AS (
        SELECT @BlockNr AS BlockNr, COUNT(DISTINCT BlockNr) AS Amt
        FROM ##ThisBlockSupports T
        WHERE T.BlockNr <> @BlockNr AND T.IsFalling = 1
    )
    UPDATE BL
    SET FallingBlocks = c.Amt
    FROM ##BlocksList BL
    INNER JOIN cte_BlocksToFall c ON c.BlockNr = BL.BlockNr

    FETCH NEXT FROM BlockCursor INTO @BlockNr
END

CLOSE BlockCursor
DEALLOCATE BlockCursor



SELECT SUM(BL.FallingBlocks) FROM ##BlocksList BL
--SELECT * FROM ##BlocksList BL

--SELECT * FROM ##ThisBlockSupports TBS
--2240 too low

/*


DROP TABLE ##TowerSpace
DROP TABLE ##BlocksList
DROP TABLE ##TempBlocks
DROP TABLE ##ThisBlockSupports
DROP TABLE ##ThisBlockIssupportedBy

*/

