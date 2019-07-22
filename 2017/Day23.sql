USE Test_WME

SET NOCOUNT ON

CREATE TABLE ##Input (Line NVARCHAR(MAX));

BULK INSERT ##Input
FROM 'D:\Wilfred\AdventOfCode\2017\input23.txt'
WITH (ROWTERMINATOR = '0x0A');


CREATE TABLE ##Instructions (ID INT IDENTITY(1,1), InstrNr BIGINT, Instr VARCHAR(3), Register VARCHAR(20), Value VARCHAR(20))

INSERT ##Instructions (InstrNr, Instr, Register, Value)
SELECT ROW_NUMBER() OVER (ORDER BY (SELECT 0))
,      LEFT(Line, 3)
,      SUBSTRING(Line, 5, 1)
,      LTRIM(RTRIM(SUBSTRING(Line, 6, LEN(Line))))
FROM ##Input

--SELECT * FROM ##Instructions

CREATE TABLE ##Registers (ID INT IDENTITY(1,1), Program INT, Register VARCHAR(20), Value BIGINT DEFAULT 0)

--SELECT * FROM ##Registers

INSERT ##Registers (Program, Register)
SELECT DISTINCT 0, Register FROM ##Instructions WHERE ASCII(Register) BETWEEN 65 AND 122

UPDATE ##Registers
SET Value = 1
WHERE Register = 'a'


DECLARE @NrOfInstr INT 
DECLARE @EndProgram BIGINT = 0

DECLARE @InstrPointer0 BIGINT = 1 
DECLARE @Instr0 CHAR(3)
DECLARE @Register0 VARCHAR(20)
DECLARE @Value0 VARCHAR(20)
DECLARE @QueueID0 BIGINT = 0
DECLARE @SendInstr0 BIGINT = 0
DECLARE @GenericCounter BIGINT = 0

--DECLARE @CountMul INT = 0

SELECT @NrOfInstr = COUNT(1) FROM ##Instructions

WHILE @EndProgram = 0
BEGIN

    SELECT @Instr0 = Instr
    ,      @Register0 = Register
    ,      @Value0 = Value
    FROM ##Instructions
    WHERE @InstrPointer0 = InstrNr

    IF ASCII(@Value0) BETWEEN 65 AND 122
    BEGIN
        SELECT @Value0 = Value FROM ##Registers WHERE Register = @Value0 AND Program = 0
    END
   
    SET @GenericCounter = @GenericCounter + 1

--    IF (@GenericCounter % 100000) = 0 
    SELECT * FROM ##Registers


    UPDATE R1
    SET R1.Value = @Value0
    FROM ##Registers R1
    WHERE @Instr0 = 'set' AND R1.Register = @Register0 AND Program = 0

    UPDATE R1
    SET R1.Value = R1.Value - @Value0
    FROM ##Registers R1
    WHERE @Instr0 = 'sub' AND R1.Register = @Register0 AND Program = 0

    UPDATE R1
    SET R1.Value = R1.Value * @Value0
    FROM ##Registers R1
    WHERE @Instr0 = 'mul' AND R1.Register = @Register0 AND Program = 0

--    IF (@Instr0 = 'mul') SET @CountMul = @CountMul + 1

    IF (@Instr0 = 'jnz')
    BEGIN

        IF ASCII(@Register0) BETWEEN 65 AND 122
        BEGIN
            SELECT @Register0 = Value FROM ##Registers WHERE Register = @Register0 AND Program = 0
        END
        IF @Register0 <> CAST(0 AS BIGINT) SET @InstrPointer0 = @InstrPointer0 + CAST(@Value0 AS BIGINT) - 1 -- Correct for later addition
    END
  
    SET @InstrPointer0 = @InstrPointer0 + 1

    IF @InstrPointer0 >= @NrOfInstr 
        SET @EndProgram = 1


    IF @GenericCounter > 10 SET @EndProgram = 1
                         
    Print @InstrPointer0

END

SELECT @SendInstr0, 
       @GenericCounter,
       --@CountMul,
       *
FROM ##Registers

--SELECT * FROM ##Instructions

/*

DROP TABLE ##Registers
DROP TABLE ##Instructions
DROP TABLE ##Input


*/


--4225 for Part 1 was correct


/*

Het programma telt alle niet priemgetallen tussen 123700 t/m 106700 met increments van 17

(Op een zo inefficient mogelijke manier)
*/

DECLARE @IsPrime INT = 1
DECLARE @NrOfPrimes INT = 0
DECLARE @StartNr INT = 106700
DECLARE @EndNr INT = 123700
DECLARE @Incr INT = 17

DECLARE @Counter INT = 2
DECLARE @CurrentValue INT = @StartNr

WHILE @CurrentValue <= @EndNr
BEGIN

    IF (@CurrentValue % 2) <> 0 --Skip all even numbers
    BEGIN

        SET @Counter = 3
        SET @IsPrime = 1

        WHILE @Counter < @CurrentValue AND @IsPrime = 1
        BEGIN
            IF (@CurrentValue % @Counter = 0) SET @IsPrime = 0
            SET @Counter = @Counter + 1
        END
        
        IF @IsPrime = 1 SET @NrOfPrimes = @NrOfPrimes + 1 

    END
    ELSE 
    BEGIN
        SET @IsPrime = 0
    END

    PRINT 'Number ' + CAST(@CurrentValue AS NVARCHAR(7)) + ' IsPrime = ' + CAST(@IsPrime AS VARCHAR(2))

    SET @CurrentValue = @CurrentValue + @Incr

END

SELECT (@EndNr - @StartNr) / @Incr - @NrOfPrimes, @EndNr, @StartNr, @Incr, @NrOfPrimes

--904 niet goed, too low
--905 is correct (want grenzen moeten meetellen)