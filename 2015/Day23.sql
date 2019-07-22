use Test_WME

SET NOCOUNT ON

CREATE TABLE ##Input (Line NVARCHAR(MAX));

BULK INSERT ##Input
FROM 'D:\Wilfred\AdventOfCode\2015\input23.txt'
WITH (ROWTERMINATOR = '0x0A');

CREATE TABLE ##Register (ID BIGINT IDENTITY(1,1), RegName CHAR, RegValue BIGINT)
INSERT ##Register (RegName, RegValue) VALUES ('a', 1), ('b',0)

CREATE TABLE ##Instructions (ID BIGINT IDENTITY(1,1), InstrNr BIGINT, Instr CHAR(3), InstrReg VARCHAR(3), InstrCount VARCHAR(3))

INSERT ##Instructions(InstrNr, Instr, InstrReg, InstrCount)
SELECT ROW_NUMBER() OVER (ORDER BY (SELECT 0))
,      LEFT(Line, 3) AS Instr
,      LTRIM(RTRIM(CASE WHEN CHARINDEX(',', Line) > 0
            THEN SUBSTRING(Line, 4, CHARINDEX(',', Line) - 4) 
            ELSE SUBSTRING(Line, 4, LEN(Line))
            END)) AS Reg
,      LTRIM(RTRIM(CASE WHEN CHARINDEX(',', Line) > 0
            THEN SUBSTRING(Line, CHARINDEX(',', Line) + 1, LEN(Line)) 
            ELSE NULL
            END)) AS InstrCount
--,* 
FROM ##Input


DECLARE @InstrPointer BIGINT = 1
DECLARE @MaxInstr BIGINT

SELECT @MaxInstr = MAX(InstrNr) FROM ##Instructions

DECLARE @Instr CHAR(3)
DECLARE @InstrReg VARCHAR(3)
DECLARE @InstrCount VARCHAR(3)

DECLARE @Counter BIGINT = 0

WHILE @InstrPointer > 0 AND @InstrPointer <= @MaxInstr
BEGIN

    SELECT @Instr = Instr
    ,      @InstrReg = InstrReg
    ,      @InstrCount = InstrCount
    FROM ##Instructions
    WHERE InstrNr = @InstrPointer

    UPDATE ##Register
    SET RegValue = CASE WHEN @Instr = 'hlf' THEN RegValue / 2
                        WHEN @Instr = 'tpl' THEN RegValue * 3
                        WHEN @Instr = 'inc' THEN RegValue + 1
                        ELSE RegValue END
    ,   @InstrPointer = CASE WHEN (@Instr = 'jie' AND RegValue % 2 = 0)
                               OR (@Instr = 'jio' AND RegValue = 1)
                             THEN @InstrPointer + @InstrCount - 1
                             ELSE @InstrPointer END
    WHERE RegName = @InstrReg

    IF @Instr = 'jmp' SET @InstrPointer = @InstrPointer + @InstrReg - 1

    SET @InstrPointer = @InstrPointer + 1

    SET @Counter = @Counter + 1

    IF @Counter % 100 = 0 PRINT CAST(@Counter AS VARCHAR(10)) + ' ' + @Instr + ' ' + @InstrReg + ' ' + ISNULL(@InstrCount, '')

    --SELECT @Counter, @InstrPointer, @Instr, @InstrReg, @InstrCount, RegName, RegValue FROM ##Register

END


SELECT * FROM ##Register
SELECT * FROM ##Instructions

--271148293 is too high for part 1
--4591 is too high for part 1
--170 is correct for part 1
--247 is correct for part 2

/*

DROP TABLE ##Input
DROP TABLE ##Register
DROP TABLE ##Instructions

    hlf r sets register r to half its current value, then continues with the next instruction.
    tpl r sets register r to triple its current value, then continues with the next instruction.
    inc r increments register r, adding 1 to it, then continues with the next instruction.
    jmp offset is a jump; it continues with the instruction offset away relative to itself.
    jie r, offset is like jmp, but only jumps if register r is even ("jump if even").
    jio r, offset is like jmp, but only jumps if register r is 1 ("jump if one", not odd).


*/



