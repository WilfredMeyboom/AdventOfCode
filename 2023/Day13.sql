USE Test_WME

SET NOCOUNT ON

DECLARE @year VARCHAR(4) = '2023'
DECLARE @day VARCHAR(2)  = '13'

EXEC dbo.GetInput @year = @year, @day = @day
EXEC dbo.ParseInput @year = @year, @day = @day 

--SELECT TOP 10 * FROM ##Input
--SELECT TOP 10 * FROM ##InputInts
--SELECT TOP 10 * FROM ##InputNumbered
--SELECT TOP 10 * FROM ##InputSplit
--SELECT TOP 10 * FROM ##InputSplitCust

-- We'll be cutting up the grid into individual maps. For this there needs to be an empty row below the input
INSERT ##InputGrid (RowNr, ColNr, Val)
SELECT MAX(RowNr) + 1, 0, NULL FROM ##InputGrid
  
CREATE TABLE ##Maps (ID INT IDENTITY(1,1), MapNr INT, RowNr INT, ColNr INT, Val CHAR)

-- Fill a table with all map data (per map, per row, per column)
;WITH cte_Rows2Map AS (
    SELECT ROW_NUMBER() OVER (ORDER BY RowNr) AS MapNr
    ,      ISNULL(LAG(RowNr) OVER (ORDER BY RowNr) + 1, 0) AS StartRowNr
    ,      RowNr AS EndRowNr
    FROM ##InputGrid
    WHERE Val IS NULL
)
INSERT ##Maps (MapNr, RowNr, ColNr, Val)
SELECT c.MapNr, I.RowNr - c.StartRowNr, I.ColNr, I.Val
FROM ##InputGrid I
INNER JOIN cte_Rows2Map c ON I.RowNr BETWEEN c.StartRowNr AND c.EndRowNr
WHERE I.Val IS NOT NULL
ORDER BY MapNr, RowNr, ColNr


CREATE TABLE ##MirrorLines (ID INT IDENTITY(1,1), MapNr INT, RowOrColNr INT, RowOrCol CHAR(3), RowSize INT, ColSize INT)

-- Find any lines (horizontal and vertical) where the first row/column is the same on both sides
;WITH cte_MirrorOverRow AS (
    SELECT M1.MapNr, M1.RowNr, COUNT(1) AS NrOfMatchingVals, 'Row' AS MirrorDir
    FROM ##Maps M1
    INNER JOIN ##Maps M2 ON M1.MapNr = M2.MapNr 
                        AND M1.RowNr = M2.RowNr - 1 
                        AND M1.ColNr = M2.ColNr
                        AND M1.Val = M2.Val
    GROUP BY M1.MapNr, M1.RowNr
), cte_MirrorOverCol AS (
    SELECT M1.MapNr, M1.ColNr, COUNT(1) AS NrOfMatchingVals, 'Col' AS MirrorDir
    FROM ##Maps M1
    INNER JOIN ##Maps M2 ON M1.MapNr = M2.MapNr 
                        AND M1.RowNr = M2.RowNr
                        AND M1.ColNr = M2.ColNr - 1
                        AND M1.Val = M2.Val
    GROUP BY M1.MapNr, M1.ColNr
), cte_Mapsize AS (
    SELECT MapNr, MAX(RowNr) - MIN(RowNr) + 1 AS RowSize, MAX(ColNr) - MIN(ColNr) + 1 AS ColSize
    FROM ##Maps
    GROUP BY MapNr
)
INSERT ##MirrorLines (MapNr, RowOrColNr, RowOrCol, RowSize, ColSize)
SELECT cM.MapNr, CMOR.RowNr, CMOR.MirrorDir, cM.RowSize, cM.ColSize 
FROM cte_Mapsize cM
INNER JOIN cte_MirrorOverRow CMOR ON cM.MapNr = CMOR.MapNr AND CMOR.NrOfMatchingVals = cM.ColSize

UNION 

SELECT cM.MapNr, CMOC.ColNr, CMOC.MirrorDir, cM.RowSize, cM.ColSize 
FROM cte_Mapsize cM
INNER JOIN cte_MirrorOverCol CMOC ON cM.MapNr = CMOC.MapNr AND CMOC.NrOfMatchingVals = cM.RowSize
ORDER BY cM.MapNr

