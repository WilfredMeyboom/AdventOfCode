use Test_WME

SET NOCOUNT ON

CREATE TABLE ##Input16 (Name NVARCHAR(MAX));

BULK INSERT ##Input16
FROM 'D:\Wilfred\AdventOfCode\input16.txt'
WITH (ROWTERMINATOR = '0x0A');


--SELECT COUNT(1) FROM ##Input16 WHERE Name LIKE '%After%' --838

--;WITH cte_Cutoff AS (
--SELECT TOP 2514 * FROM ##Input16 WHERE Name IS NOT NULL
--)
--SELECT COUNT(1)
--FROM cte_Cutoff
--WHERE Name LIKE '%After%' --838


CREATE TABLE ##Sample (ID INT IDENTITY(1,1), Nr INT PRIMARY KEY, R0Bef INT, R1Bef INT, R2Bef INT, R3Bef INT, Opcode INT, InstrA INT, InstrB INT, InstrC INT, R0Aft INT, R1Aft INT, R2Aft INT, R3Aft INT)

DECLARE @Nr INT = 1
DECLARE @Str VARCHAR(20)

DECLARE SampleCursor CURSOR FOR SELECT TOP 2514 * FROM ##Input16 WHERE Name IS NOT NULL

OPEN SampleCursor

FETCH NEXT FROM SampleCursor INTO @Str

WHILE @@FETCH_STATUS = 0
BEGIN
    
    IF EXISTS (SELECT 1 WHERE @Str LIKE '%Before%')
    BEGIN

       SELECT @Str = REPLACE(REPLACE( @Str, 'Before: [',''), ']','')

       INSERT ##Sample (Nr, R0Bef, R1Bef, R2Bef, R3Bef)
       SELECT @Nr
       ,      SUBSTRING(@Str, 1, 1)
       ,      SUBSTRING(@Str, 4, 1)
       ,      SUBSTRING(@Str, 7, 1)
       ,      SUBSTRING(@Str, 10, 1)

    END
    ELSE IF EXISTS (SELECT 1 WHERE @Str LIKE '%After%')
    BEGIN

       SELECT @Str = REPLACE(REPLACE( @Str, 'After:  [',''), ']','')

       UPDATE ##Sample 
       SET R0Aft = SUBSTRING(@Str, 1, 1)
       ,   R1Aft = SUBSTRING(@Str, 4, 1)
       ,   R2Aft = SUBSTRING(@Str, 7, 1)
       ,   R3Aft = SUBSTRING(@Str, 10, 1)
       WHERE Nr = @Nr

       SET @Nr = @Nr + 1

    END
    ELSE
    BEGIN

        UPDATE ##Sample
        SET Opcode = SUBSTRING(@Str, 1, CHARINDEX(' ', @Str, 0))
        ,   InstrA = SUBSTRING(@Str, CHARINDEX(' ', @Str, 0) + 1, 1)
        ,   InstrB = SUBSTRING(@Str, CHARINDEX(' ', @Str, 0) + 3, 1)
        ,   InstrC = SUBSTRING(@Str, CHARINDEX(' ', @Str, 0) + 5, 1)
        WHERE Nr = @Nr

    END

    FETCH NEXT FROM SampleCursor INTO @Str

END

CLOSE SampleCursor
DEALLOCATE SampleCursor

--------------------------------------------------------------------------------------------------------------------------------

CREATE TABLE ##Results (ID INT IDENTITY(1,1), Nr INT, OpCode VARCHAR(5), R0Aft INT, R1Aft INT, R2Aft INT, R3Aft INT)


INSERT ##Results (Nr, OpCode, R0Aft, R1Aft, R2Aft, R3Aft)
SELECT S.Nr
,      Opc.OpCode
,      CASE WHEN Opc.DestReg = 0 THEN Opc.Result ELSE S.R0Aft END AS R0Aft 
,      CASE WHEN Opc.DestReg = 1 THEN Opc.Result ELSE S.R1Aft END AS R1Aft 
,      CASE WHEN Opc.DestReg = 2 THEN Opc.Result ELSE S.R2Aft END AS R2Aft 
,      CASE WHEN Opc.DestReg = 3 THEN Opc.Result ELSE S.R3Aft END AS R3Aft 

