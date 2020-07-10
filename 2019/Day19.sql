USE Test_WME
GO

SET NOCOUNT ON

DECLARE @ProgramFile VARCHAR(250) = 'C:\Source\AdventOfCode\2019\input19.txt'

CREATE TABLE ##Pointers (OpCodeCompNr BIGINT, Pointer BIGINT, RelativeBase BIGINT)

DECLARE @Output BIGINT = 0

INSERT ##Pointers (OpCodeCompNr, Pointer, RelativeBase) VALUES (0, 0, 0)

-- PROCEDURE [dbo].[IntCodeComp] (@ProgramFile VARCHAR(250)
--								, @OpCodeCompNr INT
--								, @Input BIGINT
--								, @Output BIGINT OUTPUT)

------------------- IntComp loaded

DECLARE @SkipPart1 INT = 1

IF @SkipPart1 = 0 
BEGIN

CREATE TABLE ##Grid (ID INT IDENTITY(1,1), x INT, y INT, val INT)

;WITH cte_Numbers AS (
    SELECT TOP 50 ROW_NUMBER() OVER (ORDER BY (SELECT 0)) - 1 nr FROM sys.messages
)
INSERT ##Grid (x, y)
SELECT Nr1.nr, Nr2.nr
FROM cte_Numbers Nr1
CROSS APPLY cte_Numbers Nr2

DECLARE @x INT = 0
DECLARE @y INT = 0

WHILE @y < 50
BEGIN
    
    SET @x = 0

    WHILE @x < 50
    BEGIN

        -- Reset the OpcodeComp
        UPDATE ##Pointers SET Pointer = 0, RelativeBase = 0
        DROP TABLE OpCodes
        
        EXEC IntCodeComp @ProgramFile, 0, @x, @Output OUTPUT

        IF @Output <> -99999 Print 'Output different than expected: ' + CAST(@Output AS VARCHAR(50))

        EXEC IntCodeComp @ProgramFile, 0, @y, @Output OUTPUT

        IF @Output <> -99999 Print 'Output different than expected: ' + CAST(@Output AS VARCHAR(50))

        EXEC IntCodeComp @ProgramFile, 0, -1 /*Dummy*/, @Output OUTPUT

        UPDATE ##Grid SET val = @Output WHERE x = @x And y = @y

        SET @x = @x + 1

    END

    SET @y = @y + 1
END


SELECT * FROM ##Grid
SELECT COUNT(1) FROM ##Grid WHERE val = 1

-- 220 is correct for part 1

END -- End of part 1

/*

DROP TABLE ##Grid
DROP TABLE ##Pointers

*/

/*
--Visualization
DECLARE @x INT = 0
DECLARE @y INT = 0
DECLARE @MinX INT
DECLARE @MaxX INT
DECLARE @MaxY INT
DECLARE @Str NVARCHAR(MAX) = ''

SELECT @X = MIN(X), @Y = MIN(Y), @MaxX = MAX(X), @MaxY = MAX(Y) FROM ##Grid
SET @MinX = @X

WHILE (@Y <= @MaxY)
BEGIN

    SET @Str = ''

    WHILE (@X <= @MaxX)
    BEGIN
    
        SELECT @Str = @Str + (CASE WHEN G.val = 1 THEN '#' ELSE '.' END)
        FROM ##Grid G
        WHERE G.X = @X AND G.Y = @Y

        SET @X = @X + 1

    END

    PRINT @Str

    SET @Y = @Y + 1
    SET @X = @MinX
END
*/


DECLARE @SquareFound INT = 0

--Set a starting point
SET @x = 150
SET @y = 150

-- Checking these points;
-- 150,150 = 0
-- 200,150 = 1
-- 250,150 = 0

DECLARE @StoredX INT = 150
DECLARE @TopRightX INT
DECLARE @TopRightY INT
DECLARE @TopLeftX INT
DECLARE @TopLeftY INT
DECLARE @BottomRightX INT
DECLARE @BottomRightY INT

WHILE @SquareFound = 0
BEGIN

    SET @x = @StoredX - 1
    SET @y = @y + 1

    SET @Output = 0 

    -- Move the active point to the right until we find the tractor beam
    WHILE @Output <> 1
    BEGIN 

        SET @x = @x + 1

        -- Reset the OpcodeComp
        UPDATE ##Pointers SET Pointer = 0, RelativeBase = 0
        DROP TABLE OpCodes
        
        EXEC IntCodeComp @ProgramFile, 0, @x, @Output OUTPUT
        EXEC IntCodeComp @ProgramFile, 0, @y, @Output OUTPUT
        EXEC IntCodeComp @ProgramFile, 0, -1 /*Dummy*/, @Output OUTPUT

    END

    SET @StoredX = @x - 1 -- Store this x value for the next iteration so we don't need to do loads of useless checks

    --PRINT 'On line ' + CAST(@y AS VARCHAR(5)) + ' start of beam found at ' + CAST(@x AS VARCHAR(5))

    --The active point should be the lower left corner
    --Based on that, check if the top right corner has a tractor
    SET @TopRightX = @x + 99
    SET @TopRightY = @y - 99

    -- Reset the OpcodeComp
    UPDATE ##Pointers SET Pointer = 0, RelativeBase = 0
    DROP TABLE OpCodes
        
    EXEC IntCodeComp @ProgramFile, 0, @TopRightX, @Output OUTPUT
    EXEC IntCodeComp @ProgramFile, 0, @TopRightY, @Output OUTPUT
    EXEC IntCodeComp @ProgramFile, 0, -1 /*Dummy*/, @Output OUTPUT

    IF @Output = 1
    BEGIN
        --Two points found, lets try the lower right corner
        SET @BottomRightX = @x + 99
        SET @BottomRightY = @y

        -- Reset the OpcodeComp
        UPDATE ##Pointers SET Pointer = 0, RelativeBase = 0
        DROP TABLE OpCodes
        
        EXEC IntCodeComp @ProgramFile, 0, @BottomRightX, @Output OUTPUT
        EXEC IntCodeComp @ProgramFile, 0, @BottomRightY, @Output OUTPUT
        EXEC IntCodeComp @ProgramFile, 0, -1 /*Dummy*/, @Output OUTPUT

        IF @Output = 1
        BEGIN
            --Two points found, lets try the lower right corner
            SET @TopLeftX = @x
            SET @TopLeftY = @y - 99

            -- Reset the OpcodeComp
            UPDATE ##Pointers SET Pointer = 0, RelativeBase = 0
            DROP TABLE OpCodes
            
            EXEC IntCodeComp @ProgramFile, 0, @TopLeftX, @Output OUTPUT
            EXEC IntCodeComp @ProgramFile, 0, @TopLeftY, @Output OUTPUT
            EXEC IntCodeComp @ProgramFile, 0, -1 /*Dummy*/, @Output OUTPUT
            
            IF @Output = 1 SET @SquareFound = 1
        END
        ELSE
        BEGIN
            PRINT 'Point not at ' + CAST(@x AS VARCHAR(5)) + ',' + CAST(@y AS VARCHAR(5))
        END
    
    END
    ELSE
    BEGIN
        PRINT 'Point not at ' + CAST(@x AS VARCHAR(5)) + ',' + CAST(@y AS VARCHAR(5))
    END

END

SELECT @TopLeftX, @TopLeftY, @TopLeftX * 10000 + @TopLeftY

DROP TABLE ##Pointers


