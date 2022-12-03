USE Test_WME

SET NOCOUNT ON

DECLARE @year VARCHAR(4) = '2021'
DECLARE @day VARCHAR(2)  = '22'

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
--SELECT TOP 10 * FROM ##InputGrid
--SELECT TOP 10 * FROM ##InputInts
--SELECT * FROM ##InputSplit
--SELECT TOP 10 * FROM ##InputSplitCust

--CREATE TABLE ##Grid (ID INT IDENTITY(1,1), x INT, y INT, z INT, Val INT, UNIQUE(x,y,z))

--;WITH cte_Nrs AS (
--SELECT TOP 101 ROW_NUMBER() OVER (ORDER BY (SELECT 0)) -51 Nr FROM sys.messages
--)
--INSERT ##Grid (x,y,z,Val)
--SELECT x.Nr AS x, y.Nr AS y, z.Nr AS z, 0 AS Val
--FROM cte_Nrs x
--CROSS APPLY cte_Nrs y
--CROSS APPLY cte_Nrs z

DECLARE @xMin INT
DECLARE @xMax INT
DECLARE @yMin INT
DECLARE @yMax INT
DECLARE @zMin INT
DECLARE @zMax INT
DECLARE @Val VARCHAR(10)
DECLARE @Counter INT = 0
/*
DECLARE cursor_name CURSOR FAST_FORWARD READ_ONLY FOR 
    SELECT I1.Piece
    , CAST(I3.Piece AS INT) AS xMin
    , CAST(I4.Piece AS INT) AS xMax
    , CAST(I6.Piece AS INT) AS yMin
    , CAST(I7.Piece AS INT) AS yMax
    , CAST(I9.Piece AS INT) AS zMin
    , CAST(I10.Piece AS INT) AS zMax
    FROM ##InputSplitCust I1
    INNER JOIN ##InputSplitCust I3 ON I3.RowNr = I1.RowNr AND I3.PieceNr = 3
    INNER JOIN ##InputSplitCust I4 ON I4.RowNr = I1.RowNr AND I4.PieceNr = 4
    INNER JOIN ##InputSplitCust I6 ON I6.RowNr = I1.RowNr AND I6.PieceNr = 6
    INNER JOIN ##InputSplitCust I7 ON I7.RowNr = I1.RowNr AND I7.PieceNr = 7
    INNER JOIN ##InputSplitCust I9 ON I9.RowNr = I1.RowNr AND I9.PieceNr = 9
    INNER JOIN ##InputSplitCust I10 ON I10.RowNr = I1.RowNr AND I10.PieceNr = 10
    WHERE I1.PieceNr = 1
    ORDER BY I1.RowNr


OPEN cursor_name

FETCH NEXT FROM cursor_name INTO @Val, @xMin, @xMax, @yMin, @yMax, @zMin, @zMax

WHILE @@FETCH_STATUS = 0
BEGIN
    
    UPDATE G 
    SET Val = CASE WHEN @Val = 'on' THEN 1 ELSE 0 END
    FROM ##Grid G
    WHERE x BETWEEN @xMin AND @xMax
    AND y BETWEEN @yMin AND @yMax
    AND z BETWEEN @zMin AND @zMax

    PRINT CAST(@Counter AS VARCHAR(5)) + ' Iteration done'

    SET @Counter = @Counter + 1

    FETCH NEXT FROM cursor_name INTO @Val, @xMin, @xMax, @yMin, @yMax, @zMin, @zMax
END

CLOSE cursor_name
DEALLOCATE cursor_name


SELECT COUNT(1) FROM ##Grid WHERE Val = 1
*/

--DROP TABLE ##Grid

CREATE TABLE ##Grid (ID INT IDENTITY(1,1), x BIGINT, y BIGINT, z BIGINT, Val INT, UNIQUE(x,y,z))

SET @Counter = 0