FROM ##Sample S
INNER JOIN (
    SELECT 'addr' AS OpCode
    ,      Nr
    ,      InstrC AS DestReg
    ,      CASE WHEN InstrA = 0 THEN R0Bef
                WHEN InstrA = 1 THEN R1Bef
                WHEN InstrA = 2 THEN R2Bef
                WHEN InstrA = 3 THEN R3Bef
           END
           +
           CASE WHEN InstrB = 0 THEN R0Bef
                WHEN InstrB = 1 THEN R1Bef
                WHEN InstrB = 2 THEN R2Bef
                WHEN InstrB = 3 THEN R3Bef
           END AS Result
    FROM ##Sample
    ) Opc ON S.Nr = Opc.Nr

UNION

SELECT S.Nr
,      Opc.OpCode
,      CASE WHEN Opc.DestReg = 0 THEN Opc.Result ELSE S.R0Aft END AS R0Aft 
,      CASE WHEN Opc.DestReg = 1 THEN Opc.Result ELSE S.R1Aft END AS R1Aft 
,      CASE WHEN Opc.DestReg = 2 THEN Opc.Result ELSE S.R2Aft END AS R2Aft 
,      CASE WHEN Opc.DestReg = 3 THEN Opc.Result ELSE S.R3Aft END AS R3Aft 

FROM ##Sample S
INNER JOIN (
    SELECT 'addi' AS OpCode
    ,      Nr
    ,      InstrC AS DestReg
    ,      CASE WHEN InstrA = 0 THEN R0Bef
                WHEN InstrA = 1 THEN R1Bef
                WHEN InstrA = 2 THEN R2Bef
                WHEN InstrA = 3 THEN R3Bef
           END
           + InstrB
           AS Result
    FROM ##Sample
    ) Opc ON S.Nr = Opc.Nr

UNION

SELECT S.Nr
,      Opc.OpCode
,      CASE WHEN Opc.DestReg = 0 THEN Opc.Result ELSE S.R0Aft END AS R0Aft 
,      CASE WHEN Opc.DestReg = 1 THEN Opc.Result ELSE S.R1Aft END AS R1Aft 
,      CASE WHEN Opc.DestReg = 2 THEN Opc.Result ELSE S.R2Aft END AS R2Aft 
,      CASE WHEN Opc.DestReg = 3 THEN Opc.Result ELSE S.R3Aft END AS R3Aft 

FROM ##Sample S
INNER JOIN (
    SELECT 'mulr' AS OpCode
    ,      Nr
    ,      InstrC AS DestReg
    ,      CASE WHEN InstrA = 0 THEN R0Bef
                WHEN InstrA = 1 THEN R1Bef
                WHEN InstrA = 2 THEN R2Bef
                WHEN InstrA = 3 THEN R3Bef
           END
           *
           CASE WHEN InstrB = 0 THEN R0Bef
                WHEN InstrB = 1 THEN R1Bef
                WHEN InstrB = 2 THEN R2Bef
                WHEN InstrB = 3 THEN R3Bef
           END AS Result
    FROM ##Sample
    ) Opc ON S.Nr = Opc.Nr

UNION

SELECT S.Nr
,      Opc.OpCode
,      CASE WHEN Opc.DestReg = 0 THEN Opc.Result ELSE S.R0Aft END AS R0Aft 
,      CASE WHEN Opc.DestReg = 1 THEN Opc.Result ELSE S.R1Aft END AS R1Aft 
,      CASE WHEN Opc.DestReg = 2 THEN Opc.Result ELSE S.R2Aft END AS R2Aft 
,      CASE WHEN Opc.DestReg = 3 THEN Opc.Result ELSE S.R3Aft END AS R3Aft 

FROM ##Sample S
INNER JOIN (
    SELECT 'muli' AS OpCode
    ,      Nr
    ,      InstrC AS DestReg
    ,      CASE WHEN InstrA = 0 THEN R0Bef
                WHEN InstrA = 1 THEN R1Bef
                WHEN InstrA = 2 THEN R2Bef
                WHEN InstrA = 3 THEN R3Bef
           END
           * InstrB
           AS Result
    FROM ##Sample
    ) Opc ON S.Nr = Opc.Nr

UNION

SELECT S.Nr
,      Opc.OpCode
,      CASE WHEN Opc.DestReg = 0 THEN Opc.Result ELSE S.R0Aft END AS R0Aft 
,      CASE WHEN Opc.DestReg = 1 THEN Opc.Result ELSE S.R1Aft END AS R1Aft 
,      CASE WHEN Opc.DestReg = 2 THEN Opc.Result ELSE S.R2Aft END AS R2Aft 
,      CASE WHEN Opc.DestReg = 3 THEN Opc.Result ELSE S.R3Aft END AS R3Aft 

