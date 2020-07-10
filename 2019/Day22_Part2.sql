use Test_WME

--It is impossible to fully carry out the instructions on the new deck (the deck is too large and the instructions are to work intensive)
--But that is not necessary, we need the card in position 2020 at the end of the run. 
--  If we can track position 2020 backward to the start we can find the card in the original ordered deck
--  For this we need to translate the instructions to manipulations of a position in the deck
--  Then we can deduce a formula for calculating the previous position based on the current position (hoping it is linear)
--  And finally we can calculate over all iterations

SET NOCOUNT ON

CREATE TABLE #Input (Nr NVARCHAR(MAX));

BULK INSERT #Input
FROM 'C:\Source\AdventOfCode\2019\input22.txt'
WITH (ROWTERMINATOR = '0x0A');

--SELECT *,REPLACE(Nr, 'deal with increment ', '') FROM #Input

CREATE TABLE ##Instructions (ID INT IDENTITY(1,1), InstrType INT, InstrCount INT)

INSERT ##Instructions (InstrType, InstrCount)
SELECT CASE WHEN Nr LIKE 'deal with increment%' THEN 3
            WHEN Nr LIKE 'cut%' THEN 2
            WHEN Nr LIKE 'deal into new stack%' THEN 1
            END
,      REPLACE(REPLACE(REPLACE(Nr, 'deal with increment ', ''), 'deal into new stack', '0'), 'cut ', '')
FROM #Input

--SELECT * FROM ##Instructions

DECLARE @DeckSize NUMERIC(38,0)
SET @DeckSize = 119315717514047
--SET @DeckSize = 10007

DECLARE @NrOfShuffles NUMERIC(38,0) = 101741582076661

DECLARE @StartPoint NUMERIC(38,0)
SET @StartPoint = 2020
--SET @StartPoint = 3589 -- Use the result from part 1 as a test case. We should find 2019 as a result
DECLARE @Pos NUMERIC(38,0)
SET @Pos = @StartPoint
DECLARE @Stepsize NUMERIC(38,0) = 1  -- a 
DECLARE @Offset NUMERIC(38,0) = 0    -- b (in y = ax + b)
DECLARE @ID INT

DECLARE @InstrType INT
DECLARE @InstrCount INT

DECLARE InstrCursor CURSOR FOR SELECT ID, InstrType, InstrCount FROM ##Instructions ORDER BY ID DESC

OPEN InstrCursor
FETCH NEXT FROM InstrCursor INTO @ID, @InstrType, @InstrCount

WHILE @@FETCH_STATUS = 0
BEGIN

    --Test based on 2019
    --SELECT @ID, @Pos, ((@Stepsize * 3589) % @DeckSize + @Offset + @DeckSize) % @DeckSize, @Stepsize, @Offset, @InstrType, @InstrCount
    
    IF @InstrType = 1 
    BEGIN
        SET @Pos = ((@Decksize - @Pos - 1) + @Decksize) % @DeckSize
        SET @Stepsize = -1 * @Stepsize
        SET @Offset = -1 * @Offset + @DeckSize -1
    END

    IF @InstrType = 2 
    BEGIN
        SET @Pos = ((@Pos + @InstrCount) + @DeckSize) % @DeckSize
        SET @Offset = (@Offset + @InstrCount) % @DeckSize
    END

    IF @InstrType = 3 
    BEGIN
        SELECT @Pos = (dbo.InverseMod(@InstrCount, @DeckSize) * @Pos) % @DeckSize
        SELECT @Stepsize = (@Stepsize * dbo.InverseMod(@InstrCount, @DeckSize)) % @DeckSize,
               @Offset = (@Offset * dbo.InverseMod(@InstrCount, @DeckSize)) % @DeckSize
    END

    FETCH NEXT FROM InstrCursor INTO @ID, @InstrType, @InstrCount

END

CLOSE InstrCursor
DEALLOCATE InstrCursor

-- Check based on 2019 starting point
SELECT @ID, @Pos AS PrevPos, (@Stepsize * 3589) % @DeckSize + @Offset AS CalculationPrevPos, @Stepsize AS StepsizeOrA, @Offset AS OffsetOrB, @InstrType AS InstrType, @InstrCount AS InstrCount
--          ^                 ^Calculation of the position of the card before the run. Based on ax + b
--          L Actual position of the card before the run. Based on reversing every shuffle action

DROP TABLE #Input
DROP TABLE ##Instructions


/*
StepsizeOrA	
-15432842991580	

OffsetOrB
83455140491327

And now we need to do (StepSize * x + Offset)^NrOfShuffles

Credit to Jonathan Paulson
https://www.youtube.com/watch?v=U4AE92wnNYc

The formula can be rewritten:

*/

SELECT (@StartPoint * dbo.PowerWithMod(@StepSize, @NrOfShuffles, @DeckSize) + 
            (((dbo.PowerWithMod(@StepSize, @NrOfShuffles, @DeckSize)-1) * @Offset) % @DeckSize)
                * dbo.InverseMod(@Stepsize - 1, @DeckSize))
                    % @DeckSize

-- Mod calculation can be brought inside a multiplication

-- 4893716342290 is correct for part 2


/*
ALTER FUNCTION [dbo].[InverseMod] (@a NUMERIC(38,0), @m NUMERIC(38,0))
RETURNS NUMERIC(38,0)
BEGIN

    RETURN dbo.PowerWithMod (@a, @m-2, @m)
    
END

GO


ALTER FUNCTION [dbo].[PowerWithMod] (@x NUMERIC(38,0), @m NUMERIC(38,0), @mod NUMERIC(38,0))
RETURNS NUMERIC(38,0)
BEGIN

    DECLARE @r NUMERIC(38,0) = 1

    WHILE @m > 0
    BEGIN
        IF @m % 2 = 1 --odd number
        BEGIN
            SET @r = (@r * @x) % @mod
            SET @m = @m - 1
        END
        SET @m = @m / 2
        SET @x = (@x * @x) % @mod

    END

    RETURN @r
END

*/