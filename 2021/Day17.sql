USE Test_WME

SET NOCOUNT ON

DECLARE @year VARCHAR(4) = '2021'
DECLARE @day VARCHAR(2)  = '17'

EXEC dbo.GetInput @year = @year, @day = @day
EXEC dbo.ParseInput @year = @year, @day = @day, @SplitCustom = '= .,'

DECLARE @TargetYMin INT
DECLARE @TargetYMax INT

DECLARE @TargetXMin INT
DECLARE @TargetXMax INT

SELECT @TargetXMin = Piece FROM ##InputSplitCust WHERE PieceNr = 4
SELECT @TargetXMax = Piece FROM ##InputSplitCust WHERE PieceNr = 5

SELECT @TargetYMin = Piece FROM ##InputSplitCust WHERE PieceNr = 8
SELECT @TargetYMax = Piece FROM ##InputSplitCust WHERE PieceNr = 7

-- What goes up, must come down
-- Since x and y are independent of eachother we can look at just the motion on the y axis
-- Regardless of the initial y value. The probe will have the same speed (in the other direction) when it returns to the y = 0 axis
-- So for the maximum y velocity, the next step (after returning to y=0) should end up just inside the target area (= @TargetYMax)
-- Triangular numbers; the height = (n * (n-1)) / 2
SELECT (ABS(@TargetYMax) * (ABS(@TargetYMax) - 1)) / 2 

-- 3160 Is correct for part 1


DECLARE @vX INT = 1
DECLARE @vY INT = 1
DECLARE @y INT

DECLARE @CounterX INT = 0
DECLARE @CounterY INT = @TargetYMax
DECLARE @InTarget INT = 0
DECLARE @x INT
DECLARE @Solutions INT = 0

-- Try all x velocity values that range from 1 to just pass the target range
-- Combined with y velocity that range from the -TargetYMax to TargetYMax 
-- (due to part 1 we know the upperbound, the lowerbound follows naturally)
WHILE @CounterX <= @TargetXMax
BEGIN

    SET @CounterY = @TargetYMax

    WHILE @CounterY <= ABS(@TargetYMax)
    BEGIN
        
        SET @x = 0
        SET @y = 0

        SET @vx = @CounterX
        SET @vy = @CounterY

        SET @InTarget = 0

        -- If we're inside the target range stop searching
        -- Or if we've passed the target range stop searching
        WHILE @InTarget = 0 AND @y >= @TargetYMax
        BEGIN

            SET @x = @x + @vX
            SET @y = @y + @vY

            IF @vx > 0 SET @vx = @vx - 1
            SET @vy = @vy - 1

            IF @x BETWEEN @TargetXMin AND @TargetXMax
                AND @y BETWEEN @TargetYMax AND @TargetYMin SET @InTarget = 1

            -- PRINT CAST(@X AS VARCHAR(10)) + ',' + CAST(@y AS Varchar(10))

        END

        -- If we're inside the target range add it as a possible solution
        IF @InTarget = 1 SET @Solutions = @Solutions + 1

        SET @CounterY = @CounterY + 1

    END

    SET @CounterX = @CounterX + 1
END


--Possible y values 
SELECT @Solutions AS Part2

-- 1928 is correct for Part2