FROM ##Sample S
INNER JOIN (
    SELECT 'banr' AS OpCode
    ,      Nr
    ,      InstrC AS DestReg
    ,      CASE WHEN InstrA = 0 THEN R0Bef
                WHEN InstrA = 1 THEN R1Bef
                WHEN InstrA = 2 THEN R2Bef
                WHEN InstrA = 3 THEN R3Bef
           END
           &
           CASE WHEN InstrB = 0 THEN R0Bef
                WHEN InstrB = 1 THEN R1Bef
                WHEN InstrB = 2 THEN R2Bef
                WHEN InstrB = 3 THEN R3Bef
           END AS Result
    FROM ##Sample
    ) Opc ON S.Nr = Opc.Nr

UNION

SELECT S.Nr
,      Opc.OpCode
,      CASE WHEN Opc.DestReg = 0 THEN Opc.Result ELSE S.R0Aft END AS R0Aft 
,      CASE WHEN Opc.DestReg = 1 THEN Opc.Result ELSE S.R1Aft END AS R1Aft 
,      CASE WHEN Opc.DestReg = 2 THEN Opc.Result ELSE S.R2Aft END AS R2Aft 
,      CASE WHEN Opc.DestReg = 3 THEN Opc.Result ELSE S.R3Aft END AS R3Aft 

FROM ##Sample S
INNER JOIN (
    SELECT 'bani' AS OpCode
    ,      Nr
    ,      InstrC AS DestReg
    ,      CASE WHEN InstrA = 0 THEN R0Bef
                WHEN InstrA = 1 THEN R1Bef
                WHEN InstrA = 2 THEN R2Bef
                WHEN InstrA = 3 THEN R3Bef
           END
           & InstrB
           AS Result
    FROM ##Sample
    ) Opc ON S.Nr = Opc.Nr


UNION

SELECT S.Nr
,      Opc.OpCode
,      CASE WHEN Opc.DestReg = 0 THEN Opc.Result ELSE S.R0Aft END AS R0Aft 
,      CASE WHEN Opc.DestReg = 1 THEN Opc.Result ELSE S.R1Aft END AS R1Aft 
,      CASE WHEN Opc.DestReg = 2 THEN Opc.Result ELSE S.R2Aft END AS R2Aft 
,      CASE WHEN Opc.DestReg = 3 THEN Opc.Result ELSE S.R3Aft END AS R3Aft 

FROM ##Sample S
INNER JOIN (
    SELECT 'borr' AS OpCode
    ,      Nr
    ,      InstrC AS DestReg
    ,      CASE WHEN InstrA = 0 THEN R0Bef
                WHEN InstrA = 1 THEN R1Bef
                WHEN InstrA = 2 THEN R2Bef
                WHEN InstrA = 3 THEN R3Bef
           END
           |
           CASE WHEN InstrB = 0 THEN R0Bef
                WHEN InstrB = 1 THEN R1Bef
                WHEN InstrB = 2 THEN R2Bef
                WHEN InstrB = 3 THEN R3Bef
           END AS Result
    FROM ##Sample
    ) Opc ON S.Nr = Opc.Nr

UNION

SELECT S.Nr
,      Opc.OpCode
,      CASE WHEN Opc.DestReg = 0 THEN Opc.Result ELSE S.R0Aft END AS R0Aft 
,      CASE WHEN Opc.DestReg = 1 THEN Opc.Result ELSE S.R1Aft END AS R1Aft 
,      CASE WHEN Opc.DestReg = 2 THEN Opc.Result ELSE S.R2Aft END AS R2Aft 
,      CASE WHEN Opc.DestReg = 3 THEN Opc.Result ELSE S.R3Aft END AS R3Aft 

FROM ##Sample S
INNER JOIN (
    SELECT 'bori' AS OpCode
    ,      Nr
    ,      InstrC AS DestReg
    ,      CASE WHEN InstrA = 0 THEN R0Bef
                WHEN InstrA = 1 THEN R1Bef
                WHEN InstrA = 2 THEN R2Bef
                WHEN InstrA = 3 THEN R3Bef
           END
           | InstrB
           AS Result
    FROM ##Sample
    ) Opc ON S.Nr = Opc.Nr

UNION

