use Test_WME

SET NOCOUNT ON

CREATE TABLE ##Input (Line NVARCHAR(MAX));

BULK INSERT ##Input
FROM 'D:\Wilfred\AdventOfCode\2016\input25.txt'
WITH (ROWTERMINATOR = '0x0A');

CREATE TABLE ##Instructions (ID INT IDENTITY(1,1), InstrNr INT, Instruction VARCHAR(5), Instr1 VARCHAR(5), Instr2 VARCHAR(5))

INSERT ##Instructions (InstrNr, Instruction, Instr1, Instr2)
SELECT  ROW_NUMBER() OVER (ORDER BY (SELECT 0))
,       LEFT(Line, 3) 
,       CASE WHEN LEFT(Line, 3) IN ('inc','dec') THEN SUBSTRING(Line, 5, LEN(Line)) ELSE LEFT(SUBSTRING(Line, 5, LEN(Line)), CHARINDEX(' ', SUBSTRING(Line, 5, LEN(Line)))) END
,       CASE WHEN LEFT(Line, 3) IN ('inc','dec') THEN NULL ELSE SUBSTRING(SUBSTRING(Line, 5, LEN(Line)), CHARINDEX(' ', SUBSTRING(Line, 5, LEN(Line)))+ 1, LEN(Line)) END
FROM ##Input

--SELECT * FROM ##Instructions WHERE Instruction = 'tgl'
UPDATE ##Instructions
SET Instr1 = Instr2
,   Instr2 = NULL
WHERE Instruction = 'tgl'



CREATE TABLE ##Registers (ID INT IDENTITY(1,1), RegName CHAR(1), RegValue INT)

INSERT ##Registers (RegName, RegValue) VALUES ('A', 175), ('B', 0), ('C', 0), ('D', 0) --Part 1


DECLARE @Counter INT = 1
DECLARE @ProgramDone INT = 0

DECLARE @Instr VARCHAR(15)
DECLARE @Instr1 VARCHAR(15)
DECLARE @Instr1Int INT
DECLARE @Instr2 VARCHAR(15)
DECLARE @Instr2Int INT

DECLARE @TempCounter INT = 1

WHILE @ProgramDone = 0 --AND @TempCounter < 10
BEGIN

    SELECT @Instr = Instruction, @Instr1 = LTRIM(RTRIM(Instr1)), @Instr2 = LTRIM(RTRIM(Instr2))
    FROM ##Instructions
    WHERE InstrNr = @Counter

    --PRINT @Instr + ' ' + @Instr1 + ' ' + ISNULL(@Instr2, '-') + ' ' + CAST(@Counter AS VARCHAR(20))

    --IF (SELECT RegValue FROM ##Registers WHERE RegName = 'A') > 5000
--        SELECT @TempCounter, @Counter, @Instr, @Instr1, @Instr2, * FROM ##Registers
    
    UPDATE ##Registers
    SET RegValue = RegValue + 1
    WHERE @Instr = 'inc' AND @Instr1 = RegName

    UPDATE ##Registers
    SET RegValue = RegValue - 1
    WHERE @Instr = 'dec' AND @Instr1 = RegName

    SELECT @Instr1Int = CAST(RegValue AS INT)
    FROM ##Registers 
    WHERE @Instr1 = RegName

    SELECT @Instr2Int = CAST(RegValue AS INT)
    FROM ##Registers 
    WHERE @Instr2 = RegName

    IF @Instr = 'cpy'
    BEGIN
        
        IF ASCII(RIGHT(@Instr1,1)) BETWEEN 48 AND 57
        BEGIN
            UPDATE ##Registers
            SET RegValue = CAST(@Instr1 AS INT)
            WHERE @Instr = 'cpy' AND RegName = @Instr2
        END
        ELSE
        BEGIN
            UPDATE ##Registers
            SET RegValue = @Instr1Int
            WHERE @Instr = 'cpy' AND RegName = @Instr2
        END
    END

    IF @Instr = 'jnz'
    BEGIN
        
        IF ASCII(RIGHT(@Instr1,1)) BETWEEN 48 AND 57
        BEGIN
            IF ASCII(RIGHT(@Instr2,1)) BETWEEN 48 AND 57
            BEGIN
            --PRINT 'I'
                    SELECT @Counter = @Counter + CAST(@Instr2 AS INT) - 1 --Correct for future increment
                    WHERE @Instr = 'jnz' AND @Instr1 <> 0
            END
            ELSE
            BEGIN
            --PRINT 'II'
                    SELECT @Counter = @Counter + @Instr2Int - 1 --Correct for future increment
                    WHERE @Instr = 'jnz' AND @Instr1 <> 0
            END
        END
        ELSE
        BEGIN
            IF ASCII(RIGHT(@Instr2,1)) BETWEEN 48 AND 57
            BEGIN
            --PRINT 'III'
                    SELECT @Counter = @Counter + CAST(@Instr2 AS INT) - 1 --Correct for future increment
                    WHERE @Instr = 'jnz' AND @Instr1Int <> 0
            END
            ELSE
            BEGIN
            --PRINT 'IV'
                    SELECT @Counter = @Counter + @Instr2Int - 1 --Correct for future increment
                    WHERE @Instr = 'jnz' AND @Instr1Int <> 0
            END
        END
    END



    IF @Instr = 'tgl'
    BEGIN

        --PRINT @Instr + ' ' + @Instr1 + ' ' + ISNULL(@Instr2, '-') + ' ' + CAST(@Counter AS VARCHAR(20))
        
        UPDATE ##Instructions
        SET Instruction = CASE WHEN Instruction = 'inc' THEN 'dec'
                               WHEN Instruction IN ('dec', 'tgl') THEN 'inc'
                               WHEN Instruction = 'jnz' THEN 'cpy'
                               ELSE 'jnz'
                          END
        WHERE @Instr = 'tgl' 
          AND @Instr1Int <> 0 --Only toggle if it is not the instruction itself
          AND InstrNr = @Counter + @Instr1Int

    END

    IF @Instr = 'out' (SELECT RegValue FROM ##Registers WHERE RegName = 'B')
    
    SET @Counter = @Counter + 1
    IF NOT EXISTS (SELECT 1 FROM ##Instructions WHERE InstrNr = @Counter) SET @ProgramDone = 1

    --SELECT @Counter, * FROM ##Registers
--    PRINT @Counter
--PRINT @Instr + ' ' + @Instr1 + ' ' + ISNULL(@Instr2, '-') + ' ' + CAST(@Counter AS VARCHAR(20))

    SET @TempCounter = @TempCounter + 1

END

--SELECT * FROM ##Registers
SELECT @TempCounter, @Counter, @Instr, @Instr1, @Instr2, * FROM ##Registers
SELECT * FROM ##Instructions

/*

DROP TABLE ##Input
DROP TABLE ##Instructions
DROP TABLE ##Registers

*/


--Dus hij berekent 7*365 = 2555 + de startwaarde x die we zoeken        -- 1 t/m 10

-- Deel door 2 (rounding down) en sla op in a
--Dus ik ben op zoek naar een sequence die als je deelt door twee steeds wisselend wel / niet een rest heeft

-- 0,1,2,5,10,21

DECLARE @Nr INT = 0

WHILE @Nr < 2555
BEGIN

    IF @Nr % 2 = 0
        SET @Nr = @Nr * 2 + 1
    ELSE
        SET @Nr = @Nr * 2

    PRINT @Nr

END

SELECT @Nr - 2555