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

/*
CREATE TABLE ##SpringOptions (ID INT IDENTITY(1,1), Ind INT, Line VARCHAR(100), Groups VARCHAR(20))

;WITH cte_options AS (
    SELECT '.' AS Opt 
    UNION 
    SELECT '#'
), cte_LineOptions AS (
    SELECT Ind
    ,      LEFT(Line, CHARINDEX('?', Line) - 1) + c.Opt + SUBSTRING(Line, CHARINDEX('?', Line) + 1, LEN(Line)) AS Line
    FROM ##InputNumbered
    CROSS APPLY cte_options c

    UNION ALL 

    SELECT Ind
    ,      LEFT(Line, CHARINDEX('?', Line) - 1) + c.Opt + SUBSTRING(Line, CHARINDEX('?', Line) + 1, LEN(Line)) AS Line
    FROM cte_LineOptions
    CROSS APPLY cte_options c
    WHERE Line LIKE '%?%'
), cte_LineSum AS (
    SELECT RowNr AS Ind, SUM(TRY_CAST(Piece AS INT)) AS NrOfSprings
    FROM ##InputSplit I
    GROUP BY RowNr
)
INSERT ##SpringOptions (Ind, Line, Groups)
SELECT cLO.Ind, LEFT(Line, CHARINDEX(' ', Line) - 1), SUBSTRING(Line, CHARINDEX(' ', Line) + 1, LEN(Line))
FROM cte_LineOptions cLO
INNER JOIN cte_LineSum cLS ON cLO.Ind = cLS.Ind
WHERE Line NOT LIKE '%?%'
AND LEN(Line) - LEN(REPLACE(Line, '#', '')) = cLS.NrOfSprings


DECLARE @MaxInt INT 
SELECT @MaxInt = MAX(TRY_CAST(Piece AS INT)) FROM ##InputSplit

;WITH cte_Hashtags AS (
    SELECT 1 AS Ind
    ,      CAST('#' AS VARCHAR(100)) AS Hsh

    UNION ALL

    SELECT Ind + 1
    ,      CAST('#' + Hsh AS VARCHAR(100))
    FROM cte_Hashtags
    WHERE LEN(Hsh) < @MaxInt
), cte_Pattern AS (
SELECT '%' + REPLACE(
        REPLACE(
         REPLACE(
          REPLACE(
           REPLACE(
            REPLACE(
             REPLACE(
              REPLACE(
               REPLACE(
                REPLACE(
                 REPLACE(
                  REPLACE(
                   REPLACE(
                    REPLACE(
                     REPLACE(
                      REPLACE(REPLACE(Groups, ',', '%.%'), '16', Hsh.[16])
                     , '15', Hsh.[15])
                    , '14', Hsh.[14])
                   , '13', Hsh.[13])
                  , '12', Hsh.[12])
                 , '11', Hsh.[11])
                , '10', Hsh.[10])
               , '9', Hsh.[9])
              , '8', Hsh.[8])
             , '7', Hsh.[7])
            , '6', Hsh.[6])
           , '5', Hsh.[5])
          , '4', Hsh.[4])
         , '3', Hsh.[3])
        , '2', Hsh.[2])
       , '1', Hsh.[1])
       + '%' AS Pattern
, SO.Line, SO.Ind
FROM ##SpringOptions SO
CROSS APPLY 
    (SELECT [1],[2],[3],[4],[5],[6],[7],[8],[9],[10],[11],[12],[13],[14],[15],[16]
     FROM (
        SELECT Ind, Hsh
        FROM cte_Hashtags H
        ) Sub
    PIVOT (
        MAX(Hsh)
        FOR Ind IN ([1],[2],[3],[4],[5],[6],[7],[8],[9],[10],[11],[12],[13],[14],[15],[16])
    ) Pvt
) Hsh
)
SELECT --COUNT(1) AS Part1 --Pattern, Line, Ind
Ind, COUNT(1)
FROM cte_Pattern
WHERE Line LIKE Pattern
GROUP BY /*Pattern, Line,*/ Ind
ORDER BY Ind
*/



DECLARE @Spring VARCHAR(250)
DECLARE @Groups VARCHAR(250)
DECLARE @Result INT
DECLARE @Total INT = 0

DECLARE SpringCursor CURSOR FOR 
    SELECT LEFT(Line, CHARINDEX(' ', Line) - 1)
    ,      SUBSTRING(Line, CHARINDEX(' ', Line) + 1, LEN(Line))
    FROM ##InputNumbered

OPEN SpringCursor

FETCH NEXT FROM SpringCursor INTO @Spring, @Groups

