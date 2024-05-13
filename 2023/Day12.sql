USE Test_WME

SET NOCOUNT ON

DECLARE @year VARCHAR(4) = '2023'
DECLARE @day VARCHAR(2)  = '12'

EXEC dbo.GetInput @year = @year, @day = @day
EXEC dbo.ParseInput @year = @year, @day = @day, @SplitCustom = '| |'

--SELECT TOP 10 * FROM ##Input
--SELECT TOP 10 * FROM ##InputInts
--SELECT TOP 10 * FROM ##InputGrid
--SELECT TOP 10 * FROM ##InputSplit
--SELECT TOP 10 * FROM ##InputSplitCust

-- Create a table in which we store solutions we already calculated
CREATE TABLE ##Caching (ID INT IDENTITY(1,1), SpringGroups VARCHAR(500), Arrangements BIGINT)
CREATE CLUSTERED INDEX IX_Caching ON ##Caching (SpringGroups)

DECLARE @Spring VARCHAR(250)
DECLARE @Groups VARCHAR(250)
DECLARE @Type VARCHAR(10)
DECLARE @Result BIGINT

-- Create a table containing all solutions we need to calculate
-- (And we'll need to store intermediate results because SQL Server doesn't allow recursion with more the 32 levels)
CREATE TABLE ##SpringGroups (ID INT IDENTITY(1,1), Spring VARCHAR(250), Groups VARCHAR(250), Arrangements BIGINT, Src VARCHAR(10))

-- Insert all Spring Groups combinations we need to look at for both part 1 and part 2
INSERT ##SpringGroups (Spring, Groups, Src)
SELECT LEFT(Line, CHARINDEX(' ', Line) - 1) AS Spring
,      SUBSTRING(Line, CHARINDEX(' ', Line) + 1, LEN(Line)) AS Groups
,      'Part1' AS Src
FROM ##InputNumbered
UNION ALL
SELECT Spring + '?' + Spring + '?' + Spring + '?' + Spring + '?' + Spring AS Spring
,      Groups + ',' + Groups + ',' + Groups + ',' + Groups + ',' + Groups AS Groups
,      'Part2' AS Src
FROM (
    SELECT LEFT(Line, CHARINDEX(' ', Line) - 1) AS Spring
    ,      SUBSTRING(Line, CHARINDEX(' ', Line) + 1, LEN(Line)) AS Groups
    FROM ##InputNumbered
    ) Sub

-- We'll do part 1 first. Because this is fast and we fill the caching table with useful results
DECLARE SpringCursor CURSOR FOR 
    SELECT Spring
    ,      Groups
    FROM ##SpringGroups
    WHERE Src = 'Part1'

OPEN SpringCursor

FETCH NEXT FROM SpringCursor INTO @Spring, @Groups

WHILE @@FETCH_STATUS = 0
BEGIN

    EXEC dbo.GetNrOfSpringArrangments @Spring, @Groups, @Result = @Result OUTPUT
    UPDATE ##SpringGroups SET Arrangements = @Result WHERE Spring = @Spring AND Groups = @Groups

    FETCH NEXT FROM SpringCursor INTO @Spring, @Groups
END

CLOSE SpringCursor
DEALLOCATE SpringCursor

SELECT SUM(Arrangements) AS Part1 FROM ##SpringGroups WHERE Src = 'Part1' 


-- And basically we do the same for part2
-- Always start with the shortest spring / groups combo
-- If a spring / groups combo returned -1, it should also have left a shorter spring / groups combo and this should be calculated before retrying the original one

