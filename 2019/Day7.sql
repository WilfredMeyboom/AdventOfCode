USE Test_WME
GO

CREATE OR ALTER PROCEDURE IntCodeComp (@ProgramFile VARCHAR(250), @Input BIGINT, @OpCodeCompNr INT, @Output BIGINT OUTPUT) AS 
BEGIN

    SET NOCOUNT ON

    --Create on first call
    IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'OpCodes')
        CREATE TABLE OpCodes (CompNr INT, Ind INT, Val BIGINT)

    IF (SELECT COUNT(1) FROM OpCodes WHERE CompNr = @OpCodeCompNr) = 0
    BEGIN

        CREATE TABLE #Input (Nr NVARCHAR(MAX));

        DECLARE @Sql NVARCHAR(MAX)

        SET @Sql = 'BULK INSERT #Input FROM ''' + @ProgramFile + 
            ''' WITH (ROWTERMINATOR = ''0x0A'');'
        --PRINT @Sql
        EXEC sp_executesql @Sql

        UPDATE #Input SET Nr = LEFT(Nr, LEN(Nr)-1)

        --SELECT * FROM #Input

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

        DROP TABLE #Input
    END



    DECLARE @Pointer INT
    DECLARE @Instr INT
    DECLARE @ParameterInstr VARCHAR(10)
    DECLARE @FirstNr BIGINT
    DECLARE @SecondNr BIGINT
    DECLARE @DestNr INT
    
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

    
        --PRINT ISNULL(
        --    'Opcodecomp: ' + CAST(@OpCodeCompNr AS VARCHAR(3)) + 
        --    ' ParamInstr: ' + CAST(@ParameterInstr AS VARCHAR(10)) + 
        --    ' Instr: ' + CAST(@Instr AS VARCHAR(2)) + 
        --    ' FirstNr: ' + CAST(@FirstNr AS VARCHAR(500)) + 
        --    ' SecondNr: ' + ISNULL(CAST(@SecondNr AS VARCHAR(500)), '-') + 
        --    ' ParamMode1: ' + CAST(@ParamMode1 AS VARCHAR(1)) + 
        --    ' ParamMode2: ' + ISNULL(CAST(@ParamMode2 AS VARCHAR(1)), '-')
        --    , 'Log fail')

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
            
                SET @Output = -99
                RETURN
            END
        END

        IF @Instr = 4
        BEGIN
            IF @ParamMode1 = 0 SELECT @Output = Val FROM OpCodes WHERE Ind = (SELECT Val FROM OpCodes WHERE Ind = @Pointer + 1 AND CompNr = @OpCodeCompNr) AND CompNr = @OpCodeCompNr
                          ELSE SELECT @Output = Val FROM OpCodes WHERE Ind = @Pointer + 1 AND CompNr = @OpCodeCompNr

            --PRINT 'Output = ' + CAST(@Output AS VARCHAR(100))

            SET @Pointer = @Pointer + 2

            UPDATE ##Pointers 
            SET Pointer = @Pointer
            WHERE OpCodeCompNr = @OpCodeCompNr
            
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

-- Natural program end
    SET @Output = 99
    RETURN

END
