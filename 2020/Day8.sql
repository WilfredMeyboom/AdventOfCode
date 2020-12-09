USE Test_WME

SET NOCOUNT ON

CREATE TABLE ##Input (Line NVARCHAR(MAX));

BULK INSERT ##Input
FROM 'C:\Source\AdventOfCode\2020\input8.txt'
WITH (ROWTERMINATOR = '0x0A');

CREATE TABLE ##Program (ID INT IDENTITY(1,1), Instr CHAR(3), InstrVal BIGINT)

INSERT ##Program (Instr, InstrVal)
SELECT LEFT(Line, 3) AS Instr, SUBSTRING(Line, 4, LEN(Line)) AS InstrVal
FROM ##Input

CREATE TABLE ##VisitedInstr (InstrID INT)

DECLARE @Accum BIGINT = 0
DECLARE @Pointer BIGINT = 1

DECLARE @Instr CHAR(3)
DECLARE @InstrVal BIGINT

WHILE NOT EXISTS (SELECT 1 FROM ##VisitedInstr GROUP BY InstrID HAVING COUNT(1) > 1)
BEGIN

    SELECT @Instr = Instr, @InstrVal = InstrVal FROM ##Program WHERE ID = @Pointer

    IF (@Instr = 'acc') SET @Accum = @Accum + @InstrVal

    IF (@Instr = 'jmp') SET @Pointer = @Pointer + @InstrVal - 1

    SET @Pointer = @Pointer + 1

    INSERT ##VisitedInstr (InstrID) SELECT @Pointer
END

PRINT 'Part 1 answer:'
PRINT @Accum
PRINT ''

-- 1475 is correct for part 1

ALTER TABLE ##Program ADD NopJmpCounter BIGINT

;WITH cte_NopJmpNr AS (
    SELECT ID, ROW_NUMBER() OVER (ORDER BY ID) AS NopJmpNr
    FROM ##Program
    WHERE Instr IN ('jmp', 'nop')
)
UPDATE P
SET NopJmpCounter = cN.NopJmpNr
FROM ##Program P
INNER JOIN cte_NopJmpNr cN ON P.ID = cN.ID


DECLARE @CorrectEnd INT = 0
DECLARE @NopJmpCounter BIGINT = 1

WHILE @CorrectEnd = 0
BEGIN

    SET @Accum = 0
    TRUNCATE TABLE ##VisitedInstr
    SET @Pointer = 1

    -- Switch one instruction
    UPDATE ##Program
    SET Instr = CASE WHEN Instr = 'nop' THEN 'jmp' ELSE 'nop' END
    WHERE NopJmpCounter = @NopJmpCounter

    PRINT 'Trying NopJmpCounter: ' + CAST(@NopJmpCounter AS VARCHAR(6)) + ' at ' + CAST(GETDATE() AS VARCHAR(50))

    WHILE (NOT EXISTS (SELECT 1 FROM ##VisitedInstr GROUP BY InstrID HAVING COUNT(1) > 1)) AND @CorrectEnd = 0
    BEGIN

        SELECT @Instr = Instr, @InstrVal = InstrVal FROM ##Program WHERE ID = @Pointer

        IF (@Instr = 'acc') SET @Accum = @Accum + @InstrVal

        IF (@Instr = 'jmp') SET @Pointer = @Pointer + @InstrVal - 1

        SET @Pointer = @Pointer + 1

        INSERT ##VisitedInstr (InstrID) SELECT @Pointer

        IF @Pointer = (SELECT MAX(ID) + 1 FROM ##Program) SET @CorrectEnd = 1
    END

    -- Switch instruction back
    UPDATE ##Program
    SET Instr = CASE WHEN Instr = 'nop' THEN 'jmp' ELSE 'nop' END
    WHERE NopJmpCounter = @NopJmpCounter

    SET @NopJmpCounter = @NopJmpCounter + 1


END

PRINT '@NopJmpCounter: ' + CAST(@NopJmpCounter AS VARCHAR(6))
PRINT '@Accum: ' + CAST(@Accum AS VARCHAR(12))

-- 1270 is correct for part 2

/*
DROP TABLE ##VisitedInstr
DROP TABLE ##Program
DROP TABLE ##Input
*/

