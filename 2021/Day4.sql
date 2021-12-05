USE Test_WME

DECLARE @year VARCHAR(4) = '2021'
DECLARE @day VARCHAR(2)  = '4'

EXEC dbo.GetInput @year = @year, @day = @day
EXEC dbo.ParseInput @year = @year, @day = @day 

SELECT TOP 10 * FROM ##InputNumbered
SELECT TOP 10 * FROM ##InputGrid
SELECT TOP 10 * FROM ##InputInts
SELECT TOP 10 * FROM ##InputSplit


--SELECT * FROM ##InputSplit


CREATE TABLE ##Cards(ID INT IDENTITY(1,1), CardNr INT, RowNr INT, ColNr INT, Val INT, Marked INT)

INSERT ##Cards(CardNr, RowNr, ColNr, Val, Marked)
SELECT (RowNr-2)/6 AS CardNr, (RowNr-2)%6 AS RowNr, PieceNr, Piece, 0
FROM ##InputSplit --cte_Pieces
WHERE RowNr > 1
ORDER BY 1,2,3

  
--SELECT * FROM ##Cards

DECLARE @CardFound INT = 0
DECLARE @Index INT = 1
DECLARE @NumberCalled INT

WHILE @CardFound = 0
BEGIN

    SELECT @NumberCalled = CAST(Piece AS INT) FROM ##InputSplit WHERE RowNr = 1 AND PieceNr = @Index

    UPDATE ##Cards
    SET Marked = 1
    WHERE Val = @NumberCalled


    ;WITH cte_Checked AS (
        SELECT CardNr, RowNr, SUM(Marked) AS Checked
        FROM ##Cards
        GROUP BY CardNr, RowNr
        HAVING SUM(Marked) > 4
    
        UNION ALL

        SELECT CardNr, ColNr, SUM(Marked)
        FROM ##Cards
        GROUP BY CardNr, ColNr
        HAVING SUM(Marked) > 4
    )
    SELECT @CardFound = CardNr
    FROM cte_Checked

    SET @Index = @Index + 1

END


SELECT C.CardNr, SUM (Val), SUM (Val) * @NumberCalled AS Part1
FROM ##Cards C
WHERE C.Marked = 0 AND CardNr = @CardFound
GROUP BY C.CardNr

--41668 is correct for part 1

DECLARE @LeftOverCards INT = 500 

WHILE @LeftOverCards > 0
BEGIN

    SELECT @NumberCalled = CAST(Piece AS INT) FROM ##InputSplit WHERE RowNr = 1 AND PieceNr = @Index

    UPDATE ##Cards
    SET Marked = 1
    WHERE Val = @NumberCalled

    ;WITH cte_Checked AS (
        SELECT CardNr, RowNr, SUM(Marked) AS Checked
        FROM ##Cards
        GROUP BY CardNr, RowNr
        HAVING SUM(Marked) > 4
    
        UNION ALL

        SELECT CardNr, ColNr, SUM(Marked)
        FROM ##Cards
        GROUP BY CardNr, ColNr
        HAVING SUM(Marked) > 4
    )
    DELETE FROM ##Cards
    WHERE CardNr IN (SELECT CardNr FROM cte_Checked)

    SELECT @LeftOverCards = COUNT(DISTINCT CardNr)
    FROM ##Cards C

    IF @LeftOverCards = 1 SELECT * INTO ##LastCard FROM ##Cards

    -- This becomes relevant once there is only one card left. We need to keep it to calculate the answer (after it finishes)
    IF @LeftOverCards <= 1
        UPDATE ##LastCard
        SET Marked = 1
        WHERE Val = @NumberCalled

    SET @Index = @Index + 1

END


SELECT C.CardNr, SUM (Val), SUM (Val) * @NumberCalled AS Part2
FROM ##LastCard C
WHERE C.Marked = 0 
GROUP BY C.CardNr

DROP TABLE ##LastCard
DROP TABLE ##Cards


