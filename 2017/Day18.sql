USE Test_WME

SET NOCOUNT ON

CREATE TABLE ##Input (Line NVARCHAR(MAX));

BULK INSERT ##Input
FROM 'D:\Wilfred\AdventOfCode\2017\input18.txt'
WITH (ROWTERMINATOR = '0x0A');


CREATE TABLE ##Instructions (ID INT IDENTITY(1,1), InstrNr BIGINT, Instr VARCHAR(3), Register VARCHAR(20), Value VARCHAR(20))

INSERT ##Instructions (InstrNr, Instr, Register, Value)
SELECT ROW_NUMBER() OVER (ORDER BY (SELECT 0))
,      LEFT(Line, 3)
,      SUBSTRING(Line, 5, 1)
,      LTRIM(RTRIM(SUBSTRING(Line, 6, LEN(Line))))
FROM ##Input


/*
DELETE FROM ##Instructions
INSERT ##Instructions (InstrNr, Instr, Register, Value) VALUES (0, 'set','a','1')
INSERT ##Instructions (InstrNr, Instr, Register, Value) VALUES (1, 'add','a','2')
INSERT ##Instructions (InstrNr, Instr, Register, Value) VALUES (2, 'mul','a','a')
INSERT ##Instructions (InstrNr, Instr, Register, Value) VALUES (3, 'mod','a','5')
INSERT ##Instructions (InstrNr, Instr, Register, Value) VALUES (4, 'snd','a','')
INSERT ##Instructions (InstrNr, Instr, Register, Value) VALUES (5, 'set','a','0')
INSERT ##Instructions (InstrNr, Instr, Register, Value) VALUES (6, 'rcv','a','')
INSERT ##Instructions (InstrNr, Instr, Register, Value) VALUES (7, 'jgz','a','-1')
INSERT ##Instructions (InstrNr, Instr, Register, Value) VALUES (8, 'set','a','1')
INSERT ##Instructions (InstrNr, Instr, Register, Value) VALUES (9, 'jgz','a','-2')
*/

/*
DELETE FROM ##Instructions
INSERT ##Instructions (InstrNr, Instr, Register, Value) VALUES (0, 'snd','1','')
INSERT ##Instructions (InstrNr, Instr, Register, Value) VALUES (1, 'snd','2','')
INSERT ##Instructions (InstrNr, Instr, Register, Value) VALUES (2, 'snd','p','')
INSERT ##Instructions (InstrNr, Instr, Register, Value) VALUES (3, 'rcv','a','')
INSERT ##Instructions (InstrNr, Instr, Register, Value) VALUES (4, 'rcv','b','')
INSERT ##Instructions (InstrNr, Instr, Register, Value) VALUES (5, 'rcv','c','')
INSERT ##Instructions (InstrNr, Instr, Register, Value) VALUES (6, 'rcv','d','')
*/


/*
CREATE TABLE ##Registers (ID INT IDENTITY(1,1), Register VARCHAR(20), Value BIGINT DEFAULT 0)

INSERT ##Registers (Register)
SELECT DISTINCT(Register) FROM ##Instructions WHERE ASCII(Register) BETWEEN 65 AND 122


DECLARE @InstrPointer INT = 0 
DECLARE @NrOfInstr INT 
DECLARE @Instr CHAR(3)
DECLARE @Register VARCHAR(20)
DECLARE @Value VARCHAR(20)
DECLARE @LastSoundPlayed VARCHAR(20) = 0

SELECT @NrOfInstr = COUNT(1) FROM ##Instructions

WHILE @InstrPointer BETWEEN 0 AND @NrOfInstr
BEGIN

    SELECT @Instr = Instr
    ,      @Register = Register
    ,      @Value = Value
    FROM ##Instructions
    WHERE @InstrPointer = InstrNr

--    SELECT @Instr, @Register, @Value, @InstrPointer, * FROM ##Registers

    IF ASCII(@Value) BETWEEN 65 AND 122
    BEGIN
        SELECT @Value = Value FROM ##Registers WHERE Register = @Value
    END

    UPDATE R1
    SET R1.Value = @Value
    FROM ##Registers R1
    WHERE @Instr = 'set' AND R1.Register = @Register

    UPDATE R1
    SET R1.Value = R1.Value + @Value
    FROM ##Registers R1
    WHERE @Instr = 'add' AND R1.Register = @Register

--    PRINT @Value + ' ' + @Instr + ' ' + @Register

    UPDATE R1
    SET R1.Value = R1.Value * @Value
    FROM ##Registers R1
    WHERE @Instr = 'mul' AND R1.Register = @Register

    UPDATE R1
    SET R1.Value = R1.Value % @Value
    FROM ##Registers R1
    WHERE @Instr = 'mod' AND R1.Register = @Register

    IF (@Instr = 'jgz')
    BEGIN
    
        IF ASCII(@Register) BETWEEN 65 AND 122
        BEGIN
            SELECT @Register = Value FROM ##Registers WHERE Register = @Register
        END

        --PRINT @Register
        --PRINT @InstrPointer
        --PRINT @Value

        IF @Register > 0 SET @InstrPointer = @InstrPointer + @Value - 1 -- Correct for later addition

    END

    IF (@Instr = 'snd') 
    BEGIN
        
        SELECT @Value = Value FROM ##Registers WHERE Register = @Register

        PRINT 'Sound played with frequency ' + @Value + ' at ' + CAST(GETDATE() AS VARCHAR(50))

        SET @LastSoundPlayed = @Value

    END

    IF (@Instr = 'rcv') 
    BEGIN

        IF ASCII(@Register) BETWEEN 65 AND 122
        BEGIN
            SELECT @Register = Value FROM ##Registers WHERE Register = @Register
        END
                
        IF @Register > 0 
        BEGIN
            PRINT 'Frequency recovered with value ' + @LastSoundPlayed + ' at ' + CAST(GETDATE() AS VARCHAR(50))

            SET @InstrPointer = @InstrPointer + @NrOfInstr
        END

    END

    SET @InstrPointer = @InstrPointer + 1

END
*/





