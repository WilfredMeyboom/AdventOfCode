USE Test_WME
GO

SET NOCOUNT ON

CREATE TABLE ##OpCodes (Ind BIGINT, Val BIGINT, Phase BIGINT)
CREATE TABLE ##Pointers (Phase BIGINT, Pointer BIGINT)

DECLARE @Output BIGINT = 0
DECLARE @Phase BIGINT = 1

INSERT ##Pointers (Phase, Pointer) VALUES (@Phase,0), (-@Phase,0)

CREATE TABLE #Input (Nr NVARCHAR(MAX));

BULK INSERT #Input
FROM 'C:\Source\AdventOfCode\input17.txt'
WITH (ROWTERMINATOR = '0x0A');

;WITH cte_Values AS (
    SELECT 0 AS Ind
    ,      SUBSTRING(Nr, 1, CHARINDEX(',', Nr) - 1) AS Val
    ,      SUBSTRING(Nr, CHARINDEX(',', Nr) + 1, LEN(Nr)) + ',' AS Rest
    FROM #Input
    UNION ALL
    SELECT Ind + 1
    ,      SUBSTRING(Rest, 1, CHARINDEX(',', Rest) - 1) AS Val
    ,      SUBSTRING(Rest, CHARINDEX(',', Rest) + 1, LEN(Rest)) AS Rest
    FROM cte_Values
    WHERE LEN(Rest) > 0
)
INSERT ##OpCodes (Ind, Val, Phase)
SELECT Ind, Val, @Phase
FROM cte_Values OPTION (MAXRECURSION 10000)

DROP TABLE #Input

CREATE TABLE ##Grid (ID INT IDENTITY(1,1), x INT, y INT, Val INT)
DECLARE @x INT = 0
DECLARE @y INT = 0

WHILE @Output <> -99 
BEGIN    

    EXEC IntCodeComp 0, @Phase, @Output OUTPUT

    PRINT 'Output: ' + CAST(@Output AS VARCHAR(4))

    INSERT ##Grid (x, y, Val) SELECT @x, @y, @Output

    SET @x = @x + 1

    IF @Output = 10
    BEGIN
        SET @x = 0
        Set @y = @y + 1
    END
END

--SELECT * FROM ##Pointers
--SELECT * FROM ##OpCodes

DROP TABLE ##Opcodes
DROP TABLE ##Pointers

SELECT * FROM ##Grid WHERE x = 12 AND y = 16

--DROP TABLE ##Grid

SELECT SUM(GC.x * GC.y)
FROM ##Grid GC
INNER JOIN ##Grid GN ON GC.x = GN.x AND GC.y = GN.y + 1 AND GN.Val = 35
INNER JOIN ##Grid GS ON GC.x = GS.x AND GC.y = GS.y - 1 AND GS.Val = 35
INNER JOIN ##Grid GW ON GC.x = GW.x + 1 AND GC.y = GW.y AND GW.Val = 35
INNER JOIN ##Grid GE ON GC.x = GE.x - 1 AND GC.y = GE.y AND GE.Val = 35
WHERE GC.Val = 35


DECLARE @m INT = 0
DECLARE @n INT = 0 
DECLARE @mMax INT
DECLARE @nMax INT
DECLARE @Line VARCHAR(200)

SELECT @mMax = MAX(x), @nMax = MAX(y) FROM ##Grid

WHILE @n < @nMax
BEGIN
    
    SET @m = 0
    SET @Line = ''

    WHILE @m < @mMax
    BEGIN

        SELECT @Line = @Line + CASE WHEN Val = 35 THEN '#'
                                    WHEN Val IN (46,10,99) THEN ' '
                                    ELSE '^' END
        FROM ##Grid
        WHERE x = @m AND y = @n

        SET @m = @m + 1

    END

    PRINT @Line

    SET @n = @n + 1

END

