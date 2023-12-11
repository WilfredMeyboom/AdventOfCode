USE Test_WME

SET NOCOUNT ON

DECLARE @year VARCHAR(4) = '2023'
DECLARE @day VARCHAR(2)  = '11'

EXEC dbo.GetInput @year = @year, @day = @day
EXEC dbo.ParseInput @year = @year, @day = @day 

--SELECT TOP 10 * FROM ##Input
--SELECT TOP 10 * FROM ##InputInts
--SELECT TOP 10 * FROM ##InputNumbered
--SELECT TOP 10 * FROM ##InputSplitCust
--SELECT * FROM ##InputSplit

CREATE TABLE ##Empty (ID INT IDENTITY(1,1), Dir VARCHAR(5), Nr INT)

-- Create one table which contains all empty rows and empty columns
;WITH cte_Grid AS (
    SELECT RowNr, ColNr, CAST(CASE WHEN Val = '.' THEN 0 ELSE 1 END AS INT) Val
    FROM ##InputGrid
)
INSERT ##Empty(Dir, Nr)
SELECT 'Row', RowNr
FROM cte_Grid
GROUP BY RowNr
HAVING SUM(Val) = 0

UNION

SELECT 'Col', ColNr
FROM cte_Grid
GROUP BY ColNr
HAVING SUM(Val) = 0


-- Find all combinations by joining the grid onto itself (and only allowing unequal indexes one way)
-- Join this to the number of empty rows and columns between the two points
-- For every combination calculate the manhattan distance (the difference in rows + the differnce in columns) and add the number of empty rows and colums crossed (they count as an extra distance per row/column)
;WITH cte_Dist AS (
    SELECT MAX(ABS(I1.RowNr - I2.RowNr)) + MAX(ABS(I1.ColNr - I2.ColNr)) + SUM(CASE WHEN E.Nr IS NOT NULL THEN 1 ELSE 0 END) AS Dist
    FROM ##InputGrid I1
    INNER JOIN ##InputGrid I2 ON I1.Ind < I2.Ind AND I2.Val = '#'
    LEFT JOIN ##Empty E ON (((E.Nr BETWEEN I1.RowNr AND I2.RowNr) OR (E.Nr BETWEEN I2.RowNr AND I1.RowNr)) AND E.Dir = 'Row')
                        OR (((E.Nr BETWEEN I1.ColNr AND I2.ColNr) OR (E.Nr BETWEEN I2.ColNr AND I1.ColNr)) AND E.Dir = 'Col')
    WHERE I1.Val = '#'
    GROUP BY I1.Ind, I2.Ind
)
SELECT SUM(Dist) AS Part1
FROM cte_Dist

-- This is basically the same question but the number of rows/columns are counted 999999 more times (for a total of 1M)
;WITH cte_Dist AS (
    SELECT CAST(MAX(ABS(I1.RowNr - I2.RowNr)) AS BIGINT) + MAX(ABS(I1.ColNr - I2.ColNr)) + SUM(CASE WHEN E.Nr IS NOT NULL THEN 1 ELSE 0 END) * 999999 AS Dist
    FROM ##InputGrid I1
    INNER JOIN ##InputGrid I2 ON I1.Ind < I2.Ind AND I2.Val = '#'
    LEFT JOIN ##Empty E ON (((E.Nr BETWEEN I1.RowNr AND I2.RowNr) OR (E.Nr BETWEEN I2.RowNr AND I1.RowNr)) AND E.Dir = 'Row')
                        OR (((E.Nr BETWEEN I1.ColNr AND I2.ColNr) OR (E.Nr BETWEEN I2.ColNr AND I1.ColNr)) AND E.Dir = 'Col')
    WHERE I1.Val = '#'
    GROUP BY I1.Ind, I2.Ind
)
SELECT SUM(Dist) AS Part2
FROM cte_Dist

/*

DROP TABLE ##Empty

*/