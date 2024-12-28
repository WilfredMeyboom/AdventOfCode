USE Test_WME

SET NOCOUNT ON

DECLARE @year VARCHAR(4) = '2024'
DECLARE @day VARCHAR(2)  = '25'

EXEC dbo.GetInput @year = @year, @day = @day
EXEC dbo.ParseInput @year = @year, @day = @day 

--SELECT TOP 10 * FROM ##Input
--SELECT TOP 10 * FROM ##InputInts
--SELECT TOP 10 * FROM ##InputNumbered
--SELECT TOP 10 * FROM ##InputGrid
--SELECT TOP 10 * FROM ##InputSplit
--SELECT TOP 10 * FROM ##InputSplitCust

;WITH cte_LockAndKeys AS (
    SELECT RowNr / 8 AS LockKeyNr, RowNr % 8 AS RowNr, ColNr, Val FROM ##InputGrid WHERE Val IS NOT NULL
), cte_Overlap AS (
    SELECT c1.LockKeyNr AS Nr1, c2.LockKeyNr AS Nr2
    FROM cte_LockAndKeys c1
    INNER JOIN cte_LockAndKeys c2 ON c1.LockKeyNr < c2.LockKeyNr AND c1.RowNr = c2.RowNr AND c1.ColNr = c2.ColNr AND c1.Val = '#' AND c2.Val = '#'
    GROUP BY c1.LockKeyNr, c2.LockKeyNr
)
SELECT COUNT(1)
FROM (SELECT LockKeyNr FROM cte_LockAndKeys GROUP BY LockKeyNr) AS S1
INNER JOIN (SELECT LockKeyNr FROM cte_LockAndKeys GROUP BY LockKeyNr) AS S2 ON S1.LockKeyNr < S2.LockKeyNr
LEFT JOIN cte_Overlap c ON c.Nr1 = S1.LockKeyNr AND c.Nr2 = S2.LockKeyNr
WHERE c.Nr1 IS NULL

--5900 too high