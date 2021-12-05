USE Test_WME

DECLARE @year VARCHAR(4) = '2015'
DECLARE @day VARCHAR(2)  = '1'

EXEC dbo.GetInput @year = @year, @day = @day
EXEC dbo.ParseInput @year = @year, @day = @day 

SELECT TOP 10 * FROM ##InputNumbered
SELECT TOP 10 * FROM ##InputGrid
SELECT TOP 10 * FROM ##InputInts
SELECT TOP 10 * FROM ##InputSplit

;WITH cte_Amt AS (
    SELECT Val, COUNT(1) AS Amt
    FROM ##InputGrid
    GROUP BY Val
)
SELECT ABS(C1.Amt-C2.Amt) Part1
FROM cte_Amt C1
INNER JOIN cte_Amt C2 ON C1.Val > C2.Val

-- 232 is correct for part 1

;WITH cte_Floors AS (
    SELECT ColNr + 1 AS ColNr    -- Character counting starts at 1
    , CASE WHEN Val = '(' THEN 1 ELSE -1 END AS IntVal
    FROM ##InputGrid
), cte_RunningTotal AS (
    SELECT ColNr, SUM(IntVal) OVER (ORDER BY ColNr) AS FloorNr
    FROM cte_Floors
)
SELECT MIN(ColNr) AS Part2
FROM cte_RunningTotal
WHERE FloorNr = -1


--1783 is correct for part 2




