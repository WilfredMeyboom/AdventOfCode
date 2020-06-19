USE Test_WME
GO

SET NOCOUNT ON

USE Test_WME
GO

SET NOCOUNT ON

DECLARE @ProgramFile VARCHAR(250) = 'C:\Source\AdventOfCode\2019\input15.txt'

CREATE TABLE ##Pointers (OpCodeCompNr BIGINT, Pointer BIGINT, RelativeBase BIGINT)

DECLARE @Output BIGINT = 0

INSERT ##Pointers (OpCodeCompNr, Pointer, RelativeBase) VALUES (0, 0, 0)

-- PROCEDURE [dbo].[IntCodeComp] (@ProgramFile VARCHAR(250)
--								, @OpCodeCompNr INT
--								, @Input BIGINT
--								, @Output BIGINT OUTPUT)

------------------- IntComp loaded

CREATE TABLE ##Grid (ID INT IDENTITY(1,1), x INT, y INT, NorthWall INT, EastWall INT, SouthWall INT, WestWall INT)
DECLARE @x INT = 0
DECLARE @y INT = 0
DECLARE @Dir INT = 4
DECLARE @MazeDone INT = 0
INSERT ##Grid (x, y) SELECT @x, @y

WHILE @Output <> -99 AND @MazeDone = 0
BEGIN    

    IF (@Dir = 1 AND (SELECT ISNULL(WestWall, 0) FROM ##Grid WHERE x = @x AND y = @y) <> 1)
    OR (@Dir = 2 AND (SELECT ISNULL(EastWall, 0) FROM ##Grid WHERE x = @x AND y = @y) <> 1)
    OR (@Dir = 3 AND (SELECT ISNULL(SouthWall, 0) FROM ##Grid WHERE x = @x AND y = @y) <> 1)
    OR (@Dir = 4 AND (SELECT ISNULL(NorthWall, 0) FROM ##Grid WHERE x = @x AND y = @y) <> 1)
    BEGIN
        -- Als links van je is leeg dan draai naar links en stap
        SELECT @Dir = CASE WHEN (@Dir = 1) THEN 3
                           WHEN (@Dir = 2) THEN 4
                           WHEN (@Dir = 3) THEN 2
                           WHEN (@Dir = 4) THEN 1 END
    END
    ELSE IF (@Dir = 1 AND (SELECT ISNULL(NorthWall, 0) FROM ##Grid WHERE x = @x AND y = @y) = 1)
         OR (@Dir = 2 AND (SELECT ISNULL(SouthWall, 0) FROM ##Grid WHERE x = @x AND y = @y) = 1)
         OR (@Dir = 3 AND (SELECT ISNULL(WestWall, 0) FROM ##Grid WHERE x = @x AND y = @y) = 1)
         OR (@Dir = 4 AND (SELECT ISNULL(EastWall, 0) FROM ##Grid WHERE x = @x AND y = @y) = 1)
         BEGIN
         -- Als voor je een muur staat dan draai naar rechts en stap
        SELECT @Dir = CASE WHEN (@Dir = 1) THEN 4
                           WHEN (@Dir = 2) THEN 3
                           WHEN (@Dir = 3) THEN 1
                           WHEN (@Dir = 4) THEN 2 END
         END
         --ELSE             
         -- Als voor je leeg is en links van je een muur dan stap vooruit
         -- So... do nothing

    EXEC IntCodeComp @ProgramFile, 0, @Dir, @Output OUTPUT

    PRINT 'Direction: ' + CAST(@Dir AS VARCHAR(1)) 
    PRINT 'Output: ' + CAST(@Output AS VARCHAR(4))

    IF @Output = 0
    BEGIN
        IF @Dir = 1 UPDATE ##Grid SET NorthWall = 1 WHERE @x = x AND @y = y
        IF @Dir = 2 UPDATE ##Grid SET SouthWall = 1 WHERE @x = x AND @y = y
        IF @Dir = 3 UPDATE ##Grid SET WestWall = 1 WHERE @x = x AND @y = y
        IF @Dir = 4 UPDATE ##Grid SET EastWall = 1 WHERE @x = x AND @y = y
    END
    
    IF @Output IN (1,2)
    BEGIN

        IF @Dir = 1 
        BEGIN
            UPDATE ##Grid SET NorthWall = 0 WHERE x = @x AND y = @y
            SET @y = @y + 1
            IF NOT EXISTS (SELECT 1 FROM ##Grid WHERE x = @x AND y = @Y)
                INSERT ##Grid (x, y, SouthWall) SELECT @x, @y, 0
        END

        IF @Dir = 2 
        BEGIN
            UPDATE ##Grid SET SouthWall = 0 WHERE x = @x AND y = @y
            SET @y = @y - 1
            IF NOT EXISTS (SELECT 1 FROM ##Grid WHERE x = @x AND y = @Y)
                INSERT ##Grid (x, y, NorthWall) SELECT @x, @y, 0
        END

        IF @Dir = 3 
        BEGIN
            UPDATE ##Grid SET WestWall = 0 WHERE x = @x AND y = @y
            SET @x = @x - 1
            IF NOT EXISTS (SELECT 1 FROM ##Grid WHERE x = @x AND y = @Y)
                INSERT ##Grid (x, y, EastWall) SELECT @x, @y, 0
        END

        IF @Dir = 4 
        BEGIN
            
            UPDATE ##Grid SET EastWall = 0 WHERE x = @x AND y = @y
            SET @x = @x + 1
            IF NOT EXISTS (SELECT 1 FROM ##Grid WHERE x = @x AND y = @Y)
                INSERT ##Grid (x, y, WestWall) SELECT @x, @y, 0

        END
        
    END

    IF @Output = 2 PRINT 'Oxygen repair system found at x = ' + CAST(@x AS VARCHAR(4)) + ', y = ' + CAST(@y AS VARCHAR(4))

    IF (SELECT COUNT(1) FROM ##Grid WHERE NorthWall IS NULL
                                       OR SouthWall IS NULL
                                       OR EastWall IS NULL
                                       OR WestWall IS NULL) = 0 SET @MazeDone = 1
END

-- Oxygen repair system found at x = 14, y = -14

--SELECT * FROM ##Pointers
--SELECT * FROM ##OpCodes

DROP TABLE Opcodes
DROP TABLE ##Pointers
--DROP TABLE ##Grid
SELECT * FROM ##Grid

CREATE TABLE ##Map (x INT, y INT, nrOfSteps INT)

--INSERT ##Map (x, y, nrOfSteps) VALUES (0,0,0) -- Part 1
INSERT ##Map (x, y, nrOfSteps) VALUES (14,-14,0)

WHILE (SELECT COUNT(1) FROM ##Map) < (SELECT COUNT(1) FROM ##Grid)
BEGIN

    INSERT ##Map(x, y, nrOfSteps)
    SELECT G.x, G.y, M.nrOfSteps + 1
    FROM ##Map M
    INNER JOIN ##Grid G ON (M.x = G.x + 1 AND M.y = G.y AND G.EastWall = 0)
                        OR (M.x = G.x - 1 AND M.y = G.y AND G.WestWall = 0)
                        OR (M.x = G.x AND M.y = G.y + 1 AND G.NorthWall = 0)
                        OR (M.x = G.x AND M.y = G.y - 1 AND G.SouthWall = 0)
    LEFT JOIN ##Map M2 ON M2.x = G.x AND M2.y = G.y
    WHERE M2.nrOfSteps IS NULL


END

--Part 1
SELECT * FROM ##Map WHERE x = 0 AND y = 0

-- 404 is correct for part 1

SELECT MAX(NrOfSteps) FROM ##Map 

-- 406 is correct for part 2

--DROP TABLE ##Map


/*

OpcodeComp is unchanged

*/