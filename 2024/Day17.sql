USE Test_WME

SET NOCOUNT ON

DECLARE @year VARCHAR(4) = '2024'
DECLARE @day VARCHAR(2)  = '17'

EXEC dbo.GetInput @year = @year, @day = @day
EXEC dbo.ParseInput @year = @year, @day = @day 

--SELECT TOP 10 * FROM ##Input
--SELECT TOP 10 * FROM ##InputInts
--SELECT TOP 10 * FROM ##InputNumbered
--SELECT TOP 10 * FROM ##InputGrid
--SELECT TOP 10 * FROM ##InputSplit
--SELECT TOP 10 * FROM ##InputSplitCust

SELECT ROW_NUMBER() OVER (ORDER BY (SELECT 0)) - 1 AS InstrNr, CAST(Piece AS INT) Op
INTO Program
FROM ##InputSplit WHERE RowNr = 5 AND PieceNr > 1

/*
    If register C contains 9, the program 2,6 would set register B to 1.
    If register A contains 10, the program 5,0,5,1,5,4 would output 0,1,2.
    If register A contains 2024, the program 0,1,5,4,3,0 would output 4,2,5,6,7,7,7,7,3,1,0 and leave 0 in register A.
    If register B contains 29, the program 1,7 would set register B to 26.
    If register B contains 2024 and register C contains 43690, the program 4,0 would set register B to 44354.

--SET @RegB = 2024
--SET @RegC = 43690
--DELETE FROM Program
--INSERT Program VALUES (0,0),(1,1),(2,5),(3,4),(4,3),(5,0)

*/

DECLARE @StartingRegA VARCHAR(MAX)
SELECT @StartingRegA = Piece FROM ##InputSplit WHERE RowNr = 1 AND PieceNr = 3

SELECT dbo.Day17_Program(@StartingRegA) AS Part1

--7,4,2,5,1,4,6,0,4 for part 1

CREATE TABLE ##Results (ID INT IDENTITY(1,1), RegA BIGINT, Results VARCHAR(MAX), Sol INT)
CREATE TABLE ##Coefficients (ID INT IDENTITY(1,1), Sol INT, Pos INT, Coeff INT)

INSERT ##Coefficients (Sol, Pos, Coeff) VALUES (1,1,4)

DECLARE @Cnt INT = 2
DECLARE @Sol INT
DECLARE @MaxSol INT
DECLARE @BackupSol INT
DECLARE @NewCoeff BIGINT

