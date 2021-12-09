USE Test_WME

SET NOCOUNT ON

DECLARE @year VARCHAR(4) = '2021'
DECLARE @day VARCHAR(2)  = '9'

EXEC dbo.GetInput @year = @year, @day = @day
EXEC dbo.ParseInput @year = @year, @day = @day 

--SELECT TOP 10 * FROM ##InputNumbered
SELECT TOP 10 * FROM ##InputGrid
--SELECT TOP 10 * FROM ##InputInts
--SELECT TOP 10 * FROM ##InputSplit
--SELECT TOP 10 * FROM ##InputSplitCust


;WITH cte_Low AS (
    SELECT M.RowNr
    ,      M.ColNr
    ,      M.Val
    ,      COUNT(1) AS NrOfAdjecentPoints
    ,      SUM(CASE WHEN M.Val < LR.Val THEN 1 ELSE 0 END) AS NrOfHigherPoints
    FROM ##InputGrid M
    LEFT JOIN ##InputGrid LR ON (M.RowNr = LR.RowNr AND ABS(M.ColNr - LR.ColNr) = 1)  -- Join all horizontal points
                             OR (M.ColNr = LR.ColNr AND ABS(M.RowNr - LR.RowNr) = 1)  -- Join all vertical points
    GROUP BY M.RowNr, M.ColNr, M.Val
)
SELECT SUM(Val + 1) AS Part1
FROM cte_Low
WHERE NrOfAdjecentPoints = NrOfHigherPoints -- If all adjecent points are higher then it is a low point

-- 564 is correct for part 1



;WITH cte_Low AS (
    SELECT M.RowNr
    ,      M.ColNr
    ,      COUNT(1) AS NrOfAdjecentPoints
    ,      SUM(CASE WHEN M.Val < LR.Val THEN 1 ELSE 0 END) AS NrOfHigherPoints
    FROM ##InputGrid M
    LEFT JOIN ##InputGrid LR ON (M.RowNr = LR.RowNr AND ABS(M.ColNr - LR.ColNr) = 1)  -- Join all horizontal points
                             OR (M.ColNr = LR.ColNr AND ABS(M.RowNr - LR.RowNr) = 1)  -- Join all vertical points
    GROUP BY M.RowNr, M.ColNr, M.Val
), cte_StartingPoints AS (
    SELECT RowNr, ColNr, ROW_NUMBER() OVER (ORDER BY (SELECT 0)) AS LakeNr
    FROM cte_Low
    WHERE NrOfAdjecentPoints = NrOfHigherPoints -- If all adjecent points are higher then it is a low point
), cte_Lakes AS (
    SELECT IG.RowNr, IG.ColNr, IG.Val, cSP.LakeNr
    FROM ##InputGrid IG
    INNER JOIN cte_StartingPoints cSP ON IG.RowNr = cSP.RowNr AND IG.ColNr = cSP.ColNr

    UNION ALL

    SELECT LR.RowNr, LR.ColNr, LR.Val, cL.LakeNr
    FROM cte_Lakes cL
    InNER JOIN ##InputGrid LR ON (cL.RowNr = LR.RowNr AND ABS(cL.ColNr - LR.ColNr) = 1)  -- Join all horizontal points
                             OR (cL.ColNr = LR.ColNr AND ABS(cL.RowNr - LR.RowNr) = 1)  -- Join all vertical points
    WHERE cL.Val < LR.Val AND LR.Val < 9
), cte_Points AS (
    SELECT RowNr, ColNr, Val, LakeNr
    FROM cte_Lakes
    GROUP BY RowNr, ColNr, Val, LakeNr
)
SELECT [1] * [2] * [3] AS Part2 
FROM (
    SELECT TOP (3) ROW_NUMBER() OVER (ORDER BY (SELECT 0)) AS SizeOrder, COUNT(1) AS LakeSize
    FROM cte_Points
    GROUP BY LakeNr
    ORDER BY 2 DESC
) T
PIVOT
(
    SUM(LakeSize)
    FOR SizeOrder
    IN ([1], [2], [3])
) AS PivotTable


--1038240 is correct for part2

