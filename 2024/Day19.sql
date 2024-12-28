USE Test_WME

SET NOCOUNT ON

DECLARE @year VARCHAR(4) = '2024'
DECLARE @day VARCHAR(2)  = '19'

EXEC dbo.GetInput @year = @year, @day = @day
EXEC dbo.ParseInput @year = @year, @day = @day 

--SELECT TOP 10 * FROM ##Input
--SELECT TOP 10 * FROM ##InputInts
--SELECT TOP 10 * FROM ##InputNumbered
--SELECT TOP 10 * FROM ##InputGrid
--SELECT TOP 10 * FROM ##InputSplit
--SELECT TOP 10 * FROM ##InputSplitCust

CREATE TABLE ##Towels (ID INT IDENTITY(1,1), TowelNr INT, Towel VARCHAR(10))
INSERT ##Towels (TowelNr, Towel)
SELECT ROW_NUMBER() OVER (ORDER BY (SELECT 0)), Piece FROM ##InputSplit WHERE RowNr = 1 

CREATE TABLE ##Arrangements (ID INT IDENTITY(1,1), Arrangement VARCHAR(500), Possible INT, NrOfPossibilities BIGINT)
INSERT ##Arrangements (Arrangement)
SELECT Piece FROM ##InputSplit WHERE RowNr > 1 

CREATE TABLE ##Dictionary (ID INT IDENTITY(1,1), Arrangement VARCHAR(500), Possible BIGINT)

--SELECT * FROM ##Towels
--SELECT * FROM ##Arrangements

DECLARE @CurrentArrangement VARCHAR(500)
DECLARE @Output BIGINT

WHILE EXISTS (SELECT 1 FROM ##Arrangements WHERE Possible IS NULL)
BEGIN

    SELECT TOP(1) @CurrentArrangement = Arrangement FROM ##Arrangements WHERE Possible IS NULL

    EXEC dbo.spAnalyzeArrangement @CurrentArrangement, @Output OUTPUT

    UPDATE ##Arrangements
    SET Possible = @Output
    WHERE Arrangement = @CurrentArrangement
END

SELECT COUNT(1) AS Part1 FROM ##Arrangements WHERE Possible = 1

DELETE FROM ##Arrangements WHERE Possible = 0
DELETE FROM ##Dictionary

WHILE EXISTS (SELECT 1 FROM ##Arrangements WHERE NrOfPossibilities IS NULL)
BEGIN

    SELECT TOP(1) @CurrentArrangement = Arrangement FROM ##Arrangements WHERE NrOfPossibilities IS NULL

    EXEC dbo.spAnalyzeArrangement2 @CurrentArrangement, @Output OUTPUT

    UPDATE ##Arrangements
    SET NrOfPossibilities = @Output
    WHERE Arrangement = @CurrentArrangement
END

SELECT SUM(NrOfPossibilities) AS Part2 FROM ##Arrangements
--SELECT * FROM ##Arrangements
--SELECT * FROM ##Dictionary

DROP TABLE ##Dictionary
DROP TABLE ##Towels
DROP TABLE ##Arrangements

/*
GO
CREATE OR ALTER PROC dbo.spAnalyzeArrangement (@Arrangement VARCHAR(500), @Output INT OUTPUT)
AS 
BEGIN
    SET @Output = 0

    IF @Arrangement = ''
    BEGIN
        SET @Output = 1
        RETURN
    END

    IF EXISTS (SELECT 1 FROM ##Dictionary WHERE Arrangement = @Arrangement)
    BEGIN
         SELECT @Output = Possible FROM ##Dictionary WHERE Arrangement = @Arrangement
         RETURN
    END

    --PRINT @Arrangement

    DECLARE @TowelNr INT = 1
    DECLARE @TempArrangement VARCHAR(500)

    WHILE EXISTS (SELECT 1 FROM ##Towels WHERE TowelNr = @TowelNr) AND @Output = 0
    BEGIN
        
        IF EXISTS (SELECT 1 FROM ##Towels T WHERE T.TowelNr = @TowelNr AND @Arrangement LIKE T.Towel + '%')
        BEGIN
            SELECT @TempArrangement = RIGHT(@Arrangement, LEN(@Arrangement) - LEN(Towel)) FROM ##Towels T WHERE T.TowelNr = @TowelNr 
            EXEC dbo.spAnalyzeArrangement @TempArrangement, @Output OUTPUT

            IF NOT EXISTS (SELECT 1 FROM ##Dictionary WHERE Arrangement = @TempArrangement)
                INSERT ##Dictionary (Arrangement, Possible) SELECT @TempArrangement, @Output 
        END

        SET @TowelNr = @TowelNr + 1
    END

END



GO
CREATE OR ALTER PROC dbo.spAnalyzeArrangement2 (@Arrangement VARCHAR(500), @Output BIGINT OUTPUT)
AS 
BEGIN

    --PRINT @Arrangement

    SET @Output = 0
    DECLARE @TempOutput BIGINT = 0

    IF @Arrangement = ''
    BEGIN
        SET @Output = 1
        --PRINT 'Empty leftover string, returns 1'
        RETURN
    END

    IF EXISTS (SELECT 1 FROM ##Dictionary WHERE Arrangement = @Arrangement)
    BEGIN
         SELECT @Output = Possible FROM ##Dictionary WHERE Arrangement = @Arrangement
         --PRINT 'Present in dictionary: ' + CAST(@Output AS VARCHAR(10))
         RETURN
    END

    DECLARE @TowelNr INT = 1
    DECLARE @TempArrangement VARCHAR(500)

    WHILE EXISTS (SELECT 1 FROM ##Towels WHERE TowelNr = @TowelNr)
    BEGIN
        
        IF EXISTS (SELECT 1 FROM ##Towels T WHERE T.TowelNr = @TowelNr AND @Arrangement LIKE T.Towel + '%')
        BEGIN
            SELECT @TempArrangement = RIGHT(@Arrangement, LEN(@Arrangement) - LEN(Towel)) FROM ##Towels T WHERE T.TowelNr = @TowelNr 
            EXEC dbo.spAnalyzeArrangement2 @TempArrangement, @TempOutput OUTPUT

            IF NOT EXISTS (SELECT 1 FROM ##Dictionary WHERE Arrangement = @TempArrangement)
                INSERT ##Dictionary (Arrangement, Possible) SELECT @TempArrangement, @TempOutput
                
            SET @Output = @Output + @TempOutput
        END

        SET @TowelNr = @TowelNr + 1
    END

    --PRINT 'End of loop reached. Returning options: ' + CAST(@Output AS VARCHAR(10))

END

*/