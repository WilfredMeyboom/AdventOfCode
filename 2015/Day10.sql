use Test_WME

SET NOCOUNT ON

DECLARE @Input VARCHAR(MAX) = '1113122113'
DECLARE @Output VARCHAR(MAX)

DECLARE @Counter INT = 1

DECLARE @Pos INT
DECLARE @CurrentChar CHAR

DECLARE @Count INT
DECLARE @Number CHAR

CREATE TABLE ##Results (ID INT IDENTITY(1,1), Res VARCHAR(MAX))

WHILE @Counter <= 50
BEGIN

    SET @Pos = 1
    SET @Count = 0
    SET @Number = '0'
    SET @Output = ''

    WHILE @Pos <= LEN(@Input)
    BEGIN
        
        SET @CurrentChar = SUBSTRING(@Input, @Pos, 1)

        IF @Number = '0'
        BEGIN

            SET @Number = @CurrentChar
            SET @Count = 1

        END
        ELSE IF @Number = @CurrentChar
        BEGIN
            
            SET @Count = @Count + 1

        END
        ELSE
        BEGIN

            SET @Output = @Output + CAST(@Count AS VARCHAR(3)) + @Number

            SET @Number = @CurrentChar
            SET @Count = 1

        END

        SET @Pos = @Pos + 1

    END

    SET @Output = @Output + CAST(@Count AS VARCHAR(3)) + @Number

    SET @Counter = @Counter + 1

    SET @Input = @Output

    INSERT ##Results (Res) SELECT @Output

END


SELECT @Output
SELECT LEN(@Output)

--SELECT * FROM ##Results

--DROP TABLE ##Results

--IN: 1113122113
--OUT: 311311222113



--2652 is too low for part 1
--2722 is too low for part 1
--360154 is correct for part 1



--5102693 Too low for part 2
--5125912 Too high for part 2
--5101943 Too low for part 2
--5110000 is incorrect for part 2
--5103798 is correct for part 2