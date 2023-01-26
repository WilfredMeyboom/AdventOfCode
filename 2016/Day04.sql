use Test_WME

SET NOCOUNT ON

DECLARE @year VARCHAR(4) = '2016'
DECLARE @day VARCHAR(2)  = '4'

EXEC dbo.GetInput @year = @year, @day = @day
EXEC dbo.ParseInput @year = @year, @day = @day, @SplitCustom = '-[]' 

--SELECT TOP 10 * FROM ##InputNumbered
--SELECT TOP 10 * FROM ##InputGrid
--SELECT TOP 10 * FROM ##InputInts
--SELECT TOP 10 * FROM ##InputSplit
--SELECT * FROM ##Input

;WITH cte_checksums AS (
    SELECT RowNr, ColNr FROM ##InputGrid WHERE Val = '['
), cte_calculatedChecksums AS (
    SELECT RowNr, [1] + [2] + [3] + [4] + [5] AS CalcChecksum
    FROM (
        SELECT I.RowNr, I.Val, ROW_NUMBER() OVER (PARTITION BY I.RowNr ORDER BY COUNT(1) DESC, I.Val) AS RN
        FROM ##InputGrid I 
        INNER JOIN cte_checksums c ON I.RowNr = c.RowNr
        WHERE ASCII(I.Val) BETWEEN 97 AND 122
        GROUP BY I.RowNr, I.Val 
    ) T
    PIVOT (
        MAX(Val) FOR RN IN ([1],[2],[3],[4],[5])
    ) PVT
)
SELECT SUM(
        CASE WHEN c.CalcChecksum = I2.Piece 
             THEN CAST(REVERSE(LEFT(REVERSE(I1.Piece), CHARINDEX('-', REVERSE(I1.Piece)) - 1)) AS INT)
             ELSE 0 
        END) AS Part1
FROM cte_calculatedChecksums c
INNER JOIN ##InputSplit I2 ON c.RowNr = I2.RowNr -1 AND I2.PieceNr = 2
INNER JOIN ##InputSplit I1 ON c.RowNr = I1.RowNr -1 AND I1.PieceNr = 1


CREATE TABLE ##Results (Sentence VARCHAR(MAX), SectorID INT)

;WITH cte_SectorIDs AS (
    SELECT RowNr, CAST(Piece AS INT) AS SectorID FROM ##InputSplitCust WHERE TRY_CAST(Piece AS INT) IS NOT NULL 
), cte_MaxCols AS (
    SELECT RowNr, MAX(ColNr) MaxColNr FROM ##InputGrid GROUP BY RowNr
), cte_PerLetter AS (
    SELECT I.RowNr, I.ColNr, c.SectorID
    ,      CASE WHEN Val = '-' THEN ' '
                WHEN ASCII(Val) + SectorID % 26 > 122 THEN CHAR(ASCII(Val) + SectorID % 26 - 26) ELSE CHAR(ASCII(Val) + SectorID % 26) END AS RotatedLetter
    FROM ##InputGrid I
    INNER JOIN cte_SectorIDs c ON I.RowNr = c.RowNr - 1
), cte_Sentences AS (
    SELECT RowNr,
           ColNr,
           CAST(RotatedLetter AS VARCHAR(200)) AS Sentence,
           SectorID
    FROM cte_PerLetter
    WHERE ColNr = 0

    UNION ALL

    SELECT cS.RowNr,
           cPL.ColNr,
           CAST(Sentence + ISNULL(RotatedLetter, '') AS VARCHAR(200)),
           cS.SectorID
    FROM cte_Sentences cS
    INNER JOIN cte_PerLetter cPL ON cS.RowNr = cPL.RowNr AND cS.ColNr = cPL.ColNr - 1
)
INSERT ##Results (Sentence, SectorID)
SELECT Sentence, SectorID
FROM cte_Sentences c
INNER JOIN cte_MaxCols S ON c.ColNr = S.MaxColNr AND c.RowNr = S.RowNr

-- Because there are some interesting names in there
SELECT * FROM ##Results ORDER BY SectorID

SELECT SectorID AS Part2 FROM ##Results WHERE Sentence LIKE '%North%'

DROP TABLE ##Results

