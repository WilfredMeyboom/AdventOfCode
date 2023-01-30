use Test_WME

SET NOCOUNT ON

DECLARE @year VARCHAR(4) = '2016'
DECLARE @day VARCHAR(2)  = '6'

EXEC dbo.GetInput @year = @year, @day = @day
EXEC dbo.ParseInput @year = @year, @day = @day

--SELECT TOP 10 * FROM ##InputNumbered
--SELECT TOP 10 * FROM ##InputGrid
--SELECT TOP 10 * FROM ##InputInts
--SELECT TOP 10 * FROM ##InputSplit
--SELECT * FROM ##Input

;WITH cte_Cnt AS (
    SELECT ColNr, Val, COUNT(1) AS Cnt FROM ##InputGrid GROUP BY ColNr, Val
)
SELECT [0] + [1] + [2] + [3] + [4] + [5] + [6] + [7] AS Part1
FROM (
    SELECT c.ColNr, c.Val
    FROM cte_Cnt c
    INNER JOIN (SELECT ColNr, MAX(Cnt) AS MaxCnt FROM cte_Cnt GROUP BY ColNr) T ON c.ColNr = T.ColNr AND c.Cnt = T.MaxCnt
) U
PIVOT (
    MAX(Val) FOR ColNr IN ([0],[1],[2],[3],[4],[5],[6],[7])
) PVT


;WITH cte_Cnt AS (
    SELECT ColNr, Val, COUNT(1) AS Cnt FROM ##InputGrid GROUP BY ColNr, Val
)
SELECT [0] + [1] + [2] + [3] + [4] + [5] + [6] + [7] AS Part2
FROM (
    SELECT c.ColNr, c.Val
    FROM cte_Cnt c
    INNER JOIN (SELECT ColNr, MIN(Cnt) AS MinCnt FROM cte_Cnt GROUP BY ColNr) T ON c.ColNr = T.ColNr AND c.Cnt = T.MinCnt
) U
PIVOT (
    MAX(Val) FOR ColNr IN ([0],[1],[2],[3],[4],[5],[6],[7])
) PVT
