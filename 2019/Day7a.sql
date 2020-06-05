use Test_WME
GO

SET NOCOUNT ON

DECLARE @ProgramFile VARCHAR(250) = 'C:\Source\AdventOfCode\2019\input7.txt'

--CREATE TABLE ##OpCodes (Ind BIGINT, Val BIGINT, Phase BIGINT)
CREATE TABLE ##Pointers (OpCodeCompNr BIGINT, Pointer INT)
CREATE TABLE ##Results (ID INT IDENTITY(1,1), ThrusterID INT, Result BIGINT)

CREATE TABLE ##Thrusters (ID BIGINT IDENTITY(1,1), AmpA BIGINT, AmpB BIGINT, AmpC BIGINT, AmpD BIGINT, AmpE BIGINT, OutputValue BIGINT)

;WITH cte_Nrs AS 
(
    SELECT 0 AS Nr
    UNION SELECT 1
    UNION SELECT 2
    UNION SELECT 3
    UNION SELECT 4
    --SELECT 5 AS Nr
    --UNION SELECT 6
    --UNION SELECT 7
    --UNION SELECT 8
    --UNION SELECT 9
)
INSERT ##Thrusters(AmpA, AmpB, AmpC, AmpD, AmpE, OutputValue)
SELECT T0.Nr, T1.Nr, T2.Nr, T3.Nr, T4.Nr, 0 --Default starting value
FROM cte_Nrs T0
INNER JOIN cte_Nrs T1 ON T0.Nr <> T1.Nr
INNER JOIN cte_Nrs T2 ON T0.Nr <> T2.Nr AND T1.Nr <> T2.Nr
INNER JOIN cte_Nrs T3 ON T0.Nr <> T3.Nr AND T1.Nr <> T3.Nr AND T2.Nr <> T3.Nr
INNER JOIN cte_Nrs T4 ON T0.Nr <> T4.Nr AND T1.Nr <> T4.Nr AND T2.Nr <> T4.Nr AND T3.Nr <> T4.Nr

--Set the initial phase for each thruster
INSERT ##Pointers (OpCodeCompNr, Pointer) VALUES (0,0), (1,0), (2,0), (3,0), (4,0)
--INSERT ##Pointers (OpCodeCompNr, Pointer) VALUES (5,0), (6,0), (7,0), (8,0), (9,0)



DECLARE @AmpA BIGINT
DECLARE @AmpB BIGINT
DECLARE @AmpC BIGINT
DECLARE @AmpD BIGINT
DECLARE @AmpE BIGINT
DECLARE @ID BIGINT
DECLARE @Output BIGINT = 0

DECLARE AmpSettingCursor CURSOR FOR
SELECT ID, AmpA, AmpB, AmpC, AmpD, AmpE FROM ##Thrusters

OPEN AmpSettingCursor

FETCH NEXT FROM AmpSettingCursor INTO @ID, @AmpA, @AmpB, @AmpC, @AmpD, @AmpE

