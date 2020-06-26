-- Advent of Code header als je de IntComp nodig hebt

USE Test_WME
GO

SET NOCOUNT ON

DECLARE @ProgramFile VARCHAR(250) = 'C:\Source\AdventOfCode\2019\input17.txt'

CREATE TABLE ##Pointers (OpCodeCompNr BIGINT, Pointer BIGINT, RelativeBase BIGINT)

DECLARE @Output BIGINT = 0

INSERT ##Pointers (OpCodeCompNr, Pointer, RelativeBase) VALUES (0, 0, 0)

-- PROCEDURE [dbo].[IntCodeComp] (@ProgramFile VARCHAR(250)
--								, @OpCodeCompNr INT
--								, @Input BIGINT
--								, @Output BIGINT OUTPUT)

------------------- IntComp loaded


DECLARE @SkipPart1 INT = 1

IF @SkipPart1 = 0
BEGIN

CREATE TABLE ##Grid (ID INT IDENTITY(1,1), x INT, y INT, Val INT)
DECLARE @x INT = 0
DECLARE @y INT = 0

WHILE @Output <> 99 
BEGIN    

    EXEC IntCodeComp @ProgramFile, 0, 0 /*input*/, @Output OUTPUT

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

DROP TABLE Opcodes
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

END -- End of part 1
ELSE
BEGIN -- Start part 2

SET @ProgramFile = 'C:\Source\AdventOfCode\2019\input17_Part2.txt'


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
INSERT ##InputInstructions (Input) VALUES (76),(44),(54),(44),(54),(44),(76),(44),(54),(44),(76),(44),(56),(44),(82),(44),(54),(10)
INSERT ##InputInstructions (Input) VALUES (110),(10)
  


--SELECT * FROM ##InputInstructions



DECLARE @Counter INT = 1
DECLARE @Input INT
DECLARE @ScaffoldingDone INT = 0

--Initialize input
SELECT @Input = Input FROM ##InputInstructions WHERE ID = @Counter

WHILE @Output <> -999999 
BEGIN    

    --PRINT 'Input: ' + CAST(@Input AS VARCHAR(10))

    EXEC IntCodeComp @ProgramFile, 0, @Input, @Output OUTPUT


    IF @Output = -99999 
    BEGIN
        SET @ScaffoldingDone = 1
        SET @Counter = @Counter + 1
        SELECT @Input = Input FROM ##InputInstructions WHERE ID = @Counter
        PRINT 'Input: ' + CAST(@Input AS VARCHAR(10))
    END

    IF @ScaffoldingDone = 1
        PRINT 'Output: ' + CAST(@Output AS VARCHAR(10))


END


/*
DROP TABLE Opcodes
DROP TABLE ##Pointers
DROP TABLE ##InputInstructions
*/

END -- End of part 2

--897344 is correct for part 2 


/*
USE [Test_WME]
GO
/****** Object:  StoredProcedure [dbo].[IntCodeComp]    Script Date: 2020-06-26 5:38:35 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
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
    SET @Output = -999999
    RETURN

END

*/

