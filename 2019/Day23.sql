USE Test_WME
GO

SET NOCOUNT ON

DECLARE @ProgramFile VARCHAR(250) = 'C:\Source\AdventOfCode\2019\input23.txt'

CREATE TABLE ##Pointers (OpCodeCompNr BIGINT, Pointer BIGINT, RelativeBase BIGINT, Ticks BIGINT)

DECLARE @Output BIGINT = 0

INSERT ##Pointers (OpCodeCompNr, Pointer, RelativeBase, Ticks)
SELECT TOP 50 ROW_NUMBER() OVER (ORDER BY (SELECT 0)) - 1, 0, 0, 0
FROM sys.messages


-- PROCEDURE [dbo].[IntCodeComp] (@ProgramFile VARCHAR(250)
--                                , @OpCodeCompNr INT
--                                , @Input BIGINT
--                                , @Output BIGINT OUTPUT)

------------------- IntComp loaded

DECLARE @Counter INT = 0
DECLARE @Debug INT = 0

--Boot up comps
WHILE @Counter < 50
BEGIN

IF @Debug = 1 PRINT 'Initialize IntCodeComp ' + CAST(@Counter AS VARCHAR(2)) + ' at ' + CAST(GETDATE() AS VARCHAR(50))

    EXEC [dbo].[IntCodeComp]  @ProgramFile 
                            , @Counter --@OpCodeCompNr INT
                            , @Counter --@Input BIGINT
                            , @Output OUTPUT

IF @Debug = 1 PRINT 'Done initializing IntCodeComp ' + CAST(@Counter AS VARCHAR(2)) + ' at ' + CAST(GETDATE() AS VARCHAR(50))

    
    SET @Counter = @Counter + 1
END

CREATE TABLE ##PacketQueue (ID BIGINT IDENTITY(1,1), DestComp INT, X BIGINT, Y BIGINT, OrgComp INT, Ticks INT)

DECLARE @X BIGINT
DECLARE @Y BIGINT
DECLARE @Dest INT
DECLARE @CurrentComp INT = 0
DECLARE @ID BIGINT
DECLARE @TimeSlice INT = 0
DECLARE @Ticks BIGINT = 0


