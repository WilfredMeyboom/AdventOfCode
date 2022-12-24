USE Test_WME

SET NOCOUNT ON

DECLARE @year VARCHAR(4) = '2022'
DECLARE @day VARCHAR(2)  = '24'

EXEC dbo.GetInput @year = @year, @day = @day
EXEC dbo.ParseInput @year = @year, @day = @day 

--SELECT TOP 10 * FROM ##Input
--SELECT TOP 10 * FROM ##InputInts
--SELECT TOP 10 * FROM ##InputNumbered
--SELECT TOP 10 * FROM ##InputGrid
--SELECT TOP 10 * FROM ##InputSplit
--SELECT TOP 10 * FROM ##InputSplitCust
  
CREATE TABLE ##Blizzards (ID INT IDENTITY(1,1), Dir CHAR, x INT, y INT)
CREATE INDEX Ind_Bliz ON ##Blizzards (x,y)

INSERT ##Blizzards
(
    Dir,
    x,
    y
)
SELECT val, RowNr, ColNr FROM ##InputGrid WHERE Val IN ('<','>','v','^')

DECLARE @Counter INT = 0

CREATE TABLE ##Positions (ID INT IDENTITY(1,1), x INT, y INT, t INT)
INSERT ##Positions(x,y,t) SELECT 0, 1, 0
CREATE INDEX Ind_Pos ON ##Positions (t)

DECLARE @MaxX INT
DECLARE @MaxY INT
DECLARE @ExitX INT
DECLARE @ExitY INT
SELECT @ExitX = MAX(RowNr), @ExitY = MAX(ColNr) - 1, @MaxX = MAX(RowNr), @MaxY = MAX(ColNr) FROM ##inputgrid

