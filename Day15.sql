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
FROM 'C:\Source\AdventOfCode\input15.txt'
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

CREATE TABLE ##Grid (ID INT IDENTITY(1,1), x INT, y INT, NorthWall INT, EastWall INT, SouthWall INT, WestWall INT)
DECLARE @x INT = 0
DECLARE @y INT = 0
DECLARE @Dir INT = 4
DECLARE @MazeDone INT = 0
INSERT ##Grid (x, y) SELECT @x, @y

WHILE @Output <> -99 AND @MazeDone = 0
BEGIN    

    IF (@Dir = 1 AND (SELECT ISNULL(WestWall, 0) FROM ##Grid WHERE x = @x AND y = @y) <> 1)
    OR (@Dir = 2 AND (SELECT ISNULL(EastWall, 0) FROM ##Grid WHERE x = @x AND y = @y) <> 1)
    OR (@Dir = 3 AND (SELECT ISNULL(SouthWall, 0) FROM ##Grid WHERE x = @x AND y = @y) <> 1)
    OR (@Dir = 4 AND (SELECT ISNULL(NorthWall, 0) FROM ##Grid WHERE x = @x AND y = @y) <> 1)
    BEGIN
        -- Als links van je is leeg dan draai naar links en stap
        SELECT @Dir = CASE WHEN (@Dir = 1) THEN 3
                           WHEN (@Dir = 2) THEN 4
                           WHEN (@Dir = 3) THEN 2
                           WHEN (@Dir = 4) THEN 1 END
    END
    ELSE IF (@Dir = 1 AND (SELECT ISNULL(NorthWall, 0) FROM ##Grid WHERE x = @x AND y = @y) = 1)
         OR (@Dir = 2 AND (SELECT ISNULL(SouthWall, 0) FROM ##Grid WHERE x = @x AND y = @y) = 1)
         OR (@Dir = 3 AND (SELECT ISNULL(WestWall, 0) FROM ##Grid WHERE x = @x AND y = @y) = 1)
         OR (@Dir = 4 AND (SELECT ISNULL(EastWall, 0) FROM ##Grid WHERE x = @x AND y = @y) = 1)
         BEGIN
         -- Als voor je een muur staat dan draai naar rechts en stap
        SELECT @Dir = CASE WHEN (@Dir = 1) THEN 4
                           WHEN (@Dir = 2) THEN 3
                           WHEN (@Dir = 3) THEN 1
                           WHEN (@Dir = 4) THEN 2 END
         END
         --ELSE             
         -- Als voor je leeg is en links van je een muur dan stap vooruit
         -- So... do nothing

    EXEC IntCodeComp @Dir, @Phase, @Output OUTPUT

    PRINT 'Direction: ' + CAST(@Dir AS VARCHAR(1)) 
    PRINT 'Output: ' + CAST(@Output AS VARCHAR(4))

    IF @Output = 0
    BEGIN
        IF @Dir = 1 UPDATE ##Grid SET NorthWall = 1 WHERE @x = x AND @y = y
        IF @Dir = 2 UPDATE ##Grid SET SouthWall = 1 WHERE @x = x AND @y = y
        IF @Dir = 3 UPDATE ##Grid SET WestWall = 1 WHERE @x = x AND @y = y
        IF @Dir = 4 UPDATE ##Grid SET EastWall = 1 WHERE @x = x AND @y = y
    END
    
    IF @Output IN (1,2)
    BEGIN

        IF @Dir = 1 
        BEGIN
            UPDATE ##Grid SET NorthWall = 0 WHERE x = @x AND y = @y
            SET @y = @y + 1
            IF NOT EXISTS (SELECT 1 FROM ##Grid WHERE x = @x AND y = @Y)
                INSERT ##Grid (x, y, SouthWall) SELECT @x, @y, 0
        END

        IF @Dir = 2 
        BEGIN
            UPDATE ##Grid SET SouthWall = 0 WHERE x = @x AND y = @y
            SET @y = @y - 1
            IF NOT EXISTS (SELECT 1 FROM ##Grid WHERE x = @x AND y = @Y)
                INSERT ##Grid (x, y, NorthWall) SELECT @x, @y, 0
        END

        IF @Dir = 3 
        BEGIN
            UPDATE ##Grid SET WestWall = 0 WHERE x = @x AND y = @y
            SET @x = @x - 1
            IF NOT EXISTS (SELECT 1 FROM ##Grid WHERE x = @x AND y = @Y)
                INSERT ##Grid (x, y, EastWall) SELECT @x, @y, 0
        END

        IF @Dir = 4 
        BEGIN
            
            UPDATE ##Grid SET EastWall = 0 WHERE x = @x AND y = @y
            SET @x = @x + 1
            IF NOT EXISTS (SELECT 1 FROM ##Grid WHERE x = @x AND y = @Y)
                INSERT ##Grid (x, y, WestWall) SELECT @x, @y, 0

        END
        
    END

    IF @Output = 2 PRINT 'Oxygen repair system found at x = ' + CAST(@x AS VARCHAR(4)) + ', y = ' + CAST(@y AS VARCHAR(4))

    IF (SELECT COUNT(1) FROM ##Grid WHERE NorthWall IS NULL
                                       OR SouthWall IS NULL
                                       OR EastWall IS NULL
                                       OR WestWall IS NULL) = 0 SET @MazeDone = 1
END

-- Oxygen repair system found at x = 14, y = -14

--SELECT * FROM ##Pointers
--SELECT * FROM ##OpCodes

DROP TABLE ##Opcodes
DROP TABLE ##Pointers
--DROP TABLE ##Grid
SELECT * FROM ##Grid

CREATE TABLE ##Map (x INT, y INT, nrOfSteps INT)

--INSERT ##Map (x, y, nrOfSteps) VALUES (0,0,0) -- Part 1
INSERT ##Map (x, y, nrOfSteps) VALUES (14,-14,0)

WHILE (SELECT COUNT(1) FROM ##Map) < (SELECT COUNT(1) FROM ##Grid)
BEGIN

    INSERT ##Map(x, y, nrOfSteps)
    SELECT G.x, G.y, M.nrOfSteps + 1
    FROM ##Map M
    INNER JOIN ##Grid G ON (M.x = G.x + 1 AND M.y = G.y AND G.EastWall = 0)
                        OR (M.x = G.x - 1 AND M.y = G.y AND G.WestWall = 0)
                        OR (M.x = G.x AND M.y = G.y + 1 AND G.NorthWall = 0)
                        OR (M.x = G.x AND M.y = G.y - 1 AND G.SouthWall = 0)
    LEFT JOIN ##Map M2 ON M2.x = G.x AND M2.y = G.y
    WHERE M2.nrOfSteps IS NULL


END

--Part 1
--SELECT * FROM ##Map WHERE x = 14 AND y = -14

-- 404 is correct for part 1

SELECT MAX(NrOfSteps) FROM ##Map 

-- 406 is correct for part 2

--DROP TABLE ##Map


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