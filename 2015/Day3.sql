use Test_WME

SET NOCOUNT ON

CREATE TABLE ##Input (Line NVARCHAR(MAX));

BULK INSERT ##Input
FROM 'D:\Wilfred\AdventOfCode\2015\input3.txt'
WITH (ROWTERMINATOR = '0x0A');


CREATE TABLE ##Instructions (ID INT IDENTITY(1,1), InstrNr INT, Instr CHAR)

;WITH cte_Instr AS (
    SELECT 1 AS InstrNr
    ,      LEFT(Line, 1) AS Instr
    ,      SUBSTRING(Line, 2, LEN(Line)) AS Remainder
    FROM ##Input
    UNION ALL
    SELECT InstrNr + 1
    ,      LEFT(Remainder, 1) AS Instr
    ,      SUBSTRING(Remainder, 2, LEN(Remainder)) AS Remainder
    FROM cte_Instr
    WHERE LEN(Remainder) > 0
)
INSERT ##Instructions (InstrNr, Instr)
SELECT InstrNr, Instr
FROM cte_Instr
OPTION (MAXRECURSION 10000)

--SELECT * FROM ##Instructions

DECLARE @Instr CHAR
DECLARE @PosX INT = 0
DECLARE @PosY INT = 0

CREATE TABLE ##Map (ID INT IDENTITY(1,1), X INT, Y INT)

INSERT ##Map (X,Y) VALUES (0,0)

CREATE UNIQUE INDEX UQ_Map ON ##Map (X, Y)

DECLARE MoveCursor CURSOR FOR 
SELECT Instr FROM ##Instructions ORDER BY InstrNr

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

    PRINT 'X: ' + CAST(@PosX AS VARCHAR(3)) + ' ' + 'Y: ' + CAST(@PosY AS VARCHAR(3)) + ' ' + @Instr

    FETCH NEXT FROM MoveCursor INTO @Instr

END


CLOSE MoveCursor
DEALLOCATE MoveCursor

SELECT * FROM ##Map

--2572 is correct for part 1

DELETE FROM ##Map
SET @PosX = 0
SET @PosY = 0

DECLARE @PosX2 INT = 0
DECLARE @PosY2 INT = 0

DECLARE MoveCursor CURSOR FOR 
SELECT Instr FROM ##Instructions ORDER BY InstrNr

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

SELECT * FROM ##Map

--2631 is correct for part 2

--SELECT * FROM ##Instructions
/*

DROP TABLE ##Map
DROP TABLE ##Instructions
DROP TABLE ##Input

*/