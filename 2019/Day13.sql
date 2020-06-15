USE Test_WME
GO

SET NOCOUNT ON

DECLARE @ProgramFile VARCHAR(250) = 'C:\Source\AdventOfCode\2019\input13.txt'

CREATE TABLE ##Pointers (OpCodeCompNr BIGINT, Pointer BIGINT, RelativeBase BIGINT)

DECLARE @Output BIGINT = 0

INSERT ##Pointers (OpCodeCompNr, Pointer, RelativeBase) VALUES (0, 0, 0)

------------------- IntComp loaded
DECLARE @SkipPart1 BIT = 1

CREATE TABLE ##Game(ID INT IDENTITY(1,1), x INT, y INT, val INT)
DECLARE @Counter INT = 0
DECLARE @CurrentID INT 
DECLARE @Input BIGINT = 0
DECLARE @Score BIGINT

DECLARE @x INT = 0
DECLARE @y INT = 0
DECLARE @Line VARCHAR(150)

IF @SkipPart1 = 0
BEGIN

WHILE @Output <> 99
BEGIN
    EXEC IntCodeComp @ProgramFile, 0, @Input, @Output OUTPUT
     
    --PRINT '-------------------------------------------------------------------------------->' + CAST(@Output AS VARCHAR(50))
    IF @Counter = 0 
    BEGIN
        INSERT ##Game(x) SELECT @Output
        SET @CurrentID = @@IDENTITY
    END

    IF @Counter = 1 UPDATE ##Game SET y = @Output WHERE ID = @CurrentID
    IF @Counter = 2 UPDATE ##Game SET val = @Output WHERE ID = @CurrentID

    SET @Counter = (@Counter + 1) % 3

--    SELECT @Output = 99 FROM ##Game WHERE x = -1 AND y = 0 AND Val = 0 -- Setup is complete
END

PRINT 'Setup complete'

SELECT * FROM ##Game WHERE Val = 2

END --SkipPart1
--268 is correct for part 1
----------------------------------------------------End of part 1

DECLARE @PaddleX INT = 21 --Known from part 1
SET @Counter = 0
SET @Output = 0

-- Reset OpcodeComp
DELETE FROM ##Game
--DROP TABLE Opcodes
CREATE TABLE ##GameHistory(ID INT, x INT, y INT, val INT)

SET @Output = 0
UPDATE ##Pointers SET OpCodeCompNr = 1, Pointer = 0, RelativeBase = 0

SET @ProgramFile = 'C:\Source\AdventOfCode\2019\input13_Part2.txt'

WHILE @Output <> 99
BEGIN
    EXEC IntCodeComp @ProgramFile, 1, @Input, @Output OUTPUT
     
    IF @Counter = 0 
    BEGIN
        INSERT ##Game(x) SELECT @Output
        SET @CurrentID = @@IDENTITY
    END

    IF @Counter = 1 UPDATE ##Game SET y = @Output WHERE ID = @CurrentID
    IF @Counter = 2 UPDATE ##Game SET val = @Output WHERE ID = @CurrentID

    SET @Counter = (@Counter + 1) % 3

    IF EXISTS (SELECT 1 FROM ##Game WHERE Val = 4)
    BEGIN

        IF EXISTS (SELECT 1 FROM ##Game WHERE x = -1 AND y = 0)
        BEGIN

            --SELECT * FROM ##Game

            SELECT @Score = Val FROM ##Game WHERE x = -1 AND y = 0
            
            PRINT 'Iteration done; Current score: ' + CAST(@Score AS VARCHAR(10)) + ' Timestamp: ' + CAST(GETDATE() AS VARCHAR(50))
        END

        SELECT @Input = CASE WHEN GB.x < @PaddleX THEN -1
                             WHEN GB.x > @PaddleX THEN 1
                             ELSE 0 END
        FROM ##Game GB
        WHERE GB.Val = 4

        SET @PaddleX = @PaddleX + @Input

        INSERT ##GameHistory (ID, x, y, val) SELECT ID, x, y, val FROM ##Game
        DELETE FROM ##Game

    END

END

-- 13989 is correct for part 2


--SELECT * FROM ##Pointers
--SELECT * FROM ##OpCodes

SELECT * FROM ##Game

/*
DECLARE @x INT = 0
DECLARE @y INT = 0
DECLARE @Line VARCHAR(150)

WHILE @y < 24
BEGIN
    SET @x = 0
    SET @Line = ''
    WHILE @x < 42
    BEGIN
        SELECT @Line = @Line + CASE WHEN Val = 1 THEN 'X' 
                                    WHEN Val = 2 THEN 'B'
                                    WHEN Val = 3 THEN '-'
                                    WHEN Val = 4 THEN '0'
                               ELSE ' ' END 
        FROM ##Game WHERE x = @x And y = @y

        SET @x = @x + 1
    END

    PRINT @Line
    SET @y = @y + 1
END
*/



--SELECT * FROM ##GameHistory WHERE val IN (3,4) ORDER BY val, ID

--DROP TABLE ##Game
--DROP TABLE ##GameHistory

DROP TABLE Opcodes
DROP TABLE ##Pointers



/*

OpcodeComp unchanged

*/

