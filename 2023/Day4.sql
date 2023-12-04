USE Test_WME

SET NOCOUNT ON

DECLARE @year VARCHAR(4) = '2023'
DECLARE @day VARCHAR(2)  = '4'

EXEC dbo.GetInput @year = @year, @day = @day
EXEC dbo.ParseInput @year = @year, @day = @day 

--SELECT TOP 10 * FROM ##Input
--SELECT TOP 10 * FROM ##InputInts
--SELECT TOP 10 * FROM ##InputNumbered
--SELECT TOP 10 * FROM ##InputGrid
--SELECT TOP 10 * FROM ##InputSplitCust
 

--Winning nrs are from PieceNr 3 through 12. Cards without matches are automatically filtered out
;WITH cte_ScorePerCard AS (
    SELECT IWin.RowNr, POWER(2,COUNT(1) - 1) AS Score
    FROM ##InputSplit IWin
    INNER JOIN ##InputSplit IMine ON IWin.RowNr = IMine.RowNr AND IWin.Piece = IMine.Piece AND IMine.PieceNr > 12
    WHERE IWin.PieceNr BETWEEN 3 AND 12
    GROUP BY IWin.RowNr
)
SELECT SUM(Score) AS Part1
FROM cte_ScorePerCard


CREATE TABLE ##ScratchCards (ID INT IDENTITY(1,1), RowNr INT, Matches INT, NrOfCards BIGINT)

-- Populate the table
INSERT ##ScratchCards (RowNr)
SELECT DISTINCT RowNr FROM ##InputSplit ORDER BY RowNr

-- Store the number of matches per card
;WITH cte_MatchesPerCard AS (
    SELECT IWin.RowNr, COUNT(1) AS Matches
    FROM ##InputSplit IWin
    INNER JOIN ##InputSplit IMine ON IWin.RowNr = IMine.RowNr AND IWin.Piece = IMine.Piece AND IMine.PieceNr > 12
    WHERE IWin.PieceNr BETWEEN 3 AND 12
    GROUP BY IWin.RowNr
)
UPDATE SC
SET Matches = cM.Matches
FROM ##ScratchCards SC
INNER JOIN cte_MatchesPerCard cM ON SC.RowNr = cM.RowNr
  
-- If the matches is empty, the card has no matches and we just need to count the card itself
UPDATE ##ScratchCards
SET Matches = 0
,   NrOfCards = 1
WHERE Matches IS NULL

-- Let's go through all the cards beginning at the end
DECLARE @RowNr INT

DECLARE CardCursor CURSOR FOR SELECT RowNr FROM ##ScratchCards WHERE NrOfCards IS NULL ORDER BY RowNr DESC

OPEN CardCursor

FETCH NEXT FROM CardCursor INTO @RowNr

WHILE @@FETCH_STATUS = 0
BEGIN

    -- The number of cards is the sum of the cards it refers to +1 for the card itself
    ;WITH cte_SumCards AS (
        SELECT SC.RowNr, SUM(SC2.NrOfCards) + 1 AS SumCards
        FROM ##ScratchCards SC
        INNER JOIN ##ScratchCards SC2 ON SC2.RowNr BETWEEN SC.RowNr + 1 AND SC.RowNr + SC.Matches
        WHERE SC.RowNr = @RowNr
        GROUP BY SC.RowNr
    )
    UPDATE SC
    SET NrOfCards = cS.SumCards
    FROM ##ScratchCards SC
    INNER JOIN cte_SumCards cS ON SC.RowNr = cS.RowNr

    FETCH NEXT FROM CardCursor INTO @RowNr

END

CLOSE CardCursor
DEALLOCATE CardCursor

-- Count all the cards
SELECT SUM(NrOfCards) AS Part2 FROM ##ScratchCards

DROP TABLE ##ScratchCards