/*
L 12,L 6,L 8,R 6,L 8,L 8,R 4,R 6,R 6,L 12,L 6,L 8,R 6,L 8,L 8,R 4,R 6,R 6,L 12,R 6,L 8,L 12,R 6,L 8,L 8,L 8,R 4,R 6,R 6,L 12,L 6,L 8,R 6,L 8,L 8,R 4,R 6,R 6,L 12,R 6,L 8
<C>,<A>,<C>,<A>,<B>,<B>,<A>,<C>,<A>,<B>

<A> = L 8,L 8,R 4,R 6,R 6
<B> = L 12,R 6,L 8
<C> = L 12,L 6,L 8,R 6
*/ 

CREATE TABLE ##InputInstructions (ID INT IDENTITY(1,1), Input INT)
INSERT ##InputInstructions (Input) VALUES (67),(44),(65),(44),(67),(44),(65),(44),(66),(44),(66),(44),(65),(44),(67),(44),(65),(44),(66),(10)
INSERT ##InputInstructions (Input) VALUES (76),(44),(56),(44),(76),(44),(56),(44),(82),(44),(52),(44),(82),(44),(54),(44),(82),(44),(54),(10)
INSERT ##InputInstructions (Input) VALUES (76),(44),(54),(44),(54),(44),(82),(44),(54),(44),(76),(44),(56),(10)
INSERT ##InputInstructions (Input) VALUES (76),(44),(54),(44),(54),(44),(76),(44),(54),(76),(44),(56),(44),(82),(44),(54),(10)
INSERT ##InputInstructions (Input) VALUES (110),(10)


SELECT * FROM ##InputInstructions


CREATE TABLE ##OpCodes (Ind BIGINT, Val BIGINT, Phase BIGINT)
CREATE TABLE ##Pointers (Phase BIGINT, Pointer BIGINT)

DECLARE @Output BIGINT = 0
DECLARE @Phase BIGINT = 1

INSERT ##Pointers (Phase, Pointer) VALUES (@Phase,0), (-@Phase,0)

CREATE TABLE #Input (Nr NVARCHAR(MAX));

BULK INSERT #Input
FROM 'C:\Source\AdventOfCode\input17.txt'
WITH (ROWTERMINATOR = '0x0A');

;WITH cte_Values AS (
    SELECT 0 AS Ind
    ,      SUBSTRING(Nr, 1, CHARINDEX(',', Nr) - 1) AS Val
    ,      SUBSTRING(Nr, CHARINDEX(',', Nr) + 1, LEN(Nr)) + ',' AS Rest
    FROM #Input
    UNION ALL
    SELECT Ind + 1
    ,      SUBSTRING(Rest, 1, CHARINDEX(',', Rest) - 1) AS Val
    ,      SUBSTRING(Rest, CHARINDEX(',', Rest) + 1, LEN(Rest)) AS Rest
    FROM cte_Values
    WHERE LEN(Rest) > 0
)
INSERT ##OpCodes (Ind, Val, Phase)
SELECT Ind, Val, @Phase
FROM cte_Values OPTION (MAXRECURSION 10000)

DROP TABLE #Input

UPDATE ##OpCodes SET Val = 2 WHERE Ind = 0

DECLARE @Counter INT = 1
DECLARE @Input INT

WHILE @Output <> -99 
BEGIN    

    SELECT @Input = Input FROM ##InputInstructions WHERE ID = @Counter

    EXEC IntCodeComp @Input, @Phase, @Output OUTPUT

    PRINT 'Output: ' + CAST(@Output AS VARCHAR(10))

    IF @Output = -9999 SET @Counter = @Counter + 1

END




