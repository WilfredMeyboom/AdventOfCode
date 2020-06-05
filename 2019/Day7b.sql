use Test_WME
GO

SET NOCOUNT ON

DECLARE @ProgramFile VARCHAR(250) = 'C:\Source\AdventOfCode\2019\input7_example2.1.txt'

--CREATE TABLE ##OpCodes (Ind BIGINT, Val BIGINT, Phase BIGINT)
CREATE TABLE ##Pointers (OpCodeCompNr BIGINT, Pointer BIGINT)
CREATE TABLE ##Results (ID INT IDENTITY(1,1), ThrusterID INT, Result BIGINT)

CREATE TABLE ##Thrusters (ID BIGINT IDENTITY(1,1), AmpA BIGINT, AmpB BIGINT, AmpC BIGINT, AmpD BIGINT, AmpE BIGINT, OutputValue BIGINT)

;WITH cte_Nrs AS 
(
    --SELECT 0 AS Nr
    --UNION SELECT 1
    --UNION SELECT 2
    --UNION SELECT 3
    --UNION SELECT 4
    SELECT 5 AS Nr
    UNION SELECT 6
    UNION SELECT 7
    UNION SELECT 8
    UNION SELECT 9
)
INSERT ##Thrusters(AmpA, AmpB, AmpC, AmpD, AmpE, OutputValue)
SELECT T0.Nr, T1.Nr, T2.Nr, T3.Nr, T4.Nr, 0 --Default starting value
FROM cte_Nrs T0
INNER JOIN cte_Nrs T1 ON T0.Nr <> T1.Nr
INNER JOIN cte_Nrs T2 ON T0.Nr <> T2.Nr AND T1.Nr <> T2.Nr
INNER JOIN cte_Nrs T3 ON T0.Nr <> T3.Nr AND T1.Nr <> T3.Nr AND T2.Nr <> T3.Nr
INNER JOIN cte_Nrs T4 ON T0.Nr <> T4.Nr AND T1.Nr <> T4.Nr AND T2.Nr <> T4.Nr AND T3.Nr <> T4.Nr

--Set the initial phase for each thruster
--INSERT ##Pointers (OpCodeCompNr, Pointer) VALUES (0,0), (1,0), (2,0), (3,0), (4,0)
INSERT ##Pointers (OpCodeCompNr, Pointer) VALUES (5,0), (6,0), (7,0), (8,0), (9,0)



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

    --Initialize OpcodeComps
    EXEC IntCodeComp @ProgramFile, @AmpA, @AmpA, @Output OUTPUT
    --PRINT @Output
    EXEC IntCodeComp @ProgramFile, @AmpB, @AmpB, @Output OUTPUT
    --PRINT @Output
    EXEC IntCodeComp @ProgramFile, @AmpC, @AmpC, @Output OUTPUT
    --PRINT @Output
    EXEC IntCodeComp @ProgramFile, @AmpD, @AmpD, @Output OUTPUT
    --PRINT @Output
    EXEC IntCodeComp @ProgramFile, @AmpE, @AmpE, @Output OUTPUT
    --PRINT @Output

    SET @Output = 0

    WHILE @Output <> 99
    BEGIN
        EXEC IntCodeComp @ProgramFile, @Output, @AmpA, @Output OUTPUT
        --PRINT @Output
        EXEC IntCodeComp @ProgramFile, @Output, @AmpB, @Output OUTPUT
        --PRINT @Output
        EXEC IntCodeComp @ProgramFile, @Output, @AmpC, @Output OUTPUT
        --PRINT @Output
        EXEC IntCodeComp @ProgramFile, @Output, @AmpD, @Output OUTPUT
        --PRINT @Output
        EXEC IntCodeComp @ProgramFile, @Output, @AmpE, @Output OUTPUT
        --PRINT @Output
 
        --SELECT * FROM OpCodes
    END

    IF @Output NOT IN (0, 99)
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

USE Test_WME
GO