CREATE TABLE ##Registers (ID INT IDENTITY(1,1), Program INT, Register VARCHAR(20), Value BIGINT DEFAULT 0)

INSERT ##Registers (Program, Register)
SELECT DISTINCT 0, Register FROM ##Instructions WHERE ASCII(Register) BETWEEN 65 AND 122
UNION 
SELECT DISTINCT 1, Register FROM ##Instructions WHERE ASCII(Register) BETWEEN 65 AND 122

UPDATE ##Registers
SET Value = Program
WHERE Register = 'p'


DECLARE @NrOfInstr INT 
DECLARE @EndProgram BIGINT = 0

DECLARE @InstrPointer0 BIGINT = 1 
DECLARE @Instr0 CHAR(3)
DECLARE @Register0 VARCHAR(20)
DECLARE @Value0 VARCHAR(20)
DECLARE @QueueID0 BIGINT = 0
DECLARE @SendInstr0 BIGINT = 0

DECLARE @InstrPointer1 BIGINT = 1 
DECLARE @Instr1 CHAR(3)
DECLARE @Register1 VARCHAR(20)
DECLARE @Value1 VARCHAR(20)
DECLARE @QueueID1 BIGINT = 0
DECLARE @SendInstr1 BIGINT = 0
DECLARE @GenericCounter BIGINT = 0


SELECT @NrOfInstr = COUNT(1) FROM ##Instructions

CREATE TABLE ##Queue (ID BIGINT IDENTITY(1,1), ForProgram BIGINT, Value BIGINT)

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

--    IF @GenericCounter >= 1400 SELECT @GenericCounter, @Instr, @Register, @Value, @InstrPointer0, @InstrPointer1, * FROM ##Registers
    
    SET @GenericCounter = @GenericCounter + 1

