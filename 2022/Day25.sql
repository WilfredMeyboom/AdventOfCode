USE Test_WME

SET NOCOUNT ON

DECLARE @year VARCHAR(4) = '2022'
DECLARE @day VARCHAR(2)  = '25'

EXEC dbo.GetInput @year = @year, @day = @day
EXEC dbo.ParseInput @year = @year, @day = @day 

--SELECT TOP 10 * FROM ##Input
--SELECT TOP 10 * FROM ##InputInts
--SELECT TOP 10 * FROM ##InputNumbered
--SELECT TOP 10 * FROM ##InputGrid
--SELECT TOP 10 * FROM ##InputSplit
--SELECT TOP 10 * FROM ##InputSplitCust
  
CREATE TABLE ##Digits (ID INT IDENTITY(1,1), chr CHAR)

DECLARE @Solution VARCHAR(50) = ''
DECLARE @Sum INT
DECLARE @CarryOver INT = 0
DECLARE @Digit INT

WHILE EXISTS (SELECT 1 FROM ##InputNumbered WHERE Line <> '')
BEGIN

    TRUNCATE TABLE ##Digits

    INSERT ##Digits (chr)
    SELECT RIGHT(Line,1)
    FROM ##InputNumbered
    WHERE Line <> ''

    UPDATE ##InputNumbered
    SET Line = SUBSTRING(Line, 1, LEN(Line) - 1)
    WHERE Line <> '' 

    SELECT @Sum = SUM(CASE WHEN chr = '=' THEN -2
                           WHEN chr = '-' THEN -1
                           ELSE CAST(chr AS INT)
                      END) + @CarryOver
    FROM ##Digits D

    SET @CarryOver = @Sum / 5 
    SET @Digit = @Sum % 5
    
    IF @Digit IN (0, 1, 2) SET @Solution = CAST(@Digit AS VARCHAR(2)) + @Solution
    IF @Digit = -1 SET @Solution = '-' + @Solution
    IF @Digit = -2 SET @Solution = '=' + @Solution
    IF @Digit = 4
    BEGIN
        SET @CarryOver = @CarryOver + 1
        SET @Solution = '-' + @Solution
    END
    IF @Digit = 3
    BEGIN
        SET @CarryOver = @CarryOver + 1
        SET @Solution = '=' + @Solution
    END
    IF @Digit = -4
    BEGIN
        SET @CarryOver = @CarryOver - 1
        SET @Solution = '1' + @Solution
    END
    IF @Digit = -3
    BEGIN
        SET @CarryOver = @CarryOver - 1
        SET @Solution = '2' + @Solution
    END

    PRINT 'Sum: ' + CAST(@Sum AS VARCHAR(10))
    PRINT 'CarryOver: ' + CAST(@CarryOver AS VARCHAR(10))
    PRINT 'Digit: ' + CAST(@Digit AS VARCHAR(10))
    PRINT 'Solution: ' + @Solution

END

SELECT @Solution AS Part1


DROP TABLE ##Digits

