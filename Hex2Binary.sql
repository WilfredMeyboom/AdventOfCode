USE Test_WME
GO

CREATE OR ALTER FUNCTION dbo.Hex2Binary (@hex AS VARCHAR(32)) RETURNS VARCHAR(128)
AS
BEGIN

    DECLARE @res VARCHAR(128) = ''

    WHILE LEN(@hex) > 0
    BEGIN
        
        IF (LEFT(@hex,1) = '0') SET @res = @res + '0000'
        IF (LEFT(@hex,1) = '1') SET @res = @res + '0001'
        IF (LEFT(@hex,1) = '2') SET @res = @res + '0010'
        IF (LEFT(@hex,1) = '3') SET @res = @res + '0011'
        IF (LEFT(@hex,1) = '4') SET @res = @res + '0100'
        IF (LEFT(@hex,1) = '5') SET @res = @res + '0101'
        IF (LEFT(@hex,1) = '6') SET @res = @res + '0110'
        IF (LEFT(@hex,1) = '7') SET @res = @res + '0111'
        IF (LEFT(@hex,1) = '8') SET @res = @res + '1000'
        IF (LEFT(@hex,1) = '9') SET @res = @res + '1001'
        IF (LEFT(@hex,1) = 'A') SET @res = @res + '1010'
        IF (LEFT(@hex,1) = 'B') SET @res = @res + '1011'
        IF (LEFT(@hex,1) = 'C') SET @res = @res + '1100'
        IF (LEFT(@hex,1) = 'D') SET @res = @res + '1101'
        IF (LEFT(@hex,1) = 'E') SET @res = @res + '1110'
        IF (LEFT(@hex,1) = 'F') SET @res = @res + '1111'

        
        SET @hex = SUBSTRING(@hex, 2, LEN(@hex))
    END

    RETURN @res

END


--SELECT dbo.Hex2Binary('A')
--SELECT dbo.Hex2Binary('FF')
--SELECT dbo.Binary2Decimal(dbo.Hex2Binary('22E09'))

