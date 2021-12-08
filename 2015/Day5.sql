USE Test_WME

SET NOCOUNT ON

DECLARE @year VARCHAR(4) = '2015'
DECLARE @day VARCHAR(2)  = '5'

EXEC dbo.GetInput @year = @year, @day = @day
EXEC dbo.ParseInput @year = @year, @day = @day 

--SELECT TOP 10 * FROM ##InputNumbered
--SELECT TOP 10 * FROM ##InputGrid
--SELECT TOP 10 * FROM ##InputInts
--SELECT TOP 10 * FROM ##InputSplit
--SELECT TOP 10 * FROM ##InputSplitCust

;WITH cte_ForbiddenLines AS (
    SELECT L1.RowNr 
    FROM ##InputGrid L1
    INNER JOIN ##InputGrid L2 ON L1.RowNr = L2.RowNr AND L1.ColNr + 1 = L2.ColNr
    WHERE (L1.Val = 'a' AND L2.Val = 'b')
       OR (L1.Val = 'c' AND L2.Val = 'd')
       OR (L1.Val = 'p' AND L2.Val = 'q')
       OR (L1.Val = 'x' AND L2.Val = 'y')
    GROUP BY L1.RowNr
), cte_TwiceInARow AS (
    SELECT L1.RowNr
    FROM ##InputGrid L1
    INNER JOIN ##InputGrid L2 ON L1.RowNr = L2.RowNr AND L1.ColNr + 1 = L2.ColNr
    WHERE L1.Val = L2.Val 
    GROUP BY L1.RowNr
), cte_Atleast3Vowels AS (
    SELECT RowNr
    FROM ##InputGrid
    WHERE Val IN ('a','e','i','o','u')
    GROUP BY RowNr
    HAVING COUNT(1) >= 3
)
SELECT COUNT(1) AS Part1
FROM cte_Atleast3Vowels T1
INNER JOIN cte_TwiceInARow T2 ON T1.RowNr = T2.RowNr
LEFT JOIN cte_ForbiddenLines T3 ON T3.RowNr = T1.RowNr
WHERE T3.RowNr IS NULL

--258 is correct for part 1


;WITH cte_TwiceInARow AS (
    SELECT L1.RowNr, L1.ColNr, L1.Val, L2.Val AS SecondVal
    FROM ##InputGrid L1
    INNER JOIN ##InputGrid L2 ON L1.RowNr = L2.RowNr AND L1.ColNr + 1 = L2.ColNr
), cte_TwiceTwiceInARow AS (
    SELECT T1.RowNr
    FROM cte_TwiceInARow T1
    INNER JOIN cte_TwiceInARow T2 ON T1.RowNr = T2.RowNr AND T1.ColNr < T2.ColNr - 1 AND T1.Val = T2.Val AND T1.SecondVal = T2.SecondVal
    GROUP BY T1.RowNr
), cte_TwiceOneInBetween AS (
    SELECT L1.RowNr
    FROM ##InputGrid L1
    INNER JOIN ##InputGrid L2 ON L1.RowNr = L2.RowNr AND L1.ColNr + 1 = L2.ColNr
    INNER JOIN ##InputGrid L3 ON L1.RowNr = L3.RowNr AND L2.ColNr + 1 = L3.ColNr
    WHERE L1.Val = L3.Val
    GROUP BY L1.RowNr
)
SELECT COUNT(*) AS Part2
FROM cte_TwiceTwiceInARow T1
INNER JOIN cte_TwiceOneInBetween T2 ON T1.RowNr = T2.RowNr

-- 53 is correct for part 2


