USE Test_WME

DECLARE @year VARCHAR(4) = '2022'
DECLARE @day VARCHAR(2)  = '6'

EXEC dbo.GetInput @year = @year, @day = @day
EXEC dbo.ParseInput @year = @year, @day = @day 

--SELECT TOP 10 * FROM ##Input
--SELECT TOP 10 * FROM ##InputInts
--SELECT TOP 10 * FROM ##InputNumbered
--SELECT TOP 10 * FROM ##InputGrid
--SELECT TOP 10 * FROM ##InputSplit
--SELECT TOP 10 * FROM ##InputSplitCust
  
DECLARE @SeqLength INT = 4

;WITH cte_Seq AS (
    SELECT ColNr AS StartPos
    ,      ColNr AS CurrentPos
    ,      CAST(Val AS VARCHAR(50)) AS Seq
    ,      1 AS NrOfChars
    FROM ##InputGrid

    UNION ALL

    SELECT c.StartPos
    ,      i.ColNr
    ,      CAST(c.Seq + i.Val AS VARCHAR(50))
    ,      NrOfChars + 1
    FROM cte_Seq c
    INNER JOIN ##InputGrid i ON c.CurrentPos = i.ColNr - 1
    WHERE NrOfChars <= @SeqLength
    AND c.Seq NOT LIKE '%' + i.Val + '%'
)
SELECT MIN(CurrentPos) + 1 AS Part1
FROM cte_Seq
WHERE NrOfChars = @SeqLength

SET @SeqLength = 14

;WITH cte_Seq AS (
    SELECT ColNr AS StartPos
    ,      ColNr AS CurrentPos
    ,      CAST(Val AS VARCHAR(50)) AS Seq
    ,      1 AS NrOfChars
    FROM ##InputGrid

    UNION ALL

    SELECT c.StartPos
    ,      i.ColNr
    ,      CAST(c.Seq + i.Val AS VARCHAR(50))
    ,      NrOfChars + 1
    FROM cte_Seq c
    INNER JOIN ##InputGrid i ON c.CurrentPos = i.ColNr - 1
    WHERE NrOfChars <= @SeqLength
    AND c.Seq NOT LIKE '%' + i.Val + '%'
)
SELECT MIN(CurrentPos) + 1 AS Part2
FROM cte_Seq
WHERE NrOfChars = @SeqLength


-- This also works but it gets very messy very quickly:

--SELECT i1.colnr, i2.colnr,i3.colnr,i4.colnr,i1.val,i2.val,i3.val,i4.val FROM ##InputGrid i1
--INNER JOIN ##InputGrid i2 ON i1.ColNr = i2.ColNr - 1 AND i1.Val <> i2.Val
--INNER JOIN ##InputGrid i3 ON i2.ColNr = i3.ColNr - 1 AND i1.Val <> i3.Val AND i2.val <> i3.val
--INNER JOIN ##InputGrid i4 ON i3.ColNr = i4.ColNr - 1 AND i1.Val <> i4.Val AND i2.val <> i4.val AND i3.val <> i4.val
--ORDER BY i1.ColNr

