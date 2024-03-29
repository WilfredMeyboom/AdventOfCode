USE Test_WME
GO

CREATE OR ALTER FUNCTION dbo.Decimal2Binary (@dec AS BIGINT, @returnLength INT = 0) RETURNS VARCHAR(32)
AS
BEGIN

    DECLARE @res VARCHAR(32) = ''
    DECLARE @ind INT = 31

    WHILE @ind >= 0
    BEGIN
        
        IF @dec >= POWER(CAST(2 AS BIGINT),@ind)
        BEGIN
            SET @dec = @dec - POWER(CAST(2 AS BIGINT),@ind)
            SET @res = @res + '1'
        END
        ELSE
        BEGIN
            SET @res = @res + '0'
        END
        
        SET @ind = @ind - 1
    END

    --Resultstring is always 32 bits
    --Returnlength is allowed to reduce the resultstring as long as no significant bits are cut off

    IF 33 - CHARINDEX('1', @res) > @returnLength SET @returnLength = 33 - CHARINDEX('1', @res) 

    --RETURN @Res
    RETURN RIGHT(@res, @returnLength)

END


--SELECT dbo.Decimal2Binary(29,32)
--SELECT dbo.Decimal2Binary(29,5)
--SELECT dbo.Decimal2Binary(29,16)
--SELECT dbo.Decimal2Binary(29,0)
--SELECT dbo.Decimal2Binary(3245632,2)

