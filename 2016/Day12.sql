USE Test_WME

SET NOCOUNT ON

DECLARE @year VARCHAR(4) = '2016'
DECLARE @day VARCHAR(2)  = '12'

EXEC dbo.GetInput @year = @year, @day = @day
EXEC dbo.ParseInput @year = @year, @day = @day

--SELECT TOP 10 * FROM ##InputNumbered
--SELECT TOP 10 * FROM ##InputGrid
--SELECT TOP 10 * FROM ##InputInts
--SELECT TOP 100 * FROM ##InputSplit
--SELECT * FROM ##Input

CREATE TABLE ##Instructions (ID INT IDENTITY(1,1), InstrNr INT, Instruction VARCHAR(5), Instr1 VARCHAR(5), Instr2 VARCHAR(5))

INSERT ##Instructions (InstrNr, Instruction, Instr1, Instr2)
SELECT  ROW_NUMBER() OVER (ORDER BY (SELECT 0))
,       LEFT(Line, 3) 
,       CASE WHEN LEFT(Line, 3) IN ('inc','dec') THEN SUBSTRING(Line, 5, LEN(Line)) ELSE LEFT(SUBSTRING(Line, 5, LEN(Line)), CHARINDEX(' ', SUBSTRING(Line, 5, LEN(Line)))) END
,       CASE WHEN LEFT(Line, 3) IN ('inc','dec') THEN NULL ELSE SUBSTRING(SUBSTRING(Line, 5, LEN(Line)), CHARINDEX(' ', SUBSTRING(Line, 5, LEN(Line)))+ 1, LEN(Line)) END
FROM ##Input


CREATE TABLE ##Registers (ID INT IDENTITY(1,1), RegName CHAR(1), RegValue INT)

INSERT ##Registers (RegName, RegValue) VALUES ('A', 0), ('B', 0), ('C', 0), ('D', 0)

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

SELECT RegValue AS Part1 FROM ##Registers WHERE RegName = 'A'

/*

DROP TABLE ##Input
DROP TABLE ##Instructions
DROP TABLE ##Registers

*/


/* --Input program:

--Initialize registers A = 1, B = 1, D = 26
1	1	cpy	1 	a
2	2	cpy	1 	b
3	3	cpy	26 	d

-- If c = 0 then goto instruction 10 else set c = 7
4	4	jnz	c 	2
5	5	jnz	1 	5
6	6	cpy	7 	c

-- Add c to d, setting to d = 33 (only do this if c is not equal to 0)
7	7	inc	d	NULL
8	8	dec	c	NULL
9	9	jnz	c 	-2

-- Calculate Fibonacci number, up to term d + 2, since first two terms are hard coded (d = 26 or d = 33)
-- Register A contains the result fibonacci(28) = 317811  or fibonacci(33) = 9227465
10	10	cpy	a 	c
11	11	inc	a	NULL
12	12	dec	b	NULL
13	13	jnz	b 	-2
14	14	cpy	c 	b
15	15	dec	d	NULL
16	16	jnz	d 	-6

-- Add 13 x 14 (= 182) to register A
17	17	cpy	13 	c
18	18	cpy	14 	d
19	19	inc	a	NULL
20	20	dec	d	NULL
21	21	jnz	d 	-2
22	22	dec	c	NULL
23	23	jnz	c 	-5
*/

--Let's do that a little more efficient:
--DECLARE @Counter INT

DECLARE @I1 INT = 1
DECLARE @I2 INT = 1
DECLARE @Temp INT
SET @Counter = 0

WHILE @Counter < 33
BEGIN

    SET @Temp = @I1
    SET @I1 = @I2
    SET @I2 = @Temp + @I2

    IF @Counter = 25 SELECT @I2 + 13 * 14 AS Part1

    SET @Counter = @Counter + 1
END

SELECT @I2 + 13 * 14 AS Part2