WHILE @@FETCH_STATUS = 0
BEGIN

    EXEC @Result = dbo.GetNrOfSpringArrangments @Spring, @Groups
    SET @Total = @Total + @Result
    PRINT @Spring + ' ' + @Groups + ' ' + CAST(@Result AS VARCHAR(10))

    FETCH NEXT FROM SpringCursor INTO @Spring, @Groups
END

CLOSE SpringCursor
DEALLOCATE SpringCursor

SELECT @Total AS Part1



SET @Total = 0

DECLARE SpringCursor2 CURSOR FOR 
    SELECT Spring + '?' + Spring + '?' + Spring + '?' + Spring + '?' + Spring, Groups + ',' + Groups + ',' + Groups + ',' + Groups + ',' + Groups
    FROM (
        SELECT LEFT(Line, CHARINDEX(' ', Line) - 1) AS Spring
        ,      SUBSTRING(Line, CHARINDEX(' ', Line) + 1, LEN(Line)) AS Groups
        FROM ##InputNumbered
        ) Sub

OPEN SpringCursor2

FETCH NEXT FROM SpringCursor2 INTO @Spring, @Groups

WHILE @@FETCH_STATUS = 0
BEGIN

    EXEC @Result = dbo.GetNrOfSpringArrangments @Spring, @Groups
    SET @Total = @Total + @Result
    PRINT @Spring + ' ' + @Groups + ' ' + CAST(@Result AS VARCHAR(10))

    FETCH NEXT FROM SpringCursor2 INTO @Spring, @Groups
END

CLOSE SpringCursor2
DEALLOCATE SpringCursor2

SELECT @Total AS Part2



/*

DROP TABLE ##SpringOptions

*/


/*



CREATE OR ALTER PROC dbo.GetNrOfSpringArrangments (@Spring VARCHAR(250), @Groups VARCHAR(250)) AS
BEGIN
--PRINT @Spring
--PRINT @Groups
    DECLARE @Result INT = 0
    DECLARE @TempResult INT = 0
    DECLARE @NrOfHashes INT
    DECLARE @Sub VARCHAR(250)
    DECLARE @GroupLength INT

    IF LEN(REPLACE(@Spring, '.', '')) = 0 AND LEN(@Groups) = 0 RETURN 1

    SELECT @GroupLength = SUM(CAST(value AS INT)) FROM STRING_SPLIT(@Groups, ',')
    SET @GroupLength = @GroupLength + (LEN(@Groups) - LEN(REPLACE(@Groups, ',', '')))

    IF LEN(@Spring) < @GroupLength RETURN 0

    IF LEFT(@Spring, 1) = '?'
    BEGIN
        SET @Sub = '.' + SUBSTRING(@Spring,2,LEN(@Spring))
        EXEC @TempResult = dbo.GetNrOfSpringArrangments @Spring = @Sub, @Groups = @Groups
        SET @Result = @Result + @TempResult
        SET @Sub = '#' + SUBSTRING(@Spring,2,LEN(@Spring))
        EXEC @TempResult = dbo.GetNrOfSpringArrangments @Spring = @Sub, @Groups = @Groups
        SET @Result = @Result + @TempResult
    END
    ELSE
    IF LEFT(@Spring, 1) = '.'
    BEGIN
        WHILE LEFT(@Spring, 1) = '.' SET @Spring = SUBSTRING(@Spring, 2, LEN(@Spring))
        IF LEFT(@Groups, 1) = ',' SET @Groups = SUBSTRING(@Groups, 2, LEN(@Groups))
        EXEC @TempResult = dbo.GetNrOfSpringArrangments @Spring = @Spring, @Groups = @Groups
        SET @Result = @Result + @TempResult
    END
    ELSE -- LEFT(@Spring, 1) = '#'
    BEGIN
        IF (LEFT(@Groups, 1) = ',' OR LEN(@Groups) = 0) RETURN 0
        SET @NrOfHashes = CAST(CASE WHEN CHARINDEX(',', @Groups) > 0 THEN LEFT(@Groups, CHARINDEX(',', @Groups) - 1) ELSE @Groups END AS INT)
        SET @Sub = LEFT(@Spring, @NrOfHashes)
        IF LEN(REPLACE(@Sub, '.', '')) < @NrOfHashes RETURN 0
        SET @Spring = SUBSTRING(@Spring, @NrOfHashes + 1, LEN(@Spring))
        SET @Groups = CASE WHEN CHARINDEX(',', @Groups) > 0 THEN SUBSTRING(@Groups, CHARINDEX(',', @Groups), LEN(@Groups)) ELSE '' END
        EXEC @TempResult = dbo.GetNrOfSpringArrangments @Spring = @Spring, @Groups = @Groups
        SET @Result = @Result + @TempResult
    END


    RETURN @Result
END




*/

/*

?.?????#??????? 1,1
?????.????????. 1,1

*/