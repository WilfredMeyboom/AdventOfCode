USE Test_WME

SET NOCOUNT ON

CREATE TABLE ##Input (Line NVARCHAR(MAX));

BULK INSERT ##Input
FROM 'C:\Source\AdventOfCode\2020\input22.txt'
WITH (ROWTERMINATOR = '0x0A');

CREATE TABLE ##Deck1 (ID INT IDENTITY(1,1), Nr INT)
CREATE TABLE ##Deck2 (ID INT IDENTITY(1,1), Nr INT)
CREATE TABLE ##NewDeck1 (ID INT IDENTITY(1,1), Nr INT)
CREATE TABLE ##NewDeck2 (ID INT IDENTITY(1,1), Nr INT)

DECLARE @InputSize INT
SELECT @InputSize = COUNT(1) FROM ##Input

INSERT ##Deck1 (Nr)
SELECT TOP ((@InputSize - 3)/2) Line FROM ##Input WHERE LEFT(Line,1) <> 'P'

DELETE TOP((@InputSize - 1)/2+1) FROM ##Input

INSERT ##Deck2 (Nr)
SELECT Line FROM ##Input WHERE LEFT(Line,1) <> 'P'

--SELECT * FROM ##Deck1
--SELECT * FROM ##Deck2

DECLARE @DeckSize1 INT
DECLARE @DeckSize2 INT
DECLARE @MatchCounter INT = 0
DECLARE @RoundCounter INT = 0
DECLARE @MatchesThisRound INT = 0

DECLARE @DoPart1 INT = 0

IF @DoPart1 = 1
BEGIN 
SELECT @DeckSize1 = COUNT(1) FROM ##Deck1
SELECT @DeckSize2 = COUNT(1) FROM ##Deck2

--Deck2 has the highest card so player 2 will be the winner

WHILE @DeckSize1 > 0 AND @DeckSize2 > 0
BEGIN
    
    SET @MatchesThisRound = (@DeckSize1 + @DeckSize2) / 2

    --Move the tail of the larger deck to the top of new deck
    IF @DeckSize1 > @DeckSize2 
    BEGIN
        INSERT ##NewDeck1 (Nr) SELECT Nr FROM ##Deck1 ORDER BY ID OFFSET @DeckSize2 ROWS
        SET @MatchesThisRound = @DeckSize2
    END

    IF @DeckSize1 < @DeckSize2 
    BEGIN        
        INSERT ##NewDeck2 (Nr) SELECT Nr FROM ##Deck2 ORDER BY ID OFFSET @DeckSize1 ROWS
        SET @MatchesThisRound = @DeckSize1
    END

    SET @MatchCounter = @MatchCounter + @MatchesThisRound

    --Add Cards to Deck 1
    ;WITH cte_Deck1 AS (
        SELECT TOP (@MatchesThisRound)
               ROW_NUMBER() OVER (ORDER BY ID) RowNr
        ,      Nr
        ,      1 AS Player
        FROM ##Deck1
    ), cte_Deck2 AS (
        SELECT TOP (@MatchesThisRound) 
               ROW_NUMBER() OVER (ORDER BY ID) RowNr
        ,      Nr
        ,      2 AS Player
        FROM ##Deck2
    ), cte_Wins AS (
        SELECT D1.RowNr
        FROM cte_Deck1 D1
        INNER JOIN cte_Deck2 D2 ON D1.RowNr = D2.RowNr AND D1.Nr > D2.Nr
    ), cte_Cards AS (
        SELECT Nr, RowNr, Player
        FROM cte_Deck1
        WHERE RowNr IN (SELECT RowNr FROM cte_Wins)
        UNION ALL
        SELECT Nr, RowNr, Player
        FROM cte_Deck2
        WHERE RowNr IN (SELECT RowNr FROM cte_Wins)
    )
    INSERT ##NewDeck1 (Nr)
    SELECT Nr
    FROM cte_Cards
    ORDER BY RowNr, Player

    --Add Cards to Deck 2
    ;WITH cte_Deck1 AS (
        SELECT TOP (@MatchesThisRound)
               ROW_NUMBER() OVER (ORDER BY ID) RowNr
        ,      Nr
        ,      1 AS Player
        FROM ##Deck1
    ), cte_Deck2 AS (
        SELECT TOP (@MatchesThisRound) 
               ROW_NUMBER() OVER (ORDER BY ID) RowNr
        ,      Nr
        ,      2 AS Player
        FROM ##Deck2
    ), cte_Wins AS (
        SELECT D1.RowNr
        FROM cte_Deck1 D1
        INNER JOIN cte_Deck2 D2 ON D1.RowNr = D2.RowNr AND D1.Nr < D2.Nr
    ), cte_Cards AS (
        SELECT Nr, RowNr, Player
        FROM cte_Deck1
        WHERE RowNr IN (SELECT RowNr FROM cte_Wins)
        UNION ALL
        SELECT Nr, RowNr, Player
        FROM cte_Deck2
        WHERE RowNr IN (SELECT RowNr FROM cte_Wins)
    )
    INSERT ##NewDeck2 (Nr)
    SELECT Nr
    FROM cte_Cards
    ORDER BY RowNr, Player DESC

    --SELECT * FROM ##NewDeck1
    --SELECT * FROM ##NewDeck2

    --Switch out the decks
    DELETE FROM ##Deck1
    DELETE FROM ##Deck2
    INSERT ##Deck1 (Nr) SELECT Nr FROM ##NewDeck1 ORDER BY ID
    INSERT ##Deck2 (Nr) SELECT Nr FROM ##NewDeck2 ORDER BY ID
    DELETE FROM ##NewDeck1
    DELETE FROM ##NewDeck2

    SELECT @DeckSize1 = COUNT(1) FROM ##Deck1
    SELECT @DeckSize2 = COUNT(1) FROM ##Deck2

    SET @RoundCounter = @RoundCounter + 1

    PRINT 'Round: ' + CAST(@RoundCounter AS VARCHAR(20)) +  ' MatchCounter: ' + CAST(@MatchCounter AS VARCHAR(20))

