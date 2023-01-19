use Test_WME

SET NOCOUNT ON

DECLARE @year VARCHAR(4) = '2015'
DECLARE @day VARCHAR(2)  = '23'

EXEC dbo.GetInput @year = @year, @day = @day
EXEC dbo.ParseInput @year = @year, @day = @day 


CREATE TABLE ##Register (ID BIGINT IDENTITY(1,1), RegName CHAR, RegValue BIGINT)
INSERT ##Register (RegName, RegValue) VALUES ('a', 0), ('b',0)

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


/*

    hlf r sets register r to half its current value, then continues with the next instruction.
    tpl r sets register r to triple its current value, then continues with the next instruction.
    inc r increments register r, adding 1 to it, then continues with the next instruction.
    jmp offset is a jump; it continues with the instruction offset away relative to itself.
    jie r, offset is like jmp, but only jumps if register r is even ("jump if even").
    jio r, offset is like jmp, but only jumps if register r is 1 ("jump if one", not odd).

*/

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

END

SELECT RegValue AS Part1 FROM ##Register WHERE RegName = 'b'


-- Reset for part 2

SET @InstrPointer = 1
SET @Counter = 0

TRUNCATE TABLE ##Register
INSERT ##Register (RegName, RegValue) VALUES ('a', 1), ('b',0)


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

END



SELECT RegValue AS Part2 FROM ##Register WHERE RegName = 'b'



DROP TABLE ##Register
DROP TABLE ##Instructions
