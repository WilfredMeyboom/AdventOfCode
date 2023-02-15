USE Test_WME

SET NOCOUNT ON

DECLARE @year VARCHAR(4) = '2016'
DECLARE @day VARCHAR(2)  = '7'

EXEC dbo.GetInput @year = @year, @day = @day
EXEC dbo.ParseInput @year = @year, @day = @day

--SELECT TOP 10 * FROM ##InputNumbered
--SELECT TOP 10 * FROM ##InputGrid
--SELECT TOP 10 * FROM ##InputInts
--SELECT TOP 10 * FROM ##InputSplit
--SELECT * FROM ##Input

;WITH cte_Letters AS (
    SELECT RowNr, ColNr, Val 
    ,      SUM(CASE WHEN Val IN ('[',']') THEN 1 ELSE 0 END) OVER (PARTITION BY RowNr ORDER BY ColNr) AS HypernetSeq
    FROM ##InputGrid
), cte_PerRowPerSeq AS (
    SELECT c1.RowNr, c1.HypernetSeq
    FROM cte_Letters c1
    INNER JOIN cte_Letters c4 ON c1.RowNr = c4.RowNr AND c1.HypernetSeq = c4.HypernetSeq AND c1.ColNr = c4.ColNr - 3 AND c1.Val = c4.Val
    INNER JOIN cte_Letters c2 ON c1.RowNr = c2.RowNr AND c1.HypernetSeq = c2.HypernetSeq AND c1.ColNr = c2.ColNr - 1 AND c1.Val <> c2.Val
    INNER JOIN cte_Letters c3 ON c1.RowNr = c3.RowNr AND c1.HypernetSeq = c3.HypernetSeq AND c1.ColNr = c3.ColNr - 2 AND c2.Val = c3.Val
    GROUP BY c1.RowNr, c1.HypernetSeq
)
SELECT COUNT(DISTINCT d1.RowNr) AS Part1
FROM cte_PerRowPerSeq d1
LEFT JOIN cte_PerRowPerSeq d2 ON d1.RowNr = d2.RowNr AND d1.HypernetSeq <> d2.HypernetSeq AND d2.HypernetSeq % 2 = 1
WHERE d2.RowNr IS NULL AND d1.HypernetSeq % 2 = 0



;WITH cte_Letters AS (
    SELECT RowNr, ColNr, Val 
    ,      SUM(CASE WHEN Val IN ('[',']') THEN 1 ELSE 0 END) OVER (PARTITION BY RowNr ORDER BY ColNr) AS HypernetSeq
    FROM ##InputGrid
), cte_PerRowPerSeq AS (
    SELECT c1.RowNr, c1.HypernetSeq, c1.Val AS OuterVal, c2.Val AS InnerVal
    FROM cte_Letters c1
    INNER JOIN cte_Letters c3 ON c1.RowNr = c3.RowNr AND c1.HypernetSeq = c3.HypernetSeq AND c1.ColNr = c3.ColNr - 2 AND c1.Val = c3.Val
    INNER JOIN cte_Letters c2 ON c1.RowNr = c2.RowNr AND c1.HypernetSeq = c2.HypernetSeq AND c1.ColNr = c2.ColNr - 1 AND c1.Val <> c2.Val
    GROUP BY c1.RowNr, c1.HypernetSeq, c1.Val, c2.Val 
)
SELECT COUNT(DISTINCT d1.RowNr) AS Part2
FROM cte_PerRowPerSeq d1
INNER JOIN cte_PerRowPerSeq d2 ON d1.RowNr = d2.RowNr AND d1.HypernetSeq <> d2.HypernetSeq AND d2.HypernetSeq % 2 = 1 AND d1.OuterVal = d2.InnerVal AND d1.InnerVal = d2.OuterVal
WHERE d1.HypernetSeq % 2 = 0



