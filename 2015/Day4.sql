USE Test_WME

SET NOCOUNT ON

DECLARE @year VARCHAR(4) = '2015'
DECLARE @day VARCHAR(2)  = '4'

EXEC dbo.GetInput @year = @year, @day = @day
EXEC dbo.ParseInput @year = @year, @day = @day 

--SELECT TOP 10 * FROM ##InputNumbered
--SELECT TOP 10 * FROM ##InputGrid
--SELECT TOP 10 * FROM ##InputInts
--SELECT TOP 10 * FROM ##InputSplit
--SELECT TOP 10 * FROM ##InputSplitCust



DECLARE @Input VARCHAR(10)

SELECT @Input = Line FROM ##InputNumbered

DECLARE @Counter INT = 0

DECLARE @HashFound INT = 0
DECLARE @FirstHashFound INT = 0
DECLARE @HashPart VARCHAR(6)

WHILE @HashFound = 0
BEGIN

    SET @Counter = @Counter + 1

    SET @HashPart = LEFT(CONVERT(CHAR(32), HASHBYTES('MD5', @Input + CAST(@Counter AS VARCHAR(15))), 2), 6)

    IF @FirstHashFound = 0
        IF @HashPart LIKE '00000%' 
        BEGIN
            SELECT @Counter AS Part1
            SET @FirstHashFound = 1
        END

    IF @HashPart = '000000' SET @HashFound = 1

    --IF @Counter % 100000 = 0 PRINT CAST(GETDATE() AS VARCHAR(25)) + ' ' + CAST(@Counter AS VARCHAR(15))

END

SELECT @Counter AS Part2

--282749 is correct for part 1

--9962624 is correct for part 2