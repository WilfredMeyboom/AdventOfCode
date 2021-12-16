USE Test_WME
GO

CREATE OR ALTER FUNCTION dbo.Binary2Decimal (@bin AS VARCHAR(44)) RETURNS BIGINT
AS
BEGIN
    SET @bin = LTRIM(RTRIM(@bin))

    DECLARE @Res BIGINT = 0

    WHILE (LEN(@bin) > 0)
    BEGIN
        
        SET @Res = 2 * @Res + CAST(LEFT(@bin, 1) AS INT)

        SET @bin = SUBSTRING(@bin, 2, LEN(@bin))

    END

    RETURN @Res
END