SELECT S.Nr
,      Opc.OpCode
,      CASE WHEN Opc.DestReg = 0 THEN Opc.Result ELSE S.R0Aft END AS R0Aft 
,      CASE WHEN Opc.DestReg = 1 THEN Opc.Result ELSE S.R1Aft END AS R1Aft 
,      CASE WHEN Opc.DestReg = 2 THEN Opc.Result ELSE S.R2Aft END AS R2Aft 
,      CASE WHEN Opc.DestReg = 3 THEN Opc.Result ELSE S.R3Aft END AS R3Aft 

FROM ##Sample S
INNER JOIN (
    SELECT 'setr' AS OpCode
    ,      Nr
    ,      InstrC AS DestReg
    ,      CASE WHEN InstrA = 0 THEN R0Bef
                WHEN InstrA = 1 THEN R1Bef
                WHEN InstrA = 2 THEN R2Bef
                WHEN InstrA = 3 THEN R3Bef
           END AS Result
    FROM ##Sample
    ) Opc ON S.Nr = Opc.Nr

UNION

SELECT S.Nr
,      Opc.OpCode
,      CASE WHEN Opc.DestReg = 0 THEN Opc.Result ELSE S.R0Aft END AS R0Aft 
,      CASE WHEN Opc.DestReg = 1 THEN Opc.Result ELSE S.R1Aft END AS R1Aft 
,      CASE WHEN Opc.DestReg = 2 THEN Opc.Result ELSE S.R2Aft END AS R2Aft 
,      CASE WHEN Opc.DestReg = 3 THEN Opc.Result ELSE S.R3Aft END AS R3Aft 

FROM ##Sample S
INNER JOIN (
    SELECT 'seti' AS OpCode
    ,      Nr
    ,      InstrC AS DestReg
    ,      InstrA AS Result
    FROM ##Sample
    ) Opc ON S.Nr = Opc.Nr

UNION

SELECT S.Nr
,      Opc.OpCode
,      CASE WHEN Opc.DestReg = 0 THEN Opc.Result ELSE S.R0Aft END AS R0Aft 
,      CASE WHEN Opc.DestReg = 1 THEN Opc.Result ELSE S.R1Aft END AS R1Aft 
,      CASE WHEN Opc.DestReg = 2 THEN Opc.Result ELSE S.R2Aft END AS R2Aft 
,      CASE WHEN Opc.DestReg = 3 THEN Opc.Result ELSE S.R3Aft END AS R3Aft 

FROM ##Sample S
INNER JOIN (
    SELECT 'gtir' AS OpCode
    ,      Nr
    ,      InstrC AS DestReg
    ,      CASE WHEN 
               InstrA >
               CASE WHEN InstrB = 0 THEN R0Bef
                    WHEN InstrB = 1 THEN R1Bef
                    WHEN InstrB = 2 THEN R2Bef
                    WHEN InstrB = 3 THEN R3Bef
               END 
           THEN 1 ELSE 0 END AS Result
    FROM ##Sample
    ) Opc ON S.Nr = Opc.Nr

UNION

SELECT S.Nr
,      Opc.OpCode
,      CASE WHEN Opc.DestReg = 0 THEN Opc.Result ELSE S.R0Aft END AS R0Aft 
,      CASE WHEN Opc.DestReg = 1 THEN Opc.Result ELSE S.R1Aft END AS R1Aft 
,      CASE WHEN Opc.DestReg = 2 THEN Opc.Result ELSE S.R2Aft END AS R2Aft 
,      CASE WHEN Opc.DestReg = 3 THEN Opc.Result ELSE S.R3Aft END AS R3Aft 

FROM ##Sample S
INNER JOIN (
    SELECT 'gtri' AS OpCode
    ,      Nr
    ,      InstrC AS DestReg
    ,      CASE WHEN 
               CASE WHEN InstrA = 0 THEN R0Bef
                    WHEN InstrA = 1 THEN R1Bef
                    WHEN InstrA = 2 THEN R2Bef
                    WHEN InstrA = 3 THEN R3Bef
               END
               > InstrB 
           THEN 1 ELSE 0 END AS Result
    FROM ##Sample
    ) Opc ON S.Nr = Opc.Nr

UNION

SELECT S.Nr
,      Opc.OpCode
,      CASE WHEN Opc.DestReg = 0 THEN Opc.Result ELSE S.R0Aft END AS R0Aft 
,      CASE WHEN Opc.DestReg = 1 THEN Opc.Result ELSE S.R1Aft END AS R1Aft 
,      CASE WHEN Opc.DestReg = 2 THEN Opc.Result ELSE S.R2Aft END AS R2Aft 
,      CASE WHEN Opc.DestReg = 3 THEN Opc.Result ELSE S.R3Aft END AS R3Aft 

