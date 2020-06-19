use Test_WME

SET NOCOUNT ON

CREATE TABLE #Input (Nr NVARCHAR(MAX));

BULK INSERT #Input
FROM 'C:\Source\AdventOfCode\2019\input16.txt'
WITH (ROWTERMINATOR = '0x0A');

-- Workaround for invisible character at the end of the input string
IF (SELECT LEN(Nr) FROM #Input) > 650 UPDATE #Input SET Nr = LEFT(Nr, LEN(Nr) - 1)

DECLARE @InputLen INT
DECLARE @Offset INT
DECLARE @Phase INT = 0

SELECT @InputLen = LEN(Nr), @Offset = LEFT(Nr, 7) FROM #Input

DECLARE @TotalLength INT = @InputLen * 10000


CREATE TABLE ##Input (ID INT IDENTITY(1,1), PosNr INT, Val INT)

;WITH cte_Nrs AS (
    SELECT RIGHT(Nr, 1) AS Number
    ,      SUBSTRING(Nr, 1, LEN(Nr) - 1) AS Rest
    FROM #Input
    UNION ALL
    SELECT RIGHT(Rest, 1) AS Number
    ,      SUBSTRING(Rest, 1, LEN(Rest) - 1) AS Rest
    FROM cte_Nrs
    WHERE LEN(Rest) > 0
)
INSERT ##Input (PosNr, Val)
SELECT ROW_NUMBER() OVER (ORDER BY (SELECT 0))
,      Number
FROM cte_Nrs
OPTION (MAXRECURSION 10000)

DROP TABLE #Input

DECLARE @Len INT
SELECT @Len = COUNT(1) FROM ##Input

UPDATE I1 
SET I1.Val = I2.Val
FROM ##Input I1
INNER JOIN ##Input I2 ON I1.ID = @Len - I2.ID + 1

--SELECT * FROM ##Input

DECLARE @SkipPart1 INT = 1

IF @SkipPart1 = 0
BEGIN

CREATE TABLE ##BasePattern (ID INT, Val INT)

INSERT ##BasePattern (ID, Val) VALUES (0, 0), (1, 1), (2, 0), (3, -1)


CREATE TABLE ##Pattern (ID INT IDENTITY(1,1), RowNr INT, PosNr INT, Val INT)

DECLARE @x INT = 1
DECLARE @y INT = 1
DECLARE @Counter INT = 1

WHILE @y <= @Len
BEGIN

    SET @Counter = 0
    SET @x = 1

    WHILE @x <= @Len + 1
    BEGIN

        INSERT ##Pattern(RowNr, PosNr, Val) SELECT @y, @x, Val FROM ##BasePattern WHERE ID = @Counter
        
        IF @x % @y = 0 SET @Counter = (@Counter + 1) % 4

        SET @x = @x + 1
    END

    SET @y = @y + 1
END

DELETE FROM ##Pattern WHERE PosNr = 1
UPDATE ##Pattern SET PosNr = PosNr - 1

--SELECT * FROM ##Pattern

CREATE TABLE ##Output (ID INT IDENTITY(1,1), Phase INT, PosNr INT, Val INT)

WHILE @Phase <= 100
BEGIN

    PRINT 'Starting phase ' + CAST(@Phase AS VARCHAR(10)) + ' at ' + CAST(GETDATE() AS VARCHAR(50))

    INSERT ##Output (Phase, PosNr, Val) SELECT @Phase, PosNr, Val FROM ##Input

    ;WITH cte_Calc AS (
        SELECT P.RowNr, RIGHT(SUM(I.Val * P.Val), 1) AS NewVal
        FROM ##Input I
        INNER JOIN ##Pattern P ON P.PosNr = I.PosNr
        GROUP BY P.RowNr
    )
    UPDATE I
    SET I.Val = cC.NewVal
    FROM ##Input I
    INNER JOIN cte_Calc cC ON I.PosNr = cC.RowNr
    
    --GROUP BY  I.PosNr

    SET @Phase = @Phase + 1
END


SELECT * FROM ##Output --WHERE Phase = 100 AND PosNr <= 8

-- 59281788 is correct for part 1 

/*

DROP TABLE ##BasePattern
DROP TABLE ##Pattern
DROP TABLE ##Input
DROP TABLE ##Output

*/

END -- /Part 1
ELSE
BEGIN
-- Part 2

-- Special effect of the base pattern allows easier calculation. 
-- This only applies to the calculation of the second half of the number for the next phase:
-- Every new digit is a summation of the digits in the current number after the position
-- Example 12345678 -> In the next phase, 
--                     The last digit will be 8
--                     The one before that will be (8 + 7) % 10 = 5
--                     The one before that will be (8 + 7 + 6) % 10 = 1
--                     The one before that will be (8 + 7 + 6 + 5) % 10 = 6
--
-- This only works up until half the number but that is more than what we need


DECLARE @NewLen INT
SET @NewLen = @Len * 10000 - @Offset

DECLARE @NeededMult INT
SELECT @NeededMult = CEILING((@NewLen * 1.0) / @Len)

CREATE TABLE ##NewInput (ID INT IDENTITY(1,1), PosNr INT, Val INT)

;WITH cte_Multiplier AS (
    SELECT TOP (@NeededMult) ROW_NUMBER() OVER (ORDER BY (SELECT 0)) AS Multiplier FROM sys.messages
)
INSERT ##NewInput (PosNr, Val)
SELECT PosNr + (Multiplier - 1) * @Len AS NewPos, Val
FROM ##Input
CROSS APPLY cte_Multiplier
ORDER BY Multiplier, PosNr



WHILE @Phase < 100
BEGIN

    PRINT 'Starting phase ' + CAST(@Phase AS VARCHAR(10)) + ' at ' + CAST(GETDATE() AS VARCHAR(50))
    
    ;WITH cte_NewVal AS (
        SELECT PosNr, (SUM(Val) OVER (ORDER BY PosNr DESC)) % 10 AS NewVal
        FROM ##NewInput
    )
    UPDATE I
    SET I.Val = cN.NewVal
    FROM ##NewInput I
    INNER JOIN cte_NewVal cN ON I.PosNr = cN.PosNr

    SET @Phase = @Phase + 1

END

DECLARE @OffsetOffset INT 
SELECT @OffsetOffset = COUNT(1) - @NewLen FROM ##NewInput
-- 293

SELECT TOP 8 * FROM ##NewInput WHERE ID > @OffsetOffset
ORDER BY PosNr

/*

DROP TABLE ##Input
DROP TABLE ##NewInput

DROP TABLE #Input
*/


END --If to run just part 2


