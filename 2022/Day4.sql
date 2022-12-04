USE Test_WME

DECLARE @year VARCHAR(4) = '2022'
DECLARE @day VARCHAR(2)  = '4'

EXEC dbo.GetInput @year = @year, @day = @day
EXEC dbo.ParseInput @year = @year, @day = @day, @SplitCustom = ', -' 

--SELECT TOP 10 * FROM ##Input
--SELECT TOP 10 * FROM ##InputInts
--SELECT TOP 10 * FROM ##InputNumbered
--SELECT TOP 10 * FROM ##InputGrid
--SELECT TOP 10 * FROM ##InputSplit
--SELECT * FROM ##InputSplitCust
  
;WITH cte_Periods AS (
    SELECT CAST(i1.Piece AS INT) AS StartPiece, CAST(i2.Piece AS INT) AS EndPiece, i1.RowNr, i1.PieceNr AS PieceNr1, i2.PieceNr AS PieceNr2
    FROM ##InputSplitCust i1
    INNER JOIN ##InputSplitCust i2 ON i1.RowNr = i2.RowNr AND i1.PieceNr = i2.PieceNr - 1
    WHERE i1.PieceNr IN (1,3)
), cte_Overlap AS (
    SELECT p1.RowNr
    , MAX(CASE WHEN p1.StartPiece BETWEEN p2.StartPiece AND P2.EndPiece AND p1.EndPiece BETWEEN p2.StartPiece AND P2.EndPiece THEN 1 ELSE 0 END) AS FullOverlap
    , MAX(CASE WHEN (p1.StartPiece > P2.EndPiece OR p1.EndPiece < p2.StartPiece ) THEN 1 ELSE 0 END) AS NoOverlap  -- It's easier to determine no overlap
    FROM cte_Periods p1
    INNER JOIN cte_Periods p2 ON p1.RowNr = p2.RowNr AND p1.PieceNr1 <> p2.PieceNr1
    GROUP BY p1.RowNr
)  -- Some overlap (part 2) is all rows minus no overlap rows
SELECT SUM(FullOverlap) AS Part1, COUNT(1) - SUM(NoOverlap) AS Part2 FROM cte_Overlap