FROM ##Sample S
INNER JOIN (
    SELECT 'gtrr' AS OpCode
    ,      Nr
    ,      InstrC AS DestReg
    ,      CASE WHEN 
               CASE WHEN InstrA = 0 THEN R0Bef
                    WHEN InstrA = 1 THEN R1Bef
                    WHEN InstrA = 2 THEN R2Bef
                    WHEN InstrA = 3 THEN R3Bef
               END
               >
               CASE WHEN InstrB = 0 THEN R0Bef
                    WHEN InstrB = 1 THEN R1Bef
                    WHEN InstrB = 2 THEN R2Bef
                    WHEN InstrB = 3 THEN R3Bef
               END 
           THEN 1 ELSE 0 END AS Result
    FROM ##Sample
    ) Opc ON S.Nr = Opc.Nr

UNION

SELECT S.Nr
,      Opc.OpCode
,      CASE WHEN Opc.DestReg = 0 THEN Opc.Result ELSE S.R0Aft END AS R0Aft 
,      CASE WHEN Opc.DestReg = 1 THEN Opc.Result ELSE S.R1Aft END AS R1Aft 
,      CASE WHEN Opc.DestReg = 2 THEN Opc.Result ELSE S.R2Aft END AS R2Aft 
,      CASE WHEN Opc.DestReg = 3 THEN Opc.Result ELSE S.R3Aft END AS R3Aft 

FROM ##Sample S
INNER JOIN (
    SELECT 'eqir' AS OpCode
    ,      Nr
    ,      InstrC AS DestReg
    ,      CASE WHEN 
               InstrA =
               CASE WHEN InstrB = 0 THEN R0Bef
                    WHEN InstrB = 1 THEN R1Bef
                    WHEN InstrB = 2 THEN R2Bef
                    WHEN InstrB = 3 THEN R3Bef
               END 
           THEN 1 ELSE 0 END AS Result
    FROM ##Sample
    ) Opc ON S.Nr = Opc.Nr

UNION

SELECT S.Nr
,      Opc.OpCode
,      CASE WHEN Opc.DestReg = 0 THEN Opc.Result ELSE S.R0Aft END AS R0Aft 
,      CASE WHEN Opc.DestReg = 1 THEN Opc.Result ELSE S.R1Aft END AS R1Aft 
,      CASE WHEN Opc.DestReg = 2 THEN Opc.Result ELSE S.R2Aft END AS R2Aft 
,      CASE WHEN Opc.DestReg = 3 THEN Opc.Result ELSE S.R3Aft END AS R3Aft 

FROM ##Sample S
INNER JOIN (
    SELECT 'eqri' AS OpCode
    ,      Nr
    ,      InstrC AS DestReg
    ,      CASE WHEN 
               CASE WHEN InstrA = 0 THEN R0Bef
                    WHEN InstrA = 1 THEN R1Bef
                    WHEN InstrA = 2 THEN R2Bef
                    WHEN InstrA = 3 THEN R3Bef
               END
               = InstrB 
           THEN 1 ELSE 0 END AS Result
    FROM ##Sample
    ) Opc ON S.Nr = Opc.Nr

UNION

SELECT S.Nr
,      Opc.OpCode
,      CASE WHEN Opc.DestReg = 0 THEN Opc.Result ELSE S.R0Aft END AS R0Aft 
,      CASE WHEN Opc.DestReg = 1 THEN Opc.Result ELSE S.R1Aft END AS R1Aft 
,      CASE WHEN Opc.DestReg = 2 THEN Opc.Result ELSE S.R2Aft END AS R2Aft 
,      CASE WHEN Opc.DestReg = 3 THEN Opc.Result ELSE S.R3Aft END AS R3Aft 

FROM ##Sample S
INNER JOIN (
    SELECT 'eqrr' AS OpCode
    ,      Nr
    ,      InstrC AS DestReg
    ,      CASE WHEN 
               CASE WHEN InstrA = 0 THEN R0Bef
                    WHEN InstrA = 1 THEN R1Bef
                    WHEN InstrA = 2 THEN R2Bef
                    WHEN InstrA = 3 THEN R3Bef
               END
               =
               CASE WHEN InstrB = 0 THEN R0Bef
                    WHEN InstrB = 1 THEN R1Bef
                    WHEN InstrB = 2 THEN R2Bef
                    WHEN InstrB = 3 THEN R3Bef
               END 
           THEN 1 ELSE 0 END AS Result
    FROM ##Sample
    ) Opc ON S.Nr = Opc.Nr



