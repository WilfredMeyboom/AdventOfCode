USE Test_WME

SET NOCOUNT ON

DECLARE @year VARCHAR(4) = '2021'
DECLARE @day VARCHAR(2)  = '21'

IF EXISTS (SELECT * FROM tempdb.sys.tables WHERE name = '##Input') DROP TABLE ##Input
CREATE TABLE ##Input (Line NVARCHAR(MAX) NULL);

IF EXISTS (SELECT * FROM tempdb.sys.tables WHERE name = '##InputNumbered') DROP TABLE ##InputNumbered
CREATE TABLE ##InputNumbered (Ind INT NOT NULL, Line NVARCHAR(MAX) NULL);

IF EXISTS (SELECT * FROM tempdb.sys.tables WHERE name = '##InputGrid') DROP TABLE ##InputGrid
CREATE TABLE ##InputGrid (Ind INT IDENTITY(1,1), RowNr INT, ColNr INT, Val CHAR);

IF EXISTS (SELECT * FROM tempdb.sys.tables WHERE name = '##InputInts') DROP TABLE ##InputInts
CREATE TABLE ##InputInts (Ind INT NOT NULL, Val BIGINT);

IF EXISTS (SELECT * FROM tempdb.sys.tables WHERE name = '##InputSplit') DROP TABLE ##InputSplit
CREATE TABLE ##InputSplit (Ind INT IDENTITY(1,1), RowNr INT, PieceNr INT, Piece VARCHAR(MAX));

IF EXISTS (SELECT * FROM tempdb.sys.tables WHERE name = '##InputSplitCust') DROP TABLE ##InputSplitCust
CREATE TABLE ##InputSplitCust (Ind INT IDENTITY(1,1), RowNr INT, PieceNr INT, Piece VARCHAR(MAX));

EXEC dbo.GetInput @year = @year, @day = @day
EXEC dbo.ParseInput @year = @year, @day = @day, @SplitCustom = '= .,'

--SELECT * FROM ##InputNumbered
--SELECT TOP 10 * FROM ##InputGrid
--SELECT TOP 10 * FROM ##InputInts
--SELECT * FROM ##InputSplit
--SELECT TOP 10 * FROM ##InputSplitCust

DECLARE @P1Start BIGINT = 7
DECLARE @P2Start BIGINT = 9


DECLARE @P1Score BIGINT = 0
DECLARE @P2Score BIGINT = 0

DECLARE @Dice INT = 1
DECLARE @Counter INT = 0
DECLARE @Turn INT = 1

WHILE @P1Score < 1000 AND @P2Score < 1000
BEGIN

IF @Turn = 1
BEGIN
    SET @P1Start = (@P1Start + (@Dice * 3 + 3))%10
    SET @P1Score = @P1Score + CASE WHEN @P1Start = 0 THEN 10 ELSE @P1Start END

    SET @Dice = (@Dice + 3)%100

    SET @Turn = 2
    SET @Counter = @Counter + 3
END
ELSE
BEGIN

    SET @P2Start = (@P2Start + (@Dice * 3 + 3))%10
    SET @P2Score = @P2Score + CASE WHEN @P2Start = 0 THEN 10 ELSE @P2Start END

    SET @Dice = (@Dice + 3)%100

    SET @Turn = 1
    SET @Counter = @Counter + 3
END

END

PRINT @P1Score
PRINT @P2Score
PRINT @Dice
PRINT @P1Start
PRINT @P2Start

SELECT @P1Score * @Counter, @P2Score * @Counter

CREATE TABLE ##Rolls (Ind INT, Val INT, Freq INT)
INSERT ##Rolls (Ind, Val, Freq) VALUES (1,3,1),(2,4,3),(3,5,6),(4,6,7),(5,7,6),(6,8,3),(7,9,1)


