USE Test_WME

DECLARE @year VARCHAR(4) = '2022'
DECLARE @day VARCHAR(2)  = '8'

EXEC dbo.GetInput @year = @year, @day = @day
EXEC dbo.ParseInput @year = @year, @day = @day 

--SELECT TOP 10 * FROM ##Input
--SELECT TOP 10 * FROM ##InputInts
--SELECT TOP 10 * FROM ##InputNumbered
--SELECT TOP 100 * FROM ##InputGrid
--SELECT TOP 10 * FROM ##InputSplit
--SELECT TOP 10 * FROM ##InputSplitCust
  
DECLARE @MaxRow INT
DECLARE @MaxCol INT
DECLARE @MinRow INT
DECLARE @MinCol INT

SELECT @MaxRow = MAX(RowNr), @MaxCol = MAX(Colnr), @MinCol = MIN(ColNr), @MinRow = MIN(Rownr) FROM ##InputGrid


;WITH cte_Grid AS (
    SELECT RowNr, 
           ColNr,
           RowNr AS newRowNr,
           ColNr AS newColNr,
           Val,
           Dir,
           1 AS Step
    FROM ##InputGrid
    CROSS APPLY (SELECT 'N' AS Dir UNION SELECT 'W' UNION SELECT 'E' UNION SELECT 'S') Direction
    WHERE ColNr BETWEEN @MinCol + 1 AND @MaxCol - 1 AND RowNr BETWEEN @MinRow + 1 AND @MaxRow - 1

    UNION ALL

    SELECT c.RowNr,
           c.ColNr,
           i.RowNr,
           i.ColNr,
           c.Val,
           c.Dir,
           Step + 1
    FROM cte_Grid c
    INNER JOIN ##InputGrid i ON ((c.Dir = 'N' AND c.NewColNr = i.ColNr AND c.NewRowNr = i.RowNr + 1)
                              OR (c.Dir = 'S' AND c.NewColNr = i.ColNr AND c.NewRowNr = i.RowNr - 1)
                              OR (c.Dir = 'W' AND c.NewColNr = i.ColNr + 1 AND c.NewRowNr = i.RowNr)
                              OR (c.Dir = 'E' AND c.NewColNr = i.ColNr - 1 AND c.NewRowNr = i.RowNr))
                              AND c.Val > i.Val
)
SELECT * 
INTO ##Results
FROM cte_Grid


;WITH cte_UniqueTrees AS (
    SELECT RowNr, ColNr
    FROM ##Results
    WHERE NewRowNr = @MinRow OR NewColNr = @MinRow OR NewRowNr = @MaxRow OR NewColNr = @MaxCol
    GROUP BY RowNr, ColNr
)
SELECT COUNT(1) + MAX(E.EdgeTrees) AS Part1
FROM cte_UniqueTrees
CROSS APPLY (SELECT COUNT(1) AS EdgeTrees FROM ##InputGrid WHERE RowNr = @MinRow OR ColNr = @MinRow OR RowNr = @MaxRow OR ColNr = @MaxCol) AS E



SELECT TOP 1 CASE WHEN RowNr = N - 1 THEN N - 1 ELSE N END              --Correct the number of trees for each direction if the end of the grid was reached
           * CASE WHEN ColNr = W - 1 THEN W - 1 ELSE W END
           * CASE WHEN ColNr = @MaxCol + 1 - E THEN E - 1 ELSE E END
           * CASE WHEN RowNr = @MaxRow + 1 - S THEN S - 1 ELSE S END
           AS Part2
FROM (
    SELECT R.RowNr, R.Colnr, MAX(R.Step) AS MaxStep, R.Dir
    FROM ##Results R
    GROUP BY R.RowNr, R.Colnr, R.Dir
) Sub
PIVOT (MAX(Maxstep) FOR Dir IN (N,W,E,S)) AS pvt
ORDER BY Part2 DESC


DROP TABLE ##Results

-- 199272 is correct for part 2

-- Runtime 00:08:52