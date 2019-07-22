USE Test_WME

DECLARE @Input VARCHAR(10) = 'yzbqklnj'

DECLARE @Counter INT = 0

DECLARE @HashFound INT = 0

WHILE @HashFound = 0
BEGIN

    SET @Counter = @Counter + 1

    IF (SELECT LEFT(CONVERT(CHAR(32), HASHBYTES('MD5', @Input + CAST(@Counter AS VARCHAR(15))), 2), 6)) = '000000' SET @HashFound = 1

    IF @Counter % 100000 = 0 PRINT CAST(GETDATE() AS VARCHAR(25)) + ' ' + CAST(@Counter AS VARCHAR(15))

END

SELECT @Counter

--282749 is correct for part 1

--9962624 is correct for part 2