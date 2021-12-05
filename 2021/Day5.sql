USE Test_WME

DECLARE @year VARCHAR(4) = '2021'
DECLARE @day VARCHAR(2)  = '5'

EXEC dbo.GetInput @year = @year, @day = @day
EXEC dbo.ParseInput @year = @year, @day = @day 

SELECT TOP 10 * FROM ##InputNumbered
SELECT TOP 10 * FROM ##InputGrid
SELECT TOP 10 * FROM ##InputInts
SELECT TOP 10 * FROM ##InputSplit

--Check the size of the grid
--SELECT PieceNr, MIN(CAST(Piece AS INT)), MAX(CAST(Piece AS INT)) FROM ##InputSplit WHERE TRY_CAST(Piece AS INT) IS NOT NULL GROUP BY PieceNr ORDER BY PieceNr

CREATE TABLE ##Grid (ID INT IDENTITY(1,1), x INT, y INT, marked INT, UNIQUE (x,y))

;WITH cte_x AS (SELECT TOP 1000 ROW_NUMBER() OVER (ORDER BY (SELECT 0)) -1 AS X FROM sys.messages)
, cte_y AS (SELECT TOP 1000 ROW_NUMBER() OVER (ORDER BY (SELECT 0)) -1 AS y FROM sys.messages)
INSERT ##Grid(x,y,marked)
SELECT x, y, 0
FROM cte_x CROSS APPLY cte_y


DECLARE @LineNr INT

DECLARE lineCursor CURSOR FAST_FORWARD READ_ONLY FOR 
    SELECT I1.RowNr 
    FROM ##InputSplit I1
    INNER JOIN ##InputSplit I2 ON I1.RowNr = I2.RowNr 
                              AND I1.PieceNr = I2.PieceNr - 3
                              AND I1.Piece = I2.Piece

OPEN lineCursor

FETCH NEXT FROM lineCursor INTO @LineNr

DECLARE @x1 INT
DECLARE @y1 INT
DECLARE @x2 INT
DECLARE @y2 INT


WHILE @@FETCH_STATUS = 0
BEGIN
    
    SELECT @x1 = CAST(Piece AS INT) FROM ##InputSplit WHERE RowNr = @LineNr AND PieceNr = 1
    SELECT @y1 = CAST(Piece AS INT) FROM ##InputSplit WHERE RowNr = @LineNr AND PieceNr = 2
    SELECT @x2 = CAST(Piece AS INT) FROM ##InputSplit WHERE RowNr = @LineNr AND PieceNr = 4
    SELECT @y2 = CAST(Piece AS INT) FROM ##InputSplit WHERE RowNr = @LineNr AND PieceNr = 5

    UPDATE ##Grid
    SET marked = marked + 1
    WHERE (x BETWEEN @x1 AND @x2 OR x BETWEEN @x2 AND @x1)
    AND (y BETWEEN @y1 AND @y2 OR y BETWEEN @y2 AND @y1)

    FETCH NEXT FROM lineCursor INTO @LineNr
END

CLOSE lineCursor
DEALLOCATE lineCursor

    
SELECT COUNT(1) AS Part1 FROM ##Grid G
WHERE G.marked > 1

--5632

DECLARE @LineSize INT

DECLARE diagonalCursor CURSOR FAST_FORWARD READ_ONLY FOR 
   SELECT DISTINCT RowNr FROM ##InputSplit WHERE RowNr NOT IN (
   SELECT I1.RowNr 
    FROM ##InputSplit I1
    INNER JOIN ##InputSplit I2 ON I1.RowNr = I2.RowNr 
                              AND I1.PieceNr = I2.PieceNr - 3
                              AND I1.Piece = I2.Piece
                              )
OPEN diagonalCursor

FETCH NEXT FROM diagonalCursor INTO @LineNr

WHILE @@FETCH_STATUS = 0
BEGIN
    
    SELECT @x1 = CAST(Piece AS INT) FROM ##InputSplit WHERE RowNr = @LineNr AND PieceNr = 1
    SELECT @y1 = CAST(Piece AS INT) FROM ##InputSplit WHERE RowNr = @LineNr AND PieceNr = 2
    SELECT @x2 = CAST(Piece AS INT) FROM ##InputSplit WHERE RowNr = @LineNr AND PieceNr = 4
    SELECT @y2 = CAST(Piece AS INT) FROM ##InputSplit WHERE RowNr = @LineNr AND PieceNr = 5

    SELECT @LineSize = ABS(@x1 - @x2) + 1

    ;WITH cte_steps AS (
        SELECT TOP (@LineSize) ROW_NUMBER() OVER (ORDER BY (SELECT 0)) - 1 AS step FROM sys.messages
    ), cte_points AS (
        SELECT @x1 + CASE WHEN @x1 < @x2 THEN step ELSE - step END x
        ,      @y1 + CASE WHEN @y1 < @y2 THEN step ELSE - step END y
        FROM cte_steps
    )
    UPDATE ##Grid
    SET marked = G.marked + 1
    FROM ##Grid G
    INNER JOIN cte_points P ON P.x = G.x AND P.y = G.y

    FETCH NEXT FROM diagonalCursor INTO @LineNr
END

CLOSE diagonalCursor
DEALLOCATE diagonalCursor


SELECT COUNT(1) AS Part2 FROM ##Grid G
WHERE G.marked > 1

--22213

DROP TABLE ##Grid

