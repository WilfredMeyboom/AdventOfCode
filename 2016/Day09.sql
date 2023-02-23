USE Test_WME

SET NOCOUNT ON

DECLARE @year VARCHAR(4) = '2016'
DECLARE @day VARCHAR(2)  = '9'

EXEC dbo.GetInput @year = @year, @day = @day
EXEC dbo.ParseInput @year = @year, @day = @day

--SELECT TOP 10 * FROM ##InputNumbered
--SELECT TOP 10 * FROM ##InputGrid
--SELECT TOP 10 * FROM ##InputInts
--SELECT TOP 10 * FROM ##InputSplit
--SELECT * FROM ##Input

DECLARE @Index INT = 1
DECLARE @Input VARCHAR(MAX)
DECLARE @Res VARCHAR(MAX) = ''
DECLARE @Length INT
DECLARE @Quantity INT

SELECT TOP 1 @Input = Line FROM ##Input

WHILE (LEN(@Input) > 0)
BEGIN
    
    -- Keep going if there are markers left in the string
    IF (CHARINDEX('(', @Input) > 0)
    BEGIN
        
        --Move the part before the next marker to the result string
        SET @Res = @Res + SUBSTRING(@Input, 1, CHARINDEX('(', @Input) - 1)
        SET @Input = SUBSTRING(@Input,  CHARINDEX('(', @Input) + 1, LEN(@Input))

        --Get the length component of the next marker
        SET @Length = CAST(SUBSTRING(@Input, 1, CHARINDEX('x', @Input) - 1) AS INT)
        SET @Input = SUBSTRING(@Input,  CHARINDEX('x', @Input) + 1, LEN(@Input))

        --Get the quantity of the next marker
        SET @Quantity = CAST(SUBSTRING(@Input, 1, CHARINDEX(')', @Input) - 1) AS INT)
        SET @Input = SUBSTRING(@Input,  CHARINDEX(')', @Input) + 1, LEN(@Input))

        SET @Index = 0

        -- Expand the text according to the marker
        WHILE @Index < @Quantity
        BEGIN
            SET @Res = @Res + SUBSTRING(@Input, 1, @Length)
            SET @Index = @Index + 1
        END

        -- Remove the length according to the marker from the input string
        SET @Input = SUBSTRING(@Input, @Length + 1, LEN(@Input))

    END
    ELSE
    BEGIN
        SET @Res = @Res + @Input
        SET @Input = ''
    END

END

SELECT LEN(@Res) AS Part1

SELECT dbo.AOCY2016D09_DetermineSize(Line) AS Part2 FROM ##Input

/*

-- The recursive function: 

CREATE OR ALTER FUNCTION dbo.AOCY2016D09_DetermineSize (@Str VARCHAR(MAX))
RETURNS BIGINT
AS 
BEGIN
    
    DECLARE @Size BIGINT = 0
    DECLARE @Length INT
    DECLARE @Quantity INT
    
    WHILE (LEN(@Str) > 0)
    BEGIN

        -- If there aren't any markers left in the string, just return the length
        IF CHARINDEX('(', @Str) = 0 RETURN @Size + LEN(@Str)

        -- Nr of characters before the next marker
        SET @Size = @Size + CHARINDEX('(', @Str) - 1
        SET @Str = SUBSTRING(@Str,  CHARINDEX('(', @Str) + 1, LEN(@Str))

        -- Get the length component of the next marker
        SET @Length = CAST(SUBSTRING(@Str, 1, CHARINDEX('x', @Str) - 1) AS INT)
        SET @Str = SUBSTRING(@Str,  CHARINDEX('x', @Str) + 1, LEN(@Str))

        -- Get the quantity of the next marker
        SET @Quantity = CAST(SUBSTRING(@Str, 1, CHARINDEX(')', @Str) - 1) AS INT)
        SET @Str = SUBSTRING(@Str,  CHARINDEX(')', @Str) + 1, LEN(@Str))


        SET @Size = @Size + dbo.AOCY2016D09_DetermineSize(LEFT(@Str, @Length)) * @Quantity

         -- Remove the length according to the marker from the input string
        SET @Str = SUBSTRING(@Str, @Length + 1, LEN(@Str))

    END

    RETURN @Size

END

*/

