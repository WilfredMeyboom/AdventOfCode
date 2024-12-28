USE Test_WME

SET NOCOUNT ON

DECLARE @year VARCHAR(4) = '2024'
DECLARE @day VARCHAR(2)  = '2'

EXEC dbo.GetInput @year = @year, @day = @day
EXEC dbo.ParseInput @year = @year, @day = @day 

--SELECT TOP 10 * FROM ##Input
--SELECT TOP 10 * FROM ##InputInts
--SELECT TOP 10 * FROM ##InputNumbered
--SELECT TOP 10 * FROM ##InputGrid
--SELECT TOP 10 * FROM ##InputSplit
--SELECT TOP 10 * FROM ##InputSplitCust



;WITH cte_StepBiggerThan3 AS (
	SELECT I1.RowNr
	FROM ##InputSplit I1
	INNER JOIN ##InputSplit I2 ON I1.RowNr = I2.RowNr AND I1.PieceNr = I2.PieceNr - 1 AND ABS(CAST(I1.Piece AS INT) - CAST(I2.Piece AS INT)) > 3
	GROUP BY I1.RowNr
), cte_SwitchingDirection AS (
	SELECT I1.RowNr
	FROM ##InputSplit I1
	INNER JOIN ##InputSplit I2 ON I1.RowNr = I2.RowNr AND I1.PieceNr = I2.PieceNr - 1 
	INNER JOIN ##InputSplit I3 ON I1.RowNr = I3.RowNr AND I2.PieceNr = I3.PieceNr - 1 
	WHERE (CAST(I1.Piece AS INT) <= CAST(I2.Piece AS INT) AND CAST(I2.Piece AS INT) >= CAST(I3.Piece AS INT))
	OR (CAST(I1.Piece AS INT) >= CAST(I2.Piece AS INT) AND CAST(I2.Piece AS INT) <= CAST(I3.Piece AS INT))
	GROUP BY I1.RowNr
)
SELECT COUNT(DISTINCT I1.RowNr) AS Part1
FROM ##InputSplit I1
LEFT JOIN cte_StepBiggerThan3 c1 ON I1.RowNr = c1.RowNr
LEFT JOIN cte_SwitchingDirection c2 ON I1.RowNr = c2.RowNr
WHERE c1.RowNr IS NULL AND c2.RowNr IS NULL


;WITH cte_Nrs AS (
	SELECT TOP 10 ROW_NUMBER() OVER (ORDER BY (SELECT 0)) AS Nr FROM sys.messages
), cte_NrOfPieces AS (
    SELECT RowNr, MAX(PieceNr) AS NrOfPieces
    FROM ##InputSplit
    GROUP BY RowNr
)
	SELECT CAST(Piece AS INT) AS Piece
    , CASE WHEN I.PieceNr < c.Nr THEN I.PieceNr ELSE I.PieceNr - 1 END AS PieceNr
    , I.RowNr * 10 + c.Nr AS RowNr
    , I.RowNr AS OriginalRowNr
    INTO ##AlternateInput
    FROM ##InputSplit I
    INNER JOIN cte_NrOfPieces cN ON I.RowNr = cN.RowNr
    CROSS APPLY cte_Nrs c 
    WHERE c.Nr <= cN.NrOfPieces
    AND I.PieceNr <> c.Nr


;WITH cte_StepBiggerThan3 AS (
	SELECT I1.RowNr
	FROM ##AlternateInput I1
	INNER JOIN ##AlternateInput I2 ON I1.RowNr = I2.RowNr AND I1.PieceNr = I2.PieceNr - 1 AND ABS(CAST(I1.Piece AS INT) - CAST(I2.Piece AS INT)) > 3
	GROUP BY I1.RowNr
), cte_SwitchingDirection AS (
	SELECT I1.RowNr
	FROM ##AlternateInput I1
	INNER JOIN ##AlternateInput I2 ON I1.RowNr = I2.RowNr AND I1.PieceNr = I2.PieceNr - 1 
	INNER JOIN ##AlternateInput I3 ON I1.RowNr = I3.RowNr AND I2.PieceNr = I3.PieceNr - 1 
	WHERE (CAST(I1.Piece AS INT) <= CAST(I2.Piece AS INT) AND CAST(I2.Piece AS INT) >= CAST(I3.Piece AS INT))
	OR (CAST(I1.Piece AS INT) >= CAST(I2.Piece AS INT) AND CAST(I2.Piece AS INT) <= CAST(I3.Piece AS INT))
	GROUP BY I1.RowNr
)
SELECT COUNT(DISTINCT I1.OriginalRowNr) AS Part2
FROM ##AlternateInput I1
LEFT JOIN cte_StepBiggerThan3 c1 ON I1.RowNr = c1.RowNr
LEFT JOIN cte_SwitchingDirection c2 ON I1.RowNr = c2.RowNr
WHERE c1.RowNr IS NULL AND c2.RowNr IS NULL

--1247 is too high

--DROP TABLE ##AlternateInput