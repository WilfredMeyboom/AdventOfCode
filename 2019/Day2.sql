use Test_WME

SET NOCOUNT ON

CREATE TABLE #Input (Nr NVARCHAR(MAX));

BULK INSERT #Input
FROM 'C:\Source\AdventOfCode\2019\input2.txt'
WITH (ROWTERMINATOR = '0x0A');

UPDATE #Input
SET nr = LEFT(nr, LEN(nr)-1)

--SELECT * FROM #Input

--DELETE FROM #Input
--INSERT #Input (Nr) VALUES ('1,9,10,3,2,3,11,0,99,30,40,50')

CREATE TABLE #BaseOpCodes (Ind INT, Val INT)

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
INSERT #BaseOpCodes (Ind, Val)
SELECT Ind, Val
FROM cte_Values OPTION (MAXRECURSION 10000)


DECLARE @Pointer INT
DECLARE @Instr INT
DECLARE @FirstNr INT
DECLARE @SecondNr INT
DECLARE @DestNr INT

SET @Pointer = 0
SET @Instr = 0

--SELECT * FROM #BaseOpCodes

--UPDATE #OpCodes
--SET Val = 12
--WHERE Ind = 1

--UPDATE #OpCodes
--SET Val = 2
--WHERE Ind = 2

DECLARE @CalcDone BIT = 0
DECLARE @Counter1 INT = 0
DECLARE @Counter2 INT = 0

WHILE @CalcDone = 0
BEGIN
    
    SELECT * INTO #OpCodes FROM #BaseOpCodes

    UPDATE #OpCodes
    SET Val = @Counter1
    WHERE Ind = 1

    UPDATE #OpCodes
    SET Val = @Counter2
    WHERE Ind = 2

    --SELECT * FROM #OpCodes

    WHILE @Instr <> 99
    BEGIN

        SELECT @Instr = Val FROM #OpCodes WHERE Ind = @Pointer
        SELECT @FirstNr = Val FROM #OpCodes WHERE Ind = (SELECT Val FROM #OpCodes WHERE Ind = @Pointer + 1)
        SELECT @SecondNr = Val FROM #OpCodes WHERE Ind = (SELECT Val FROM #OpCodes WHERE Ind = @Pointer + 2)
        SELECT @DestNr = Val FROM #OpCodes WHERE Ind = @Pointer + 3

    --PRINT 'Instr ' + CAST(@Instr AS VARCHAR(2))
    --PRINT @FirstNr 
    --PRINT @SecondNr
    --PRINT @DestNr    


        UPDATE #OpCodes
        SET Val = CASE WHEN @Instr = 1 THEN @FirstNr + @SecondNr
                       WHEN @Instr = 2 THEN @FirstNr * @SecondNr
                                       ELSE Val END
        WHERE Ind = @DestNr

        SET @Pointer = @Pointer + 4

    END

    SELECT @CalcDone = 1 FROM #OpCodes WHERE Ind = 0 AND Val = 19690720
 
    DROP TABLE #OpCodes

    IF @CalcDone = 0
    BEGIN

        SET @Counter1 = @Counter1 + 1

        IF @Counter1 = 100
        BEGIN
            SET @Counter1 = 0
            SET @Counter2 = @Counter2 + 1
            IF @Counter2 = 100 SET @CalcDone = 1
        END

        PRINT CAST(@Counter1 AS VARCHAR(3)) + ' ' + CAST(@Counter2 AS VARCHAR(3)) + ' ' + CAST(GETDATE() AS VARCHAR(50))

        SET @Pointer = 0
        SET @Instr = 0 
    END

--SELECT * FROM #BaseOpCodes
END


SELECT @Counter1, @Counter2


DROP TABLE #Input
DROP TABLE #BaseOpCodes

--3790689 is correct for part 1

--6533 is correct for part 2