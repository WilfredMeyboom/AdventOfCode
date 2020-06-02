use Test_WME

SET NOCOUNT ON

CREATE TABLE #Input (Nr NVARCHAR(MAX));

BULK INSERT #Input
FROM 'C:\Source\AdventOfCode\input16_example3.txt'
WITH (ROWTERMINATOR = '0x0A');

CREATE TABLE ##Input (ID INT IDENTITY(1,1), Ind INT, Nr INT, UNIQUE(Ind))

;WITH cte_Nrs AS (
    SELECT 1 AS Ind
    ,      LEFT(Nr, 1) AS Number
    ,      SUBSTRING(Nr, 2, LEN(Nr)) AS Rest
    FROM #Input
    UNION ALL
    SELECT Ind + 1 AS Ind
    ,      LEFT(Rest, 1) AS Number
    ,      SUBSTRING(Rest, 2, LEN(Rest)) AS Rest
    FROM cte_Nrs
    WHERE LEN(Rest) > 0
)
INSERT ##Input (Ind, Nr)
SELECT Ind, Number
FROM cte_Nrs
OPTION (MAXRECURSION 10000)

DROP TABLE #Input

CREATE TABLE ##BasePattern (ID INT, Val INT)

INSERT ##BasePattern (ID, Val) VALUES (0, 0), (1, 1), (2, 0), (3, -1)

CREATE TABLE ##Output (ID INT IDENTITY(1,1), Ind INT, Nr INT)
CREATE TABLE ##OutputHistory (ID INT IDENTITY(1,1), Ind INT, Nr INT, Iteration INT)

CREATE TABLE ##Pattern (Ind INT, BaseID INT, Val INT)
CREATE TABLE ##PatternOrdered (Ind INT, BaseID INT, Val INT, UNIQUE (Ind))

DECLARE @LenInput INT
SELECT @LenInput = COUNT(1) FROM ##Input
DECLARE @LenPattern INT
DECLARE @OutputNr INT = 1
DECLARE @PatternNr INT
DECLARE @Counter INT
DECLARE @OutputVal INT
DECLARE @Iteration INT = 0

WHILE @Iteration < 100
BEGIN
SET @OutputNr = 1
WHILE @OutputNr <= @LenInput
BEGIN
    
    SET @PatternNr = 0

    WHILE @PatternNr < @OutputNr
    BEGIN
        INSERT ##Pattern (Ind, BaseID, Val) SELECT @PatternNr, ID, Val FROM ##BasePattern
        SET @PatternNr = @PatternNr + 1
    END

    INSERT ##PatternOrdered (Ind, BaseID, Val)
    SELECT ROW_NUMBER() OVER (ORDER BY BaseID, Ind) - 1, BaseID, Val FROM ##Pattern ORDER BY BaseID, Ind

    SELECT @LenPattern = COUNT(1) FROM ##PatternOrdered

    SET @Counter = 1
    SET @OutputVal = 0

    WHILE @Counter <= @LenInput
    BEGIN

        --SELECT * FROM ##Input WHERE Ind = @Counter
        --SELECT * FROM ##PatternOrdered WHERE Ind = (@Counter % @LenPattern)

        SET @OutputVal = @OutputVal +
                         (SELECT Nr FROM ##Input WHERE Ind = @Counter) *
                         (SELECT Val FROM ##PatternOrdered WHERE Ind = (@Counter % @LenPattern))

        SET @Counter = @Counter + 1

    END

    --PRINT @OutputVal

    INSERT ##Output(Ind, Nr) VALUES (@Counter, RIGHT(CAST(@OutputVal AS VARCHAR(10)), 1))

    SET @OutputNr = @OutputNr + 1

    DELETE FROM ##Pattern
    DELETE FROM ##PatternOrdered
END

DELETE FROM ##Input
INSERT ##OutputHistory (Ind, Nr, Iteration) SELECT Ind, Nr, @Iteration FROM ##Output
INSERT ##Input (Ind, Nr) SELECT ROW_NUMBER() OVER (ORDER BY ID), Nr FROM ##Output
DELETE FROM ##Output

PRINT 'Iteration done: ' + CAST(@Iteration AS VARCHAR(3)) + ' at ' + CAST(GETDATE() AS VARCHAR(50))

SET @Iteration = @Iteration + 1

END

SELECT * FROM ##OutputHistory WHERE Iteration = 99 ORDER BY ID

--SELECT * FROM ##Input

/*

DROP TABLE ##Input
DROP TABLE ##BasePattern
DROP TABLE ##Output
DROP TABLE ##Pattern
DROP TABLE ##PatternOrdered
DROP TABLE ##OutputHistory

*/


--SELECT * 
--INTO Day16_OutputHistory
--FROM ##OutputHistory

SELECT * FROM Day16_OutputHistory WHERE Iteration = 99 ORDER BY ID
--42867034 is too low for part 1
SELECT * FROM Day16_OutputHistory WHERE Iteration = 49 ORDER BY ID
--30366900
SELECT * FROM Day16_OutputHistory WHERE Iteration = 0 ORDER BY ID
--21701290
SELECT * FROM Day16_OutputHistory WHERE nr IS NULL
--