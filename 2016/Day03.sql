use Test_WME

SET NOCOUNT ON

DECLARE @year VARCHAR(4) = '2016'
DECLARE @day VARCHAR(2)  = '3'

EXEC dbo.GetInput @year = @year, @day = @day
EXEC dbo.ParseInput @year = @year, @day = @day 

--SELECT TOP 10 * FROM ##InputNumbered
--SELECT TOP 10 * FROM ##InputGrid
--SELECT TOP 10 * FROM ##InputInts
--SELECT TOP 10 * FROM ##InputSplit
--SELECT * FROM ##Input

SELECT COUNT(1) AS Part1
FROM (
    SELECT RowNr, PieceNr, Piece
    FROM ##InputSplit
    ) T
PIVOT (
    MAX(Piece) FOR PieceNr IN ([1],[2],[3])
    ) Pvt
WHERE CAST([1] AS INT) + CAST([2] AS INT) > CAST([3] AS INT)
  AND CAST([1] AS INT) + CAST([3] AS INT) > CAST([2] AS INT)
  AND CAST([2] AS INT) + CAST([3] AS INT) > CAST([1] AS INT)


SELECT COUNT(1) AS Part2
FROM (
    SELECT 3*((RowNr-1) / 3) + PieceNr AS NewRowNr, RowNr % 3 + 1 AS NewPieceNr, Piece
    FROM ##InputSplit
    ) T
PIVOT (
    MAX(Piece) FOR NewPieceNr IN ([1],[2],[3])
    ) Pvt
WHERE CAST([1] AS INT) + CAST([2] AS INT) > CAST([3] AS INT)
  AND CAST([1] AS INT) + CAST([3] AS INT) > CAST([2] AS INT)
  AND CAST([2] AS INT) + CAST([3] AS INT) > CAST([1] AS INT)

