use Test_WME

SET NOCOUNT ON

CREATE TABLE ##Input (Line NVARCHAR(MAX));

BULK INSERT ##Input
FROM 'C:\Source\AdventOfCode\2018\input21.txt'
WITH (ROWTERMINATOR = '0x0A');

DECLARE @IPReg INT
SELECT @IPReg = LTRIM(RTRIM(REPLACE(Line, '#ip', ''))) FROM ##Input WHERE Line LIKE '#ip%'
--SELECT @IPReg

DELETE FROM ##Input WHERE Line LIKE '#ip%'

CREATE TABLE ##Program (InstrNr INT IDENTITY(0,1) PRIMARY KEY, Instr CHAR(4), A INT, B INT, C INT)

INSERT ##Program (Instr, A, B, C)
SELECT LEFT(Line, 4) AS Instr
,      LEFT(SUBSTRING(Line, 6, LEN(Line)), CHARINDEX(' ', SUBSTRING(Line, 6, LEN(Line)))) AS A
,      REVERSE(LEFT(LTRIM(REVERSE(LEFT(Line, LEN(Line) - 1))), CHARINDEX(' ', LTRIM(REVERSE(LEFT(Line, LEN(Line) - 1)))))) AS B
,      RIGHT(Line, 1) AS C--Only 6 Registers so this works
FROM ##Input

--SELECT * FROM ##Program 

CREATE TABLE ##Register (Nr INT IDENTITY(0,1) PRIMARY KEY, Val BIGINT)

INSERT ##Register (Val) SELECT TOP 6 0 FROM sys.messages
UPDATE ##Register SET Val = 10199686 WHERE Nr = 0
--SELECT * FROM ##Register


DECLARE @ProgramSize INT
SELECT @ProgramSize = COUNT(1) FROM ##Program

DECLARE @IP INT = 0 --InstructionPointer
DECLARE @A BIGINT
DECLARE @B BIGINT
DECLARE @C BIGINT
DECLARE @Instr CHAR(4)

DECLARE @RegA BIGINT
DECLARE @RegB BIGINT
DECLARE @Debug INT = 1
DECLARE @Counter BIGINT = 0

DECLARE @DoPart2 INT = 0


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

        PRINT 'Count:' + CAST(@Counter AS VARCHAR(50)) + '|' + @Instr + '|A:' + CAST(@A AS VARCHAR(20)) + '|B:' + CAST(@B AS VARCHAR(20)) + '|RegA:' + ISNULL(CAST(@RegA AS VARCHAR(20)), '*') + '|RegB:' + ISNULL(CAST(@RegB AS VARCHAR(20)),'*') + '|C:' + CAST(@C AS VARCHAR(20)) + '|IP:' + CAST(@IP AS VARCHAR(20))
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

    IF @IP = 28 AND @DoPart2 = 0 
    BEGIN
        PRINT 'First check on:' + CAST(@RegA AS VARCHAR(20))
        --SET @IP = 9999
    END

    --IF @IP = 28 AND @DoPart2 = 1
    --BEGIN
    --    INSERT ##Solutions (Sol) SELECT @RegA
    --END
    

    SET @IP = @IP + 1

END

--SELECT * FROM ##Register

--SELECT * FROM ##Program WHERE A = 0 OR B = 0 --> Instr 28 is key

-- 15823996 is correct for part 1

/*

DROP TABLE ##Register
DROP TABLE ##Program
DROP TABLE ##Input
DROP TABLE ##Solutions

*/

-- As expected. Part 2 cannot be done by simply running the code

/* This is the program in psuedo code
R4 = 0

6   R3 = R4 | 65536
7   R4 = 16098955
8&9 R4 = R4 + R3 & 255
10  R4 = R4 & 16777215
11  R4 = R4 * 65899
12  R4 = R4 & 16777215

13 IF (256 > R3) 
   THEN JUMP TO 28 
   ELSE R3 = (R3 / 256) + 1 AND JUMP to 8

28 IF R4 == R0 EXIT ELSE GOTO 6
*/

DECLARE @R0 BIGINT = 0 
DECLARE @R3 BIGINT = 0
DECLARE @R4 BIGINT = 0 

DECLARE @ContinuProgram INT = 1

SET @R3 = @R4 | 65536
SET @R4 = 16098955

CREATE TABLE ##Solutions (ID INT IDENTITY(1,1), Sol BIGINT)

WHILE @ContinuProgram = 1
BEGIN
    
    SET @R4 = (((@R4 + (@R3 & 255)) & 16777215) * 65899) & 16777215

    --PRINT @R3
    --PRINT @R4

    IF @R3 < 256 
    BEGIN
        INSERT ##Solutions (Sol) SELECT @R4

        SET @R3 = @R4 | 65536
        SET @R4 = 16098955

        IF (SELECT COUNT(1) FROM ##Solutions) > 100000 SET @ContinuProgram = 0
    END
    ELSE 
    BEGIN
        SET @R3 = (@R3 / 256)
    END

END

-- Do the same solutions start popping up?
SELECT * FROM ##Solutions S1
INNER JOIN ##Solutions S2 ON S1.Sol = S2.Sol AND S1.ID < S2.ID
ORDER BY 1, 3
-- Yes, they do

-- This seems to be one cycle of solutions
SELECT * FROM ##Solutions WHERE ID BETWEEN 10330 AND 11458 ORDER BY 1

-- So the last one is the request will take the longest time (i.e. the most instructions) to reach
SELECT * FROM ##Solutions WHERE ID = (11458 - 1)

-- 10199686 is correct for part 2