/*
USE [Test_WME]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[IntCodeComp] (@Input BIGINT, @Phase BIGINT, @Output BIGINT OUTPUT) AS 
BEGIN

    SET NOCOUNT ON

    DECLARE @FirstRun INT = 0
 
    DECLARE @Pointer BIGINT
    DECLARE @Instr BIGINT
    DECLARE @ParameterInstr VARCHAR(20)
    DECLARE @FirstNr BIGINT
    DECLARE @SecondNr BIGINT
    DECLARE @ThirdNr BIGINT
    DECLARE @DestNr BIGINT
    DECLARE @ParamMode1 BIGINT
    DECLARE @ParamMode2 BIGINT
    DECLARE @ParamMode3 BIGINT
    DECLARE @Base BIGINT

    SELECT @Pointer = Pointer FROM ##Pointers WHERE Phase = @Phase
    SELECT @Base = Pointer FROM ##Pointers WHERE Phase = -1 * @Phase

    SET @Instr = 0

    WHILE @Instr <> 99
    BEGIN
    
        SELECT @ParameterInstr = '00000' + CAST(Val AS VARCHAR(20)) FROM ##OpCodes WHERE Ind = @Pointer AND Phase = @Phase

        SET @Instr = RIGHT(@ParameterInstr, 2)
        SET @ParamMode1 = SUBSTRING(@ParameterInstr, LEN(@parameterInstr) - 2, 1)
        SET @ParamMode2 = SUBSTRING(@ParameterInstr, LEN(@parameterInstr) - 3, 1)
        SET @ParamMode3 = SUBSTRING(@ParameterInstr, LEN(@parameterInstr) - 4, 1)

        --PRINT '*** The instruction is ' + CAST(@Instr AS VARCHAR(2)) + '***'
        
        --PRINT 'The first parameter is in mode: ' + CAST(@ParamMode1 AS VARCHAR(1))

        SELECT @FirstNr = Val FROM ##OpCodes WHERE Ind = @Pointer + 1 AND Phase = @Phase

        IF @ParamMode1 = 0 
        BEGIN
            -- If the reference is to an unknown memory address, add it with value 0
            IF NOT EXISTS(SELECT 1 FROM ##OpCodes WHERE Ind = @FirstNr) INSERT ##OpCodes(Ind, Val, Phase) SELECT @FirstNr, 0, @Phase

            SELECT @FirstNr = Val FROM ##OpCodes WHERE Ind = @FirstNr AND @Phase = Phase
        END
        IF @ParamMode1 = 2
        BEGIN
            -- If the reference is to an unknown memory address, add it with value 0
            IF NOT EXISTS(SELECT 1 FROM ##OpCodes WHERE Ind = @FirstNr + @Base) INSERT ##OpCodes(Ind, Val, Phase) SELECT @FirstNr + @Base, 0, @Phase

            SELECT @FirstNr = Val FROM ##OpCodes WHERE Ind = @FirstNr + @Base AND @Phase = Phase
        END

        --PRINT 'The value of the first number is: ' + CAST(@FirstNr AS VARCHAR(20))

        -- These three only take 1 parameter, for the rest we need to determine the 2nd parameter
        IF @Instr NOT IN (3, 4, 9) 
        BEGIN
            SELECT @SecondNr = Val FROM ##OpCodes WHERE Ind = @Pointer + 2 AND Phase = @Phase
            --PRINT 'The second parameter is in mode: ' + CAST(@ParamMode2 AS VARCHAR(1))

            IF @ParamMode2 = 0 
            BEGIN
                -- If the reference is to an unknown memory address, add it with value 0
                IF NOT EXISTS(SELECT 1 FROM ##OpCodes WHERE Ind = @SecondNr) INSERT ##OpCodes(Ind, Val, Phase) SELECT @SecondNr, 0, @Phase

                SELECT @SecondNr = Val FROM ##OpCodes WHERE Ind = @SecondNr AND @Phase = Phase
            END
            IF @ParamMode2 = 2
            BEGIN
                -- If the reference is to an unknown memory address, add it with value 0
                IF NOT EXISTS(SELECT 1 FROM ##OpCodes WHERE Ind = @SecondNr + @Base) INSERT ##OpCodes(Ind, Val, Phase) SELECT @SecondNr + @Base, 0, @Phase

                SELECT @SecondNr = Val FROM ##OpCodes WHERE Ind = @SecondNr + @Base AND @Phase = Phase
            END

            --PRINT 'The value of the second number is: ' + CAST(@SecondNr AS VARCHAR(20))

        END

        -- These four take 3 parameters
        IF @Instr IN (1, 2, 7, 8) 
        BEGIN

            --PRINT 'The third parameter is in mode: ' + CAST(@ParamMode3 AS VARCHAR(1))

            SELECT @ThirdNr = Val FROM ##OpCodes WHERE Ind = @Pointer + 3 AND Phase = @Phase

            IF @ParamMode3  = 2
                SELECT @ThirdNr = @ThirdNr + @Base

            -- Check if memory slot exists
            IF NOT EXISTS(SELECT 1 FROM ##OpCodes WHERE Ind = @ThirdNr) INSERT ##OpCodes(Ind, Val, Phase) SELECT @ThirdNr, 0, @Phase

            --PRINT 'The value of the third number is: ' + CAST(@ThirdNr AS VARCHAR(20))

        END

        --SELECT *, @Instr FROM ##OpCodes
        --PRINT CAST(@ParameterInstr AS VARCHAR(20)) + ' ' + CAST(@FirstNr AS VARCHAR(20)) + ' ' + ISNULL(CAST(@SecondNr AS VARCHAR(20)), 'X') + ' ' + ISNULL(CAST(@ThirdNr AS VARCHAR(20)), 'X')
 
        IF @Instr In (1,2)
        BEGIN

            UPDATE ##OpCodes
            SET Val = CASE WHEN @Instr = 1 THEN @FirstNr + @SecondNr
                           WHEN @Instr = 2 THEN @FirstNr * @SecondNr
                                            ELSE Val END
            WHERE Ind = @ThirdNr AND Phase = @Phase

            SET @Pointer = @Pointer + 4
        END

        IF @Instr = 3
        BEGIN

            --PRINT 'Phase: ' + CAST(@Phase AS VARCHAR(2))
            --PRINT 'Input: ' + CAST(@Input AS VARCHAR(2))

            --For now
            SELECT @FirstNr = Val FROM ##OpCodes WHERE Ind = @Pointer + 1 AND Phase = @Phase

            UPDATE ##OpCodes
            SET Val = @Input
            WHERE Ind = @FirstNr + @Base AND Phase = @Phase

            SET @Pointer = @Pointer + 2

        END

        IF @Instr = 4
        BEGIN
            IF @ParamMode1 IN (0, 2) SELECT @Output = @FirstNr
                          ELSE SELECT @Output = Val FROM ##OpCodes WHERE Ind = @Pointer + 1 AND Phase = @Phase

            --PRINT 'Output = ' + CAST(@Output AS VARCHAR(20))

            SET @Pointer = @Pointer + 2

            UPDATE ##Pointers SET Pointer = @Pointer WHERE Phase = @Phase
            UPDATE ##Pointers SET Pointer = @Base WHERE Phase = -1 * @Phase

            RETURN 
            
        END

        IF @Instr = 5
        BEGIN
            IF @FirstNr <> 0 SET @Pointer = @SecondNr
            ELSE SET @Pointer = @Pointer + 3
        END

        IF @Instr = 6
        BEGIN
            IF @FirstNr = 0 SET @Pointer = @SecondNr
            ELSE SET @Pointer = @Pointer + 3
        END

        IF @Instr = 7
        BEGIN
            UPDATE ##OpCodes
            SET Val = CASE WHEN @FirstNr < @SecondNr THEN 1 ELSE 0 END
            WHERE Ind = @ThirdNr AND Phase = @Phase
        
            SET @Pointer = @Pointer + 4
        END

        IF @Instr = 8
        BEGIN
    
            UPDATE ##OpCodes
            SET Val = CASE WHEN @FirstNr = @SecondNr THEN 1 ELSE 0 END
            WHERE Ind = @ThirdNr AND Phase = @Phase
        
            SET @Pointer = @Pointer + 4

        END

        IF @Instr = 9
        BEGIN

            SET @Base = @Base + @FirstNr

            SET @Pointer = @Pointer + 2

            --PRINT 'Base is now: ' + CAST(@Base AS VARCHAR(5))
        END

    END

--    DROP TABLE ##OpCodes

    SET @Output = -99
    RETURN

END
*/