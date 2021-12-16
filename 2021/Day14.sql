USE Test_WME

SET NOCOUNT ON

DECLARE @year VARCHAR(4) = '2021'
DECLARE @day VARCHAR(2)  = '14'

EXEC dbo.GetInput @year = @year, @day = @day
EXEC dbo.ParseInput @year = @year, @day = @day, @SplitCustom = '- >'

--SELECT TOP 10 * FROM ##InputNumbered
--SELECT * FROM ##InputGrid ORDER BY RowNr
--SELECT TOP 10 * FROM ##InputInts
--SELECT * FROM ##InputSplit
--SELECT * FROM ##InputSplitCust

-- First row is the starting polymer, second row is empty
DELETE FROM ##InputSplitCust WHERE RowNr IN (1,2)


DECLARE @Counter INT = 0

CREATE TABLE ##PolymerComposition (ID INT IDENTITY(1,1), Pair CHAR(2), Amt BIGINT)

--Fill the table with the current polymer composition
;WITH cte_1 AS (
    SELECT Val + CAST(LEAD(Val) OVER (ORDER BY ColNr) AS CHAR(1)) AS Pair
    FROM ##InputGrid I WHERE RowNr = 0
)
INSERT ##PolymerComposition (Pair, Amt)
SELECT Pair, COUNT(1) AS Amt
FROM cte_1
WHERE Pair IS NOT NULL
GROUP BY Pair

-- Add character pairs that are not in the polymer yet but are in the specification
INSERT ##PolymerComposition (Pair, Amt)
SELECT I.Piece, 0 
FROM ##InputSplitCust I 
LEFT JOIN ##PolymerComposition R ON R.Pair = I.Piece 
WHERE I.PieceNr = 1 AND R.Pair IS NULL

-- Start stepping
WHILE @Counter < 40
BEGIN

    ;WITH cte_Transform AS (
        SELECT I.Piece, LEFT(I.Piece,1) + I2.Piece AS NewPiece1, I2.Piece + RIGHT(I.Piece,1) AS NewPiece2
        FROM ##InputSplitCust I
        INNER JOIN ##InputSplitCust I2 ON  I2.RowNr = I.RowNr AND I2.PieceNr > I.PieceNr
    ), cte_NewAmounts AS (
        SELECT R2.Pair, SUM(R.Amt) AS NewAmt
        FROM ##PolymerComposition R
        INNER JOIN cte_Transform c ON c.Piece = R.Pair
        INNER JOIN ##PolymerComposition R2 ON R2.Pair IN (c.NewPiece1, c.NewPiece2)
        GROUP BY R2.Pair
    )
    UPDATE R
    SET Amt = ISNULL(c.NewAmt,0)
    FROM ##PolymerComposition R
    LEFT JOIN cte_NewAmounts c ON c.Pair = R.Pair


    SET @Counter = @Counter + 1

    IF @Counter = 10 --End of Part 1
    BEGIN
        ;WITH cte_PerElement AS (
            SELECT LEFT(Pair,1) AS Element, RIGHT(Pair,1) AS OtherElement, Amt
            FROM ##PolymerComposition R
        ), cte_ElementsCombined AS (
            SELECT Element, Amt
            FROM cte_PerElement

            UNION ALL       --Keep duplicates

            SELECT OtherElement, Amt
            FROM cte_PerElement
        ), cte_ElementAmounts AS (
            SELECT Element, CEILING((SUM(Amt)/2.0)) AS Amt --Every element is part of 2 pairs
                                                           --which means it is counted double
                                                           --Exception are the very first and last elements
            FROM cte_ElementsCombined
            GROUP BY Element
        )
        SELECT MAX(Amt) - MIN(Amt) AS Part1
        FROM cte_ElementAmounts
    END

END

;WITH cte_PerElement AS (
    SELECT LEFT(Pair,1) AS Element, RIGHT(Pair,1) AS OtherElement, Amt
    FROM ##PolymerComposition R
), cte_ElementsCombined AS (
    SELECT Element, Amt
    FROM cte_PerElement

    UNION ALL       --Keep duplicates

    SELECT OtherElement, Amt
    FROM cte_PerElement
), cte_ElementAmounts AS (
    SELECT Element, CEILING((SUM(Amt)/2.0)) AS Amt --Every element is part of 2 pairs
                                                    --which means it is counted double
                                                    --Exception are the very first and last elements
    FROM cte_ElementsCombined
    GROUP BY Element
)
SELECT MAX(Amt) - MIN(Amt) AS Part2
FROM cte_ElementAmounts

DROP TABLE ##PolymerComposition
