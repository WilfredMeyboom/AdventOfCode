USE Test_WME

SET NOCOUNT ON

DECLARE @year VARCHAR(4) = '2022'
DECLARE @day VARCHAR(2)  = '17'

EXEC dbo.GetInput @year = @year, @day = @day
EXEC dbo.ParseInput @year = @year, @day = @day 

--SELECT TOP 10 * FROM ##Input
--SELECT TOP 10 * FROM ##InputInts
--SELECT TOP 10 * FROM ##InputNumbered
--SELECT * FROM ##InputGrid
--SELECT TOP 10 * FROM ##InputSplit
--SELECT TOP 10 * FROM ##InputSplitCust
  
CREATE TABLE ##Shapes (ID INT IDENTITY(1,1), ShapeNr INT, X INT, Y INT, RelX INT, RelY INT)

-- Shape: ####
INSERT ##Shapes (ShapeNr, X, Y, RelX, RelY)
SELECT 0, 0, 0, 0, 0
UNION 
SELECT 0, 0, 0, 1, 0
UNION 
SELECT 0, 0, 0, 2, 0
UNION 
SELECT 0, 0, 0, 3, 0

-- Shape: .#.
--        ###
--        .#.
INSERT ##Shapes (ShapeNr, X, Y, RelX, RelY)
SELECT 1, 0, 0, 0, 1
UNION 
SELECT 1, 0, 0, 1, 1
UNION 
SELECT 1, 0, 0, 2, 1
UNION 
SELECT 1, 0, 0, 1, 0
UNION 
SELECT 1, 0, 0, 1, 2

-- Shape: ..#
--        ..#
--        ###
INSERT ##Shapes (ShapeNr, X, Y, RelX, RelY)
SELECT 2, 0, 0, 0, 0
UNION 
SELECT 2, 0, 0, 1, 0
UNION 
SELECT 2, 0, 0, 2, 0
UNION 
SELECT 2, 0, 0, 2, 1
UNION 
SELECT 2, 0, 0, 2, 2

-- Shape: #
--        #
--        #
--        #
INSERT ##Shapes (ShapeNr, X, Y, RelX, RelY)
SELECT 3, 0, 0, 0, 0
UNION 
SELECT 3, 0, 0, 0, 1
UNION 
SELECT 3, 0, 0, 0, 2
UNION 
SELECT 3, 0, 0, 0, 3

-- Shape: ##
--        ##
INSERT ##Shapes (ShapeNr, X, Y, RelX, RelY)
SELECT 4, 0, 0, 0, 0
UNION 
SELECT 4, 0, 0, 0, 1
UNION 
SELECT 4, 0, 0, 1, 0
UNION 
SELECT 4, 0, 0, 1, 1


CREATE TABLE ##Pit (ID INT IDENTITY(1,1), X INT, Y INT, Val INT)

-- Val = 1 is a floor
-- Val = 2 is a wall
-- Val = 3 is a piece


;WITH cte_Nrs AS (
    SELECT TOP 9 ROW_NUMBER() OVER (ORDER BY (SELECT 0)) - 1 AS Nr FROM sys.messages
)
INSERT ##Pit (X, Y, Val)
SELECT c1.Nr, c2.Nr, CASE WHEN c2.Nr = 0 THEN 1 ELSE 2 END
FROM cte_Nrs c1
CROSS APPLY cte_Nrs c2 
WHERE c2.Nr = 0 OR c1.Nr = 0 OR c1.Nr = 8

CREATE UNIQUE INDEX Ind_Pit ON ##Pit(x,y)


DECLARE @ShapesCounter INT = 0
DECLARE @NewX INT = 3
DECLARE @NewY INT
DECLARE @MoveCounter INT = 0
DECLARE @TotalMoves INT
DECLARE @CurrentShape INT
DECLARE @ShapeDidNotDrop INT
DECLARE @Move INT

SELECT @TotalMoves = COUNT(1) FROM ##InputGrid

CREATE TABLE ##Heigths (ID INT IDENTITY(1,1), ShapeNr INT, Heigth BIGINT)

