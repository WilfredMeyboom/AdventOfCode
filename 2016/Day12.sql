use Test_WME

SET NOCOUNT ON

CREATE TABLE ##Input (Line NVARCHAR(MAX));

BULK INSERT ##Input
FROM 'D:\Wilfred\AdventOfCode\2016\input12.txt'
WITH (ROWTERMINATOR = '0x0A');

CREATE TABLE ##Instructions (ID INT IDENTITY(1,1), InstrNr INT, Instruction VARCHAR(5), Instr1 VARCHAR(5), Instr2 VARCHAR(5))

INSERT ##Instructions (InstrNr, Instruction, Instr1, Instr2)
SELECT  ROW_NUMBER() OVER (ORDER BY (SELECT 0))
,       LEFT(Line, 3) 
,       CASE WHEN LEFT(Line, 3) IN ('inc','dec') THEN SUBSTRING(Line, 5, LEN(Line)) ELSE LEFT(SUBSTRING(Line, 5, LEN(Line)), CHARINDEX(' ', SUBSTRING(Line, 5, LEN(Line)))) END
,       CASE WHEN LEFT(Line, 3) IN ('inc','dec') THEN NULL ELSE SUBSTRING(SUBSTRING(Line, 5, LEN(Line)), CHARINDEX(' ', SUBSTRING(Line, 5, LEN(Line)))+ 1, LEN(Line)) END
FROM ##Input


CREATE TABLE ##Registers (ID INT IDENTITY(1,1), RegName CHAR(1), RegValue INT)

INSERT ##Registers (RegName, RegValue) VALUES ('A', 0), ('B', 0), ('C', 1), ('D', 0)

DECLARE @Counter INT = 1
DECLARE @ProgramDone INT = 0

DECLARE @Instr VARCHAR(15)
DECLARE @Instr1 VARCHAR(15)
DECLARE @Instr2 VARCHAR(15)

WHILE @ProgramDone = 0
BEGIN

    SELECT @Instr = Instruction, @Instr1 = Instr1, @Instr2 = Instr2
    FROM ##Instructions
    WHERE InstrNr = @Counter

--    PRINT @Instr + ' ' + @Instr1 + ' ' + ISNULL(@Instr2, '-') + ' ' + CAST(@Counter AS VARCHAR(20))
    
    UPDATE ##Registers
    SET RegValue = RegValue + 1
    WHERE @Instr = 'inc' AND @Instr1 = RegName

    UPDATE ##Registers
    SET RegValue = RegValue - 1
    WHERE @Instr = 'dec' AND @Instr1 = RegName

    SELECT @Instr1 = RegValue
    FROM ##Registers 
    WHERE @Instr1 = RegName

    UPDATE ##Registers
    SET RegValue = CAST(@Instr1 AS INT)
    WHERE @Instr = 'cpy' AND RegName = @Instr2

    SELECT @Counter = @Counter + CAST(@Instr2 AS INT) - 1 --Correct for future increment
    WHERE @Instr = 'jnz' AND @Instr1 <> 0
    
    SET @Counter = @Counter + 1
    IF NOT EXISTS (SELECT 1 FROM ##Instructions WHERE InstrNr = @Counter) SET @ProgramDone = 1

 --   SELECT @Counter, * FROM ##Registers

END

SELECT * FROM ##Registers

/*

DROP TABLE ##Input
DROP TABLE ##Instructions
DROP TABLE ##Registers

*/

--> 317933 is goed