WHILE (SELECT COUNT(1) FROM ##PacketQueue WHERE DestComp = 255) = 0
BEGIN
    
    -- There are two variables:
        -- There is a package for this Intcomp (Yes/No)
        -- After running this Intcomp it generates a package (Yes/No)


    IF EXISTS(SELECT 1 
              FROM ##PacketQueue PQ
              INNER JOIN ##Pointers P ON PQ.DestComp = P.OpCodeCompNr 
              WHERE DestComp = @CurrentComp
                AND P.Ticks > PQ.Ticks
             )
    BEGIN

        SELECT TOP 1 @ID = ID, @Dest = DestComp, @X = X, @Y = Y
        FROM ##PacketQueue
        WHERE DestComp = @CurrentComp
        ORDER BY Ticks, ID --> Dit zou nog fout kunnen zijn. 

    END
    ELSE 
    BEGIN
        SET @X = -1
    END

IF @Debug = 1 PRINT 'Run IntCodeComp ' + CAST(@CurrentComp AS VARCHAR(2)) + ' at ' + CAST(GETDATE() AS VARCHAR(50)) + ' with x = ' + ISNULL(CAST(@x AS VARCHAR(50)), 'Huh?') + ' and y = ' + ISNULL(CAST(@y AS VARCHAR(50)), 'N/A')

    -- Always run the current intcomp at least once
    EXEC [dbo].[IntCodeComp]  @ProgramFile 
                            , @CurrentComp --@OpCodeCompNr INT
                            , @X --@Input BIGINT
                            , @Output OUTPUT

IF @Debug = 1 PRINT 'End of run IntCodeComp ' + CAST(@CurrentComp AS VARCHAR(2)) + ' at ' + CAST(GETDATE() AS VARCHAR(50)) + ' with output = ' + CAST(@Output AS VARCHAR(50)) 

    IF @X <> -1 AND @Output = -99999
    -- There was input so the system should come back asking for Y
    -- In this case @Output is -99999 so we can disregard this result
    BEGIN

IF @Debug = 1 PRINT 'Run IntCodeComp again ' + CAST(@CurrentComp AS VARCHAR(2)) + ' at ' + CAST(GETDATE() AS VARCHAR(50)) + ' with x = ' + CAST(@x AS VARCHAR(50)) + ' and y = ' + ISNULL(CAST(@y AS VARCHAR(50)), 'N/A')

        PRINT 'Comp ' + CAST(@CurrentComp AS VARCHAR(2)) + 
             ' had as X input ' + CAST(@X AS VARCHAR(50)) +
             ' and gives as output : ' + CAST(@Output AS VARCHAR(50)) +
             ' at timeslice : ' + CAST(@TimeSlice AS VARCHAR(10))

        EXEC [dbo].[IntCodeComp]  @ProgramFile 
                                , @CurrentComp --@OpCodeCompNr INT
                                , @Y --@Input BIGINT
                                , @Output OUTPUT

IF @Debug = 1 PRINT 'End of run IntCodeComp again ' + CAST(@CurrentComp AS VARCHAR(2)) + ' at ' + CAST(GETDATE() AS VARCHAR(50)) + ' with output = ' + CAST(@Output AS VARCHAR(50))
        
        PRINT 'Comp ' + CAST(@CurrentComp AS VARCHAR(2)) + 
              ' had as Y input ' + CAST(@Y AS VARCHAR(50)) +
              ' and gives as output : ' + CAST(@Output AS VARCHAR(50)) +
              ' at timeslice : ' + CAST(@TimeSlice AS VARCHAR(10))

        -- The package has been consumed so we delete it
        DELETE FROM ##PacketQueue WHERE ID = @ID
    END
    ELSE IF @X <> -1
    BEGIN
        -- If we supply an x the intcomp should come back asking for an y. If not, something is wrong
        PRINT '**************** ERROR This point should never be reached ****************'
    END


    IF @Output <> -99999 -- Did the work result in a package
    BEGIN
        SET @Dest = @Output

        EXEC [dbo].[IntCodeComp]  @ProgramFile 
                            , @CurrentComp --@OpCodeCompNr INT
                            , -1 --@Input BIGINT
                            , @Output OUTPUT
        SET @X = @Output

        PRINT 'Comp ' + CAST(@CurrentComp AS VARCHAR(2)) + 
              ' had as input -1' +
              ' and gives as output : ' + CAST(@Output AS VARCHAR(50)) +
              '. Executed to get the x value' +
              ' at timeslice : ' + CAST(@TimeSlice AS VARCHAR(10))


        EXEC [dbo].[IntCodeComp]  @ProgramFile 
                            , @CurrentComp --@OpCodeCompNr INT
                            , -1 --@Input BIGINT
                            , @Output OUTPUT
        SET @Y = @Output

        PRINT 'Comp ' + CAST(@CurrentComp AS VARCHAR(2)) + 
              ' had as input -1' +
              ' and gives as output : ' + CAST(@Output AS VARCHAR(50)) +
              '. Executed to get the y value' +
              ' at timeslice : ' + CAST(@TimeSlice AS VARCHAR(10))

        SELECT @Ticks = Ticks FROM ##Pointers WHERE OpCodeCompNr = @CurrentComp

        INSERT ##PacketQueue (DestComp, X, Y, OrgComp, Ticks) SELECT @Dest, @X, @Y, @CurrentComp, @Ticks

    END

    --SET @CurrentComp = (@CurrentComp + 1) % 50
    -- Start the IntcodeComp who is farthest behind the others. In case of a tie the one with a lower number
    SELECT TOP 1 @CurrentComp = P.OpCodeCompNr FROM ##Pointers P ORDER BY Ticks, OpCodeCompNr 

    IF @CurrentComp = 0 
    BEGIN
        SET @TimeSlice = @TimeSlice + 1
        PRINT 'TimeSlice : ' + CAST(@TimeSlice AS VARCHAR(10)) + ' at ' + CAST(GETDATE() AS VARCHAR(50))
    END

END

SELECT * FROM ##PacketQueue

/*

DROP TABLE ##PacketQueue
DROP TABLE ##Pointers
DROP TABLE Opcodes

*/
-- Run gestart om 10:06 en gestopt op 11:34
/*
Changed OpcodeComp:


USE [Test_WME]
GO


ALTER   PROCEDURE [dbo].[IntCodeComp] (@ProgramFile VARCHAR(250), @OpCodeCompNr INT, @Input BIGINT, @Output BIGINT OUTPUT) AS 
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


    DECLARE @Ticks BIGINT
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
    DECLARE @Debug INT = 0

    --This is the input which causes the debug to switch on
    --IF @Input = 10 SET @Debug = 1

    SELECT @Pointer = Pointer 
    ,      @RelativeBase = RelativeBase 
    ,      @Ticks = Ticks
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

        IF @Debug = 1
            PRINT ISNULL(
                'Opcodecomp: ' + CAST(@OpCodeCompNr AS VARCHAR(3)) + 
                ' Pointer: ' + CAST(@Pointer AS VARCHAR(5)) + 
                ' ParamInstr: ' + CAST(@ParameterInstr AS VARCHAR(10)) + 
                ' Instr: ' + CAST(@Instr AS VARCHAR(2)) + 
                ' 1stNr: ' + ISNULL(CAST(@1stNr AS VARCHAR(500)), '-') + 
                ' 2ndNr: ' + ISNULL(CAST(@2ndNr AS VARCHAR(500)), '-') + 
                ' 3rdNr: ' + ISNULL(CAST(@3rdNr AS VARCHAR(500)), '-') + 
                ' ParamMode1: ' + ISNULL(CAST(@ParamMode1 AS VARCHAR(1)), '-') + 
                ' ParamMode2: ' + ISNULL(CAST(@ParamMode2 AS VARCHAR(1)), '-') +
                ' ParamMode3: ' + ISNULL(CAST(@ParamMode3 AS VARCHAR(1)), '-') +
                ' RelativeBase: ' + CAST(@RelativeBase AS VARCHAR(6))
                , 'Log fail')

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
        -- After the input has been 'consumed' exit the OpcodeComp to get a new input
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

            UPDATE ##Pointers 
            SET Pointer = @Pointer
            ,   RelativeBase = @RelativeBase
            ,   Ticks = @Ticks
            WHERE OpCodeCompNr = @OpCodeCompNr
            
            SET @Output = -99999
            RETURN

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
            ,   Ticks = @Ticks
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

        -- Assuming every instruction takes 1 tick
        SET @Ticks = @Ticks + 1
    END

-- Natural program end
    SET @Output = -999999
    RETURN

END


*/