WHILE @ShapesCounter < 10000--2022
BEGIN

    SELECT @NewY = MAX(Y) + 4 FROM ##Pit P WHERE Val <> 2
    SET @CurrentShape = @ShapesCounter % 5

    -- Place shape
    UPDATE ##Shapes 
    SET X = @NewX
    ,   Y = @NewY
    WHERE ShapeNr = @CurrentShape

    -- Extend walls
    SELECT @NewY = MAX(Y + RelY) FROM ##Shapes S WHERE Shapenr = @CurrentShape
    
    ;WITH cte_Nrs AS (
        SELECT TOP 5 @NewY - ROW_NUMBER() OVER (ORDER BY (SELECT 0)) + 1 AS Y FROM sys.messages
    )
    INSERT ##Pit (X, Y, Val)
    SELECT X.X, Y.Y, 2
    FROM cte_Nrs Y
    CROSS APPLY (SELECT 0 AS X UNION SELECT 8) X
    LEFT JOIN ##Pit P ON P.Y = Y.Y AND P.X = X.X
    WHERE P.ID IS NULL

    SET @ShapeDidNotDrop = 0

    -- Loop until not dropped
    WHILE @ShapeDidNotDrop = 0
    BEGIN

        -- Move Shape <>
        SELECT @Move = CASE WHEN Val = '<' THEN -1 ELSE 1 END FROM ##InputGrid WHERE ColNr = @MoveCounter

        IF NOT EXISTS (SELECT 1 FROM ##Shapes S
                                INNER JOIN ##Pit P ON P.X = S.X + S.RelX + @Move 
                                                  AND P.Y = S.Y + S.RelY
                                WHERE S.ShapeNr = @CurrentShape
                      )
        BEGIN
                UPDATE ##Shapes SET X = X + @Move
                WHERE ShapeNr = @CurrentShape
        END


        SET @MoveCounter = (@MoveCounter + 1) % @TotalMoves

        -- Drop Shape 
        IF NOT EXISTS (SELECT 1 FROM ##Shapes S
                        INNER JOIN ##Pit P ON P.X = S.X + S.RelX  
                                            AND P.Y = S.Y + S.RelY - 1
                        WHERE S.ShapeNr = @CurrentShape
                      )
        BEGIN
                UPDATE ##Shapes SET Y = Y - 1
                WHERE ShapeNr = @CurrentShape
        END
        ELSE
        BEGIN

            -- Put Shape in grid
            INSERT ##Pit (X, Y, Val)
            SELECT X + RelX, Y + RelY, 3 + @ShapesCounter
            FROM ##Shapes S
            WHERE S.ShapeNr = @CurrentShape

            SET @ShapeDidNotDrop = 1

        END

    END

    INSERT ##Heigths (ShapeNr, Heigth)
    SELECT @CurrentShape, MAX(Y)
    FROM ##Pit 
    WHERE Val >= 3
    
    SET @ShapesCounter = @ShapesCounter + 1

END

SELECT H.Heigth AS Part1 FROM ##Heigths H WHERE ID = 2022

/*
--Data analysis... find every place where the pit is filled from left to right
--and look at the interval between those lines
;WITH cte_FullLines AS (
SELECT y FROM ##Pit GROUP BY y HAVING COUNT(x) = 9 --ORDER BY y
)
SELECT C2.y - C1.y, COUNT(1)
FROM cte_FullLines C1
CROSS APPLY cte_FullLines C2
GROUP BY C2.y - C1.y
ORDER BY 2 DESC

-- Ok, there seems to be some set interval
SELECT 2616, 2616 * 2, 2616 * 3, 2616 * 4, 2616 * 5

SELECT y, Val FROM ##Pit WHERE y IN (496, 3112, 5728) GROUP BY y, Val ORDER BY y, Val

SELECT *
FROM ##Heigths H
WHERE H.ID IN (331, 2046, 3761) -- Nexts are 8344, 10960
*/


/*
-- Let's predict 10000 because we know the actual answer (15238)
SELECT 10000 / 1715     -- 5
SELECT 1715 * 5         -- 8575
SELECT 10000 - 8575     -- 1425

SELECT * FROM ##Heigths H WHERE ID = 1425  -- 2158
SELECT  2616 * 5 + 2158 AS Part1_5
*/

-- Let's predict 1000000000000
SELECT CAST(1000000000000 AS BIGINT)/ 1715     -- 583090379
SELECT CAST(1715 AS BIGINT) * 583090379        -- 999999999985
SELECT 1000000000000 - 999999999985            -- 15

SELECT *, H.Heigth-2616 FROM ##Heigths H WHERE ID = 15+1715  -- 23 (We need to move in the first iteration of the sequence because shape 15 is too close to the floor)
SELECT  CAST(2616 AS BIGINT) * 583090379 + 23 AS Part2

--1525364431487 is correct for part 2


DROP TABLE ##Shapes
DROP TABLE ##Pit
DROP TABLE ##Heigths





