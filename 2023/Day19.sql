USE Test_WME

SET NOCOUNT ON

DECLARE @year VARCHAR(4) = '2023'
DECLARE @day VARCHAR(2)  = '19'

EXEC dbo.GetInput @year = @year, @day = @day
EXEC dbo.ParseInput @year = @year, @day = @day, @SplitCustom = '{}:,'

--SELECT TOP 10 * FROM ##Input
--SELECT TOP 10 * FROM ##InputInts
--SELECT TOP 10 * FROM ##InputNumbered
--SELECT TOP 10 * FROM ##InputGrid
--SELECT TOP 10 * FROM ##InputSplit

DECLARE @CutoffRowNr INT 

SELECT @CutoffRowNr = MIN(I1.RowNr) + 1
FROM ##InputSplitCust I1
LEFT JOIN ##InputSplitCust I2 ON I1.RowNr = I2.RowNr - 1
WHERE I2.Ind IS NULL

CREATE TABLE ##Parts (ID INT IDENTITY(1,1), OriginalRowNr INT, x INT, m INT, a INT, s INT, CurrentStatusRow INT, CurrentStatusPiece INT)

;WITH cte_Start AS (
    SELECT RowNr
    FROM ##InputSplitCust
    WHERE Piece = 'in'
)
INSERT ##Parts(OriginalRowNr, x, m, a, s, CurrentStatusRow, CurrentStatusPiece)
SELECT Pvt.RowNr, MAX(x) AS x, MAX(m) AS m, MAX(a) AS a, MAX(s) AS s, MAX(c.RowNr), 1
FROM (
    SELECT RowNr, PieceNr, LEFT(Piece,1) AS Letter, SUBSTRING(Piece, 3,LEN(Piece)) AS Val
    FROM ##InputSplitCust
    WHERE RowNr > @CutoffRowNr
) Sub
PIVOT (
    MAX(Val)
    FOR Letter IN (x,m,a,s)
) Pvt
CROSS APPLY cte_Start c
GROUP BY Pvt.RowNr

WHILE (SELECT COUNT(1) 
       FROM ##Parts P 
       INNER JOIN ##InputSplitCust I ON P.CurrentStatusRow = I.RowNr AND P.CurrentStatusPiece = I.PieceNr
       WHERE I.Piece NOT IN ('A','R')) > 0
BEGIN

    UPDATE P
    SET P.CurrentStatusRow = I2.RowNr
    ,   P.CurrentStatusPiece = I2.PieceNr
    FROM ##Parts P
    INNER JOIN ##InputSplitCust I ON P.CurrentStatusRow = I.RowNr AND P.CurrentStatusPiece = I.PieceNr
    INNER JOIN ##InputSplitCust I2 ON I.RowNr = I2.RowNr AND I.PieceNr = I2.PieceNr - 1
    WHERE I.Piece NOT LIKE '%<%' AND I.Piece NOT LIKE '%>%' AND I.Piece NOT IN ('A','R')

    UPDATE P
    SET P.CurrentStatusRow = CASE WHEN I3.Ind IS NULL THEN I2.RowNr ELSE I3.RowNr END
    ,   P.CurrentStatusPiece = CASE WHEN I3.Ind IS NULL THEN I2.PieceNr ELSE I3.PieceNr END
    FROM ##Parts P
    INNER JOIN ##InputSplitCust I ON P.CurrentStatusRow = I.RowNr AND P.CurrentStatusPiece = I.PieceNr
    INNER JOIN ##InputSplitCust I2 ON I.RowNr = I2.RowNr AND I.PieceNr = I2.PieceNr - CASE WHEN SUBSTRING(I.Piece, 2, 1) = '<' 
                                                                                           THEN CASE WHEN
                                                                                                    CASE WHEN LEFT(I.Piece,1) = 'x' THEN x
                                                                                                         WHEN LEFT(I.Piece,1) = 'm' THEN m 
                                                                                                         WHEN LEFT(I.Piece,1) = 'a' THEN a 
                                                                                                         WHEN LEFT(I.Piece,1) = 's' THEN s
                                                                                                    END
                                                                                                    - CAST(SUBSTRING(I.Piece, 3, LEN(I.Piece)) AS INT) < 0 THEN 1 ELSE 2 END
                                                                                            ELSE 
                                                                                                CASE WHEN
                                                                                                    CASE WHEN LEFT(I.Piece,1) = 'x' THEN x
                                                                                                         WHEN LEFT(I.Piece,1) = 'm' THEN m 
                                                                                                         WHEN LEFT(I.Piece,1) = 'a' THEN a 
                                                                                                         WHEN LEFT(I.Piece,1) = 's' THEN s
                                                                                                    END
                                                                                                    - CAST(SUBSTRING(I.Piece, 3, LEN(I.Piece)) AS INT) > 0 THEN 1 ELSE 2 END
                                                                                      END
    LEFT JOIN ##InputSplitCust I3 ON I3.PieceNr = 1 AND I2.Piece = I3.Piece
    WHERE I.Piece LIKE '%<%' OR I.Piece LIKE '%>%'