END

--Round: 54 MatchCounter: 773

--SELECT * FROM ##Deck1

;WITH cte_CardValues AS (
    SELECT @DeckSize2 - ROW_NUMBER() OVER (ORDER BY ID) + 1 AS CardValue
    ,      Nr
    FROM ##Deck2
)
SELECT SUM (Nr * CardValue)
FROM cte_CardValues

--33393 is correct for part 1

END

ELSE -- DoPart1

BEGIN

    ALTER TABLE ##Deck1 ADD GameNr INT
    ALTER TABLE ##Deck2 ADD GameNr INT

    UPDATE ##Deck1 SET GameNr = 1
    UPDATE ##Deck2 SET GameNr = 1

    CREATE TABLE ##GameStates (ID INT IDENTITY(1,1), GameNr INT, GameState VARCHAR(500))

    EXEC dbo.RecursiveWar 1

    DECLARE @DeckSize INT
    SELECT @DeckSize = COUNT(1) FROM ##Deck2

    ;WITH cte_CardValues AS (
    SELECT @DeckSize - ROW_NUMBER() OVER (ORDER BY ID) + 1 AS CardValue
    ,      Nr
    FROM ##Deck2
    )
    SELECT SUM (Nr * CardValue)
    FROM cte_CardValues

END

--SELECT * FROM ##Deck1 ORDER BY GameNr, ID
--SELECT * FROM ##Deck2 ORDER BY GameNr, ID
--SELECT * FROM ##GameStates

/*

DROP TABLE ##GameStates
DROP TABLE ##Deck1
DROP TABLE ##Deck2
DROP TABLE ##NewDeck1
DROP TABLE ##NewDeck2
DROP TABLE ##Input

*/

GO

