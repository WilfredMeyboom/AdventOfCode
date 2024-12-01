USE Test_WME

SET NOCOUNT ON

DECLARE @year VARCHAR(4) = '2024'
DECLARE @day VARCHAR(2)  = '1'

EXEC dbo.GetInput @year = @year, @day = @day
EXEC dbo.ParseInput @year = @year, @day = @day 

--SELECT TOP 10 * FROM ##Input
--SELECT TOP 10 * FROM ##InputInts
--SELECT TOP 10 * FROM ##InputNumbered
--SELECT TOP 10 * FROM ##InputGrid
--SELECT TOP 10 * FROM ##InputSplit
--SELECT TOP 10 * FROM ##InputSplitCust

;WITH cte_1 AS (
	SELECT ROW_NUMBER() OVER (ORDER BY Piece) AS R, Piece FROM ##InputSplit WHERE PieceNr = 1 
), cte_2 AS (
	SELECT ROW_NUMBER() OVER (ORDER BY Piece) AS R, Piece FROM ##InputSplit WHERE PieceNr = 2
)
SELECT SUM(ABS(CAST(c1.Piece AS INT) - CAST(c2.Piece AS INT)) ) AS Part1
FROM cte_1 c1
INNER JOIN cte_2 c2 ON c1.R = c2.R

;WITH cte_1 AS (
	SELECT ROW_NUMBER() OVER (ORDER BY Piece) AS R, Piece FROM ##InputSplit WHERE PieceNr = 1 
), cte_2 AS (
	SELECT Piece, COUNT(1) AS Cnt FROM ##InputSplit WHERE PieceNr = 2 GROUP BY Piece
)
SELECT SUM(CAST(c1.Piece AS BIGINT) * CAST(c2.Cnt AS BIGINT)) AS Part2
FROM cte_1 c1
INNER JOIN cte_2 c2 ON c1.Piece = c2.Piece
