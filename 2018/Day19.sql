use Test_WME

SET NOCOUNT ON

CREATE TABLE ##Input (Line NVARCHAR(MAX));

BULK INSERT ##Input
FROM 'C:\Source\AdventOfCode\2018\input19.txt'
WITH (ROWTERMINATOR = '0x0A');

DECLARE @IPReg INT
SELECT @IPReg = LTRIM(RTRIM(REPLACE(Line, '#ip', ''))) FROM ##Input WHERE Line LIKE '#ip%'
--SELECT @IPReg

DELETE FROM ##Input WHERE Line LIKE '#ip%'

CREATE TABLE ##Program (InstrNr INT IDENTITY(0,1) PRIMARY KEY, Instr CHAR(4), A INT, B INT, C INT)

INSERT ##Program (Instr, A, B, C)
SELECT LEFT(Line, 4) AS Instr
,      LEFT(SUBSTRING(Line, 6, LEN(Line)), 1) --All first instructions are 1 digit
,      SUBSTRING(Line, 7, 3)
,      RIGHT(Line, 1) --Only 6 Registers so this works
FROM ##Input

--SELECT * FROM ##Program

CREATE TABLE ##Register (Nr INT IDENTITY(0,1) PRIMARY KEY, Val BIGINT)

INSERT ##Register (Val) SELECT TOP 6 0 FROM sys.messages

--SELECT * FROM ##Register

DECLARE @ProgramSize INT
SELECT @ProgramSize = COUNT(1) FROM ##Program

DECLARE @IP INT = 0 --InstructionPointer
DECLARE @A INT
DECLARE @B INT
DECLARE @C INT
DECLARE @Instr CHAR(4)

DECLARE @RegA INT
DECLARE @RegB INT
DECLARE @Debug INT = 1
DECLARE @Counter BIGINT = 0

DECLARE @DoPart2 INT = 1

IF @DoPart2 = 1 UPDATE ##Register SET Val = 1 WHERE Nr = 0

