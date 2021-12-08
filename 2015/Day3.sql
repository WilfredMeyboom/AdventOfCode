
USE Test_WME

SET NOCOUNT ON

DECLARE @year VARCHAR(4) = '2015'
DECLARE @day VARCHAR(2)  = '3'

EXEC dbo.GetInput @year = @year, @day = @day
EXEC dbo.ParseInput @year = @year, @day = @day 

--SELECT TOP 10 * FROM ##InputNumbered
--SELECT TOP 10 * FROM ##InputGrid
--SELECT TOP 10 * FROM ##InputInts
--SELECT TOP 10 * FROM ##InputSplit
--SELECT TOP 10 * FROM ##InputSplitCust


DECLARE @Instr CHAR
DECLARE @PosX INT = 0
DECLARE @PosY INT = 0

CREATE TABLE ##Map (ID INT IDENTITY(1,1), X INT, Y INT)

INSERT ##Map (X,Y) VALUES (0,0)

CREATE UNIQUE INDEX UQ_Map ON ##Map (X, Y)

DECLARE MoveCursor CURSOR FOR 
SELECT Val FROM ##InputGrid ORDER BY RowNr, ColNr

OPEN MoveCursor

FETCH NEXT FROM MoveCursor INTO @Instr

WHILE @@FETCH_STATUS = 0
BEGIN

    IF @Instr = '^' SET @PosY = @PosY - 1
    IF @Instr = 'v' SET @PosY = @PosY + 1
    IF @Instr = '<' SET @PosX = @PosX - 1
    IF @Instr = '>' SET @PosX = @PosX + 1
    
    IF NOT EXISTS (SELECT 1 FROM ##Map WHERE X = @PosX AND Y = @PosY)
        INSERT ##Map (X, Y) SELECT @PosX, @PosY

    --PRINT 'X: ' + CAST(@PosX AS VARCHAR(3)) + ' ' + 'Y: ' + CAST(@PosY AS VARCHAR(3)) + ' ' + @Instr

    FETCH NEXT FROM MoveCursor INTO @Instr

END


CLOSE MoveCursor
DEALLOCATE MoveCursor

SELECT COUNT(1) AS Part1 FROM ##Map

--2572 is correct for part 1

DELETE FROM ##Map
SET @PosX = 0
SET @PosY = 0

DECLARE @PosX2 INT = 0
DECLARE @PosY2 INT = 0

DECLARE MoveCursor CURSOR FOR 
SELECT Val FROM ##InputGrid ORDER BY RowNr, ColNr

OPEN MoveCursor

FETCH NEXT FROM MoveCursor INTO @Instr

WHILE @@FETCH_STATUS = 0
BEGIN

    IF @Instr = '^' SET @PosY = @PosY - 1
    IF @Instr = 'v' SET @PosY = @PosY + 1
    IF @Instr = '<' SET @PosX = @PosX - 1
    IF @Instr = '>' SET @PosX = @PosX + 1
    
    IF NOT EXISTS (SELECT 1 FROM ##Map WHERE X = @PosX AND Y = @PosY)
        INSERT ##Map (X, Y) SELECT @PosX, @PosY

    --PRINT 'X: ' + CAST(@PosX AS VARCHAR(3)) + ' ' + 'Y: ' + CAST(@PosY AS VARCHAR(3)) + ' ' + @Instr

    FETCH NEXT FROM MoveCursor INTO @Instr

    IF @Instr = '^' SET @PosY2 = @PosY2 - 1
    IF @Instr = 'v' SET @PosY2 = @PosY2 + 1
    IF @Instr = '<' SET @PosX2 = @PosX2 - 1
    IF @Instr = '>' SET @PosX2 = @PosX2 + 1
    
    IF NOT EXISTS (SELECT 1 FROM ##Map WHERE X = @PosX2 AND Y = @PosY2)
        INSERT ##Map (X, Y) SELECT @PosX2, @PosY2

    --PRINT 'X: ' + CAST(@PosX AS VARCHAR(3)) + ' ' + 'Y: ' + CAST(@PosY AS VARCHAR(3)) + ' ' + @Instr

    FETCH NEXT FROM MoveCursor INTO @Instr


END

CLOSE MoveCursor
DEALLOCATE MoveCursor

SELECT COUNT(1) AS Part2 FROM ##Map

--2631 is correct for part 2

DROP TABLE ##Map

