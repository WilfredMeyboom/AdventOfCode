USE Test_WME

SET NOCOUNT ON

DECLARE @year VARCHAR(4) = '2021'
DECLARE @day VARCHAR(2)  = '25'

IF EXISTS (SELECT * FROM tempdb.sys.tables WHERE name = '##Input') DROP TABLE ##Input
CREATE TABLE ##Input (Line NVARCHAR(MAX) NULL);

IF EXISTS (SELECT * FROM tempdb.sys.tables WHERE name = '##InputNumbered') DROP TABLE ##InputNumbered
CREATE TABLE ##InputNumbered (Ind INT NOT NULL, Line NVARCHAR(MAX) NULL);

IF EXISTS (SELECT * FROM tempdb.sys.tables WHERE name = '##InputGrid') DROP TABLE ##InputGrid
CREATE TABLE ##InputGrid (Ind INT IDENTITY(1,1), RowNr INT, ColNr INT, Val CHAR);

IF EXISTS (SELECT * FROM tempdb.sys.tables WHERE name = '##InputInts') DROP TABLE ##InputInts
CREATE TABLE ##InputInts (Ind INT NOT NULL, Val BIGINT);

IF EXISTS (SELECT * FROM tempdb.sys.tables WHERE name = '##InputSplit') DROP TABLE ##InputSplit
CREATE TABLE ##InputSplit (Ind INT IDENTITY(1,1), RowNr INT, PieceNr INT, Piece VARCHAR(MAX));

IF EXISTS (SELECT * FROM tempdb.sys.tables WHERE name = '##InputSplitCust') DROP TABLE ##InputSplitCust
CREATE TABLE ##InputSplitCust (Ind INT IDENTITY(1,1), RowNr INT, PieceNr INT, Piece VARCHAR(MAX));

EXEC dbo.GetInput @year = @year, @day = @day
EXEC dbo.ParseInput @year = @year, @day = @day

--SELECT * FROM ##InputGrid IG

DECLARE @MaxX INT
DECLARE @MaxY INT

SELECT @MaxX = MAX(IG.ColNr) + 1, @MaxY = MAX(IG.RowNr) + 1 FROM ##InputGrid IG

DECLARE @Counter INT = 0
DECLARE @CucuMoved INT = 1

WHILE @CucuMoved > 0
BEGIN

    ;WITH cte_east AS (
        SELECT IG.RowNr, IG.ColNr AS X1, IG2.ColNr AS X2
        FROM ##InputGrid IG
        INNER JOIN ##InputGrid IG2 ON IG2.ColNr = (IG.ColNr + 1)%@MaxX AND IG2.RowNr = IG.RowNr
        WHERE IG.Val = '>' AND IG2.Val = '.'
    )

    UPDATE G
    SET Val = CASE WHEN G.ColNr = c.X1 THEN '.' ELSE '>' END
    FROM ##InputGrid G
    INNER JOIN cte_east c ON c.RowNr = G.RowNr AND (c.X1 = G.ColNr OR c.X2 = G.ColNr)

    SET @CucuMoved = @@ROWCOUNT

    ;WITH cte_south AS (
        SELECT IG.ColNr, IG.RowNr AS Y1, IG2.RowNr AS Y2
        FROM ##InputGrid IG
        INNER JOIN ##InputGrid IG2 ON IG2.RowNr = (IG.RowNr + 1)%@MaxY AND IG2.ColNr = IG.ColNr
        WHERE IG.Val = 'v' AND IG2.Val = '.'
    )

    UPDATE G
    SET Val = CASE WHEN G.RowNr = c.Y1 THEN '.' ELSE 'v' END
    FROM ##InputGrid G
    INNER JOIN cte_south c ON c.ColNr = G.ColNr AND (c.Y1 = G.RowNr OR c.Y2 = G.RowNr)

    SET @CucuMoved = @CucuMoved + @@ROWCOUNT

    SET @Counter = @Counter + 1

    PRINT @Counter
END


SELECT @Counter AS Part1