END


SELECT SUM(x+m+a+s) AS Part1
FROM ##Parts P
INNER JOIN ##InputSplitCust I ON P.CurrentStatusRow = I.RowNr AND P.CurrentStatusPiece = I.PieceNr
WHERE I.Piece = 'A'


CREATE TABLE ##Ranges (ID INT IDENTITY(1,1), xMin INT, xMax INT, mMin INT, mMax INT, aMin INT, aMax INT, sMin INT, sMax INT, CurrentStatusRow INT, CurrentStatusPiece INT, Step INT)

;WITH cte_Start AS (
    SELECT RowNr
    FROM ##InputSplitCust
    WHERE Piece = 'in'
)
INSERT ##Ranges (xMin, xMax, mMin, mMax, aMin, aMax, sMin, sMax, CurrentStatusRow, CurrentStatusPiece, Step) SELECT 1, 4000, 1, 4000, 1, 4000, 1, 4000, RowNr, 1, 0 FROM cte_Start

DECLARE @Step INT = 0 

WHILE (SELECT COUNT(1) 
       FROM ##Ranges R 
       INNER JOIN ##InputSplitCust I ON R.CurrentStatusRow = I.RowNr AND R.CurrentStatusPiece = I.PieceNr
       WHERE I.Piece NOT IN ('A','R')) > 0