/*

CREATE OR ALTER PROCEDURE dbo.RecursiveWar (@GameNr INT)
AS 
BEGIN
    
    DECLARE @DeckSize1 INT
    DECLARE @DeckSize2 INT
    DECLARE @DuplicateGameState INT = 0
    DECLARE @NextCard1 INT
    DECLARE @NextCard2 INT
    DECLARE @RecursiveGameWinner INT = 0
    DECLARE @GameState VARCHAR(500)
    DECLARE @NextGameNr INT
    DECLARE @Debug INT = 0

    SELECT @DeckSize1 = COUNT(1) FROM ##Deck1 WHERE GameNr = @GameNr
    SELECT @DeckSize2 = COUNT(1) FROM ##Deck2 WHERE GameNr = @GameNr

    WHILE @DeckSize1 > 0 AND @DeckSize2 > 0 AND @DuplicateGameState = 0
    BEGIN

        SELECT TOP (1) @NextCard1 = Nr FROM ##Deck1 WHERE GameNr = @GameNr ORDER BY ID
        SELECT TOP (1) @NextCard2 = Nr FROM ##Deck2 WHERE GameNr = @GameNr ORDER BY ID

        DELETE FROM ##Deck1 WHERE Nr = @NextCard1 AND GameNr = @GameNr
        DELETE FROM ##Deck2 WHERE Nr = @NextCard2 AND GameNr = @GameNr

        IF @NextCard1 <= @DeckSize1 - 1 AND @NextCard2 <= @DeckSize2 - 1
        -- We go into recursive combat
        BEGIN
            IF @Debug = 1 PRINT 'Recursive combat'

            INSERT ##Deck1 (Nr, GameNr)
            SELECT TOP (@NextCard1) Nr, @GameNr + 1 FROM ##Deck1 WHERE GameNr = @GameNr ORDER BY ID
            INSERT ##Deck2 (Nr, GameNr)
            SELECT TOP (@NextCard2) Nr, @GameNr + 1 FROM ##Deck2 WHERE GameNr = @GameNr ORDER BY ID

            SET @NextGameNr = @GameNr + 1
            EXEC @RecursiveGameWinner = dbo.RecursiveWar @NextGameNr

            -- Cleanup recursive game
            DELETE FROM ##Deck1 WHERE GameNr = @GameNr + 1
            DELETE FROM ##Deck2 WHERE GameNr = @GameNr + 1

            IF @RecursiveGameWinner = 1
            BEGIN
                INSERT ##Deck1 (Nr, GameNr) VALUES (@NextCard1, @GameNr),(@NextCard2, @GameNr)
                SET @DeckSize1 = @DeckSize1 + 1
                SET @DeckSize2 = @DeckSize2 - 1
            END
            ELSE
            BEGIN
                INSERT ##Deck2 (Nr, GameNr) VALUES (@NextCard2, @GameNr),(@NextCard1, @GameNr)
                SET @DeckSize1 = @DeckSize1 - 1
                SET @DeckSize2 = @DeckSize2 + 1
            END

        END
        ELSE
        BEGIN
        -- Regular combat
            IF @Debug = 1 PRINT 'Regular combat'

            IF @NextCard1 > @NextCard2
            BEGIN
                INSERT ##Deck1 (Nr, GameNr) VALUES (@NextCard1, @GameNr),(@NextCard2, @GameNr)
                SET @DeckSize1 = @DeckSize1 + 1
                SET @DeckSize2 = @DeckSize2 - 1
            END
            ELSE 
            BEGIN
                INSERT ##Deck2 (Nr, GameNr) VALUES (@NextCard2, @GameNr),(@NextCard1, @GameNr)
                SET @DeckSize1 = @DeckSize1 - 1
                SET @DeckSize2 = @DeckSize2 + 1
            END

        END
    
        --Check for duplicate game state
        SET @GameState = '1||'
        SELECT @GameState = @GameState  + CAST(Nr AS VARCHAR(3)) + '|' FROM ##Deck1 WHERE GameNr = @GameNr ORDER BY ID 
        SET @GameState = @GameState + '|2||'
        SELECT @GameState = @GameState  + CAST(Nr AS VARCHAR(3)) + '|' FROM ##Deck2 WHERE GameNr = @GameNr ORDER BY ID 

        IF EXISTS(SELECT 1 FROM ##GameStates WHERE GameNr = @GameNr AND GameState = @GameState)
        BEGIN
            SET @DuplicateGameState = 1
        END
        ELSE
        BEGIN
            INSERT ##GameStates (GameNr, GameState) VALUES (@GameNr, @GameState)

            IF @Debug = 1 PRINT @GameState
        END

    END

    IF @DeckSize1 = 0 PRINT 'Player 2 wins game ' + CAST(@GameNr AS VARCHAR(10)) + ' because empty deck'
    IF @DeckSize2 = 0 PRINT 'Player 1 wins game ' + CAST(@GameNr AS VARCHAR(10)) + ' because empty deck'
    IF @DuplicateGameState = 1 PRINT 'Player 1 wins game ' + CAST(@GameNr AS VARCHAR(10)) + ' because of duplicate gamestate'
    
    --Cleanup Gamestates
    DELETE FROM ##GameStates WHERE GameNr = @GameNr

    IF @DeckSize1 = 0 RETURN 2
    ELSE RETURN 1

END



*/