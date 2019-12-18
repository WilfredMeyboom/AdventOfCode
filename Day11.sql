USE Test_WME
GO

SET NOCOUNT ON

CREATE TABLE ##OpCodes (Ind BIGINT, Val BIGINT, Phase BIGINT)
CREATE TABLE ##Pointers (Phase BIGINT, Pointer BIGINT)

DECLARE @Output BIGINT = 0

INSERT ##Pointers (Phase, Pointer) VALUES (1,0), (-1,0)

---Load the IntComp
DECLARE @Phase INT = 1

        CREATE TABLE #Input (Nr NVARCHAR(MAX));

        BULK INSERT #Input
        FROM 'C:\Source\AdventOfCode\input11.txt'
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

------------------- IntComp loaded

CREATE TABLE ##Painting (ID INT IDENTITY(1,1), x INT, y INT, Color INT)

DECLARE @Counter INT = 0
DECLARE @Input BIGINT = 0
DECLARE @CurrentID INT
DECLARE @x INT = 0
DECLARE @y INT = 0
DECLARE @Dir INT = 0

INSERT ##Painting (x, y) SELECT @x, @y
SET @CurrentID = @@IDENTITY

DECLARE @DebugCounter INT = 0

WHILE @Output <> -99 --AND @DebugCounter < 20
BEGIN
    EXEC FakeIntCodeComp @Input, 1, @Output OUTPUT
     
    PRINT '' + CAST(@Output AS VARCHAR(50))
    
    IF @Counter = 0 
    BEGIN
        UPDATE ##Painting
        SET Color = @Output
        WHERE ID = @CurrentID

        --SET @Input = @Output
    END

    IF @Counter = 1 
    BEGIN
        SELECT @Dir = @Dir + CASE WHEN @Output = 0 THEN -90 ELSE 90 END
        IF @Dir = -90 SET @Dir = 270
        IF @Dir = 360 SET @Dir = 0

        IF @Dir = 0 SET @y = @y + 1
        IF @Dir = 180 SET @y = @y - 1
        IF @Dir = 90 SET @x = @x + 1
        IF @Dir = 270 SET @x = @x - 1

        SELECT TOP 1 @Input = Color
        FROM ##Painting
        WHERE x = @x AND y = @y
        ORDER BY ID DESC

        IF @Input IS NULL SET @Input = 0

        INSERT ##Painting (x, y) SELECT @x, @y
        SET @CurrentID = @@IDENTITY
        PRINT 'x: ' + CAST(@x AS VARCHAR(2)) + ', y: ' + CAST(@y AS VARCHAR(2))
    END

    SET @Counter = @Counter + 1
    IF @Counter > 1 SET @Counter = 0

    SET @DebugCounter = @DebugCounter + 1
END

--SELECT * FROM ##Pointers
--SELECT * FROM ##OpCodes

DROP TABLE ##Opcodes
DROP TABLE ##Pointers

SELECT x,y
FROM ##Painting
WHERE Color IN (0,1)
GROUP BY x,y

SELECT x,y FROM ##Painting WHERE Color = 1
GROUP BY x,y


--SELECT MIN(x), MIN(y) FROM ##Painting
--SELECT MAX(x), MAX(y) FROM ##Painting

CREATE TABLE ##Grid (x INT, y INT, color INT)

;WITH cte_x AS (
    SELECT TOP 70 ROW_NUMBER() OVER (ORDER BY (SELECT 0)) -11 AS x FROM sys.messages
), cte_y AS (
    SELECT TOP 85 ROW_NUMBER() OVER (ORDER BY (SELECT 0)) -75 AS y FROM sys.messages
)
INSERT ##Grid (x, y, color)
SELECT x, y, 0
FROM cte_x
CROSS APPLY cte_y

--SELECT * FROM ##Grid

;WITH cte_MaxID AS (
    SELECT x, y, MAX(ID) AS MaxID
    FROM ##Painting
    GROUP BY x, y
)
UPDATE G
SET color = P.color
FROM ##Grid G
INNER JOIN ##Painting P ON P.x = G.x and P.y = G.y
INNER JOIN cte_MaxID cM ON cM.x = P.x AND cM.y = P.y AND cM.MaxID = P.ID

-- 2045 is too high for part 1
-- 2000 is too high for part 1
-- 1897 is too high for part 1
-- 1800 is incorrect for part 1


--DROP TABLE ##Painting

/*
DECLARE @x INT = 0
DECLARE @y INT = 0
DECLARE @Line VARCHAR(150)

SELECT @x = MIN(x), @y = MIN(y) FROM ##Grid
DECLARE @xmax INT
DECLARE @ymax INT
SELECT @xmax = MAX(x), @ymax = MAX(y) FROM ##Grid

WHILE @y <= @ymax
BEGIN
    SELECT @x = MIN(x) FROM ##Grid

    SET @Line = ''
    WHILE @x <= @xmax
    BEGIN

        SELECT @Line = @Line + CASE WHEN Color = 0 THEN ' '
                               ELSE 'X' END 
        FROM ##Grid P
        WHERE P.x = @x And P.y = @y

        SET @x = @x + 1
    END

    PRINT @Line
    SET @y = @y + 1
END
*/

/*
DROP TABLE ##Painting
DROP TABLE ##Grid
*/

--SELECT *
--INTO ##PaintingBackup
--FROM ##Painting


SELECT * FROM ##Painting
--SELECT * FROM ##PaintingBackup

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