--SELECT @GenericCounter, @Instr0, @Instr1, @Register0, @Register1, @Value0, @Value1, @InstrPointer0, @InstrPointer1, * FROM ##Registers

    UPDATE R1
    SET R1.Value = @Value0
    FROM ##Registers R1
    WHERE @Instr0 = 'set' AND R1.Register = @Register0 AND Program = 0

    UPDATE R1
    SET R1.Value = R1.Value + @Value0
    FROM ##Registers R1
    WHERE @Instr0 = 'add' AND R1.Register = @Register0 AND Program = 0

    UPDATE R1
    SET R1.Value = R1.Value * @Value0
    FROM ##Registers R1
    WHERE @Instr0 = 'mul' AND R1.Register = @Register0 AND Program = 0

    UPDATE R1
    SET R1.Value = R1.Value % @Value0
    FROM ##Registers R1
    WHERE @Instr0 = 'mod' AND R1.Register = @Register0 AND Program = 0


    IF (@Instr0 = 'jgz')
    BEGIN

        IF ASCII(@Register0) BETWEEN 65 AND 122
        BEGIN
            SELECT @Register0 = Value FROM ##Registers WHERE Register = @Register0 AND Program = 0
        END
        IF @Register0 > CAST(0 AS BIGINT) SET @InstrPointer0 = @InstrPointer0 + CAST(@Value0 AS BIGINT) - 1 -- Correct for later addition
    END
  
    IF (@Instr0 = 'snd') 
    BEGIN
   
        IF ASCII(@Register0) BETWEEN 65 AND 122
        BEGIN
            SELECT @Value0 = Value FROM ##Registers WHERE Register = @Register0 AND Program = 0
        END
        ELSE
        BEGIN
            SET @Value0 = @Register0
        END

        INSERT ##Queue (ForProgram, Value) SELECT 1, @Value0

        SET @SendInstr0 = @SendInstr0 + 1
    END

    IF (@Instr0 = 'rcv') 
    BEGIN
        
        IF EXISTS(SELECT 1 FROM ##Queue WHERE ForProgram = 0)
        BEGIN
            
            SELECT TOP(1) @QueueID0 = ID FROM ##Queue WHERE ForProgram = 0 ORDER BY ID

            UPDATE R
            SET R.Value = Q.Value
            FROM ##Registers R
            CROSS APPLY (SELECT Value FROM ##Queue WHERE ID = @QueueID0) Q
            WHERE R.Register = @Register0 AND Program = 0

            DELETE
            FROM ##Queue 
            WHERE ID = @QueueID0
        END
        ELSE SET @InstrPointer0 = @InstrPointer0 - 1 -- Wait / Stay on the same instruction

    END

    SET @InstrPointer0 = @InstrPointer0 + 1



    SELECT @Instr1 = Instr
    ,      @Register1 = Register
    ,      @Value1 = Value
    FROM ##Instructions
    WHERE @InstrPointer1 = InstrNr

--SELECT @GenericCounter, @Instr0, @Instr1, @Register0, @Register1, @Value0, @Value1, @InstrPointer0, @InstrPointer1, * FROM ##Registers

    IF ASCII(@Value1) BETWEEN 65 AND 122
    BEGIN
        SELECT @Value1 = Value FROM ##Registers WHERE Register = @Value1 AND Program = 1
    END

    UPDATE R1
    SET R1.Value = @Value1
    FROM ##Registers R1
    WHERE @Instr1 = 'set' AND R1.Register = @Register1 AND Program = 1

    UPDATE R1
    SET R1.Value = R1.Value + @Value1
    FROM ##Registers R1
    WHERE @Instr1 = 'add' AND R1.Register = @Register1 AND Program = 1

    UPDATE R1
    SET R1.Value = R1.Value * @Value1
    FROM ##Registers R1
    WHERE @Instr1 = 'mul' AND R1.Register = @Register1 AND Program = 1

    UPDATE R1
    SET R1.Value = R1.Value % @Value1
    FROM ##Registers R1
    WHERE @Instr1 = 'mod' AND R1.Register = @Register1 AND Program = 1


    IF (@Instr1 = 'jgz')
    BEGIN
    
        IF ASCII(@Register1) BETWEEN 65 AND 122
        BEGIN
            SELECT @Register1 = Value FROM ##Registers WHERE Register = @Register1 AND Program = 1
        END

        IF @Register1 > CAST(0 AS BIGINT) SET @InstrPointer1 = @InstrPointer1 + CAST(@Value1 AS BIGINT) - 1 -- Correct for later addition

    END

    IF (@Instr1 = 'snd') 
    BEGIN

        IF ASCII(@Register1) BETWEEN 65 AND 122
        BEGIN
            SELECT @Value1 = Value FROM ##Registers WHERE Register = @Register1 AND Program = 1
        END
        ELSE
        BEGIN
            SET @Value1 = @Register1
        END

        INSERT ##Queue (ForProgram, Value) SELECT 0, @Value1

		SET @SendInstr1 = @SendInstr1 + 1
    END

    IF (@Instr1 = 'rcv') 
    BEGIN
    --SELECT * FROM ##Queue
        IF EXISTS(SELECT 1 FROM ##Queue WHERE ForProgram = 1)
        BEGIN
            SELECT TOP(1) @QueueID1 = ID FROM ##Queue WHERE ForProgram = 1 ORDER BY ID

            UPDATE R
            SET R.Value = Q.Value
            FROM ##Registers R
            CROSS APPLY (SELECT Value FROM ##Queue WHERE ID = @QueueID1) Q
            WHERE R.Register = @Register1 AND Program = 1

            DELETE
            FROM ##Queue
            WHERE ID = @QueueID1
        END
        ELSE SET @InstrPointer1 = @InstrPointer1 - 1 -- Wait / Stay on the same instruction

    END

    SET @InstrPointer1 = @InstrPointer1 + 1

    IF @InstrPointer0 >= @NrOfInstr AND @InstrPointer1 >= @NrOfInstr SET @EndProgram = 1

    IF EXISTS(SELECT 1 FROM ##Instructions WHERE InstrNr = @InstrPointer0 AND Instr = 'rcv')
        IF EXISTS(SELECT 1 FROM ##Instructions WHERE InstrNr = @InstrPointer1 AND Instr = 'rcv')
          BEGIN
            IF NOT EXISTS(SELECT 1 FROM ##Queue) SET @EndProgram = 1
          END

    IF @GenericCounter > 100000 SET @EndProgram = 1

    

END

SELECT @SendInstr0, @SendInstr1, @GenericCounter
SELECT * FROM ##Instructions



--SELECT * FROM ##Queue

/*

DROP TABLE ##Queue
DROP TABLE ##Registers
DROP TABLE ##Instructions
DROP TABLE ##Input


*/



