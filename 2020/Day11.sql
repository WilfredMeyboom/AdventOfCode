USE Test_WME

SET NOCOUNT ON

CREATE TABLE ##Input (Line NVARCHAR(MAX));

BULK INSERT ##Input
FROM 'C:\Source\AdventOfCode\2020\input11.txt'
WITH (ROWTERMINATOR = '0x0A');


--Create and fill the Grid table which is a map of the input
CREATE TABLE ##Grid (ID INT IDENTITY(1,1), x INT, y INT, val CHAR, UNIQUE(x,y))

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
INSERT ##Grid(x, y, val)
SELECT x, y, val
FROM cte_Grid
OPTION (MAXRECURSION 20000)


DECLARE @RowCount INT = 1
DECLARE @Counter INT = 1

DECLARE @DoFirstPart INT = 1

IF @DoFirstPart = 1 
BEGIN

WHILE @RowCount > 0
BEGIN

    ;WITH cte_Around AS (
        SELECT G1.X
        ,      G1.Y
        ,      SUM(CASE WHEN G2.Val = 'F' THEN 1 ELSE 0 END) AS FilledSeats
        ,      SUM(CASE WHEN G2.Val = '.' THEN 1 ELSE 0 END) AS FloorSpaces
        ,      SUM(CASE WHEN G2.Val = 'L' THEN 1 ELSE 0 END) AS EmptySeats
        FROM ##Grid G1
        LEFT JOIN ##Grid G2 ON ABS(G1.X - G2.X) <= 1 AND ABS(G1.Y - G2.Y) <= 1 AND G1.ID <> G2.ID
        GROUP BY G1.X, G1.Y
    )
    UPDATE G
    SET Val = CASE WHEN Val = 'L' AND FilledSeats = 0 THEN 'F' 
                   WHEN Val = 'F' AND FilledSeats >= 4 THEN 'L'
                   ELSE Val END
    FROM ##Grid G
    INNER JOIN cte_Around cA ON G.X = cA.X AND G.Y = cA.Y

    IF @RowCount = (SELECT COUNT(1) FROM ##Grid WHERE val = 'F')
        SET @RowCount = 0
    ELSE
        SELECT @RowCount = COUNT(1) FROM ##Grid WHERE val = 'F'

    PRINT 'Iteration ' + CAST(@Counter AS VARCHAR(5)) + ' filled seats ' + CAST(@RowCount AS VARCHAR(5)) + ' at ' + CAST(GETDATE() AS VARCHAR(50))
    SET @Counter = @Counter + 1

END


SELECT * FROM ##Grid WHERE Val = 'F'
-- 2406 is correct for part 1

END
ELSE
BEGIN

CREATE TABLE ##ChairSights (ID INT IDENTITY, X INT, Y INT, Dir VARCHAR(2), X2 INT, Y2 INT)

;WITH cte_ChairSights AS (
        SELECT G1.X
        ,      G1.Y
        ,      CASE WHEN G1.Y < G2.Y THEN 'S'
                    WHEN G1.Y > G2.Y THEN 'N'
                    ELSE '' END +
               CASE WHEN G1.X < G2.X THEN 'E'
                    WHEN G1.X > G2.X THEN 'W'
                    ELSE '' END AS Dir
        ,      G2.X AS X2
        ,      G2.Y AS Y2
        ,      G2.val
        FROM ##Grid G1
        INNER JOIN ##Grid G2 ON ABS(G1.X - G2.X) <= 1 AND ABS(G1.Y - G2.Y) <= 1 AND G1.ID <> G2.ID
        WHERE G1.val = 'L'

        UNION ALL

        SELECT cCS.X
        ,      cCS.Y
        ,      cCS.Dir
        ,      G.X
        ,      G.Y
        ,      G.val
        FROM cte_ChairSights cCs
        INNER JOIN ##Grid G ON cCS.X2  = CASE WHEN Dir IN ('N', 'S')   THEN G.X
                                              WHEN RIGHT(Dir, 1) = 'W' THEN G.X + 1
                                              WHEN RIGHT(Dir, 1) = 'E' THEN G.X - 1
                                         END
                           AND cCS.Y2 = CASE WHEN Dir IN ('W', 'E')  THEN G.Y
                                             WHEN LEFT(Dir, 1) = 'N' THEN G.Y + 1
                                             WHEN LEFT(Dir, 1) = 'S' THEN G.Y - 1
                                         END
        WHERE cCS.val <> 'L'
)
INSERT ##ChairSights (X, Y, Dir, X2, Y2)
SELECT X, Y, Dir, X2, Y2--, val
FROM cte_ChairSights
WHERE val = 'L'



WHILE @RowCount <> 0
BEGIN

    ;WITH cte_Around AS (
        SELECT G1.X
        ,      G1.Y
        ,      SUM(CASE WHEN G2.Val = 'F' THEN 1 ELSE 0 END) AS FilledSeats
        ,      SUM(CASE WHEN G2.Val = '.' THEN 1 ELSE 0 END) AS FloorSpaces
        ,      SUM(CASE WHEN G2.Val = 'L' THEN 1 ELSE 0 END) AS EmptySeats
        FROM ##Grid G1
        INNER JOIN ##ChairSights CS ON G1.X = CS.X AND G1.Y = CS.Y
        LEFT JOIN ##Grid G2 ON CS.X2 = G2.X AND CS.Y2 = G2.Y
        GROUP BY G1.X, G1.Y
    )
    UPDATE G
    SET Val = CASE WHEN Val = 'L' AND FilledSeats = 0 THEN 'F' 
                   WHEN Val = 'F' AND FilledSeats >= 5 THEN 'L'
                   ELSE Val END
    FROM ##Grid G
    INNER JOIN cte_Around cA ON G.X = cA.X AND G.Y = cA.Y

    IF @RowCount = (SELECT COUNT(1) FROM ##Grid WHERE val = 'F')
        SET @RowCount = 0
    ELSE
        SELECT @RowCount = COUNT(1) FROM ##Grid WHERE val = 'F'

    PRINT 'Iteration ' + CAST(@Counter AS VARCHAR(5)) + ' filled seats ' + CAST(@RowCount AS VARCHAR(5)) + ' at ' + CAST(GETDATE() AS VARCHAR(50))
    SET @Counter = @Counter + 1

END

SELECT * FROM ##Grid WHERE Val = 'F'

END
--2149 is correct for part 2

/*

DROP TABLE ##ChairSights
DROP TABLE ##Grid
DROP TABLE ##Input

*/