WHILE @@FETCH_STATUS = 0
BEGIN

    PRINT 'Start test for: ' + CAST(@AmpA AS VARCHAR(1)) + CAST(@AmpB AS VARCHAR(1)) + CAST(@AmpC AS VARCHAR(1)) + CAST(@AmpD AS VARCHAR(1)) + CAST(@AmpE AS VARCHAR(1)) + ' at ' + CAST(GETDATE() AS VARCHAR(50))

    UPDATE ##Pointers SET Pointer = 0
    SET @Output = 0

    --WHILE @Output <> -99
    --BEGIN
        EXEC @Output = IntCodeComp @ProgramFile, @AmpA, @AmpA --Set phase
        EXEC @Output = IntCodeComp @ProgramFile, 0, @AmpA     --Run with input 0
        --PRINT @Output
        EXEC IntCodeComp @ProgramFile, @AmpB, @AmpB
        EXEC @Output = IntCodeComp @ProgramFile, @Output, @AmpB
        --PRINT @Output
        EXEC IntCodeComp @ProgramFile, @AmpC, @AmpC
        EXEC @Output = IntCodeComp @ProgramFile, @Output, @AmpC
        --PRINT @Output
        EXEC IntCodeComp @ProgramFile, @AmpD, @AmpD
        EXEC @Output = IntCodeComp @ProgramFile, @Output, @AmpD
        --PRINT @Output
        EXEC IntCodeComp @ProgramFile, @AmpE, @AmpE
        EXEC @Output = IntCodeComp @ProgramFile, @Output, @AmpE
        --PRINT @Output
 
        --SELECT * FROM OpCodes
    --END

    UPDATE ##Thrusters
    SET OutputValue = @Output
    WHERE ID = @ID

    DROP TABLE OpCodes

    FETCH NEXT FROM AmpSettingCursor INTO @ID, @AmpA, @AmpB, @AmpC, @AmpD, @AmpE

END

CLOSE AmpSettingCursor
DEALLOCATE AmpSettingCursor

SELECT * FROM ##Thrusters ORDER BY OutputValue DESC


--DROP TABLE Test_WME.dbo.Opcodes


--SELECT * FROM ##Results

--SELECT * FROM ##OpCodes
/*


DROP TABLE ##Thrusters
DROP TABLE ##Pointers
DROP TABLE ##Results
DROP TABLE Test_WME.dbo.Opcodes

*/

-- 58285150 is correct for part 2
-- this corresponds to thrusterconfiguration 85976