-- Based on these mirrorlines, fold the entire area to make sure it is exactly mirrored
;WITH cte_Rect AS (
    SELECT ML.ID,
           ML.MapNr,
           ML.RowOrColNr,
           ML.RowOrCol,
           ML.RowSize,
           ML.ColSize
    ,      CASE WHEN RowOrCol = 'Row' AND (RowSize + 1) / 2 >= ML.RowOrColNr THEN 0 
                WHEN RowOrCol = 'Row' AND (RowSize + 1) / 2 < ML.RowOrColNr THEN 2 * ML.RowOrColNr - (ML.RowSize - 1) + 1
                ELSE 0 
           END AS StartRowUp
    ,      CASE WHEN RowOrCol = 'Row' THEN ML.RowOrColNr
                ELSE RowSize 
           END AS EndRowUp
    ,      CASE WHEN RowOrCol = 'Row' THEN ML.RowOrColNr + 1
                ELSE 0 
           END AS StartRowDown
    ,      CASE WHEN RowOrCol = 'Row' AND (RowSize + 1) / 2 >= ML.RowOrColNr THEN 2 * ML.RowOrColNr + 1
                WHEN RowOrCol = 'Row' AND (RowSize + 1) / 2 < ML.RowOrColNr THEN ML.RowSize - 1
                ELSE ML.RowSize 
           END AS EndRowDown

    ,      CASE WHEN RowOrCol = 'Col' AND (ColSize + 1) / 2 >= ML.RowOrColNr THEN 0 
                WHEN RowOrCol = 'Col' AND (ColSize + 1) / 2 < ML.RowOrColNr THEN 2 * ML.RowOrColNr - (ML.ColSize - 1) + 1
                ELSE 0
           END AS StartColLeft
    ,      CASE WHEN RowOrCol = 'Col' THEN ML.RowOrColNr
                ELSE ColSize
           END AS EndColLeft
    ,      CASE WHEN RowOrCol = 'Col' THEN ML.RowOrColNr + 1
                ELSE 0
           END AS StartColRight
    ,      CASE WHEN RowOrCol = 'Col' AND (ColSize + 1) / 2 >= ML.RowOrColNr THEN 2 * ML.RowOrColNr + 1
                WHEN RowOrCol = 'Col' AND (ColSize + 1) / 2 < ML.RowOrColNr THEN ML.ColSize - 1
                ELSE ColSize
           END AS EndColRight
    FROM ##MirrorLines ML
), cte_Mirror AS (
    SELECT c.MapNr
    ,      c.RowOrColNr
    ,      c.RowOrCol
    ,      M.RowNr
    ,      M.ColNr
    ,      CASE WHEN c.RowOrCol = 'Col' THEN M.RowNr ELSE (2 * c.RowOrColNr + 1) - M.RowNr END AS MirrorRow
    ,      CASE WHEN c.RowOrCol = 'Row' THEN M.ColNr ELSE (2 * c.RowOrColNr + 1) - M.ColNr END AS MirrorCol
    ,      M.Val
    FROM cte_Rect c
    LEFT JOIN ##Maps M ON M.RowNr BETWEEN c.StartRowDown AND c.EndRowDown AND M.ColNr BETWEEN c.StartColRight AND c.EndColRight AND M.MapNr = c.MapNr
), cte_Sizes AS (
    SELECT c.MapNr
    ,      c.RowOrColNr
    ,      c.RowOrCol
    ,      SUM(1) AS Size
    ,      SUM(CASE WHEN c.Val = M.Val THEN 1 ELSE 0 END) AS MatchingSize
    FROM cte_Mirror c
    INNER JOIN ##Maps M ON M.MapNr = c.MapNr AND M.RowNr = c.MirrorRow AND M.ColNr = c.MirrorCol
    GROUP BY c.MapNr, c.RowOrColNr, c.RowOrCol
)
SELECT SUM(CASE WHEN RowOrCol = 'Col' THEN RowOrColNr + 1 ELSE 0 END)
+      SUM(CASE WHEN RowOrCol = 'Row' THEN RowOrColNr + 1 ELSE 0 END) * 100 AS Part1
FROM cte_Sizes
WHERE Size = MatchingSize


-- Basically we do the same, find all mirror lines (horizontal and vertical) but we allow for 1 mismatch between left <-> right / top <-> down
;WITH cte_MirrorOverRow AS (
    SELECT M1.MapNr, M1.RowNr, COUNT(1) AS NrOfMatchingVals, 'Row' AS MirrorDir
    FROM ##Maps M1
    INNER JOIN ##Maps M2 ON M1.MapNr = M2.MapNr 
                        AND M1.RowNr = M2.RowNr - 1 
                        AND M1.ColNr = M2.ColNr
                        AND M1.Val = M2.Val
    GROUP BY M1.MapNr, M1.RowNr
), cte_MirrorOverCol AS (
    SELECT M1.MapNr, M1.ColNr, COUNT(1) AS NrOfMatchingVals, 'Col' AS MirrorDir
    FROM ##Maps M1
    INNER JOIN ##Maps M2 ON M1.MapNr = M2.MapNr 
                        AND M1.RowNr = M2.RowNr
                        AND M1.ColNr = M2.ColNr - 1
                        AND M1.Val = M2.Val
    GROUP BY M1.MapNr, M1.ColNr
), cte_Mapsize AS (
    SELECT MapNr, MAX(RowNr) - MIN(RowNr) + 1 AS RowSize, MAX(ColNr) - MIN(ColNr) + 1 AS ColSize
    FROM ##Maps
    GROUP BY MapNr
)
INSERT ##MirrorLines (MapNr, RowOrColNr, RowOrCol, RowSize, ColSize)
SELECT cM.MapNr, CMOR.RowNr, CMOR.MirrorDir, cM.RowSize, cM.ColSize 
FROM cte_Mapsize cM
INNER JOIN cte_MirrorOverRow CMOR ON cM.MapNr = CMOR.MapNr AND CMOR.NrOfMatchingVals = cM.ColSize - 1

