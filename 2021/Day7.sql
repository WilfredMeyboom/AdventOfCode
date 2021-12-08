USE Test_WME

SET NOCOUNT ON

DECLARE @year VARCHAR(4) = '2021'
DECLARE @day VARCHAR(2)  = '7'

EXEC dbo.GetInput @year = @year, @day = @day
EXEC dbo.ParseInput @year = @year, @day = @day 

--SELECT TOP 10 * FROM ##InputNumbered
--SELECT TOP 10 * FROM ##InputGrid
--SELECT TOP 10 * FROM ##InputInts
SELECT TOP 10 * FROM ##InputSplit
--SELECT TOP 10 * FROM ##InputSplitCust

--SELECT * FROM ##InputSplit

DECLARE @StartInd INT
DECLARE @EndInd INT

SELECT @StartInd = MIN(CAST(Piece AS INT)), @EndInd = MAX(CAST(Piece AS INT)) FROM ##InputSplit

DECLARE @Ind INT = @StartInd
DECLARE @FuelSpent BIGINT
DECLARE @MinFuelSpent BIGINT = NULL

WHILE @Ind <= @EndInd
BEGIN
    
    SELECT @FuelSpent = SUM(ABS(@Ind - CAST(Piece AS INT))) FROM ##InputSplit

    IF (@MinFuelspent > @FuelSpent OR @MinFuelSpent IS NULL)
    BEGIN
        SET @MinFuelSpent = @FuelSpent
    END

    SET @Ind = @Ind + 1

END

SELECT @MinFuelSpent AS Part1

--355989 is correct for part 1


SET @Ind  = @StartInd
SET @MinFuelSpent  = NULL

WHILE @Ind <= @EndInd
BEGIN
    
    SELECT @FuelSpent = SUM(
            (ABS(@Ind - CAST(Piece AS INT)) * (ABS(@Ind - CAST(Piece AS INT)) + 1))/2 --Triangular numbers formula
            )
    FROM ##InputSplit

    IF (@MinFuelspent > @FuelSpent OR @MinFuelSpent IS NULL)
    BEGIN
        SET @MinFuelSpent = @FuelSpent
    END

    SET @Ind = @Ind + 1

END

SELECT @MinFuelSpent AS Part2

--102245489 is correct part 2