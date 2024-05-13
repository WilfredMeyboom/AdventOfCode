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


CREATE TABLE ##Caching (ID INT IDENTITY(1,1), SpringGroups VARCHAR(500), Arrangements BIGINT)
CREATE CLUSTERED INDEX IX_Caching ON ##Caching (SpringGroups)

DECLARE @Spring VARCHAR(250)
DECLARE @Groups VARCHAR(250)
DECLARE @Result BIGINT


CREATE TABLE ##SpringGroups (ID INT IDENTITY(1,1), Spring VARCHAR(250), Groups VARCHAR(250), Arrangements BIGINT, Src VARCHAR(10))

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


DECLARE SpringCursor CURSOR FOR 
    SELECT Spring
    ,      Groups
    FROM ##SpringGroups
    WHERE Src = 'Part1'

OPEN SpringCursor

FETCH NEXT FROM SpringCursor INTO @Spring, @Groups

WHILE @@FETCH_STATUS = 0
BEGIN

    EXEC @Result = dbo.GetNrOfSpringArrangments @Spring, @Groups
    UPDATE ##SpringGroups SET Arrangements = @Result WHERE Spring = @Spring AND Groups = @Groups

    FETCH NEXT FROM SpringCursor INTO @Spring, @Groups
END

CLOSE SpringCursor
DEALLOCATE SpringCursor

SELECT SUM(Arrangements) AS Part1 FROM ##SpringGroups WHERE Src = 'Part1' 

--7118

