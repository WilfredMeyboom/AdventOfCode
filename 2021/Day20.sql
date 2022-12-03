USE Test_WME

SET NOCOUNT ON

DECLARE @year VARCHAR(4) = '2021'
DECLARE @day VARCHAR(2)  = '20'

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
EXEC dbo.ParseInput @year = @year, @day = @day, @SplitCustom = '= .,'

--SELECT * FROM ##InputNumbered
--SELECT TOP 10 * FROM ##InputGrid ORDER BY RowNr
--SELECT TOP 10 * FROM ##InputInts
--SELECT * FROM ##InputSplit
--SELECT TOP 10 * FROM ##InputSplitCust

CREATE TABLE ##Grid (ID INT IDENTITY(1,1), X INT, Y INT, Val VARCHAR(8), UNIQUE(X,Y))

INSERT ##Grid
(
    X,
    Y,
    Val
)
SELECT ColNr, RowNr, REPLACE(REPLACE(Val, '#', 1), '.', '0')
FROM ##InputGrid IG
WHERE RowNr > 0 AND Val IS NOT NULL
ORDER BY RowNr, ColNr


DECLARE @Counter INT = 0

WHILE @Counter < 1-- 25
BEGIN


    DECLARE @MinX INT
    DECLARE @MinY INT
    DECLARE @MaxX INT
    DECLARE @MaxY INT

    SELECT @MinX = MIN(X), @MaxX = MAX(X), @MinY = MIN(Y), @MaxY = MAX(Y) FROM ##Grid 

    --SELECT MIN(X), MAX(X), MIN(Y), MAX(Y) FROM ##Grid 

    ;WITH cte_X AS (
        SELECT TOP (@MaxX-@MinX+3) ROW_NUMBER() OVER (ORDER BY (SELECT 0)) + @MinX - 2 AS X FROM sys.messages M    
    )
    INSERT ##Grid(X, Y, Val)
    SELECT X, Y, 0
    FROM cte_X
    CROSS APPLY (SELECT @MinY - 1 AS Y UNION SELECT @MaxY + 1) C


    ;WITH cte_Y AS (
        SELECT TOP (@MaxY-@MinY+1) ROW_NUMBER() OVER (ORDER BY (SELECT 0)) + @MinY - 1 AS Y FROM sys.messages M    
    )
    INSERT ##Grid(X, Y, Val)
    SELECT X, Y, 0
    FROM cte_Y
    CROSS APPLY (SELECT @MinX - 1 AS X UNION SELECT @MaxX + 1) C

    --Add second ring
    SELECT @MinX = MIN(X), @MaxX = MAX(X), @MinY = MIN(Y), @MaxY = MAX(Y) FROM ##Grid 

    ;WITH cte_X AS (
        SELECT TOP (@MaxX-@MinX+3) ROW_NUMBER() OVER (ORDER BY (SELECT 0)) + @MinX - 2 AS X FROM sys.messages M    
    )
    INSERT ##Grid(X, Y, Val)
    SELECT X, Y, 0
    FROM cte_X
    CROSS APPLY (SELECT @MinY - 1 AS Y UNION SELECT @MaxY + 1) C


    ;WITH cte_Y AS (
        SELECT TOP (@MaxY-@MinY+1) ROW_NUMBER() OVER (ORDER BY (SELECT 0)) + @MinY - 1 AS Y FROM sys.messages M    
    )
    INSERT ##Grid(X, Y, Val)
    SELECT X, Y, 0
    FROM cte_Y
    CROSS APPLY (SELECT @MinX - 1 AS X UNION SELECT @MaxX + 1) C




    ;WITH cte_Index AS (
    SELECT G5.X, G5.Y, dbo.Binary2Decimal(G1.Val + G2.Val + G3.Val + G4.Val + G5.Val + G6.Val + G7.Val + G8.Val + G9.Val) AS Ind
    , G1.Val + G2.Val + G3.Val + G4.Val + G5.Val + G6.Val + G7.Val + G8.Val + G9.Val AS Bits
    FROM ##Grid G1
    INNER JOIN ##Grid G2 ON G2.X = G1.X + 1 AND G2.Y = G1.Y
    INNER JOIN ##Grid G3 ON G3.X = G1.X + 2 AND G3.Y = G1.Y
    INNER JOIN ##Grid G4 ON G4.X = G1.X AND G4.Y = G1.Y + 1
    INNER JOIN ##Grid G5 ON G5.X = G1.X + 1 AND G5.Y = G1.Y + 1
    INNER JOIN ##Grid G6 ON G6.X = G1.X + 2 AND G6.Y = G1.Y + 1
    INNER JOIN ##Grid G7 ON G7.X = G1.X AND G7.Y = G1.Y + 2
    INNER JOIN ##Grid G8 ON G8.X = G1.X + 1 AND G8.Y = G1.Y + 2
    INNER JOIN ##Grid G9 ON G9.X = G1.X + 2 AND G9.Y = G1.Y + 2
    )
    UPDATE G
    SET Val = REPLACE(REPLACE(IG.Val, '#', 1), '.', '0')
    FROM ##Grid G
    INNER JOIN cte_Index c ON c.X = G.X AND c.Y = G.Y
    INNER JOIN ##InputGrid IG ON IG.RowNr = 0 AND c.Ind = IG.ColNr
    --ORDER BY c.Y, c.X



    SELECT @MinX = MIN(X), @MaxX = MAX(X), @MinY = MIN(Y), @MaxY = MAX(Y) FROM ##Grid 

    UPDATE ##Grid SET Val = 1
    WHERE X IN (@MinX, @MaxX)

    UPDATE ##Grid SET Val = 1
    WHERE Y IN (@MinY, @MaxY)


    ;WITH cte_X AS (
        SELECT TOP (@MaxX-@MinX+3) ROW_NUMBER() OVER (ORDER BY (SELECT 0)) + @MinX - 2 AS X FROM sys.messages M    
    )
    INSERT ##Grid(X, Y, Val)
    SELECT X, Y, 1
    FROM cte_X
    CROSS APPLY (SELECT @MinY - 1 AS Y UNION SELECT @MaxY + 1) C


    ;WITH cte_Y AS (
        SELECT TOP (@MaxY-@MinY+1) ROW_NUMBER() OVER (ORDER BY (SELECT 0)) + @MinY - 1 AS Y FROM sys.messages M    
    )
    INSERT ##Grid(X, Y, Val)
    SELECT X, Y, 1
    FROM cte_Y
    CROSS APPLY (SELECT @MinX - 1 AS X UNION SELECT @MaxX + 1) C

    --Add second ring
    SELECT @MinX = MIN(X), @MaxX = MAX(X), @MinY = MIN(Y), @MaxY = MAX(Y) FROM ##Grid 

    ;WITH cte_X AS (
        SELECT TOP (@MaxX-@MinX+3) ROW_NUMBER() OVER (ORDER BY (SELECT 0)) + @MinX - 2 AS X FROM sys.messages M    
    )
    INSERT ##Grid(X, Y, Val)
    SELECT X, Y, 1
    FROM cte_X
    CROSS APPLY (SELECT @MinY - 1 AS Y UNION SELECT @MaxY + 1) C

    ;WITH cte_Y AS (
        SELECT TOP (@MaxY-@MinY+1) ROW_NUMBER() OVER (ORDER BY (SELECT 0)) + @MinY - 1 AS Y FROM sys.messages M    
    )
    INSERT ##Grid(X, Y, Val)
    SELECT X, Y, 1
    FROM cte_Y
    CROSS APPLY (SELECT @MinX - 1 AS X UNION SELECT @MaxX + 1) C

    --SELECT * FROM ##Grid ORDER BY Y, X

    ;WITH cte_Index AS (
    SELECT G5.X, G5.Y, dbo.Binary2Decimal(G1.Val + G2.Val + G3.Val + G4.Val + G5.Val + G6.Val + G7.Val + G8.Val + G9.Val) AS Ind
    , G1.Val + G2.Val + G3.Val + G4.Val + G5.Val + G6.Val + G7.Val + G8.Val + G9.Val AS Bits
    FROM ##Grid G1
    INNER JOIN ##Grid G2 ON G2.X = G1.X + 1 AND G2.Y = G1.Y
    INNER JOIN ##Grid G3 ON G3.X = G1.X + 2 AND G3.Y = G1.Y
    INNER JOIN ##Grid G4 ON G4.X = G1.X AND G4.Y = G1.Y + 1
    INNER JOIN ##Grid G5 ON G5.X = G1.X + 1 AND G5.Y = G1.Y + 1
    INNER JOIN ##Grid G6 ON G6.X = G1.X + 2 AND G6.Y = G1.Y + 1
    INNER JOIN ##Grid G7 ON G7.X = G1.X AND G7.Y = G1.Y + 2
    INNER JOIN ##Grid G8 ON G8.X = G1.X + 1 AND G8.Y = G1.Y + 2
    INNER JOIN ##Grid G9 ON G9.X = G1.X + 2 AND G9.Y = G1.Y + 2
    )
    UPDATE G
    SET Val = REPLACE(REPLACE(IG.Val, '#', 1), '.', '0')
    FROM ##Grid G
    INNER JOIN cte_Index c ON c.X = G.X AND c.Y = G.Y
    INNER JOIN ##InputGrid IG ON IG.RowNr = 0 AND c.Ind = IG.ColNr

    SELECT @MinX = MIN(X), @MaxX = MAX(X), @MinY = MIN(Y), @MaxY = MAX(Y) FROM ##Grid 

    UPDATE ##Grid SET Val = 0
    WHERE X IN (@MinX, @MaxX)

    UPDATE ##Grid SET Val = 0
    WHERE Y IN (@MinY, @MaxY)

    --SELECT * FROM ##Grid 
    --WHERE x BETWEEN -2 AND 6 AND Y BETWEEN 0 AND 8
    --ORDER BY Y, X


    SELECT COUNT(1) FROM ##Grid WHERE Val = 1

    SET @Counter = @Counter + 1

END

--6039 is too high


--DROP TABLE ##Grid
--17965 is correct for part 2
-- Runtime: 2:36 