WHILE ((SELECT COUNT(1) FROM ##SpringGroups WHERE Arrangements IS NULL) > 0)
BEGIN

    SELECT TOP(1) @Spring = Spring, @Groups = Groups, @Type = Src
    FROM ##SpringGroups
    WHERE Arrangements IS NULL
    ORDER BY LEN(Spring), LEN(Groups)

--    PRINT 'Next up: ' + @Type + ' ' + @Spring + ' ' + @Groups
    EXEC dbo.GetNrOfSpringArrangments @Spring, @Groups, @Result = @Result OUTPUT

    IF @Result <> -1
        UPDATE ##SpringGroups 
        SET Arrangements = @Result
        WHERE Spring = @Spring AND Groups = @Groups

END

SELECT SUM(Arrangements) AS Part2 FROM ##SpringGroups WHERE Src = 'Part2'

--Runtime 6 min

/*

DROP TABLE ##SpringGroups
DROP TABLE ##Caching

*/

/*

USE Test_wme
GO

CREATE OR ALTER PROC dbo.GetNrOfSpringArrangments (@Spring VARCHAR(250), @Groups VARCHAR(250), @Result BIGINT OUTPUT) AS
BEGIN

--PRINT 'Nesting level: ' + CAST(@@NESTLEVEL AS VARCHAR(10))
--PRINT 'Spring: ' + @Spring
--PRINT 'Groups: ' + @Groups

    DECLARE @TempResult BIGINT = 0
    DECLARE @NrOfHashes INT
    DECLARE @TempSpring VARCHAR(250) = @Spring
    DECLARE @TempGroups VARCHAR(250) = @Groups

    -- If we already know the result of this specific spring / groups combination then return that, nothing else needs to be done
    SET @Result = NULL
    SELECT @Result = Arrangements FROM ##Caching WHERE SpringGroups = @Spring + '|' + @Groups
    IF @Result IS NOT NULL RETURN

    -- If we are at the 32th level of recursion, we need to stop. Store the leftover as a seperate spring_groups (so we can analyze that seperately and add it to the cache)
    -- And we return -1 to let the other recursion levels know we need to terminate (and we'll try again at a later time)
    IF @@NESTLEVEL = 32 
    BEGIN
        -- Only add the leftover spring_group if it is a new one
        IF NOT EXISTS (SELECT 1 FROM ##SpringGroups WHERE Spring = @Spring AND Groups = @Groups)
            INSERT ##SpringGroups (Spring, Groups, Src) SELECT @Spring, @Groups, 'Sub'

        SET @Result = -1
        -- Return immediately, because we don't have to do anything else (in all other cases we want to update caching)
        RETURN 
    END

    -- If there are no more groups defined and the leftover spring consists of just . and ? then this is one valid configuration and we're done analyzing
    IF LEN(REPLACE(REPLACE(@Spring, '.', ''),'?','')) = 0 AND LEN(@Groups) = 0 AND @Result IS NULL
        SET @Result = 1

    -- If the length of spring is smaller than the defined length in the groups then this is an invalid configuration and we're done analyzing
    IF LEN(@Spring) < (SELECT SUM(CAST(value AS INT)) + (LEN(@Groups) - LEN(REPLACE(@Groups, ',', ''))) FROM STRING_SPLIT(@Groups, ',')) AND @Result IS NULL
        SET @Result = 0

    -- If the next character in the spring is a ? then we split paths and look at the spring when it would be a . and when it would be a #
    IF LEFT(@Spring, 1) = '?' AND @Result IS NULL
    BEGIN
        -- Try with a .
        SET @TempSpring = '.' + SUBSTRING(@Spring,2,LEN(@Spring))
        EXEC dbo.GetNrOfSpringArrangments @Spring = @TempSpring, @Groups = @Groups, @Result = @TempResult OUTPUT
        -- If we get a -1 stop everything (don't forget to copy the temp result to the actual output!)
        IF @TempResult = -1 BEGIN SET @Result = -1 RETURN END

        -- Try with a #
        SET @TempSpring = '#' + SUBSTRING(@Spring,2,LEN(@Spring))
        EXEC dbo.GetNrOfSpringArrangments @Spring = @TempSpring, @Groups = @Groups, @Result = @Result OUTPUT
        -- If we get a -1 stop everything
        IF @Result = -1 RETURN 

        -- Combine the results
        SET @Result = @Result + @TempResult
    END
    
    -- If the next character in the spring is a . remove it and any . after it, if the next character in the groups is a , also remove it as it corresponds to the .
    IF LEFT(@Spring, 1) = '.' AND @Result IS NULL
    BEGIN
        SET @TempSpring = @Spring
        SET @TempGroups = @Groups

        -- Remove as many . as possible
        WHILE LEFT(@TempSpring, 1) = '.' SET @TempSpring = SUBSTRING(@TempSpring, 2, LEN(@TempSpring))

        -- Remove a , if that is the next character in the groups
        IF LEFT(@TempGroups, 1) = ',' SET @TempGroups = SUBSTRING(@TempGroups, 2, LEN(@TempGroups))

        EXEC dbo.GetNrOfSpringArrangments @Spring = @TempSpring, @Groups = @TempGroups, @Result = @Result OUTPUT

        -- If we get a -1 stop everything
        IF @Result = -1 RETURN 
    END

    -- LEFT(@Spring, 1) = '#' because it is the only option left (for next if statements)

    -- If the spring continues with a # while the groups continues with a , then we have a mismatch and can stop analyzing
    IF ((LEFT(@Groups, 1) = ',' OR LEN(@Groups) = 0) AND @Result IS NULL) 
        SET @Result = 0

    IF (@Result IS NULL)
    BEGIN
        
        -- Get the next number from groups as this is the number of expected # from the spring
        SET @NrOfHashes = CAST(CASE WHEN CHARINDEX(',', @Groups) > 0 THEN LEFT(@Groups, CHARINDEX(',', @Groups) - 1) ELSE @Groups END AS INT)
        SET @TempSpring = LEFT(@Spring, @NrOfHashes)

        -- If there are any . in the next set of # then we have a mismatch and can stop analyzing
        IF LEN(REPLACE(@TempSpring, '.', '')) < @NrOfHashes 
        BEGIN
            SET @Result = 0
        END
        ELSE            
        BEGIN
            -- The next part of the string contains just # and ?, so we can cut that off from both the spring and the groups and continu with the rest
            SET @TempSpring = SUBSTRING(@Spring, @NrOfHashes + 1, LEN(@Spring))
            SET @TempGroups = CASE WHEN CHARINDEX(',', @Groups) > 0 THEN SUBSTRING(@Groups, CHARINDEX(',', @Groups), LEN(@Groups)) ELSE '' END

            EXEC dbo.GetNrOfSpringArrangments @Spring = @TempSpring, @Groups = @TempGroups, @Result = @Result OUTPUT
            
            -- If we get a -1 stop everything
            IF @Result = -1 RETURN
        END 
    END

    -- So we have some result (other than -1 because then we would quit immediately). Store this in the caching table
    IF NOT EXISTS (SELECT 1 FROM ##Caching WHERE SpringGroups = @Spring + @Groups) 
       INSERT ##Caching (SpringGroups, Arrangements) SELECT @Spring + '|' + @Groups, @Result

    --PRINT 'Result: ' + CAST(@Result AS VARCHAR(20))

END


*/


