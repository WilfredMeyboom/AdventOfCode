use Test_WME

SET NOCOUNT ON

CREATE TABLE #Input (Nr NVARCHAR(MAX));

BULK INSERT #Input
FROM 'C:\Source\AdventOfCode\input5.txt'
WITH (ROWTERMINATOR = '0x0A');

--SELECT * FROM #Input

--DELETE FROM #Input
--INSERT #Input (Nr) VALUES ('1,9,10,3,2,3,11,0,99,30,40,50')

CREATE TABLE #OpCodes (Ind INT, Val INT)

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
INSERT #OpCodes (Ind, Val)
SELECT Ind, Val
FROM cte_Values OPTION (MAXRECURSION 10000)


DECLARE @Pointer INT
DECLARE @Instr INT
DECLARE @ParameterInstr VARCHAR(10)
DECLARE @FirstNr INT
DECLARE @SecondNr INT
DECLARE @DestNr INT
DECLARE @Input INT
DECLARE @Output INT
DECLARE @ParamMode1 INT
DECLARE @ParamMode2 INT

SET @Pointer = 0
SET @Instr = 0


SET @Input = 5

WHILE @Instr <> 99
BEGIN

    SELECT @ParameterInstr = '00000' + CAST(Val AS VARCHAR(10)) FROM #OpCodes WHERE Ind = @Pointer

    SET @Instr = RIGHT(@ParameterInstr, 2)
    SET @ParamMode1 = SUBSTRING(@ParameterInstr, LEN(@parameterInstr) - 2, 1)
    SET @ParamMode2 = SUBSTRING(@ParameterInstr, LEN(@parameterInstr) - 3, 1)

    IF @ParamMode1 = 0 SELECT @FirstNr = Val FROM #OpCodes WHERE Ind = (SELECT Val FROM #OpCodes WHERE Ind = @Pointer + 1)
                  ELSE SELECT @FirstNr = Val FROM #OpCodes WHERE Ind = @Pointer + 1
    IF @ParamMode2 = 0 SELECT @SecondNr = Val FROM #OpCodes WHERE Ind = (SELECT Val FROM #OpCodes WHERE Ind = @Pointer + 2)
                  ELSE SELECT @SecondNr = Val FROM #OpCodes WHERE Ind = @Pointer + 2

    
--    PRINT CAST(@ParameterInstr AS VARCHAR(10)) + ' ' + CAST(@Instr AS VARCHAR(2)) + ' ' + CAST(@FirstNr AS VARCHAR(5)) + ' ' + CAST(@SecondNr AS VARCHAR(5)) + ' ' + CAST(@ParamMode1 AS VARCHAR(1)) + ' ' + CAST(@ParamMode2 AS VARCHAR(1))

    IF @Instr In (1,2)
    BEGIN
        UPDATE #OpCodes
        SET Val = CASE WHEN @Instr = 1 THEN @FirstNr + @SecondNr
                        WHEN @Instr = 2 THEN @FirstNr * @SecondNr
                                        ELSE Val END
        WHERE Ind = (SELECT Val FROM #OpCodes WHERE Ind = @Pointer + 3)

        SET @Pointer = @Pointer + 4
    END

    IF @Instr = 3
    BEGIN
        UPDATE #OpCodes
        SET Val = @Input
        WHERE Ind = (SELECT Val FROM #OpCodes WHERE Ind = @Pointer + 1)

        SET @Pointer = @Pointer + 2
    END

    IF @Instr = 4
    BEGIN
        IF @ParamMode1 = 0 SELECT @Output = Val FROM #OpCodes WHERE Ind = (SELECT Val FROM #OpCodes WHERE Ind = @Pointer + 1)
                      ELSE SELECT @Output = Val FROM #OpCodes WHERE Ind = @Pointer + 1

        PRINT 'Output = ' + CAST(@Output AS VARCHAR(10))

        SET @Pointer = @Pointer + 2
        
        --PRINT @Pointer
        
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
        UPDATE #OpCodes
        SET Val = CASE WHEN @FirstNr < @SecondNr THEN 1 ELSE 0 END
        WHERE Ind = (SELECT Val FROM #OpCodes WHERE Ind = @Pointer + 3)
        
        SET @Pointer = @Pointer + 4
    END

    IF @Instr = 8
    BEGIN
    
        UPDATE #OpCodes
        SET Val = CASE WHEN @FirstNr = @SecondNr THEN 1 ELSE 0 END
        WHERE Ind = (SELECT Val FROM #OpCodes WHERE Ind = @Pointer + 3)
        
        SET @Pointer = @Pointer + 4

    END

    --SELECT @Output = Val FROM #OpCodes WHERE Ind = (SELECT Val FROM #OpCodes WHERE Ind = @Pointer - 1)
    --PRINT 'Temp Output = ' + CAST(@Output AS VARCHAR(10))

END


--SELECT * FROM #OpCodes

DROP TABLE #Input
DROP TABLE #OpCodes

--12896948 is correct for part 1

--15537994 is too high for part 2
--7704130 is correct for part 2