WHILE NOT EXISTS (SELECT 1 FROM ##Results WHERE Results = '2,4,1,1,7,5,1,5,4,1,5,5,0,3,3,0' )
AND EXISTS (SELECT 1 FROM ##Coefficients)
BEGIN
    
    INSERT ##Results (Sol, RegA)
    SELECT Sol, SUM(POWER(CAST(8 AS BIGINT),@Cnt-Pos) * Coeff) + RN
    FROM ##Coefficients C
    CROSS APPLY (SELECT TOP(10) ROW_NUMBER() OVER (ORDER BY (SELECT 0)) - 1 AS RN FROM sys.messages) S
    GROUP BY Sol, RN

    UPDATE ##Results
    SET Results = dbo.Day17_Program(RegA)
    WHERE Results IS NULL 

    DELETE FROM ##Results WHERE '2,4,1,1,7,5,1,5,4,1,5,5,0,3,3,0' NOT LIKE '%' + Results 

    SELECT @MaxSol = MAX(Sol) FROM ##Coefficients
    SET @BackupSol = @MaxSol

    DECLARE CoeffCursor CURSOR FOR
        SELECT C.Sol, R.RegA - SUM(POWER(CAST(8 AS BIGINT),@Cnt-Pos) * Coeff) AS NewCoeff
        FROM ##Coefficients C
        INNER JOIN ##Results R ON C.Sol = R.Sol
        GROUP BY C.Sol, R.RegA

    OPEN CoeffCursor

    FETCH NEXT FROM CoeffCursor INTO @Sol, @NewCoeff

    WHILE @@FETCH_STATUS = 0
    BEGIN
       
        SET @MaxSol = @MaxSol + 1
       
        INSERT ##Coefficients
        SELECT @MaxSol, Pos, Coeff
        FROM ##Coefficients
        WHERE Sol = @Sol
        UNION
        SELECT @MaxSol, @Cnt, @NewCoeff

        FETCH NEXT FROM CoeffCursor INTO @Sol, @NewCoeff

    END

    CLOSE CoeffCursor
    DEALLOCATE CoeffCursor

    DELETE FROM ##Coefficients WHERE Sol <= @BackupSol

    SET @Cnt = @Cnt + 1

    SELECT * FROM ##Coefficients

END

SELECT MIN(RegA) AS Part2 FROM ##Results WHERE Results = '2,4,1,1,7,5,1,5,4,1,5,5,0,3,3,0' 

--DROP TABLE ##Coefficients
--DROP TABLE ##Results
--DROP TABLE Program

/*

4      0           SELECT 4                                       4
37     3,0         SELECT 8*4 + 5                                 4,5
39     3,0         SELECT 8*4 + 7                                 4,7
298    3,3,0       SELECT 8^2*4 + 8*5 + 2                         4,5,2
301    3,3,0       SELECT 8^2*4 + 8*5 + 5                         4,5,5
2390   0,3,3,0     SELECT 8^3*4 + 8^2*5 + 8*2 + 6                 4,5,2,6
2408   0,3,3,0     SELECT 8^3*4 + 8^2*5 + 8*5 + 0                 4,5,5,0  
2414   0,3,3,0     SELECT 8^3*4 + 8^2*5 + 8*5 + 6                 4,5,5,6
19124  5,0,3,3,0   SELECT 8^4*4 + 8^3*5 + 8^2*2 + 8*6 + 4         4,5,2,6,4
19269  5,0,3,3,0   SELECT 8^4*4 + 8^3*5 + 8^2*5 + 8*0 + 5         4,5,5,0,5
152996 5,5,0,3,3,0 SELECT 8^5*4 + 8^4*5 + 8^3*2 + 8^2*6 + 8*4 + 4 4,5,2,6,4,4
152999 5,5,0,3,3,0 SELECT 8^5*4 + 8^4*5 + 8^3*2 + 8^2*6 + 8*4 + 7 4,5,2,6,4,7
154155 5,5,0,3,3,0 SELECT 8^5*4 + 8^4*5 + 8^3*5 + 8^2*0 + 8*5 + 3 4,5,5,0,5,3

SELECT POWER(8,2), POWER(8,3), POWER(8,4),POWER(8,5), POWER(8,6)

4      0           SELECT 4                                       4
37     3,0         SELECT 8*4 + 5                                 4,5
298    3,3,0       SELECT 8^2*4 + 8*5 + 2                         4,5,2
301    3,3,0       SELECT 8^2*4 + 8*5 + 5                         4,5,5
2390   0,3,3,0     SELECT 8^3*4 + 8^2*5 + 8*2 + 6                 4,5,2,6
2408   0,3,3,0     SELECT 8^3*4 + 8^2*5 + 8*5 + 0                 4,5,5,0  
19124  5,0,3,3,0   SELECT 8^4*4 + 8^3*5 + 8^2*2 + 8*6 + 4         4,5,2,6,4
19269  5,0,3,3,0   SELECT 8^4*4 + 8^3*5 + 8^2*5 + 8*0 + 5         4,5,5,0,5
152996 5,5,0,3,3,0 SELECT 8^5*4 + 8^4*5 + 8^3*2 + 8^2*6 + 8*4 + 4 4,5,2,6,4,4
152999 5,5,0,3,3,0 SELECT 8^5*4 + 8^4*5 + 8^3*2 + 8^2*6 + 8*4 + 7 4,5,2,6,4,7
154155 5,5,0,3,3,0 SELECT 8^5*4 + 8^4*5 + 8^3*5 + 8^2*0 + 8*5 + 3 4,5,5,0,5,3

1223972 SELECT POWER(8,6)*4 + POWER(8,5)*5 + POWER(8,4)*2 + POWER(8,3)*6 + POWER(8,2)*4 + 8*4 + 4
1223994 SELECT POWER(8,6)*4 + POWER(8,5)*5 + POWER(8,4)*2 + POWER(8,3)*6 + POWER(8,2)*4 + 8*7 + 2
1223995 SELECT POWER(8,6)*4 + POWER(8,5)*5 + POWER(8,4)*2 + POWER(8,3)*6 + POWER(8,2)*4 + 8*7 + 3
1223996 SELECT POWER(8,6)*4 + POWER(8,5)*5 + POWER(8,4)*2 + POWER(8,3)*6 + POWER(8,2)*4 + 8*7 + 4
1233243 SELECT POWER(8,6)*4 + POWER(8,5)*5 + POWER(8,4)*5 + POWER(8,3)*0 + POWER(8,2)*5 + 8*3 + 3
*/

/*
INSERT ##Results (RegA)
SELECT POWER(8,6)*4 + POWER(8,5)*5 + POWER(8,4)*5 + POWER(8,3)*0 + POWER(8,2)*5 + 8*3 + RN--, RN
FROM (SELECT TOP(10) ROW_NUMBER() OVER (ORDER BY (SELECT 0)) - 1 AS RN FROM sys.messages) S

INSERT ##Results (RegA)
SELECT POWER(8,6)*4 + POWER(8,5)*5 + POWER(8,4)*2 + POWER(8,3)*6 + POWER(8,2)*4 + 8*7 + RN--, RN
FROM (SELECT TOP(10) ROW_NUMBER() OVER (ORDER BY (SELECT 0)) - 1 AS RN FROM sys.messages) S

INSERT ##Results (RegA)
SELECT POWER(8,6)*4 + POWER(8,5)*5 + POWER(8,4)*2 + POWER(8,3)*6 + POWER(8,2)*4 + 8*4 + RN--, RN
FROM (SELECT TOP(10) ROW_NUMBER() OVER (ORDER BY (SELECT 0)) - 1 AS RN FROM sys.messages) S

INSERT ##Results (RegA)
SELECT POWER(8,7)*4 + POWER(8,6)*5 + POWER(8,5)*5 + POWER(8,4)*0 + POWER(8,3)*5 + 8*8*3 + 8*3 + RN FROM (SELECT TOP(10) ROW_NUMBER() OVER (ORDER BY (SELECT 0)) - 1 AS RN FROM sys.messages) S
INSERT ##Results (RegA)
SELECT POWER(8,7)*4 + POWER(8,6)*5 + POWER(8,5)*2 + POWER(8,4)*6 + POWER(8,3)*4 + 8*8*4 + 8*4 + RN FROM (SELECT TOP(10) ROW_NUMBER() OVER (ORDER BY (SELECT 0)) - 1 AS RN FROM sys.messages) S
INSERT ##Results (RegA)
SELECT POWER(8,7)*4 + POWER(8,6)*5 + POWER(8,5)*2 + POWER(8,4)*6 + POWER(8,3)*4 + 8*8*7 + 8*2 + RN FROM (SELECT TOP(10) ROW_NUMBER() OVER (ORDER BY (SELECT 0)) - 1 AS RN FROM sys.messages) S
INSERT ##Results (RegA)
SELECT POWER(8,7)*4 + POWER(8,6)*5 + POWER(8,5)*2 + POWER(8,4)*6 + POWER(8,3)*4 + 8*8*7 + 8*3 + RN FROM (SELECT TOP(10) ROW_NUMBER() OVER (ORDER BY (SELECT 0)) - 1 AS RN FROM sys.messages) S
INSERT ##Results (RegA)
SELECT POWER(8,7)*4 + POWER(8,6)*5 + POWER(8,5)*2 + POWER(8,4)*6 + POWER(8,3)*4 + 8*8*7 + 8*4 + RN FROM (SELECT TOP(10) ROW_NUMBER() OVER (ORDER BY (SELECT 0)) - 1 AS RN FROM sys.messages) S


UPDATE ##Results
SET Results = dbo.Day17_Program(RegA)
WHERE Results IS NULL 

SELECT * FROM ##Results WHERE '2,4,1,1,7,5,1,5,4,1,5,5,0,3,3,0' LIKE '%' + Results ORDER BY RegA

-- Target: Program: 2,4,1,1,7,5,1,5,4,1,5,5,0,3,3,0


--DROP TABLE Program

*/

/*

GO
CREATE OR ALTER FUNCTION Day17_Program (@RegisterA BIGINT)
RETURNS VARCHAR(MAX)
AS
BEGIN

    DECLARE @RegA BIGINT = @RegisterA
    DECLARE @RegB BIGINT
    DECLARE @RegC BIGINT
    DECLARE @InstrPointer INT = 0
    DECLARE @Instr INT
    DECLARE @Operand INT
    DECLARE @Nr1 INT
    DECLARE @Nr2 BIGINT
    DECLARE @Output VARCHAR(MAX) = ''

    WHILE EXISTS (SELECT 1 FROM Program WHERE InstrNr = @InstrPointer)
    BEGIN

        SELECT TOP 1 @Instr = Op, @Operand = LEAD(Op) OVER (ORDER BY InstrNr) FROM Program WHERE InstrNr IN (@InstrPointer, @InstrPointer + 1)

        IF @Operand < 4 
            SET @Nr2 = @Operand
        ELSE
        BEGIN
            IF @Operand = 4 SET @Nr2 = @RegA
            IF @Operand = 5 SET @Nr2 = @RegB
            IF @Operand = 6 SET @Nr2 = @RegC
            --IF @Operand = 7 PRINT 'MAJOR ERROR'
        END

        --PRINT 'InstrPointer: ' + CAST(@InstrPointer AS VARCHAR(3)) + ' Instr: ' + CAST(@Instr AS VARCHAR(2)) + ' Operand: ' + CAST(@Operand AS VARCHAR(2))
        --PRINT 'RegA: ' + ISNULL(CAST(@RegA AS VARCHAR(20)),'N/A') + 
        -- ' RegB: ' + ISNULL(CAST(@RegB AS VARCHAR(20)),'N/A') + 
        -- ' RegC: ' + ISNULL(CAST(@RegC AS VARCHAR(20)),'N/A') 
        -- PRINT '----------------------------------------'

        --adv -> Nr1 / Nr2
        IF @Instr = 0
        BEGIN        
            SET @Nr2 = CAST(POWER(2,@Nr2) AS BIGINT)
            SET @RegA = @RegA / @Nr2
        END

        --bxl
        IF @Instr = 1
        BEGIN
            SET @RegB = @RegB ^ @Operand
        END

        --bst
        IF @Instr = 2
        BEGIN
            SET @RegB = @Nr2 % 8
        END

        --jnz
        IF @Instr = 3
        BEGIN
            IF @RegA <> 0 SET @InstrPointer = @Operand - 2
        END

        --bxc
        IF @Instr = 4
        BEGIN
            SET @RegB = @RegB ^ @RegC
        END

        --out
        IF @Instr = 5
        BEGIN
            SET @Output = @Output + CAST(@Nr2 % 8 AS VARCHAR(MAX)) + ','
            --PRINT @Nr2 % 8
        END

        --bdv
        IF @Instr = 6
        BEGIN
            SET @Nr2 = CAST(POWER(2,@Nr2) AS BIGINT)
            SET @RegB = @RegA / @Nr2
        END

        --cdv
        IF @Instr = 7
        BEGIN
            SET @Nr2 = CAST(POWER(2,@Nr2) AS BIGINT)
            SET @RegC = @RegA / @Nr2
        END

        SET @InstrPointer = @InstrPointer + 2
    END

--PRINT 'RegA: ' + ISNULL(CAST(@RegA AS VARCHAR(20)),'N/A') + 
--     ' RegB: ' + ISNULL(CAST(@RegB AS VARCHAR(20)),'N/A') + 
--     ' RegC: ' + ISNULL(CAST(@RegC AS VARCHAR(20)),'N/A')

--PRINT 'Reg A at start: ' + @StartingRegA
--PRINT 'Output: ' + @Output

    RETURN LEFT(@Output, LEN(@Output)-1)

END

*/