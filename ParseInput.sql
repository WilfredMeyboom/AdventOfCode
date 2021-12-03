USE [Test_WME]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



-- Mogelijke waardes voor Parsing: All, Grid, Ints, Split

ALTER   PROC [dbo].[ParseInput] (@year VARCHAR(4), @day VARCHAR(2), @Parsing VARCHAR(10) = 'All')
AS
BEGIN

    DECLARE @sql NVARCHAR(100)

    IF EXISTS (SELECT * FROM tempdb.sys.tables WHERE name = '##Input') DROP TABLE ##Input
    CREATE TABLE ##Input (Line NVARCHAR(MAX) NULL);

    IF EXISTS (SELECT * FROM tempdb.sys.tables WHERE name = '##InputNumbered') DROP TABLE ##InputNumbered
    CREATE TABLE ##InputNumbered (Ind INT NOT NULL, Line NVARCHAR(MAX) NULL);

    IF EXISTS (SELECT * FROM tempdb.sys.tables WHERE name = '##InputGrid') DROP TABLE ##InputGrid
    CREATE TABLE ##InputGrid (Ind INT IDENTITY(1,1), RowNr INT, ColNr INT, Val CHAR);

    IF EXISTS (SELECT * FROM tempdb.sys.tables WHERE name = '##InputInts') DROP TABLE ##InputInts
    CREATE TABLE ##InputInts (Ind INT NOT NULL, Val BIGINT);

    IF EXISTS (SELECT * FROM tempdb.sys.tables WHERE name = '##InputSplit') DROP TABLE ##InputSplit
    CREATE TABLE ##InputSplit (Ind INT IDENTITY(1,1), RowNr INT, PieceNr INT, Piece VARCHAR(1024));

    SET @sql = 'BULK INSERT ##Input FROM ''C:\Source\AdventOfCode\' + @year + '\Input' + @day + '.txt'' WITH (ROWTERMINATOR = ''0x0A'');'

    EXEC sp_executesql @sql = @sql

    INSERT ##InputNumbered (Ind, Line)
    SELECT ROW_NUMBER() OVER (ORDER BY(SELECT 0)) AS Ind, Line 
    FROM ##Input

    IF @Parsing = 'All' OR @Parsing = 'Grid'
    BEGIN
        
       ;WITH cte_Grid AS (
            SELECT 0 AS x
            ,      ROW_NUMBER() OVER (ORDER BY(SELECT 0)) - 1 AS y
            ,      LEFT(Line, 1) AS val
            ,      SUBSTRING(Line, 2, LEN(Line)) AS Rest
            FROM ##Input
            UNION ALL
            SELECT X + 1
            ,      Y
            ,      LEFT(Rest, 1)
            ,      SUBSTRING(Rest, 2, LEN(Rest))
            FROM cte_Grid
            WHERE LEN(Rest) > 0
        )
        INSERT ##InputGrid(ColNr, RowNr, val)
        SELECT x, y, val
        FROM cte_Grid
        OPTION (MAXRECURSION 32000)

    END

    IF @Parsing = 'All' OR @Parsing = 'Ints'
    BEGIN

        INSERT ##InputInts (Ind, Val)
        SELECT ROW_NUMBER() OVER (ORDER BY(SELECT 0)) AS Ind, TRY_CAST(Line AS BIGINT)
        FROM ##Input

    END

    IF @Parsing = 'All' OR @Parsing = 'Split'
    BEGIN
        
        DECLARE @Ind INT
        DECLARE @Line VARCHAR(1024)
        
        DECLARE inputcursor CURSOR LOCAL FAST_FORWARD READ_ONLY FOR SELECT ROW_NUMBER() OVER (ORDER BY(SELECT 0)) AS Ind, Line FROM ##Input 
        
        OPEN inputcursor
        
        FETCH NEXT FROM inputcursor INTO @Ind, @Line
        
        WHILE @@FETCH_STATUS = 0
        BEGIN
            
            ;WITH cte_Pieces AS
            (
                SELECT @Ind AS Ind  -- RowNr
                ,      1 AS PieceNr -- PieceNr
                ,      CAST(LEFT(@Line, 1) AS VARCHAR(1024)) AS Piece
                ,      SUBSTRING(@Line, 2, LEN(@Line)) AS Rest
                ,      0 AS FinishedPiece
                UNION ALL
                SELECT Ind
                ,      CASE WHEN FinishedPiece = 1 THEN PieceNr + 1 ELSE PieceNr END
                ,      CAST(CASE WHEN FinishedPiece = 0 THEN Piece + LEFT(Rest, 1) ELSE LEFT(Rest, 1) END AS VARCHAR(1024))
                ,      SUBSTRING(Rest, 2, LEN(Rest))
                ,      CASE WHEN LEFT(Rest, 1) IN (':',';','.',',',' ','-','_','|','[',']') THEN 1 ELSE 0 END
                FROM cte_Pieces
                WHERE LEN(Rest) > 0
            )
            INSERT ##InputSplit
            SELECT Ind, PieceNr - 1, Piece
            FROM cte_Pieces
            WHERE FinishedPiece = 1
        
            FETCH NEXT FROM inputcursor INTO @Ind, @Line
        END
        
        CLOSE inputcursor
        DEALLOCATE inputcursor

    END
END