/*

CREATE OR ALTER PROCEDURE IntCodeComp (@Input BIGINT, @Phase BIGINT) AS 
BEGIN

    SET NOCOUNT ON

    DECLARE @FirstRun INT = 0

    IF (SELECT COUNT(1) FROM ##OpCodes WHERE Phase = @Phase) = 0
    BEGIN

    --PRINT @Phase

        CREATE TABLE #Input (Nr NVARCHAR(MAX));

        BULK INSERT #Input
        FROM 'C:\Source\AdventOfCode\input7.txt'
        WITH (ROWTERMINATOR = '0x0A');


    --    CREATE TABLE ##OpCodes (Ind BIGINT, Val BIGINT, Phase BIGINT)

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

        SET @FirstRun = 1

        DROP TABLE #Input

    END
 
    DECLARE @Pointer BIGINT
    DECLARE @Instr BIGINT
    DECLARE @ParameterInstr VARCHAR(10)
    DECLARE @FirstNr BIGINT
    DECLARE @SecondNr BIGINT
    DECLARE @DestNr BIGINT
    DECLARE @Output BIGINT
    DECLARE @ParamMode1 BIGINT
    DECLARE @ParamMode2 BIGINT

    SELECT @Pointer = Pointer FROM ##Pointers WHERE Phase = @Phase
    SET @Instr = 0

    WHILE @Instr <> 99
    BEGIN
    
        SELECT @ParameterInstr = '00000' + CAST(Val AS VARCHAR(10)) FROM ##OpCodes WHERE Ind = @Pointer AND Phase = @Phase

        SET @Instr = RIGHT(@ParameterInstr, 2)
        SET @ParamMode1 = SUBSTRING(@ParameterInstr, LEN(@parameterInstr) - 2, 1)
        SET @ParamMode2 = SUBSTRING(@ParameterInstr, LEN(@parameterInstr) - 3, 1)

        IF @ParamMode1 = 0 SELECT @FirstNr = Val FROM ##OpCodes WHERE Ind = (SELECT Val FROM ##OpCodes WHERE Ind = @Pointer + 1 AND Phase = @Phase) AND Phase = @Phase
                      ELSE SELECT @FirstNr = Val FROM ##OpCodes WHERE Ind = @Pointer + 1 AND Phase = @Phase
        IF @ParamMode2 = 0 SELECT @SecondNr = Val FROM ##OpCodes WHERE Ind = (SELECT Val FROM ##OpCodes WHERE Ind = @Pointer + 2 AND Phase = @Phase) AND Phase = @Phase
                      ELSE SELECT @SecondNr = Val FROM ##OpCodes WHERE Ind = @Pointer + 2 AND Phase = @Phase

        --PRINT CAST(@ParameterInstr AS VARCHAR(10))
        --PRINT CAST(@Instr AS VARCHAR(2)) 
        --PRINT CAST(@FirstNr AS VARCHAR(5)) 
        --PRINT CAST(@SecondNr AS VARCHAR(5)) 
        --PRINT CAST(@ParamMode1 AS VARCHAR(1))
        --PRINT CAST(@ParamMode2 AS VARCHAR(1))

        --PRINT CAST(@ParameterInstr AS VARCHAR(10)) + ' ' + CAST(@Instr AS VARCHAR(2)) + ' ' + CAST(@FirstNr AS VARCHAR(10)) + ' ' + ISNULL(CAST(@SecondNr AS VARCHAR(10)), 'X') + ' ' + CAST(@ParamMode1 AS VARCHAR(1)) + ' ' + CAST(@ParamMode2 AS VARCHAR(1))
 
        IF @Instr In (1,2)
        BEGIN
            UPDATE ##OpCodes
            SET Val = CASE WHEN @Instr = 1 THEN @FirstNr + @SecondNr
                           WHEN @Instr = 2 THEN @FirstNr * @SecondNr
                                            ELSE Val END
            WHERE Ind = (SELECT Val FROM ##OpCodes WHERE Ind = @Pointer + 3 AND Phase = @Phase) AND Phase = @Phase

            SET @Pointer = @Pointer + 4
        END

        IF @Instr = 3
        BEGIN

            IF @FirstRun = 1
            BEGIN
                UPDATE ##OpCodes
                SET Val = @Phase
                WHERE Ind = (SELECT Val FROM ##OpCodes WHERE Ind = @Pointer + 1 AND Phase = @Phase) AND Phase = @Phase

                SET @FirstRun = 0

            END
            ELSE
            BEGIN
                UPDATE ##OpCodes
                SET Val = @Input
                WHERE Ind = (SELECT Val FROM ##OpCodes WHERE Ind = @Pointer + 1 AND Phase = @Phase) AND Phase = @Phase
            END

            SET @Pointer = @Pointer + 2

        END

        IF @Instr = 4
        BEGIN
            IF @ParamMode1 = 0 SELECT @Output = Val FROM ##OpCodes WHERE Ind = (SELECT Val FROM ##OpCodes WHERE Ind = @Pointer + 1 AND Phase = @Phase) AND Phase = @Phase
                          ELSE SELECT @Output = Val FROM ##OpCodes WHERE Ind = @Pointer + 1 AND Phase = @Phase

            --PRINT 'Output = ' + CAST(@Output AS VARCHAR(10))

            SET @Pointer = @Pointer + 2

            UPDATE ##Pointers SET Pointer = @Pointer WHERE Phase = @Phase

            RETURN @Output
            
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
            WHERE Ind = (SELECT Val FROM ##OpCodes WHERE Ind = @Pointer + 3 AND Phase = @Phase) AND Phase = @Phase
        
            SET @Pointer = @Pointer + 4
        END

        IF @Instr = 8
        BEGIN
    
            UPDATE ##OpCodes
            SET Val = CASE WHEN @FirstNr = @SecondNr THEN 1 ELSE 0 END
            WHERE Ind = (SELECT Val FROM ##OpCodes WHERE Ind = @Pointer + 3 AND Phase = @Phase) AND Phase = @Phase
        
            SET @Pointer = @Pointer + 4

        END


    END

--    DROP TABLE ##OpCodes

    RETURN -99

END

*/