WHILE @IP BETWEEN 0 AND @ProgramSize
BEGIN

    -- Keep register and IP in sync
    UPDATE ##Register
    SET Val = @IP
    WHERE Nr = @IPReg

    --Retrieve instruction
    SELECT @Instr = Instr, @A = A, @B = B, @C = C
    FROM ##Program
    WHERE InstrNr = @IP

    IF @Debug = 1
    BEGIN
        SELECT @RegA = Val FROM ##Register WHERE Nr = @A
        SELECT @RegB = Val FROM ##Register WHERE Nr = @B

        SET @Counter = @Counter + 1

        PRINT 'Count:' + CAST(@Counter AS VARCHAR(50)) + '|' + @Instr + '|A:' + CAST(@A AS VARCHAR(20)) + '|B:' + CAST(@B AS VARCHAR(20)) + '|RegA:' + CAST(@RegA AS VARCHAR(20)) + '|RegB:' + ISNULL(CAST(@RegB AS VARCHAR(20)),'*') + '|C:' + CAST(@C AS VARCHAR(20)) + '|IP:' + CAST(@IP AS VARCHAR(20))
    END

    --addr (add register) stores into register C the result of adding register A and register B.
    IF @Instr = 'addr' 
        UPDATE R 
        SET Val = RA.Val + RB.Val
        FROM ##Register R
        INNER JOIN ##Register RA ON RA.Nr = @A
        INNER JOIN ##Register RB ON RB.Nr = @B
        WHERE R.Nr = @C

    --addi (add immediate) stores into register C the result of adding register A and value B.
    IF @Instr = 'addi' 
        UPDATE R 
        SET Val = RA.Val + @B
        FROM ##Register R
        INNER JOIN ##Register RA ON RA.Nr = @A
        WHERE R.Nr = @C

    --mulr (multiply register) stores into register C the result of multiplying register A and register B.
    IF @Instr = 'mulr' 
        UPDATE R 
        SET Val = RA.Val * RB.Val
        FROM ##Register R
        INNER JOIN ##Register RA ON RA.Nr = @A
        INNER JOIN ##Register RB ON RB.Nr = @B
        WHERE R.Nr = @C

    --muli (multiply immediate) stores into register C the result of multiplying register A and value B.
    IF @Instr = 'muli' 
        UPDATE R 
        SET Val = RA.Val * @B
        FROM ##Register R
        INNER JOIN ##Register RA ON RA.Nr = @A
        WHERE R.Nr = @C

    --banr (bitwise AND register) stores into register C the result of the bitwise AND of register A and register B.
    IF @Instr = 'banr' 
        UPDATE R 
        SET Val = RA.Val & RB.Val
        FROM ##Register R
        INNER JOIN ##Register RA ON RA.Nr = @A
        INNER JOIN ##Register RB ON RB.Nr = @B
        WHERE R.Nr = @C

    --bani (bitwise AND immediate) stores into register C the result of the bitwise AND of register A and value B.
    IF @Instr = 'bani' 
        UPDATE R 
        SET Val = RA.Val & @B
        FROM ##Register R
        INNER JOIN ##Register RA ON RA.Nr = @A
        WHERE R.Nr = @C

    --borr (bitwise OR register) stores into register C the result of the bitwise OR of register A and register B.
    IF @Instr = 'borr' 
        UPDATE R 
        SET Val = RA.Val | RB.Val
        FROM ##Register R
        INNER JOIN ##Register RA ON RA.Nr = @A
        INNER JOIN ##Register RB ON RB.Nr = @B
        WHERE R.Nr = @C

    --bori (bitwise OR immediate) stores into register C the result of the bitwise OR of register A and value B.
    IF @Instr = 'bori' 
        UPDATE R 
        SET Val = RA.Val | @B
        FROM ##Register R
        INNER JOIN ##Register RA ON RA.Nr = @A
        WHERE R.Nr = @C

    --setr (set register) copies the contents of register A into register C. (Input B is ignored.)
    IF @Instr = 'setr' 
        UPDATE R 
        SET Val = RA.Val
        FROM ##Register R
        INNER JOIN ##Register RA ON RA.Nr = @A
        WHERE R.Nr = @C

    --seti (set immediate) stores value A into register C. (Input B is ignored.)
    IF @Instr = 'seti' 
        UPDATE R 
        SET Val = @A
        FROM ##Register R
        WHERE R.Nr = @C

    --gtir (greater-than immediate/register) sets register C to 1 if value A is greater than register B. Otherwise, register C is set to 0.
    IF @Instr = 'gtir' 
        UPDATE R 
        SET Val = CASE WHEN @A > RB.Val THEN 1 ELSE 0 END
        FROM ##Register R
        INNER JOIN ##Register RB ON RB.Nr = @B
        WHERE R.Nr = @C    
    
    --gtri (greater-than register/immediate) sets register C to 1 if register A is greater than value B. Otherwise, register C is set to 0.
    IF @Instr = 'gtri' 
        UPDATE R 
        SET Val = CASE WHEN RA.Val > @B THEN 1 ELSE 0 END
        FROM ##Register R
        INNER JOIN ##Register RA ON RA.Nr = @A
        WHERE R.Nr = @C    

    --gtrr (greater-than register/register) sets register C to 1 if register A is greater than register B. Otherwise, register C is set to 0.
    IF @Instr = 'gtrr' 
        UPDATE R 
        SET Val = CASE WHEN RA.Val > RB.Val THEN 1 ELSE 0 END
        FROM ##Register R
        INNER JOIN ##Register RA ON RA.Nr = @A
        INNER JOIN ##Register RB ON RB.Nr = @B
        WHERE R.Nr = @C    

    --eqir (equal immediate/register) sets register C to 1 if value A is equal to register B. Otherwise, register C is set to 0.
    IF @Instr = 'eqir' 
        UPDATE R 
        SET Val = CASE WHEN @A = RB.Val THEN 1 ELSE 0 END
        FROM ##Register R
        INNER JOIN ##Register RB ON RB.Nr = @B
        WHERE R.Nr = @C    
    
    --eqri (equal register/immediate) sets register C to 1 if register A is equal to value B. Otherwise, register C is set to 0.
    IF @Instr = 'eqri' 
        UPDATE R 
        SET Val = CASE WHEN RA.Val = @B THEN 1 ELSE 0 END
        FROM ##Register R
        INNER JOIN ##Register RA ON RA.Nr = @A
        WHERE R.Nr = @C    

    --eqrr (equal register/register) sets register C to 1 if register A is equal to register B. Otherwise, register C is set to 0.
    IF @Instr = 'eqrr' 
        UPDATE R 
        SET Val = CASE WHEN RA.Val = RB.Val THEN 1 ELSE 0 END
        FROM ##Register R
        INNER JOIN ##Register RA ON RA.Nr = @A
        INNER JOIN ##Register RB ON RB.Nr = @B
        WHERE R.Nr = @C    

    -- Keep register and IP in sync
    SELECT @IP = Val FROM ##Register WHERE Nr = @IPReg

    SET @IP = @IP + 1

END

SELECT * FROM ##Register

-- 1092 is correct for part 1 (Took 21min)

/*

DROP TABLE ##Register
DROP TABLE ##Program
DROP TABLE ##Input

*/

/*
Unfortunaly part 2 cannot be done by simply running the program. It would take far too long.

After analysing this is what the program does:
It has a target number (10551305 in our case)
It sums all divisors for this number

Divisors for 10551305 are
1, 5, 17, 85, 124133, 620665, 2110261, 10551305
They're sum is 13406472

Which is correct for part 2

*/

