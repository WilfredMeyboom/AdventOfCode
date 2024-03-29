USE [Test_WME]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- Possible values for Parsing: All, Grid, Ints, Split, SplitCust
-- To use option SplitCust, parameter SplitCustom cannot be empty

CREATE OR ALTER PROC [dbo].[ParseInput] (@year VARCHAR(4), @day VARCHAR(2), @Parsing VARCHAR(10) = 'All', @SplitCustom VARCHAR(50) = '')
AS
BEGIN

    SET NOCOUNT ON
    
    DECLARE @sql NVARCHAR(500)

    IF EXISTS (SELECT * FROM tempdb.sys.tables WHERE name = '##Input') DROP TABLE ##Input
    CREATE TABLE ##Input (Line NVARCHAR(MAX) NULL);

    IF EXISTS (SELECT * FROM tempdb.sys.tables WHERE name = '##InputNumbered') DROP TABLE ##InputNumbered
    CREATE TABLE ##InputNumbered (Ind INT NOT NULL, Line NVARCHAR(MAX) NULL);

    IF EXISTS (SELECT * FROM tempdb.sys.tables WHERE name = '##InputGrid') DROP TABLE ##InputGrid
    CREATE TABLE ##InputGrid (Ind INT IDENTITY(1,1), RowNr INT, ColNr INT, Val CHAR, UNIQUE(RowNr, ColNr));

    IF EXISTS (SELECT * FROM tempdb.sys.tables WHERE name = '##InputInts') DROP TABLE ##InputInts
    CREATE TABLE ##InputInts (Ind INT NOT NULL, Val BIGINT);

    IF EXISTS (SELECT * FROM tempdb.sys.tables WHERE name = '##InputSplit') DROP TABLE ##InputSplit
    CREATE TABLE ##InputSplit (Ind INT IDENTITY(1,1), RowNr INT, PieceNr INT, Piece VARCHAR(MAX));

    IF EXISTS (SELECT * FROM tempdb.sys.tables WHERE name = '##InputSplitCust') DROP TABLE ##InputSplitCust
    CREATE TABLE ##InputSplitCust (Ind INT IDENTITY(1,1), RowNr INT, PieceNr INT, Piece VARCHAR(MAX));

    SET @sql = 'BULK INSERT ##Input FROM ''C:\Source\AdventOfCode\' + @year + '\Input' + @day + '.txt'' WITH (ROWTERMINATOR = ''0x0A'');'

    EXEC sp_executesql @sql = @sql

    UPDATE ##Input SET Line = REPLACE(Line,CHAR(13),'') --Remove any line feeds

    INSERT ##InputNumbered (Ind, Line)
    SELECT ROW_NUMBER() OVER (ORDER BY(SELECT 0)) AS Ind, Line 
    FROM ##Input

    IF @Parsing = 'All' OR @Parsing = 'Grid'
    BEGIN
        --PRINT 'Grid'

       ;WITH cte_Grid AS (
            SELECT 0 AS x
            ,      ROW_NUMBER() OVER (ORDER BY(SELECT 0)) - 1 AS y
            ,      LEFT(Line, 1) AS val
            ,      SUBSTRING(Line, 2, LEN(Line)) AS LeftOver
            FROM ##Input
            UNION ALL
            SELECT X + 1
            ,      Y
            ,      LEFT(LeftOver, 1)
            ,      SUBSTRING(LeftOver, 2, LEN(LeftOver))
            FROM cte_Grid
            WHERE LEN(LeftOver) > 0
        )
        INSERT ##InputGrid(ColNr, RowNr, val)
        SELECT x, y, val
        FROM cte_Grid
        OPTION (MAXRECURSION 32000)

    END

    IF @Parsing = 'All' OR @Parsing = 'Ints'
    BEGIN
        --PRINT 'Ints'

        INSERT ##InputInts (Ind, Val)
        SELECT ROW_NUMBER() OVER (ORDER BY(SELECT 0)) AS Ind, TRY_CAST(Line AS BIGINT)
        FROM ##Input
        WHERE LEN(Line) < 25 -- If the line is more than 25 characters it won't be a number (bigints have a maximum of 20)

    END

    IF @Parsing = 'All' OR @Parsing = 'Split'
    BEGIN
        --PRINT 'Split'

        DECLARE @Ind INT
        DECLARE @Line VARCHAR(MAX)
        DECLARE @Pos INT = 1
        DECLARE @Chr CHAR
        DECLARE @Piece VARCHAR(MAX)
        DECLARE @PieceNr INT
        
        DECLARE inputcursor CURSOR LOCAL FAST_FORWARD READ_ONLY FOR SELECT ROW_NUMBER() OVER (ORDER BY(SELECT 0)) AS Ind, Line FROM ##Input
                
        OPEN inputcursor
        
        FETCH NEXT FROM inputcursor INTO @Ind, @Line
        
        WHILE @@FETCH_STATUS = 0
        BEGIN

            SET @Pos = 1
            SET @Piece = ''
            SET @PieceNr = 1

            WHILE @Pos <= LEN(ISNULL(@Line, ''))
            BEGIN

                SELECT @Chr = SUBSTRING(@Line, @Pos, 1)

                IF (@Chr IN (':',';','.',',',' ','_','|','[',']'))
                BEGIN
                  
                    IF (LEN(@Piece) > 0) -- Only write data if there is something to write (if two split chars follow eachother don't write)
                    BEGIN
                    
                        INSERT ##InputSplit (RowNr, PieceNr, Piece)
                        VALUES (@Ind, @PieceNr, @Piece)

                        SET @Piece = ''
                        SET @PieceNr = @PieceNr + 1

                    END
                END
                ELSE
                BEGIN
                    SET @Piece = @Piece + @Chr
                END

                SET @Pos = @Pos + 1

            END

            -- Any data left in the piece var, write it to the table
            IF LEN(@Piece) > 0
                INSERT ##InputSplit (RowNr, PieceNr, Piece)
                VALUES (@Ind, @PieceNr, @Piece)
        
            FETCH NEXT FROM inputcursor INTO @Ind, @Line
        END
        
        CLOSE inputcursor
        DEALLOCATE inputcursor

    END

    IF (@Parsing = 'All' OR @Parsing = 'SplitCust') AND @SplitCustom <> ''
    BEGIN
        --PRINT 'CustomSplit'

        DECLARE @CharArray AS TABLE (Chr CHAR)

        ;WITH cte_Chr AS (
            SELECT LEFT(@SplitCustom, 1) AS Chr
            ,      SUBSTRING(@SplitCustom, 2, LEN(@SplitCustom)) AS LeftOver
            UNION ALL
            SELECT LEFT(LeftOver,1)
            ,      SUBSTRING(LeftOver, 2, LEN(LeftOver)) 
            FROM cte_Chr
            WHERE LEN(LeftOver) > 0
        )
        INSERT @CharArray (Chr)
        SELECT Chr
        FROM cte_Chr

        DECLARE inputcursor CURSOR LOCAL FAST_FORWARD READ_ONLY FOR SELECT ROW_NUMBER() OVER (ORDER BY(SELECT 0)) AS Ind, Line FROM ##Input
                
        OPEN inputcursor
        
        FETCH NEXT FROM inputcursor INTO @Ind, @Line
        
        WHILE @@FETCH_STATUS = 0
        BEGIN

            SET @Pos = 1
            SET @Piece = ''
            SET @PieceNr = 1

            WHILE @Pos <= LEN(ISNULL(@Line, ''))
            BEGIN

                SELECT @Chr = SUBSTRING(@Line, @Pos, 1)

                IF (@Chr IN (SELECT Chr FROM @CharArray))
                BEGIN
                  
                    IF (LEN(@Piece) > 0) -- Only write data if there is something to write (if two split chars follow eachother don't write)
                    BEGIN
                    
                        INSERT ##InputSplitCust (RowNr, PieceNr, Piece)
                        VALUES (@Ind, @PieceNr, @Piece)

                        SET @Piece = ''
                        SET @PieceNr = @PieceNr + 1

                    END
                END
                ELSE
                BEGIN
                    SET @Piece = @Piece + @Chr
                END

                SET @Pos = @Pos + 1

            END

            -- Any data left in the piece var, write it to the table
            IF LEN(@Piece) > 0
                INSERT ##InputSplitCust (RowNr, PieceNr, Piece)
                VALUES (@Ind, @PieceNr, @Piece)
        
            FETCH NEXT FROM inputcursor INTO @Ind, @Line
        END
        
        CLOSE inputcursor
        DEALLOCATE inputcursor

    END
END