BEGIN

    SET @Step = @Step + 1

    UPDATE R
    SET R.CurrentStatusRow = I2.RowNr
    ,   R.CurrentStatusPiece = I2.PieceNr
    FROM ##Ranges R
    INNER JOIN ##InputSplitCust I ON R.CurrentStatusRow = I.RowNr AND R.CurrentStatusPiece = I.PieceNr
    INNER JOIN ##InputSplitCust I2 ON I.RowNr = I2.RowNr AND I.PieceNr = I2.PieceNr - 1
    WHERE I.Piece NOT LIKE '%<%' AND I.Piece NOT LIKE '%>%' AND I.Piece NOT IN ('A','R')


    ;WITH cte_Two AS (
        SELECT 0 AS Nr UNION SELECT 1
    )
    INSERT ##Ranges (xMin, xMax, mMin, mMax, aMin, aMax, sMin, sMax, CurrentStatusRow, CurrentStatusPiece, Step) 
    SELECT CASE WHEN LEFT(I.Piece, 1) = 'x' AND SUBSTRING(I.Piece,2,1) = '<' AND c.Nr = 1 THEN CAST(SUBSTRING(I.Piece,3,LEN(I.Piece)) AS INT) 
                WHEN LEFT(I.Piece, 1) = 'x' AND SUBSTRING(I.Piece,2,1) = '>' AND c.Nr = 1 THEN CAST(SUBSTRING(I.Piece,3,LEN(I.Piece)) AS INT) + 1
                ELSE xMin
           END
    ,      CASE WHEN LEFT(I.Piece, 1) = 'x' AND SUBSTRING(I.Piece,2,1) = '<' AND c.Nr = 0 THEN CAST(SUBSTRING(I.Piece,3,LEN(I.Piece)) AS INT) - 1
                WHEN LEFT(I.Piece, 1) = 'x' AND SUBSTRING(I.Piece,2,1) = '>' AND c.Nr = 0 THEN CAST(SUBSTRING(I.Piece,3,LEN(I.Piece)) AS INT)
                ELSE xMax
           END
    ,      CASE WHEN LEFT(I.Piece, 1) = 'm' AND SUBSTRING(I.Piece,2,1) = '<' AND c.Nr = 1 THEN CAST(SUBSTRING(I.Piece,3,LEN(I.Piece)) AS INT) 
                WHEN LEFT(I.Piece, 1) = 'm' AND SUBSTRING(I.Piece,2,1) = '>' AND c.Nr = 1 THEN CAST(SUBSTRING(I.Piece,3,LEN(I.Piece)) AS INT) + 1
                ELSE mMin
           END
    ,      CASE WHEN LEFT(I.Piece, 1) = 'm' AND SUBSTRING(I.Piece,2,1) = '<' AND c.Nr = 0 THEN CAST(SUBSTRING(I.Piece,3,LEN(I.Piece)) AS INT) - 1
                WHEN LEFT(I.Piece, 1) = 'm' AND SUBSTRING(I.Piece,2,1) = '>' AND c.Nr = 0 THEN CAST(SUBSTRING(I.Piece,3,LEN(I.Piece)) AS INT)
                ELSE mMax
           END
    ,      CASE WHEN LEFT(I.Piece, 1) = 'a' AND SUBSTRING(I.Piece,2,1) = '<' AND c.Nr = 1 THEN CAST(SUBSTRING(I.Piece,3,LEN(I.Piece)) AS INT) 
                WHEN LEFT(I.Piece, 1) = 'a' AND SUBSTRING(I.Piece,2,1) = '>' AND c.Nr = 1 THEN CAST(SUBSTRING(I.Piece,3,LEN(I.Piece)) AS INT) + 1
                ELSE aMin
           END
    ,      CASE WHEN LEFT(I.Piece, 1) = 'a' AND SUBSTRING(I.Piece,2,1) = '<' AND c.Nr = 0 THEN CAST(SUBSTRING(I.Piece,3,LEN(I.Piece)) AS INT) - 1
                WHEN LEFT(I.Piece, 1) = 'a' AND SUBSTRING(I.Piece,2,1) = '>' AND c.Nr = 0 THEN CAST(SUBSTRING(I.Piece,3,LEN(I.Piece)) AS INT)
                ELSE aMax
           END
    ,      CASE WHEN LEFT(I.Piece, 1) = 's' AND SUBSTRING(I.Piece,2,1) = '<' AND c.Nr = 1 THEN CAST(SUBSTRING(I.Piece,3,LEN(I.Piece)) AS INT) 
                WHEN LEFT(I.Piece, 1) = 's' AND SUBSTRING(I.Piece,2,1) = '>' AND c.Nr = 1 THEN CAST(SUBSTRING(I.Piece,3,LEN(I.Piece)) AS INT) + 1
                ELSE sMin
           END
    ,      CASE WHEN LEFT(I.Piece, 1) = 's' AND SUBSTRING(I.Piece,2,1) = '<' AND c.Nr = 0 THEN CAST(SUBSTRING(I.Piece,3,LEN(I.Piece)) AS INT) - 1
                WHEN LEFT(I.Piece, 1) = 's' AND SUBSTRING(I.Piece,2,1) = '>' AND c.Nr = 0 THEN CAST(SUBSTRING(I.Piece,3,LEN(I.Piece)) AS INT)
                ELSE sMax
           END 
    ,      CASE WHEN I3.Ind IS NULL THEN I2.RowNr ELSE I3.RowNr END
    ,      CASE WHEN I3.Ind IS NULL THEN I2.PieceNr ELSE I3.PieceNr END
    ,      @Step
    FROM ##Ranges R
    INNER JOIN ##InputSplitCust I ON R.CurrentStatusRow = I.RowNr AND R.CurrentStatusPiece = I.PieceNr
    CROSS APPLY cte_Two c
    INNER JOIN ##InputSplitCust I2 ON I.RowNr = I2.RowNr AND I.PieceNr = I2.PieceNr - CASE WHEN (SUBSTRING(I.Piece,2,1) = '<' AND C.Nr = 0) OR (SUBSTRING(I.Piece,2,1) = '>' AND C.Nr = 1) THEN 1 ELSE 2 END
    LEFT JOIN ##InputSplitCust I3 ON I3.PieceNr = 1 AND I2.Piece = I3.Piece
    WHERE I.Piece LIKE '%<%' OR I.Piece LIKE '%>%' AND R.Step = @Step - 1

    DELETE FROM R
    FROM ##Ranges R 
    INNER JOIN ##InputSplitCust I ON R.CurrentStatusRow = I.RowNr AND R.CurrentStatusPiece = I.PieceNr
    WHERE R.Step = @Step - 1 AND I.Piece NOT IN ('A','R')

END

SELECT SUM(CAST((xMax-xMin+1) AS BIGINT)*(mMax-mMin+1)*(aMax-aMin+1)*(sMax-sMin+1)) AS Part2
FROM ##Ranges R 
INNER JOIN ##InputSplitCust I ON R.CurrentStatusRow = I.RowNr AND R.CurrentStatusPiece = I.PieceNr
WHERE I.Piece = 'A'

/*

DROP TABLE ##Parts
DROP TABLE ##Ranges


*/

