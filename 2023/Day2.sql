USE Test_WME

SET NOCOUNT ON

DECLARE @year VARCHAR(4) = '2023'
DECLARE @day VARCHAR(2)  = '2'

EXEC dbo.GetInput @year = @year, @day = @day
EXEC dbo.ParseInput @year = @year, @day = @day 

--SELECT TOP 10 * FROM ##Input
--SELECT TOP 10 * FROM ##InputInts
--SELECT TOP 10 * FROM ##InputNumbered
--SELECT TOP 10 * FROM ##InputGrid
--SELECT TOP 10 * FROM ##InputSplit
--SELECT TOP 10 * FROM ##InputSplitCust
  

;WITH cte_PossibleGames AS (
    SELECT DISTINCT RowNr FROM ##InputSplit
    EXCEPT
    SELECT DISTINCT I1.RowNr
    FROM ##InputSplit I1
    INNER JOIN ##InputSplit I2 ON I1.Ind = I2.Ind + 1
    WHERE I1.Piece IN ('red', 'green', 'blue')
      AND ((I1.Piece  = 'red' AND TRY_CAST(I2.Piece AS INT) > 12)      
        OR (I1.Piece  = 'green' AND TRY_CAST(I2.Piece AS INT) > 13)
        OR (I1.Piece  = 'blue' AND TRY_CAST(I2.Piece AS INT) > 14)
        )
)
SELECT SUM(RowNr) AS Part1
FROM cte_PossibleGames

;WITH cte_MaxBallsPerGame AS (
    SELECT I1.RowNr, I1.Piece, MAX(TRY_CAST(I2.Piece AS INT)) AS MaxBalls
    FROM ##InputSplit I1
    INNER JOIN ##InputSplit I2 ON I1.Ind = I2.Ind + 1
    WHERE I1.Piece IN ('red', 'green', 'blue')
    GROUP BY I1.RowNr, I1.Piece
)
SELECT SUM(c1.MaxBalls * c2.MaxBalls * c3.MaxBalls) AS Part2
FROM cte_MaxBallsPerGame c1
INNER JOIN cte_MaxBallsPerGame c2 ON c1.RowNr = c2.RowNr AND c2.Piece = 'green'
INNER JOIN cte_MaxBallsPerGame c3 ON c1.RowNr = c3.RowNr AND c3.Piece = 'blue'
WHERE c1.Piece = 'red'