UNION 

SELECT cM.MapNr, CMOC.ColNr, CMOC.MirrorDir, cM.RowSize, cM.ColSize 
FROM cte_Mapsize cM
INNER JOIN cte_MirrorOverCol CMOC ON cM.MapNr = CMOC.MapNr AND CMOC.NrOfMatchingVals = cM.RowSize - 1
ORDER BY cM.MapNr


-- Based on this expanded set of mirrorlines, again fold the entire area and check when there is exactly one difference in the areas
;WITH cte_Rect AS (
    SELECT ML.ID,
           ML.MapNr,
           ML.RowOrColNr,
           ML.RowOrCol,
           ML.RowSize,
           ML.ColSize
    ,      CASE WHEN RowOrCol = 'Row' AND (RowSize + 1) / 2 >= ML.RowOrColNr THEN 0 
                WHEN RowOrCol = 'Row' AND (RowSize + 1) / 2 < ML.RowOrColNr THEN 2 * ML.RowOrColNr - (ML.RowSize - 1) + 1
                ELSE 0 
           END AS StartRowUp
    ,      CASE WHEN RowOrCol = 'Row' THEN ML.RowOrColNr
                ELSE RowSize 
           END AS EndRowUp
    ,      CASE WHEN RowOrCol = 'Row' THEN ML.RowOrColNr + 1
                ELSE 0 
           END AS StartRowDown
    ,      CASE WHEN RowOrCol = 'Row' AND (RowSize + 1) / 2 >= ML.RowOrColNr THEN 2 * ML.RowOrColNr + 1
                WHEN RowOrCol = 'Row' AND (RowSize + 1) / 2 < ML.RowOrColNr THEN ML.RowSize - 1
                ELSE ML.RowSize 
           END AS EndRowDown

    ,      CASE WHEN RowOrCol = 'Col' AND (ColSize + 1) / 2 >= ML.RowOrColNr THEN 0 
                WHEN RowOrCol = 'Col' AND (ColSize + 1) / 2 < ML.RowOrColNr THEN 2 * ML.RowOrColNr - (ML.ColSize - 1) + 1
                ELSE 0
           END AS StartColLeft
    ,      CASE WHEN RowOrCol = 'Col' THEN ML.RowOrColNr
                ELSE ColSize
           END AS EndColLeft
    ,      CASE WHEN RowOrCol = 'Col' THEN ML.RowOrColNr + 1
                ELSE 0
           END AS StartColRight
    ,      CASE WHEN RowOrCol = 'Col' AND (ColSize + 1) / 2 >= ML.RowOrColNr THEN 2 * ML.RowOrColNr + 1
                WHEN RowOrCol = 'Col' AND (ColSize + 1) / 2 < ML.RowOrColNr THEN ML.ColSize - 1
                ELSE ColSize
           END AS EndColRight
    FROM ##MirrorLines ML
), cte_Mirror AS (
    SELECT c.MapNr
    ,      c.RowOrColNr
    ,      c.RowOrCol
    ,      M.RowNr
    ,      M.ColNr
    ,      CASE WHEN c.RowOrCol = 'Col' THEN M.RowNr ELSE (2 * c.RowOrColNr + 1) - M.RowNr END AS MirrorRow
    ,      CASE WHEN c.RowOrCol = 'Row' THEN M.ColNr ELSE (2 * c.RowOrColNr + 1) - M.ColNr END AS MirrorCol
    ,      M.Val
    FROM cte_Rect c
    LEFT JOIN ##Maps M ON M.RowNr BETWEEN c.StartRowDown AND c.EndRowDown AND M.ColNr BETWEEN c.StartColRight AND c.EndColRight AND M.MapNr = c.MapNr
), cte_Sizes AS (
    SELECT c.MapNr
    ,      c.RowOrColNr
    ,      c.RowOrCol
    ,      SUM(1) AS Size
    ,      SUM(CASE WHEN c.Val = M.Val THEN 1 ELSE 0 END) AS MatchingSize
    FROM cte_Mirror c
    INNER JOIN ##Maps M ON M.MapNr = c.MapNr AND M.RowNr = c.MirrorRow AND M.ColNr = c.MirrorCol
    GROUP BY c.MapNr, c.RowOrColNr, c.RowOrCol
)
SELECT SUM(CASE WHEN RowOrCol = 'Col' THEN RowOrColNr + 1 ELSE 0 END)
+      SUM(CASE WHEN RowOrCol = 'Row' THEN RowOrColNr + 1 ELSE 0 END) * 100 AS Part2
FROM cte_Sizes
WHERE Size = MatchingSize + 1


/*

DROP TABLE ##Maps
DROP TABLE ##MirrorLines

*/