WHILE NOT EXISTS (SELECT 1 FROM ##Positions P WHERE x = @ExitX AND y = @ExitY)
BEGIN

    SET @Counter = @Counter + 1

    UPDATE ##Blizzards
    SET x = CASE WHEN dir = '^' THEN x - 1 
                 WHEN dir = 'v' THEN x + 1
                 ELSE x END
    ,   y = CASE WHEN dir = '<' THEN y - 1 
                 WHEN dir = '>' THEN y + 1
                 ELSE y END

    UPDATE ##Blizzards
    SET x = CASE WHEN x = 0 THEN @MaxX - 1 
                 WHEN x = @MaxX THEN 1
                 ELSE x END
    ,   y = CASE WHEN y = 0 THEN @MaxY - 1 
                 WHEN y = @MaxY THEN 1
                 ELSE y END
    WHERE x IN (0, @MaxX) OR y IN (0, @MaxY)


    ;WITH cte_Steps AS (
        SELECT 1 AS d UNION SELECT 0 UNION SELECT -1
    )
    INSERT ##Positions(x,y,t) 
    SELECT DISTINCT P.x + x.d, P.y + y.d, @Counter
    FROM ##Positions P
    CROSS APPLY cte_Steps x
    INNER JOIN cte_Steps y ON ABS(x.d) + ABS(y.d) <= 1
    LEFT JOIN ##Blizzards B ON B.x = P.x + x.d
                           AND B.y = P.y + y.d
    WHERE (P.x + x.d BETWEEN 1 AND @MaxX-1
      AND P.y + y.d BETWEEN 1 AND @MaxY-1
      AND B.ID IS NULL)
      OR (P.x + x.d = @ExitX AND P.y + y.d = @ExitY)

    DELETE FROM ##Positions WHERE t = @Counter - 1

END

SELECT @Counter AS Part1


-- Start walking back
DELETE FROM ##Positions

INSERT ##Positions(x,y,t) 
SELECT @MaxX, @ExitY, @Counter


WHILE NOT EXISTS (SELECT 1 FROM ##Positions P WHERE x = 0 AND y = 1)
BEGIN

    SET @Counter = @Counter + 1

    UPDATE ##Blizzards
    SET x = CASE WHEN dir = '^' THEN x - 1 
                 WHEN dir = 'v' THEN x + 1
                 ELSE x END
    ,   y = CASE WHEN dir = '<' THEN y - 1 
                 WHEN dir = '>' THEN y + 1
                 ELSE y END

    UPDATE ##Blizzards
    SET x = CASE WHEN x = 0 THEN @MaxX - 1 
                 WHEN x = @MaxX THEN 1
                 ELSE x END
    ,   y = CASE WHEN y = 0 THEN @MaxY - 1 
                 WHEN y = @MaxY THEN 1
                 ELSE y END
    WHERE x IN (0, @MaxX) OR y IN (0, @MaxY)


    ;WITH cte_Steps AS (
        SELECT 1 d UNION SELECT 0 UNION SELECT -1
    )
    INSERT ##Positions(x,y,t) 
    SELECT DISTINCT P.x + x.d, P.y + y.d, @Counter
    FROM ##Positions P
    CROSS APPLY cte_Steps x
    INNER JOIN cte_Steps y ON ABS(x.d) + ABS(y.d) <= 1
    LEFT JOIN ##Blizzards B ON B.x = P.x + x.d
                           AND B.y = P.y + y.d
    WHERE (P.x + x.d BETWEEN 1 AND @MaxX-1
      AND P.y + y.d BETWEEN 1 AND @MaxY-1
      AND B.ID IS NULL)
      OR (P.x + x.d = 0 AND P.y + y.d = 1)

    IF (SELECT COUNT(1) FROM ##Positions P) > 1
        DELETE FROM ##Positions WHERE t = @Counter - 1
    ELSE UPDATE ##Positions SET t = t + 1

END

--SELECT @Counter  AS Part1_5

DELETE FROM ##Positions

-- Start walking to the exit (again)
INSERT ##Positions(x,y,t) 
SELECT 0, 1, @Counter

WHILE NOT EXISTS (SELECT 1 FROM ##Positions P WHERE x = @ExitX AND y = @ExitY)
BEGIN

    SET @Counter = @Counter + 1

    UPDATE ##Blizzards
    SET x = CASE WHEN dir = '^' THEN x - 1 
                 WHEN dir = 'v' THEN x + 1
                 ELSE x END
    ,   y = CASE WHEN dir = '<' THEN y - 1 
                 WHEN dir = '>' THEN y + 1
                 ELSE y END

    UPDATE ##Blizzards
    SET x = CASE WHEN x = 0 THEN @MaxX - 1 
                 WHEN x = @MaxX THEN 1
                 ELSE x END
    ,   y = CASE WHEN y = 0 THEN @MaxY - 1 
                 WHEN y = @MaxY THEN 1
                 ELSE y END
    WHERE x IN (0, @MaxX) OR y IN (0, @MaxY)


    ;WITH cte_Steps AS (
        SELECT 1 d UNION SELECT 0 UNION SELECT -1
    )
    INSERT ##Positions(x,y,t) 
    SELECT DISTINCT P.x + x.d, P.y + y.d, @Counter
    FROM ##Positions P
    CROSS APPLY cte_Steps x
    INNER JOIN cte_Steps y ON ABS(x.d) + ABS(y.d) <= 1
    LEFT JOIN ##Blizzards B ON B.x = P.x + x.d
                           AND B.y = P.y + y.d
    WHERE (P.x + x.d BETWEEN 1 AND @MaxX-1
      AND P.y + y.d BETWEEN 1 AND @MaxY-1
      AND B.ID IS NULL)
      OR (P.x + x.d = @ExitX AND P.y + y.d = @ExitY)

    IF (SELECT COUNT(1) FROM ##Positions P) > 1
        DELETE FROM ##Positions WHERE t = @Counter - 1
    ELSE UPDATE ##Positions SET t = t + 1

END

SELECT @Counter  AS Part2

DROP TABLE ##Positions
DROP TABLE ##Blizzards

