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

    IF @Counter = 40 SELECT @Counter AS Iterations, LEN(@Output) AS Part1
    IF @Counter = 50 SELECT @Counter AS Iterations, LEN(@Output) AS Part2

    SET @Counter = @Counter + 1

    SET @Input = @Output

    INSERT ##Results (Res) SELECT @Output

END


--SELECT @Output
--SELECT LEN(@Output)


DROP TABLE ##Results

-- Runtime: 17:20:19  :/

--360154 is correct for part 1

--5103798 is correct for part 2