WHILE (SELECT COUNT(1) FROM ##SpringGroups WHERE Arrangements IS NULL) > 0
BEGIN

--DECLARE @Spring VARCHAR(250) DECLARE @Groups VARCHAR(250) DECLARE @Result BIGINT

    SELECT TOP(1) @Spring = Spring, @Groups = Groups
    FROM ##SpringGroups
    WHERE Arrangements IS NULL
    ORDER BY LEN(Spring), LEN(Groups)

    PRINT 'Next up: ' + @Spring + ' ' + @Groups
    EXEC @Result = dbo.GetNrOfSpringArrangments @Spring, @Groups

--SELECT @Result

    IF @Result <> -1
        UPDATE ##SpringGroups 
        SET Arrangements = @Result
        WHERE Spring = @Spring AND Groups = @Groups

END

SELECT SUM(Arrangements) AS Part2 FROM ##SpringGroups WHERE Src = 'Part2'

--Runtime 28 min

/*

DROP TABLE ##SpringGroups
DROP TABLE ##Caching

*/

/*



CREATE OR ALTER PROC dbo.GetNrOfSpringArrangments (@Spring VARCHAR(250), @Groups VARCHAR(250)) AS
BEGIN

--PRINT @@NESTLEVEL
--PRINT @Spring
--PRINT @Groups

    DECLARE @Result BIGINT = 0
    DECLARE @TempResult BIGINT = 0
    DECLARE @NrOfHashes INT
    DECLARE @Sub VARCHAR(250)
    DECLARE @GroupLength INT
    DECLARE @OriginalSpring VARCHAR(250) = @Spring
    DECLARE @OriginalGroups VARCHAR(250) = @Groups

    IF @@NESTLEVEL = 32 
    BEGIN
        SET @TempResult = NULL
        SELECT @TempResult = Arrangements FROM ##Caching WHERE SpringGroups = @Spring + @Groups
        IF @TempResult IS NOT NULL RETURN @TempResult

        IF NOT EXISTS (SELECT 1 FROM ##SpringGroups WHERE Spring = @Spring AND Groups = @Groups)
            INSERT ##SpringGroups (Spring, Groups, Src) SELECT @Spring, @Groups, 'Sub'
        RETURN -1
    END

    IF LEN(REPLACE(REPLACE(@Spring, '.', ''),'?','')) = 0 AND LEN(@Groups) = 0 SET @Result = 1
    ELSE
    BEGIN
        SELECT @GroupLength = SUM(CAST(value AS INT)) FROM STRING_SPLIT(@Groups, ',')
        SET @GroupLength = @GroupLength + (LEN(@Groups) - LEN(REPLACE(@Groups, ',', '')))

        IF LEN(@Spring) < @GroupLength SET @Result = 0
        ELSE
        BEGIN
            IF LEFT(@Spring, 1) = '?'
            BEGIN
                SET @Sub = '.' + SUBSTRING(@Spring,2,LEN(@Spring))
                EXEC @TempResult = dbo.GetNrOfSpringArrangments @Spring = @Sub, @Groups = @Groups
                IF @TempResult = -1 SET @Result = -1
                ELSE SET @Result = @Result + @TempResult
                SET @Sub = '#' + SUBSTRING(@Spring,2,LEN(@Spring))
                EXEC @TempResult = dbo.GetNrOfSpringArrangments @Spring = @Sub, @Groups = @Groups
                IF @TempResult = -1 SET @Result = -1
                ELSE SET @Result = @Result + @TempResult

            END
            ELSE
            IF LEFT(@Spring, 1) = '.'
            BEGIN
                WHILE LEFT(@Spring, 1) = '.' SET @Spring = SUBSTRING(@Spring, 2, LEN(@Spring))
                IF LEFT(@Groups, 1) = ',' SET @Groups = SUBSTRING(@Groups, 2, LEN(@Groups))
                EXEC @TempResult = dbo.GetNrOfSpringArrangments @Spring = @Spring, @Groups = @Groups
                IF @TempResult = -1 SET @Result = -1
                ELSE SET @Result = @Result + @TempResult
                
            END
            ELSE -- LEFT(@Spring, 1) = '#'
            BEGIN
                IF (LEFT(@Groups, 1) = ',' OR LEN(@Groups) = 0) SET @Result = 0
                ELSE
                BEGIN
                    SET @TempResult = NULL
                    SELECT @TempResult = Arrangements FROM ##Caching WHERE SpringGroups = @Spring + @Groups
                    IF @TempResult IS NOT NULL RETURN @TempResult

                    SET @NrOfHashes = CAST(CASE WHEN CHARINDEX(',', @Groups) > 0 THEN LEFT(@Groups, CHARINDEX(',', @Groups) - 1) ELSE @Groups END AS INT)
                    SET @Sub = LEFT(@Spring, @NrOfHashes)
                    IF LEN(REPLACE(@Sub, '.', '')) < @NrOfHashes 
                    BEGIN
                        IF NOT EXISTS (SELECT 1 FROM ##Caching WHERE SpringGroups = @Spring + @Groups)
                            INSERT ##Caching (SpringGroups, Arrangements) SELECT @Spring + @Groups, 0
                        SET @Result = 0
                    END
                    ELSE 
                    BEGIN
                        SET @Spring = SUBSTRING(@Spring, @NrOfHashes + 1, LEN(@Spring))
                        SET @Groups = CASE WHEN CHARINDEX(',', @Groups) > 0 THEN SUBSTRING(@Groups, CHARINDEX(',', @Groups), LEN(@Groups)) ELSE '' END
                        EXEC @TempResult = dbo.GetNrOfSpringArrangments @Spring = @Spring, @Groups = @Groups
                        IF @TempResult = -1 SET @Result = -1
                        ELSE SET @Result = @Result + @TempResult

                        IF NOT EXISTS (SELECT 1 FROM ##Caching WHERE SpringGroups = @OriginalSpring + @OriginalGroups) AND @TempResult <> -1
                            INSERT ##Caching (SpringGroups, Arrangements) SELECT @OriginalSpring + @OriginalGroups, @TempResult
                    END
                END
            END
        END
    END

    IF NOT EXISTS (SELECT 1 FROM ##Caching WHERE SpringGroups = @OriginalSpring + @OriginalGroups) AND @Result <> -1
       INSERT ##Caching (SpringGroups, Arrangements) SELECT @OriginalSpring + @OriginalGroups, @Result

    RETURN @Result
END




*/