;WITH cte_x AS (
    SELECT CAST(Piece AS BIGINT) AS x FROM ##InputSplitCust I WHERE PieceNr = 3
    UNION
    SELECT CAST(Piece AS BIGINT) AS x FROM ##InputSplitCust I WHERE PieceNr = 4
),cte_y AS (
    SELECT CAST(Piece AS BIGINT) AS y FROM ##InputSplitCust I WHERE PieceNr = 6
    UNION
    SELECT CAST(Piece AS BIGINT) AS y FROM ##InputSplitCust I WHERE PieceNr = 7
),cte_z AS (
    SELECT CAST(Piece AS BIGINT) AS z FROM ##InputSplitCust I WHERE PieceNr = 9
    UNION
    SELECT CAST(Piece AS BIGINT) AS z FROM ##InputSplitCust I WHERE PieceNr = 10
)
INSERT ##Grid
(
    x,
    y,
    z,
    Val
)
SELECT x,y,z,0
FROM cte_x
CROSS APPLY cte_y
CROSS APPLY cte_z
WHERE x BETWEEN -50 AND 50 AND y BETWEEN -50 AND 50 AND z BETWEEN -50 AND 50


DECLARE cursor_name CURSOR FAST_FORWARD READ_ONLY FOR     
    SELECT I1.Piece
    , CAST(I3.Piece AS INT) AS xMin
    , CAST(I4.Piece AS INT) AS xMax
    , CAST(I6.Piece AS INT) AS yMin
    , CAST(I7.Piece AS INT) AS yMax
    , CAST(I9.Piece AS INT) AS zMin
    , CAST(I10.Piece AS INT) AS zMax
    FROM ##InputSplitCust I1
    INNER JOIN ##InputSplitCust I3 ON I3.RowNr = I1.RowNr AND I3.PieceNr = 3
    INNER JOIN ##InputSplitCust I4 ON I4.RowNr = I1.RowNr AND I4.PieceNr = 4
    INNER JOIN ##InputSplitCust I6 ON I6.RowNr = I1.RowNr AND I6.PieceNr = 6
    INNER JOIN ##InputSplitCust I7 ON I7.RowNr = I1.RowNr AND I7.PieceNr = 7
    INNER JOIN ##InputSplitCust I9 ON I9.RowNr = I1.RowNr AND I9.PieceNr = 9
    INNER JOIN ##InputSplitCust I10 ON I10.RowNr = I1.RowNr AND I10.PieceNr = 10
    WHERE I1.PieceNr = 1
    ORDER BY I1.RowNr

OPEN cursor_name

FETCH NEXT FROM cursor_name INTO @Val, @xMin, @xMax, @yMin, @yMax, @zMin, @zMax

WHILE @@FETCH_STATUS = 0
BEGIN
    
    UPDATE G 
    SET Val = CASE WHEN @Val = 'on' THEN 1 ELSE 0 END
    FROM ##Grid G
    WHERE x BETWEEN @xMin AND @xMax
    AND y BETWEEN @yMin AND @yMax
    AND z BETWEEN @zMin AND @zMax

    PRINT CAST(@Counter AS VARCHAR(5)) + ' Iteration done'

    SET @Counter = @Counter + 1

    FETCH NEXT FROM cursor_name INTO @Val, @xMin, @xMax, @yMin, @yMax, @zMin, @zMax
END

CLOSE cursor_name
DEALLOCATE cursor_name

;WITH cte_x AS (
SELECT x, ISNULL(LEAD(x) OVER (ORDER BY x) - x , 1) AS LenX
FROM ##Grid
GROUP BY x
), cte_y AS (
SELECT y, ISNULL(LEAD(y) OVER (ORDER BY y) - y, 1) AS LenY
FROM ##Grid
GROUP BY y
), cte_z AS (
SELECT z, ISNULL(LEAD(z) OVER (ORDER BY z) - z, 1) AS LenZ
FROM ##Grid
GROUP BY z
)
SELECT (LenX * LenY * LenZ), *
FROM ##Grid G
INNER JOIN cte_x cx ON cx.x = G.x
INNER JOIN cte_y cy ON cy.y = G.y
INNER JOIN cte_z cz ON cz.z = G.z
WHERE G.Val = 1

ORDER BY G.x, G.y,G.z



SELECT * FROM ##Grid G
--DROP TABLE ##Grid
ORDER BY G.x, G.y,G.z