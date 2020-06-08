USE Test_WME
GO

SET NOCOUNT ON
SET NOCOUNT ON

DECLARE @ProgramFile VARCHAR(250) = 'C:\Source\AdventOfCode\2019\input11.txt'

CREATE TABLE ##Pointers (OpCodeCompNr BIGINT, Pointer BIGINT, RelativeBase BIGINT)

DECLARE @Output BIGINT = 0

INSERT ##Pointers (OpCodeCompNr, Pointer, RelativeBase) VALUES (0, 0, 0)


------------------- IntComp loaded

CREATE TABLE ##Painting (ID INT IDENTITY(1,1), x INT, y INT, Color INT, PaintedOnce INT)

DECLARE @Counter INT = 0
DECLARE @Input BIGINT = 0 -- Part 1: start over a black square
SET     @Input        = 1 -- Part 2: start over a white square
DECLARE @CurrentID INT
DECLARE @x INT = 0
DECLARE @y INT = 0
DECLARE @Dir INT = 0

INSERT ##Painting (x, y, Color) SELECT @x, @y, 0
SET @CurrentID = @@IDENTITY

--DECLARE @DebugCounter INT = 0

WHILE @Output <> 99 --AND @DebugCounter < 20
BEGIN
    EXEC IntCodeComp @ProgramFile, 0, @Input, @Output OUTPUT
     
--    PRINT 'Output: ' + CAST(@Output AS VARCHAR(50))
    
    IF @Counter = 0 
    BEGIN
        UPDATE ##Painting
        SET Color = @Output
        WHERE ID = @CurrentID

        IF @Output = 1
            UPDATE ##Painting
            SET PaintedOnce = 1
            WHERE ID = @CurrentID

    END

    IF @Counter = 1 
    BEGIN
        SELECT @Dir = @Dir + CASE WHEN @Output = 0 THEN -90 ELSE 90 END
        IF @Dir = -90 SET @Dir = 270
        IF @Dir = 360 SET @Dir = 0

        IF @Dir = 0 SET @y = @y + 1
        IF @Dir = 180 SET @y = @y - 1
        IF @Dir = 90 SET @x = @x + 1
        IF @Dir = 270 SET @x = @x - 1

        IF EXISTS (SELECT 1 FROM ##Painting WHERE x = @x AND y = @y)
            SELECT @Input = Color
            ,      @CurrentID = ID
            FROM ##Painting
            WHERE x = @x AND y = @y
            ORDER BY ID DESC
        ELSE
        BEGIN
            INSERT ##Painting (x, y, Color, PaintedOnce) SELECT @x, @y, 0, 0
            SET @CurrentID = @@IDENTITY
            SET @Input = 0
        END

        --PRINT 'x: ' + CAST(@x AS VARCHAR(5)) + ', y: ' + CAST(@y AS VARCHAR(5))

    END

    SET @Counter = (@Counter + 1) % 2

    --SET @DebugCounter = @DebugCounter + 1
END

--SELECT * FROM ##Pointers
--SELECT * FROM OpCodes

DROP TABLE Opcodes
DROP TABLE ##Pointers

SELECT x,y FROM ##Painting WHERE PaintedOnce = 1

-- 2045 is too high for part 1
-- 2000 is too high for part 1
-- 1897 is too high for part 1
-- 1800 is incorrect for part 1
-- 1883 is correct for part 1


DELETE FROM ##Painting WHERE Color NOT IN (0,1)



--DECLARE @X INT
--DECLARE @Y INT
DECLARE @MinX INT
DECLARE @MaxX INT
DECLARE @MinY INT
DECLARE @Str NVARCHAR(MAX) = ''

SELECT @X = MIN(X), @Y = MAX(Y), @MaxX = MAX(X), @MinY = MIN(Y) FROM ##Painting
SET @MinX = @X

WHILE (@Y >= @MinY)
BEGIN

    SET @Str = ''

    WHILE (@X <= @MaxX)
    BEGIN

        IF NOT EXISTS (SELECT 1 FROM ##Painting WHERE X = @X AND Y = @Y) INSERT ##Painting (x, y, Color) VALUES (@X, @Y, 0)
    
        SELECT @Str = @Str + (CASE WHEN G.color = 1 THEN 'XX' ELSE '  ' END)
        FROM ##Painting G
        WHERE G.X = @X AND G.Y = @Y

        SET @X = @X + 1

    END

    PRINT @Str

    SET @Y = @Y - 1
    SET @X = @MinX
END





--DROP TABLE ##Painting
--DROP TABLE ##Grid

/*

Same OpcodeComp as in Day9

*/