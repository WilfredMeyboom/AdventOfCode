use Test_WME

SET NOCOUNT ON

CREATE TABLE ##Input (Line NVARCHAR(MAX));

BULK INSERT ##Input
FROM 'D:\Wilfred\AdventOfCode\2016\input24.txt'
WITH (ROWTERMINATOR = '0x0A');

--SELECT 37 * 181 --6697

CREATE TABLE ##Tiles (ID INT IDENTITY(1,1), X INT, Y INT, Tile CHAR)

CREATE UNIQUE INDEX UQ_Tiles ON ##Tiles (X, Y)

;WITH cte_Tiles AS (
    SELECT 1 AS X
    ,      ROW_NUMBER() OVER (ORDER BY (SELECT 0)) AS Y
    ,      LEFT(Line, 1) AS Tile
    ,      SUBSTRING(Line, 2, LEN(Line)) AS Remainder
    FROM ##Input
    UNION ALL
    SELECT X + 1
    ,      Y 
    ,      LEFT(Remainder, 1)
    ,      SUBSTRING(Remainder, 2, LEN(Remainder))
    FROM cte_Tiles
    WHERE LEN(Remainder) > 0
)
INSERT ##Tiles (X, Y, Tile)
SELECT X, Y, Tile
FROM cte_Tiles
OPTION (MAXRECURSION 10000)

DELETE FROM ##Tiles WHERE Tile = '#'

--SELECT * FROM ##Tiles

CREATE TABLE ##Distances (ID INT IDENTITY(1,1), FromPoint CHAR, ToPoint CHAR, Distance INT)

;WITH cte_Targets AS (SELECT Tile FROM ##Tiles WHERE Tile NOT IN ('.', '#'))
INSERT ##Distances (FromPoint, ToPoint)
SELECT T1.Tile, T2.Tile
FROM cte_Targets T1
INNER JOIN cte_Targets T2 ON T1.Tile < T2.Tile
ORDER BY 1,2 


DECLARE @Start CHAR
DECLARE @End CHAR
DECLARE @xEnd INT
DECLARE @yEnd INT

CREATE TABLE ##Steps (ID INT IDENTITY, X INT, Y INT, Dist INT)

DECLARE DistCursor CURSOR FOR SELECT FromPoint, ToPoint FROM ##Distances

OPEN DistCursor

FETCH NEXT FROM DistCursor INTO @Start, @End

WHILE @@FETCH_STATUS = 0
BEGIN
    
    PRINT @Start + ' ' + @End

    DELETE FROM ##Steps

    INSERT ##Steps (X, Y, Dist)
    SELECT X, Y, 0 FROM ##Tiles WHERE Tile = @Start
    
    SELECT @xEnd = X, @yEnd = Y FROM ##Tiles WHERE Tile = @End

    WHILE NOT EXISTS (SELECT 1 FROM ##Steps WHERE X = @xEnd AND Y = @yEnd)
    BEGIN

        ;WITH cte_MaxDist AS (
            SELECT MAX(Dist) AS MaxDist FROM ##Steps
            )
        INSERT ##Steps (X, Y, Dist)
        SELECT DISTINCT T.X, T.Y, cMD.MaxDist + 1
        FROM ##Steps S
        INNER JOIN cte_MaxDist cMD ON S.Dist = cMD.MaxDist
        INNER JOIN ##Tiles T ON (S.X = T.X AND ABS(S.Y - T.Y) = 1) OR (S.Y = T.Y AND ABS(S.X - T.X) = 1)
        LEFT JOIN ##Steps S2 ON T.X = S2.X AND T.Y = S2.Y
        WHERE S2.ID IS NULL

    END

    PRINT 'End of loop'

    SELECT MIN(Dist) AS Dist FROM ##Steps WHERE X = @xEnd AND Y = @yEnd

    UPDATE D 
    SET D.Distance = Sub.Dist
    FROM ##Distances D
    CROSS APPLY (SELECT MIN(Dist) AS Dist FROM ##Steps WHERE X = @xEnd AND Y = @yEnd) Sub
    WHERE FromPoint = @Start AND ToPoint = @End

    FETCH NEXT FROM DistCursor INTO @Start, @End

END

CLOSE DistCursor
DEALLOCATE DistCursor



;WITH cte_Distances AS (
    SELECT FromPoint, ToPoint, Distance FROM ##Distances
    UNION 
    SELECT ToPoint, FromPoint, Distance FROM ##Distances
)
SELECT D0.Distance + D1.Distance + D2.Distance + D3.Distance + D4.Distance + D5.Distance + D6.Distance + D7.Distance
FROM cte_Distances D0
INNER JOIN cte_Distances D1 ON D0.ToPoint = D1.FromPoint AND D1.ToPoint <> D0.FromPoint
INNER JOIN cte_Distances D2 ON D1.ToPoint = D2.FromPoint AND D2.ToPoint NOT IN (D0.FromPoint, D1.FromPoint)
INNER JOIN cte_Distances D3 ON D2.ToPoint = D3.FromPoint AND D3.ToPoint NOT IN (D0.FromPoint, D1.FromPoint, D2.FromPoint)
INNER JOIN cte_Distances D4 ON D3.ToPoint = D4.FromPoint AND D4.ToPoint NOT IN (D0.FromPoint, D1.FromPoint, D2.FromPoint, D3.FromPoint)
INNER JOIN cte_Distances D5 ON D4.ToPoint = D5.FromPoint AND D5.ToPoint NOT IN (D0.FromPoint, D1.FromPoint, D2.FromPoint, D3.FromPoint, D4.FromPoint)
INNER JOIN cte_Distances D6 ON D5.ToPoint = D6.FromPoint AND D6.ToPoint NOT IN (D0.FromPoint, D1.FromPoint, D2.FromPoint, D3.FromPoint, D4.FromPoint, D5.FromPoint)
/*Part 2*/
INNER JOIN cte_Distances D7 ON D6.ToPoint = D7.FromPoint AND D7.ToPoint = 0 
WHERE D0.FromPoint = 0
ORDER BY 1

/*

DROP TABLE ##Steps
DROP TABLE ##Distances
DROP TABLE ##Tiles
DROP TABLE ##Input


*/

--470 Correct for part 1
--720 Correct for part 2