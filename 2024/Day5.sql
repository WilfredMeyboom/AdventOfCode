USE Test_WME

SET NOCOUNT ON

DECLARE @year VARCHAR(4) = '2024'
DECLARE @day VARCHAR(2)  = '5'

EXEC dbo.GetInput @year = @year, @day = @day
EXEC dbo.ParseInput @year = @year, @day = @day 

--SELECT TOP 10 * FROM ##Input
--SELECT TOP 10 * FROM ##InputInts
--SELECT TOP 10 * FROM ##InputNumbered
--SELECT TOP 10 * FROM ##InputGrid
--SELECT TOP 10 * FROM ##InputSplit
--SELECT TOP 10 * FROM ##InputSplitCust


SELECT * INTO ##Order FROM ##InputSplit WHERE RowNr < 1177
SELECT * INTO ##Pages FROM ##InputSplit WHERE RowNr > 1177

--SELECT * FROM ##InputSplit

CREATE TABLE ##InvalidPieces (ID INT IDENTITY(1,1), RowNr INT, PieceNr1 INT, Piece1 VARCHAR(5), PieceNr2 INT, Piece2 VARCHAR(5))

INSERT ##InvalidPieces (RowNr, PieceNr1, Piece1, PieceNr2, Piece2)
SELECT P1.RowNr, P1.PieceNr AS PieceNr1, P1.Piece AS Piece1, P2.PieceNr AS PieceNr2, P2.Piece AS Piece2
FROM ##Pages P1
INNER JOIN ##Pages P2 ON P1.RowNr = P2.RowNr
INNER JOIN ##Order O1 ON P1.Piece = O1.Piece AND O1.PieceNr = 1
INNER JOIN ##Order O2 ON P2.Piece = O2.Piece AND O2.PieceNr = 2 AND O1.RowNr = O2.RowNr
WHERE P1.PieceNr > P2.PieceNr
    
SELECT RowNr 
INTO ##InvalidRows
FROM ##InvalidPieces 
GROUP BY RowNr

;WITH cte_ValidRows AS (
    SELECT P.RowNr, MAX(PieceNr) AS NrOfPieces
    FROM ##Pages P
    LEFT JOIN ##InvalidRows c ON P.RowNr = c.RowNr
    WHERE c.RowNr IS NULL
    GROUP BY P.RowNr
)
SELECT SUM(CAST(Piece AS INT)) AS Part1
FROM cte_ValidRows c
INNER JOIN ##Pages P ON c.RowNr = P.RowNr AND (c.NrOfPieces / 2) + 1 = P.PieceNr



DECLARE @RowCount INT = 1

WHILE @RowCount > 0
BEGIN

    ;WITH cte_CleanUp AS (
        SELECT ID , ROW_NUMBER() OVER (PARTITION BY RowNr ORDER BY RowNr) AS Rn
        FROM ##InvalidPieces
    )
    DELETE FROM P
    FROM ##InvalidPieces P
    INNER JOIN cte_CleanUp C ON P.ID = C.ID AND C.Rn <> 1

    UPDATE P
    SET P.Piece = I.Piece2
    FROM ##Pages P 
    INNER JOIN ##InvalidPieces I ON P.RowNr = I.RowNr AND P.PieceNr = I.PieceNr1
    
    UPDATE P
    SET P.Piece = I.Piece1
    FROM ##Pages P 
    INNER JOIN ##InvalidPieces I ON P.RowNr = I.RowNr AND P.PieceNr = I.PieceNr2

    DELETE FROM ##InvalidPieces

    INSERT ##InvalidPieces (RowNr, PieceNr1, Piece1, PieceNr2, Piece2)
    SELECT P1.RowNr, P1.PieceNr AS PieceNr1, P1.Piece AS Piece1, P2.PieceNr AS PieceNr2, P2.Piece AS Piece2
    FROM ##Pages P1
    INNER JOIN ##Pages P2 ON P1.RowNr = P2.RowNr
    INNER JOIN ##Order O1 ON P1.Piece = O1.Piece AND O1.PieceNr = 1
    INNER JOIN ##Order O2 ON P2.Piece = O2.Piece AND O2.PieceNr = 2 AND O1.RowNr = O2.RowNr
    WHERE P1.PieceNr > P2.PieceNr

    SET @RowCount = @@ROWCOUNT

END

;WITH cte_InvalidRows AS (
    SELECT P.RowNr, MAX(PieceNr) AS NrOfPieces
    FROM ##Pages P
    INNER JOIN ##InvalidRows c ON P.RowNr = c.RowNr
    GROUP BY P.RowNr
)
SELECT SUM(CAST(Piece AS INT)) AS Part2
FROM cte_InvalidRows c
INNER JOIN ##Pages P ON c.RowNr = P.RowNr AND (c.NrOfPieces / 2) + 1 = P.PieceNr


DROP TABLE ##InvalidPieces
DROP TABLE ##InvalidRows
DROP TABLE ##Pages
DROP TABLE ##Order

