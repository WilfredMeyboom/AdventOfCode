USE Test_WME

SET NOCOUNT ON

DECLARE @year VARCHAR(4) = '2015'
DECLARE @day VARCHAR(2)  = '12'

EXEC dbo.GetInput @year = @year, @day = @day
EXEC dbo.ParseInput @year = @year, @day = @day, @SplitCustom = '[]{}:,;"'

--SELECT * FROM ##InputSplitCust

SELECT SUM(CAST(Piece AS INT)) AS Part1 
FROM ##InputSplitCust 
WHERE TRY_CAST(Piece AS INT) IS NOT NULL

--111754 is correct for part 1

/*
    Take the json string and search for an object {} and an array [] that don't contain arrays or objects
    When found, replace it with it's value (sum of the numbers or 0 if it is an object containing "red")
    Rinse, repeat until no objects and arrays are left which leaves the answer
*/

DECLARE @Pos INT = 1
DECLARE @Json VARCHAR(MAX)
DECLARE @StartPos INT
DECLARE @EndPos INT
DECLARE @ArrayOrObject VARCHAR(10)
DECLARE @ReplaceValue INT = 0

SELECT @Json = Line FROM ##Input

-- Keep going till we have a result
WHILE @Pos <= LEN(@Json)
BEGIN

    -- We found the start of an object
    IF SUBSTRING(@Json, @Pos, 1) = '{'
    BEGIN
        SET @StartPos = @Pos
        SET @ArrayOrObject = 'Object'
    END

    -- We found the start of an array
    IF SUBSTRING(@Json, @Pos, 1) = '['
    BEGIN
        SET @StartPos = @Pos
        SET @ArrayOrObject = 'Array'
    END

    -- We found the end of an object
    IF SUBSTRING(@Json, @Pos, 1) = '}'
    BEGIN
    print 'Object' + CAST(@StartPos AS VARCHAR(10)) + ' ' + CAST(@Pos AS VARCHAR(10)) + ' ' + @ArrayOrObject
        SET @EndPos = @Pos
        IF @ArrayOrObject = 'Object'
        BEGIN
            IF CHARINDEX('red', SUBSTRING(@Json, @StartPos, @EndPos - @Startpos)) > 0
            BEGIN
                -- Object contains red so it's value is set to zero
                SET @Json = SUBSTRING(@Json, 1, @StartPos - 1) + '0' + SUBSTRING(@Json, @EndPos + 1, LEN(@Json))
                    
                -- Start searching at the beginning
                SET @Pos = 0
            END
            ELSE
            BEGIN
                -- Replace the substring with the value of the object
                SELECT @ReplaceValue = ISNULL(SUM(CAST(value AS INT)),0) FROM STRING_SPLIT(
                                                                        REPLACE(
                                                                            SUBSTRING(@Json,@StartPos + 1, @EndPos - @StartPos - 1)
                                                                        ,':',',')
                                                                    ,',') 
                                                                WHERE TRY_CAST(value AS INT) IS NOT NULL
                SET @Json = SUBSTRING(@Json, 1, @StartPos - 1) + CAST(@ReplaceValue AS VARCHAR(20)) + SUBSTRING(@Json, @EndPos + 1, LEN(@Json))
                SET @Pos = 0
            END                
        END -- = 'Object'
    END -- = '}'

    -- We found the end of an array
    IF SUBSTRING(@Json, @Pos, 1) = ']'
    BEGIN
    print 'Array' + CAST(@StartPos AS VARCHAR(10)) + ' ' + CAST(@Pos AS VARCHAR(10)) + ' ' + @ArrayOrObject
        SET @EndPos = @Pos
        IF @ArrayOrObject = 'Array'
        BEGIN
            -- Replace the substring with the value of the array
            SELECT @ReplaceValue = ISNULL(SUM(CAST(value AS INT)),0) FROM STRING_SPLIT(SUBSTRING(@Json,@StartPos + 1, @EndPos - @StartPos - 1),',') WHERE TRY_CAST(value AS INT) IS NOT NULL
            SET @Json = SUBSTRING(@Json, 1, @StartPos - 1) + CAST(@ReplaceValue AS VARCHAR(20)) + SUBSTRING(@Json, @EndPos + 1, LEN(@Json))
            SET @Pos = 0
        END
    END

    SET @Pos = @Pos + 1
END --Move along the string

SELECT @Json AS Part2

--SELECT SUM(CAST(value AS INT)) FROM STRING_SPLIT(REPLACE('"e":"orange","c":74,"a":"yellow","b":"orange","d":34,"f":124',':',','),',') WHERE TRY_CAST(value AS INT) IS NOT NULL
--SELECT SUM(CAST(value AS INT)) FROM STRING_SPLIT('164,-41,"violet","violet",126',',') WHERE TRY_CAST(value AS INT) IS NOT NULL