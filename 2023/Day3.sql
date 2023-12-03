USE Test_WME

SET NOCOUNT ON

DECLARE @year VARCHAR(4) = '2023'
DECLARE @day VARCHAR(2)  = '3'

EXEC dbo.GetInput @year = @year, @day = @day
EXEC dbo.ParseInput @year = @year, @day = @day 

--SELECT TOP 10 * FROM ##Input
--SELECT TOP 10 * FROM ##InputInts
--SELECT TOP 10 * FROM ##InputNumbered
--SELECT TOP 10 * FROM ##InputSplit
--SELECT TOP 10 * FROM ##InputSplitCust

-- Find all digits adjacent to a symbol
SELECT I2.RowNr
,      I2.ColNr AS ColNrLeft
,      I2.ColNr AS ColNrRight
,      CAST(I2.Val AS VARCHAR(20)) AS Val
,      I1.RowNr AS RowNrSymbol
,      I1.ColNr AS ColNrSymbol
,      CASE WHEN I1.Val = '*' THEN 1 ELSE 0 END AS IsGear
INTO ##Numbers
FROM ##InputGrid I1
INNER JOIN ##InputGrid I2 ON ABS(I1.RowNr - I2.RowNr) <= 1 AND ABS(I1.ColNr - I2.ColNr) <= 1
WHERE I1.Val IN ('*','$','-','=','+','%','@','/','#','&')
AND I2.Val IN ('0','1','2','3','4','5','6','7','8','9')


DECLARE @Counter INT = 1

-- Expand the found digits to the left and the right as long as they are numbers
WHILE @Counter < 5
BEGIN

    UPDATE N
    SET ColNrLeft = CASE WHEN IL.Val IN ('0','1','2','3','4','5','6','7','8','9') THEN IL.ColNr ELSE N.ColNrLeft END
    ,   ColNrRight = CASE WHEN IR.Val IN ('0','1','2','3','4','5','6','7','8','9') THEN IR.ColNr ELSE N.ColNrRight END
    ,   Val = CASE WHEN IL.Val IN ('0','1','2','3','4','5','6','7','8','9') THEN IL.Val ELSE '' END
                + N.Val +
                CASE WHEN IR.Val IN ('0','1','2','3','4','5','6','7','8','9') THEN IR.Val ELSE '' END
    FROM ##Numbers N 
    LEFT JOIN ##InputGrid IL ON N.RowNr = IL.RowNr AND N.ColNrLeft = IL.ColNr + 1 
    LEFT JOIN ##InputGrid IR ON N.RowNr = IR.RowNr AND N.ColNrRight = IR.ColNr - 1 

    SET @Counter = @Counter + 1

END

-- We found all viable numbers, deduplicate, cast and sum for the answer
;WITH cte_Vals AS (
    SELECT RowNr, ColNrLeft, CAST(Val AS INT) AS Val FROM ##Numbers N GROUP BY RowNr, ColNrLeft, Val
)                                                     
SELECT SUM(Val) AS Part1 FROM cte_Vals


-- Take all numbers adjacent to a gear (*), don't forget to deduplicate
;WITH cte_Vals AS (
    SELECT ROW_NUMBER() OVER (ORDER BY (SELECT 0)) AS ID
    ,      RowNr
    ,      ColNrLeft
    ,      CAST(Val AS INT) AS Val
    ,      RowNrSymbol
    ,      ColNrSymbol
    FROM ##Numbers N 
    WHERE N.IsGear = 1
    GROUP BY RowNr, ColNrLeft, Val, RowNrSymbol, ColNrSymbol
)
-- Assume that a gear always has 2 or less adjacent numbers
SELECT SUM(c1.Val * c2.Val) AS Part2
FROM cte_Vals c1
INNER JOIN cte_Vals c2 ON c1.RowNrSymbol = c2.RowNrSymbol AND c1.ColNrSymbol = c2.ColNrSymbol AND c2.ID > c1.ID




/*

DROP TABLE ##Numbers

*/
