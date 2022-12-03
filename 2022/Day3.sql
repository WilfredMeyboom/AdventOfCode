USE Test_WME

DECLARE @year VARCHAR(4) = '2022'
DECLARE @day VARCHAR(2)  = '3'

EXEC dbo.GetInput @year = @year, @day = @day
EXEC dbo.ParseInput @year = @year, @day = @day 

--SELECT TOP 10 * FROM ##Input
--SELECT TOP 10 * FROM ##InputInts
--SELECT TOP 10 * FROM ##InputNumbered
--SELECT TOP 10 * FROM ##InputGrid
--SELECT TOP 10 * FROM ##InputSplit
--SELECT TOP 10 * FROM ##InputSplitCust
  
;WITH cte_Sides AS (
    SELECT RowNr
    ,      MAX(ColNr) AS RightSide
    ,      MAX(ColNr) / 2 AS Middle  
    FROM ##InputGrid GROUP BY RowNr
), cte_doubles AS (
    SELECT i1.RowNr
    ,      i1.Val
    ,      CASE WHEN ASCII(I1.Val) BETWEEN 65 AND 90    -- All values are upper or lower case letters. Check if the letter is upper case
                THEN ASCII(i1.Val) - 38                 -- Ascii value of upper case letters go from 65 to 90 but should go from 27 to 52
                ELSE ASCII(i1.Val) - 96                 -- Lower case letters go from 97 to 122 but should go from 1 to 26
           END AS lettervalue
    FROM cte_Sides C 
    INNER JOIN ##inputGrid i1 ON C.RowNr = i1.RowNr AND i1.ColNr BETWEEN 0 AND C.Middle                 
    INNER JOIN ##inputgrid i2 ON C.RowNr = i2.RowNr AND i2.ColNr BETWEEN C.Middle + 1 AND C.RightSide
    WHERE ASCII(i1.Val) = ASCII(i2.val) -- SQL is case insensitive so we need to compare on the ascii value of the letters
    GROUP BY i1.Rownr, i1.Val
)
SELECT SUM(lettervalue) AS Part1
FROM cte_doubles


;WITH cte_badges AS (
    SELECT i1.Rownr
    ,      i1.val
    ,      CASE WHEN ASCII(I1.Val) BETWEEN 65 AND 90 -- Reuse logic from part 1
                THEN ASCII(i1.Val) - 38 
                ELSE ASCII(i1.Val) - 96 
           END AS lettervalue
    FROM ##InputGrid i1
    INNER JOIN ##InputGrid i2 ON i1.RowNr = i2.RowNr - 1 AND ASCII(i1.Val) = ASCII(i2.Val) -- Join the next line / elf 
    INNER JOIN ##InputGrid i3 ON i1.RowNr = i3.RowNr - 2 AND ASCII(i1.Val) = ASCII(i3.Val) -- Join the next line / elf 
    WHERE i1.RowNr % 3 = 0 -- Only take every third elf
    GROUP BY i1.rownr, i1.val
)
SELECT SUM(lettervalue) AS Part2
FROM cte_badges

