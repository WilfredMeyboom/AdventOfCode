USE Test_WME

DECLARE @year VARCHAR(4) = '2021'
DECLARE @day VARCHAR(2)  = '1'

EXEC dbo.GetInput @year = @year, @day = @day
EXEC dbo.ParseInput @year = @year, @day = @day 

SELECT TOP 10 * FROM ##InputInts


SELECT COUNT(1) AS Part1
FROM ##InputInts c1
LEFT JOIN ##InputInts c2 ON c1.Ind + 1= c2.Ind
WHERE ISNULL(c1.Val,0) < c2.Val
ORDER BY 1

--1215 is correct for part 1

;WITH cte_slidingwindow AS (
    SELECT c1.Ind AS rn, C1.Val + c2.Val + c3.Val AS Line 
    FROM ##InputInts c1
    LEFT JOIN ##InputInts c2 ON c1.Ind + 1= c2.Ind
    LEFT JOIN ##InputInts c3 ON c2.Ind + 1= c3.Ind
)
SELECT COUNT(1) AS Part2 --*
FROM cte_slidingwindow c1
LEFT JOIN cte_slidingwindow c2 ON c1.rn + 1= c2.rn
WHERE c1.Line < c2.Line
ORDER BY 1

--1150 is correct for part 2
