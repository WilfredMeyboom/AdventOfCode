USE Test_WME

DECLARE @year VARCHAR(4) = '2015'
DECLARE @day VARCHAR(2)  = '2'

EXEC dbo.GetInput @year = @year, @day = @day
EXEC dbo.ParseInput @year = @year, @day = @day, @SplitCustom = 'x' 

--SELECT TOP 10 * FROM ##InputNumbered
--SELECT TOP 10 * FROM ##InputGrid
--SELECT TOP 10 * FROM ##InputInts
--SELECT TOP 10 * FROM ##InputSplit
SELECT TOP 10 * FROM ##InputSplitCust

--SELECT * FROM ##InputSplitCust ORDER BY RowNr, PieceNr

;WITH cte_Areas AS (
    SELECT RowNr, [1] * [2] AS lb, [2] * [3] AS bh, [1] * [3] AS lh
    FROM (
        SELECT RowNr, PieceNr, CAST(Piece AS INT) AS Piece
        FROM ##InputSplitCust
        ) T
    PIVOT (
            SUM(Piece)
            FOR PieceNr IN ([1],[2],[3])
            ) AS pivotTable
), cte_SmallestArea AS (
    SELECT RowNr
    , CASE WHEN lb < bh 
           THEN CASE WHEN lb < lh THEN lb ELSE lh END
           ELSE CASE WHEN bh < lh THEN bh ELSE lh END
           END AS smallestArea
    FROM cte_Areas
)
SELECT SUM(2 * cA.lb + 2 * cA.bh + 2 * cA.lh + cSA.smallestArea) AS Part1
FROM cte_Areas cA
INNER JOIN cte_SmallestArea cSA ON cA.RowNr = cSA.RowNr


-- 1588178 is correct for Part 1


;WITH cte_Areas AS (
    SELECT RowNr
    ,      [1] AS l
    ,      [2] AS b
    ,      [3] AS h
    ,      CASE WHEN [1] >= [2] AND [1] >= [3] THEN 2*([2] + [3])
                WHEN [2] >= [1] AND [2] >= [3] THEN 2*([1] + [3])
                WHEN [3] >= [1] AND [3] >= [2] THEN 2*([1] + [2])
           END AS Ribbon
    FROM (
        SELECT RowNr, PieceNr, CAST(Piece AS INT) AS Piece
        FROM ##InputSplitCust
        ) T
    PIVOT (
            SUM(Piece)
            FOR PieceNr IN ([1],[2],[3])
            ) AS pivotTable
), cte_Volume AS (
    SELECT RowNr
    ,      l*b*h AS Volume
    FROM cte_Areas    
)
SELECT SUM(Ribbon + Volume) AS Part2
FROM cte_Areas cA
INNER JOIN cte_Volume cV ON cA.RowNr = cV.RowNr

-- 3783758 is correct for part 2