CREATE TABLE ##GameStates (Turn INT, P1Pos INT, P2Pos INT, P1Score INT, P2Score INT, Wins1 BIGINT, Wins2 BIGINT UNIQUE(Turn, P1Pos, P2Pos, P1Score, P2Score))


DECLARE @Wins1 BIGINT = 0
DECLARE @Wins2 BIGINT = 0

EXEC dbo.GetGameWins 1, 7, 9, 0, 0, @Wins1 OUTPUT, @Wins2 OUTPUT

SELECT @Wins1, @Wins2

--433315766324816 is correct for part 1



DROP TABLE ##GameStates
DROP TABLE ##Rolls

--301868455617 is too low
--1315256406129 is too low


GO

CREATE OR ALTER PROCEDURE GetGameWins 
    @Turn INT,
    @P1Pos INT,
    @P2Pos INT,
    @P1Score INT,
    @P2Score INT,
    @Wins1 BIGINT OUTPUT,
    @Wins2 BIGINT OUTPUT

AS
BEGIN
    DECLARE @Target INT = 21

    IF @P1Score >= @Target
    BEGIN
        SET @Wins1 = 1
        SET @Wins2 = 0
        RETURN
    END
    IF @P2Score >= @Target
    BEGIN
        SET @Wins1 = 0
        SET @Wins2 = 1
        RETURN
    END
    
    IF EXISTS (SELECT 1 FROM ##GameStates GS WHERE @P1Pos = GS.P1Pos AND @P1Score = GS.P1Score AND @P2Pos = GS.P2Pos AND @P2Score = GS.P2Score AND @Turn = GS.Turn)
    BEGIN
        SELECT @Wins1 = Wins1, @Wins2 = Wins2 FROM ##GameStates GS WHERE @P1Pos = GS.P1Pos AND @P1Score = GS.P1Score AND @P2Pos = GS.P2Pos AND @P2Score = GS.P2Score AND @Turn = GS.Turn
        RETURN
    END

    DECLARE @Counter INT = 1
    DECLARE @Val INT
    DECLARE @Freq INT
    DECLARE @NewP1Pos INT
    DECLARE @NewP2Pos INT
    DECLARE @NewP1Score INT = 0
    DECLARE @NewP2Score INT = 0
    DECLARE @NewTurn INT
    DECLARE @NewWins1 BIGINT = 0
    DECLARE @NewWins2 BIGINT = 0

    WHILE @Counter <= 7
    BEGIN

        SELECT @Val = Val, @Freq = Freq
        FROM ##Rolls R
        WHERE Ind = @Counter

        SET @NewWins1=0
        SET @NewWins2=0
        
        IF @Turn = 1 
        BEGIN
            SET @NewP1Pos = ((@P1Pos + @Val -1) % 10) + 1 
            SET @NewP1Score = @P1Score + @NewP1Pos
            SET @NewTurn = 2

            EXEC GetGameWins @NewTurn, @NewP1Pos, @P2Pos, @NewP1Score, @P2Score, @NewWins1 OUTPUT, @NewWins2 OUTPUT
        END
        ELSE
        BEGIN
            SET @NewP2Pos = ((@P2Pos + @Val -1) % 10) + 1 
            SET @NewP2Score = @P2Score + @NewP2Pos
            SET @NewTurn = 1

            EXEC GetGameWins @NewTurn, @P1Pos, @NewP2Pos, @P1Score, @NewP2Score, @NewWins1 OUTPUT, @NewWins2 OUTPUT
        END
        
        SET @Wins1 = @Wins1 + @Freq * @NewWins1
        SET @Wins2 = @Wins2 + @Freq * @NewWins2

        SET @Counter = @Counter + 1
    END

    INSERT ##GameStates
    (
        Turn,
        P1Pos,
        P1Score,
        P2Pos,
        P2Score,
        Wins1,
        Wins2
    )
    SELECT @Turn, @P1Pos, @P1Score, @P2Pos, @P2Score, @Wins1, @Wins2


END