CREATE OR ALTER PROCEDURE IntCodeComp (@ProgramFile VARCHAR(250), @Input INT, @OpCodeCompNr INT) AS 
BEGIN

    SET NOCOUNT ON

    CREATE TABLE #Input (Nr NVARCHAR(MAX));

    DECLARE @Sql NVARCHAR(MAX)

    SET @Sql = 'BULK INSERT #Input FROM ''' + @ProgramFile + 
        ''' WITH (ROWTERMINATOR = ''0x0A'');'
    --PRINT @Sql
    EXEC sp_executesql @Sql

    UPDATE #Input SET Nr = LEFT(Nr, LEN(Nr)-1)

    --SELECT * FROM #Input

    --Create on first call
    IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'OpCodes')
        CREATE TABLE OpCodes (CompNr INT, Ind INT, Val INT)

    IF (SELECT COUNT(1) FROM OpCodes WHERE CompNr = @OpCodeCompNr) = 0
    BEGIN
    -- Load the computer if it is a new one
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
        INSERT OpCodes (CompNr, Ind, Val)
        SELECT @OpCodeCompNr, Ind, Val
        FROM cte_Values OPTION (MAXRECURSION 10000)

    END

    DECLARE @Pointer INT
    DECLARE @Instr INT
    DECLARE @ParameterInstr VARCHAR(10)
    DECLARE @FirstNr INT
    DECLARE @SecondNr INT
    DECLARE @DestNr INT
    DECLARE @Output INT
    DECLARE @ParamMode1 INT
    DECLARE @ParamMode2 INT
    DECLARE @InputConsumed INT = 0

    SELECT @Pointer = Pointer FROM ##Pointers WHERE OpCodeCompNr = @OpCodeCompNr
    SET @Instr = 0

    WHILE @Instr <> 99
    BEGIN

        SELECT @ParameterInstr = '00000' + CAST(Val AS VARCHAR(10)) FROM OpCodes WHERE Ind = @Pointer AND CompNr = @OpCodeCompNr

        SET @Instr = RIGHT(@ParameterInstr, 2)
        SET @ParamMode1 = SUBSTRING(@ParameterInstr, LEN(@parameterInstr) - 2, 1)
        SET @ParamMode2 = SUBSTRING(@ParameterInstr, LEN(@parameterInstr) - 3, 1)

        IF @ParamMode1 = 0 SELECT @FirstNr = Val FROM OpCodes WHERE Ind = (SELECT Val FROM OpCodes WHERE Ind = @Pointer + 1 AND CompNr = @OpCodeCompNr) AND CompNr = @OpCodeCompNr
                      ELSE SELECT @FirstNr = Val FROM OpCodes WHERE Ind = @Pointer + 1 AND CompNr = @OpCodeCompNr
        IF @ParamMode2 = 0 SELECT @SecondNr = Val FROM OpCodes WHERE Ind = (SELECT Val FROM OpCodes WHERE Ind = @Pointer + 2 AND CompNr = @OpCodeCompNr) AND CompNr = @OpCodeCompNr
                      ELSE SELECT @SecondNr = Val FROM OpCodes WHERE Ind = @Pointer + 2 AND CompNr = @OpCodeCompNr

    
        --PRINT CAST(@ParameterInstr AS VARCHAR(10)) + ' ' + CAST(@Instr AS VARCHAR(2)) + ' ' + CAST(@FirstNr AS VARCHAR(5)) + ' ' + CAST(@SecondNr AS VARCHAR(5)) + ' ' + CAST(@ParamMode1 AS VARCHAR(1)) + ' ' + CAST(@ParamMode2 AS VARCHAR(1))

        IF @Instr In (1,2)
        BEGIN
            UPDATE OpCodes
            SET Val = CASE WHEN @Instr = 1 THEN @FirstNr + @SecondNr
                            WHEN @Instr = 2 THEN @FirstNr * @SecondNr
                                            ELSE Val END
            WHERE Ind = (SELECT Val FROM OpCodes WHERE Ind = @Pointer + 3 AND CompNr = @OpCodeCompNr) AND CompNr = @OpCodeCompNr

            SET @Pointer = @Pointer + 4

        END

        IF @Instr = 3
        BEGIN

            IF @InputConsumed = 0
            BEGIN

                UPDATE OpCodes
                SET Val = @Input
                WHERE Ind = (SELECT Val FROM OpCodes WHERE Ind = @Pointer + 1 AND CompNr = @OpCodeCompNr) AND CompNr = @OpCodeCompNr

                SET @Pointer = @Pointer + 2

                SET @InputConsumed = 1
            END
            ELSE
            BEGIN

                UPDATE ##Pointers 
                SET Pointer = @Pointer
                WHERE OpCodeCompNr = @OpCodeCompNr
            
                RETURN -99
            END
        END

        IF @Instr = 4
        BEGIN
            IF @ParamMode1 = 0 SELECT @Output = Val FROM OpCodes WHERE Ind = (SELECT Val FROM OpCodes WHERE Ind = @Pointer + 1 AND CompNr = @OpCodeCompNr) AND CompNr = @OpCodeCompNr
                          ELSE SELECT @Output = Val FROM OpCodes WHERE Ind = @Pointer + 1 AND CompNr = @OpCodeCompNr

            --PRINT 'Output = ' + CAST(@Output AS VARCHAR(10))

            SET @Pointer = @Pointer + 2

            UPDATE ##Pointers 
            SET Pointer = @Pointer
            WHERE OpCodeCompNr = @OpCodeCompNr
            
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
            UPDATE OpCodes
            SET Val = CASE WHEN @FirstNr < @SecondNr THEN 1 ELSE 0 END
            WHERE Ind = (SELECT Val FROM OpCodes WHERE Ind = @Pointer + 3 AND CompNr = @OpCodeCompNr) AND CompNr = @OpCodeCompNr
        
            SET @Pointer = @Pointer + 4
        END

        IF @Instr = 8
        BEGIN
    
            UPDATE OpCodes
            SET Val = CASE WHEN @FirstNr = @SecondNr THEN 1 ELSE 0 END
            WHERE Ind = (SELECT Val FROM OpCodes WHERE Ind = @Pointer + 3 AND CompNr = @OpCodeCompNr) AND CompNr = @OpCodeCompNr
        
            SET @Pointer = @Pointer + 4

        END


    END


    DROP TABLE #Input

END


*/