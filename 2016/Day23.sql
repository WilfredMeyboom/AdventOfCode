use Test_WME

SET NOCOUNT ON

CREATE TABLE ##Input (Line NVARCHAR(MAX));

BULK INSERT ##Input
FROM 'D:\Wilfred\AdventOfCode\2016\input23.txt'
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

--INSERT ##Registers (RegName, RegValue) VALUES ('A', 7), ('B', 0), ('C', 0), ('D', 0) --Part 1
INSERT ##Registers (RegName, RegValue) VALUES ('A', 7), ('B', 0), ('C', 0), ('D', 0) --Part 2

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

    IF (SELECT RegValue FROM ##Registers WHERE RegName = 'A') > 5000
        SELECT @TempCounter, @Counter, @Instr, @Instr1, @Instr2, * FROM ##Registers
    
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

Voor 7:
@TempCounter, @Counter,                 @Registers
63398	      27	    jnz	c	-5	1	A	13776
63398	      27	    jnz	c	-5	2	B	1
63398	      27	    jnz	c	-5	3	C	0
63398	      27	    jnz	c	-5	4	D	0

*/

-- 9 is incorrect for part 1
-- 2 is incorrect for part 1
--42 is incorrect for part 1
--13776 is correct for part 1


DECLARE @A INT, @B INT, @C INT, @D INT

SET @A = 12


--Tot aan de succesvolle toggle

;WITH CTE_1 AS(
    SELECT VAL = 1
    ,      NUM = @A
    UNION ALL
    SELECT VAL=VAL*NUM
    ,      NUM = (NUM -1)
    FROM CTE_1
    WHERE NUM > 1
)                  
SELECT MAX(VAL) + 96*91 FROM CTE_1



/*
1	cpy	a 	b             1	1	cpy	a 	b
2	dec	b	NULL          2	2	dec	b	NULL
3	cpy	a 	d             3	3	cpy	a 	d
4	cpy	0 	a             4	4	cpy	0 	a
5	cpy	b 	c             5	5	cpy	b 	c
6	inc	a	NULL          6	6	inc	a	NULL
7	dec	c	NULL          7	7	dec	c	NULL
8	jnz	c 	-2            8	8	jnz	c 	-2
9	dec	d	NULL          9	9	dec	d	NULL
10	jnz	d 	-5            10	10	jnz	d 	-5
11	dec	b	NULL          11	11	dec	b	NULL
12	cpy	b 	c             12	12	cpy	b 	c
13	cpy	c 	d             13	13	cpy	c 	d
14	dec	d	NULL          14	14	dec	d	NULL
15	inc	c	NULL          15	15	inc	c	NULL
16	jnz	d 	-2            16	16	jnz	d 	-2
17	tgl		c             17	17	tgl	c	NULL
18	cpy	-16 	c             18	18	cpy	-16 	c
19	jnz	1 	c             19	19	cpy	1 	c     ---
20	cpy	96 	c             20	20	cpy	96 	c
21	jnz	91 	d             21	21	cpy	91 	d     ---
22	inc	a	NULL          22	22	inc	a	NULL
23	inc	d	NULL          23	23	dec	d	NULL  ---
24	jnz	d 	-2            24	24	jnz	d 	-2
25	inc	c	NULL          25	25	dec	c	NULL  ---
26	jnz	c 	-5            26	26	jnz	c 	-5                           
                                                       
                                                       
                                                       

*/

-- 479010336 is correct for part 2