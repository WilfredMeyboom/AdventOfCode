use Test_WME
GO

SET NOCOUNT ON

DECLARE @ProgramFile VARCHAR(250) = 'C:\Source\AdventOfCode\2019\input9.txt'

CREATE TABLE ##Pointers (OpCodeCompNr BIGINT, Pointer BIGINT, RelativeBase BIGINT)

DECLARE @Output BIGINT = 0

INSERT ##Pointers (OpCodeCompNr, Pointer, RelativeBase) VALUES (0, 0, 0)


WHILE @Output <> 99
BEGIN
--    EXEC IntCodeComp @ProgramFile, 0, 1 /*input*/, @Output OUTPUT -- For part 1
    EXEC IntCodeComp @ProgramFile, 0, 2 /*input*/, @Output OUTPUT -- For part 2

PRINT '-------------------------------------->' + CAST(@Output AS VARCHAR(50))

END

--SELECT * FROM Opcodes
--SELECT * FROM ##Pointers

DROP TABLE Opcodes
DROP TABLE ##Pointers

-- 3063082071 is correct for part 1

/*
USE Test_WME
GO

CREATE OR ALTER PROCEDURE IntCodeComp (@ProgramFile VARCHAR(250), @OpCodeCompNr INT, @Input BIGINT, @Output BIGINT OUTPUT) AS 
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
    DECLARE @1stNr BIGINT
    DECLARE @2ndNr BIGINT
    DECLARE @3rdNr INT
    
    DECLARE @ParamMode1 INT
    DECLARE @ParamMode2 INT
    DECLARE @ParamMode3 INT
    DECLARE @InputConsumed INT = 0
    DECLARE @RelativeBase BIGINT

    SELECT @Pointer = Pointer 
    ,      @RelativeBase = RelativeBase 
    FROM ##Pointers 
    WHERE OpCodeCompNr = @OpCodeCompNr

    SET @Instr = 0

    WHILE @Instr <> 99
    BEGIN

        SELECT @ParameterInstr = '00000' + CAST(Val AS VARCHAR(10)) FROM OpCodes WHERE Ind = @Pointer AND CompNr = @OpCodeCompNr

        SET @Instr = RIGHT(@ParameterInstr, 2)
        SET @ParamMode1 = SUBSTRING(@ParameterInstr, LEN(@parameterInstr) - 2, 1)
        SET @ParamMode2 = SUBSTRING(@ParameterInstr, LEN(@parameterInstr) - 3, 1)
        SET @ParamMode3 = SUBSTRING(@ParameterInstr, LEN(@parameterInstr) - 4, 1)

        --Check if memory position exists (where the computer wants to write to)
        IF @Instr IN (1, 2, 3, 7, 8, 9)
        BEGIN
            IF @ParamMode1 = 0 AND NOT EXISTS(SELECT 1 FROM OpCodes WHERE Ind = (SELECT Val FROM OpCodes WHERE Ind = @Pointer + 1 AND CompNr = @OpCodeCompNr) AND CompNr = @OpCodeCompNr) 
                INSERT OpCodes (CompNr, Ind, Val) SELECT @OpCodeCompNr, Val, 0 FROM OpCodes WHERE Ind = @Pointer + 1 AND CompNr = @OpCodeCompNr
            IF @ParamMode1 = 2 AND NOT EXISTS(SELECT 1 FROM OpCodes WHERE Ind = (SELECT Val FROM OpCodes WHERE Ind = @Pointer + 1 AND CompNr = @OpCodeCompNr) + @RelativeBase AND CompNr = @OpCodeCompNr) 
                INSERT OpCodes (CompNr, Ind, Val) SELECT @OpCodeCompNr, Val + @RelativeBase, 0 FROM OpCodes WHERE Ind = @Pointer + 1 AND CompNr = @OpCodeCompNr
        END
        IF @Instr IN (1, 2, 7, 8)
        BEGIN
            IF @ParamMode2 = 0 AND NOT EXISTS(SELECT 1 FROM OpCodes WHERE Ind = (SELECT Val FROM OpCodes WHERE Ind = @Pointer + 2 AND CompNr = @OpCodeCompNr) AND CompNr = @OpCodeCompNr) 
                INSERT OpCodes (CompNr, Ind, Val) SELECT @OpCodeCompNr, Val, 0 FROM OpCodes WHERE Ind = @Pointer + 2 AND CompNr = @OpCodeCompNr
            IF @ParamMode2 = 2 AND NOT EXISTS(SELECT 1 FROM OpCodes WHERE Ind = (SELECT Val FROM OpCodes WHERE Ind = @Pointer + 2 AND CompNr = @OpCodeCompNr) + @RelativeBase AND CompNr = @OpCodeCompNr) 
                INSERT OpCodes (CompNr, Ind, Val) SELECT @OpCodeCompNr, Val + @RelativeBase, 0 FROM OpCodes WHERE Ind = @Pointer + 2 AND CompNr = @OpCodeCompNr
            IF @ParamMode3 = 0 AND NOT EXISTS(SELECT 1 FROM OpCodes WHERE Ind = (SELECT Val FROM OpCodes WHERE Ind = @Pointer + 3 AND CompNr = @OpCodeCompNr) AND CompNr = @OpCodeCompNr) 
                INSERT OpCodes (CompNr, Ind, Val) SELECT @OpCodeCompNr, Val, 0 FROM OpCodes WHERE Ind = @Pointer + 3 AND CompNr = @OpCodeCompNr
            IF @ParamMode3 = 2 AND NOT EXISTS(SELECT 1 FROM OpCodes WHERE Ind = (SELECT Val FROM OpCodes WHERE Ind = @Pointer + 3 AND CompNr = @OpCodeCompNr) + @RelativeBase AND CompNr = @OpCodeCompNr) 
                INSERT OpCodes (CompNr, Ind, Val) SELECT @OpCodeCompNr, Val + @RelativeBase, 0 FROM OpCodes WHERE Ind = @Pointer + 3 AND CompNr = @OpCodeCompNr
        END
   
        IF @ParamMode1 = 0 SELECT @1stNr = Val FROM OpCodes WHERE Ind = (SELECT Val FROM OpCodes WHERE Ind = @Pointer + 1 AND CompNr = @OpCodeCompNr) AND CompNr = @OpCodeCompNr
        IF @ParamMode1 = 1 SELECT @1stNr = Val FROM OpCodes WHERE Ind = @Pointer + 1 AND CompNr = @OpCodeCompNr
        IF @ParamMode1 = 2 SELECT @1stNr = Val FROM OpCodes WHERE Ind = (SELECT Val + @RelativeBase FROM OpCodes WHERE Ind = @Pointer + 1 AND CompNr = @OpCodeCompNr) AND CompNr = @OpCodeCompNr

        IF @ParamMode2 = 0 SELECT @2ndNr = Val FROM OpCodes WHERE Ind = (SELECT Val FROM OpCodes WHERE Ind = @Pointer + 2 AND CompNr = @OpCodeCompNr) AND CompNr = @OpCodeCompNr
        IF @ParamMode2 = 1 SELECT @2ndNr = Val FROM OpCodes WHERE Ind = @Pointer + 2 AND CompNr = @OpCodeCompNr
        IF @ParamMode2 = 2 SELECT @2ndNr = Val FROM OpCodes WHERE Ind = (SELECT Val + @RelativeBase FROM OpCodes WHERE Ind = @Pointer + 2 AND CompNr = @OpCodeCompNr) AND CompNr = @OpCodeCompNr

        --IF @ParamMode3 = 0 
        SELECT @3rdNr = Val FROM OpCodes WHERE Ind = @Pointer + 3 AND CompNr = @OpCodeCompNr
        IF @ParamMode3 = 2 SET @3rdNr = @3rdNr + @RelativeBase
        --@ParamMode3 should never be 1

        --PRINT ISNULL(
        --    'Opcodecomp: ' + CAST(@OpCodeCompNr AS VARCHAR(3)) + 
        --    ' Pointer: ' + CAST(@Pointer AS VARCHAR(5)) + 
        --    ' ParamInstr: ' + CAST(@ParameterInstr AS VARCHAR(10)) + 
        --    ' Instr: ' + CAST(@Instr AS VARCHAR(2)) + 
        --    ' 1stNr: ' + ISNULL(CAST(@1stNr AS VARCHAR(500)), '-') + 
        --    ' 2ndNr: ' + ISNULL(CAST(@2ndNr AS VARCHAR(500)), '-') + 
        --    ' 3rdNr: ' + ISNULL(CAST(@3rdNr AS VARCHAR(500)), '-') + 
        --    ' ParamMode1: ' + ISNULL(CAST(@ParamMode1 AS VARCHAR(1)), '-') + 
        --    ' ParamMode2: ' + ISNULL(CAST(@ParamMode2 AS VARCHAR(1)), '-') +
        --    ' ParamMode3: ' + ISNULL(CAST(@ParamMode3 AS VARCHAR(1)), '-') +
        --    ' RelativeBase: ' + CAST(@RelativeBase AS VARCHAR(6))
        --    , 'Log fail')

        --SELECT @ParameterInstr AS [PI], @Pointer AS P, @RelativeBase AS RB, * FROM OpCodes ORDER BY Ind

        IF @Instr In (1,2)
        -- Add (1) or Multiply (2) two numbers
        BEGIN
            UPDATE OpCodes
            SET Val = CASE WHEN @Instr = 1 THEN @1stNr + @2ndNr
                            WHEN @Instr = 2 THEN @1stNr * @2ndNr
                                            ELSE Val END
            WHERE Ind = @3rdNr AND CompNr = @OpCodeCompNr

            SET @Pointer = @Pointer + 4

        END

        IF @Instr = 3
        -- The OpcodeComp got an input parameter when it was started. Assign this input to a register
        -- If it was already assigned then halt and get ready to be restarted with new input
        BEGIN

            IF @InputConsumed = 0
            BEGIN

                -- Retrieve the first number because it will be used as output
                SELECT @1stNr = Val FROM OpCodes WHERE Ind = @Pointer + 1 AND @OpCodeCompNr = CompNr

                IF @ParamMode1 = 0                 
                    UPDATE OpCodes
                    SET Val = @Input
                    WHERE Ind = @1stNr AND CompNr = @OpCodeCompNr

                IF @ParamMode1 = 1 PRINT '*** UNEXPECTED PARAMETER MODE FOR INSTRUCTION 3 ***'

                IF @ParamMode1 = 2
                    UPDATE OpCodes
                    SET Val = @Input
                    WHERE Ind = (@1stNr + @RelativeBase) AND CompNr = @OpCodeCompNr
                    
                SET @Pointer = @Pointer + 2

                SET @InputConsumed = 1
            END
            ELSE
            BEGIN

                UPDATE ##Pointers 
                SET Pointer = @Pointer
                ,   RelativeBase = @RelativeBase
                WHERE OpCodeCompNr = @OpCodeCompNr
            
                SET @Output = -99
                RETURN
            END
        END

        IF @Instr = 4
        -- Output the value in a certain register
        BEGIN

            SET @Output = @1stNr

            --PRINT 'Output = ' + CAST(@Output AS VARCHAR(100))

            SET @Pointer = @Pointer + 2

            UPDATE ##Pointers 
            SET Pointer = @Pointer
            ,   RelativeBase = @RelativeBase
            WHERE OpCodeCompNr = @OpCodeCompNr
            
            RETURN 
        END

        IF @Instr = 5
        -- Jump if not zero
        BEGIN
            IF @1stNr <> 0 SET @Pointer = @2ndNr
            ELSE SET @Pointer = @Pointer + 3
        END

        IF @Instr = 6
        -- Jump if zero
        BEGIN
            IF @1stNr = 0 SET @Pointer = @2ndNr
            ELSE SET @Pointer = @Pointer + 3
        END

        IF @Instr = 7
        -- If first nr is smaller than the second nr set result to 1 else 0
        BEGIN
            UPDATE OpCodes
            SET Val = CASE WHEN @1stNr < @2ndNr THEN 1 ELSE 0 END
            WHERE Ind = @3rdNr AND CompNr = @OpCodeCompNr
        
            SET @Pointer = @Pointer + 4
        END

        IF @Instr = 8
        -- If first nr is equal to the second nr set result to 1 else 0
        BEGIN
    
            UPDATE OpCodes
            SET Val = CASE WHEN @1stNr = @2ndNr THEN 1 ELSE 0 END
            WHERE Ind = @3rdNr AND CompNr = @OpCodeCompNr
        
            SET @Pointer = @Pointer + 4

        END

        IF @Instr = 9
        -- Adjust the relative base
        BEGIN
    
            SET @RelativeBase = @RelativeBase + @1stNr
        
            SET @Pointer = @Pointer + 2

        END
    END

-- Natural program end
    SET @Output = 99
    RETURN

END


*/