SELECT S.Nr, COUNT(1)
FROM ##Sample S
INNER JOIN ##Results R ON S.Nr = R.Nr
                      AND S.R0Aft = R.R0Aft
                      AND S.R1Aft = R.R1Aft
                      AND S.R2Aft = R.R2Aft
                      AND S.R3Aft = R.R3Aft
GROUP BY S.Nr
ORDER BY 2 DESC,1


---> 677 :D

---------------------------------------------------------------------------------------------------------------------------------------

CREATE TABLE ##Conversion (Opcode INT, Opname VARCHAR(5))

WHILE @@ROWCOUNT > 0
BEGIN

    ;WITH cte_IdentifiedInstructions AS (
    SELECT S.Nr
    FROM ##Sample S
    INNER JOIN ##Results R ON S.Nr = R.Nr
                          AND S.R0Aft = R.R0Aft
                          AND S.R1Aft = R.R1Aft
                          AND S.R2Aft = R.R2Aft
                          AND S.R3Aft = R.R3Aft
    GROUP BY S.Nr
    HAVING COUNT(1) = 1
    ) 
    INSERT ##Conversion
    SELECT DISTINCT S.Opcode, R.OpCode
    FROM ##Sample S
    INNER JOIN ##Results R ON S.Nr = R.Nr
                          AND S.R0Aft = R.R0Aft
                          AND S.R1Aft = R.R1Aft
                          AND S.R2Aft = R.R2Aft
                          AND S.R3Aft = R.R3Aft
    WHERE S.Nr IN (SELECT Nr FROM cte_IdentifiedInstructions)

    DELETE FROM ##Results
    WHERE OpCode IN (SELECT Opname FROM ##Conversion)

END

--SELECT * FROM ##Conversion
--SELECT * FROM ##Input16
--SELECT * FROM ##Sample

--DELETE TOP (3354) FROM ##Input16

CREATE TABLE ##Program (ID INT IDENTITY(1,1), Opcode INT, Opname VARCHAR(5), InstrA INT, InstrB INT, InstrC INT)

INSERT ##Program
SELECT Opcode = SUBSTRING(Name, 1, CHARINDEX(' ', Name, 0))
,   C.Opname
,   InstrA = SUBSTRING(Name, CHARINDEX(' ', Name, 0) + 1, 1)
,   InstrB = SUBSTRING(Name, CHARINDEX(' ', Name, 0) + 3, 1)
,   InstrC = SUBSTRING(Name, CHARINDEX(' ', Name, 0) + 5, 1)
FROM ##Input16 I
LEFT JOIN ##Conversion C ON SUBSTRING(Name, 1, CHARINDEX(' ', Name, 0)) = C.Opcode

CREATE TABLE ##Registers (Register0 INT, Register1 INT, Register2 INT, Register3 INT)

INSERT ##Registers VALUES (0, 0, 0, 0)



DECLARE @ID INT

DECLARE ProgramCursor CURSOR
FOR SELECT ID FROM ##Program ORDER BY ID

OPEN ProgramCursor

FETCH NEXT FROM ProgramCursor ID INTO @ID

WHILE @@FETCH_STATUS = 0
BEGIN

    --UPDATE R
    --SET Register0 = 
    --,   Register1 =
    --,   Register2 =
    --,   Register3 =

DECLARE @ID INT = 1
    SELECT R.Register0
    ,      R.Register1
    ,      R.Register2
    ,      R.Register3
    ,      S.Opname
    ,      S.InstrC DestReg
    ,      CASE WHEN S.InstrA = 0 THEN R.Register0
                WHEN S.InstrA = 1 THEN R.Register1
                WHEN S.InstrA = 2 THEN R.Register2
                WHEN S.InstrA = 3 THEN R.Register3
           END
           * S.InstrB AS Result
    
    FROM ##Registers R
    CROSS APPLY (
        SELECT *
        FROM ##Program
        WHERE ID = @ID
        ) S





    

    FETCH NEXT FROM ProgramCursor ID INTO @ID

END


SELECT * FROM ##Registers

/*

DROP TABLE ##Register
DROP TABLE ##Program
DROP TABLE ##Conversion
DROP TABLE ##Results
DROP TABLE ##Sample
DROP TABLE ##Input16

*/



