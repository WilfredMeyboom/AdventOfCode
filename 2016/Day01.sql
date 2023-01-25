use Test_WME

SET NOCOUNT ON

DECLARE @year VARCHAR(4) = '2016'
DECLARE @day VARCHAR(2)  = '1'

EXEC dbo.GetInput @year = @year, @day = @day
EXEC dbo.ParseInput @year = @year, @day = @day 

--SELECT TOP 10 * FROM ##InputNumbered
--SELECT TOP 10 * FROM ##InputGrid
--SELECT TOP 10 * FROM ##InputInts
--SELECT TOP 10 * FROM ##InputSplit
--SELECT * FROM ##Input

CREATE TABLE ##Directions (ID INT IDENTITY(1,1), SequenceNr INT, Turn CHAR(1), Dist INT)

INSERT ##Directions (SequenceNr, Turn, Dist)
SELECT PieceNr, LEFT(Piece,1), SUBSTRING(Piece, 2, LEN(Piece))
FROM ##InputSplit


--SELECT * FROM ##Directions

CREATE TABLE ##Positions (ID INT IDENTITY(1,1), X INT, Y INT)

DECLARE @Counter INT = 1
DECLARE @PosX INT = 0
DECLARE @PosY INT = 0
DECLARE @Heading INT = 0

WHILE @Counter <= (SELECT COUNT(1) FROM ##Directions)
BEGIN

    UPDATE D
    SET @Heading = (@Heading + CASE WHEN D.Turn = 'L' THEN 270 ELSE 90 END) % 360
    ,   @PosX = @PosX + CASE WHEN @Heading =  90 THEN D.Dist
                             WHEN @Heading = 270 THEN -D.Dist
                             ELSE 0
                             END 
    ,   @PosY = @PosY + CASE WHEN @Heading = 180 THEN D.Dist
                             WHEN @Heading = 0   THEN -D.Dist
                             ELSE 0
                             END 
    FROM ##Directions D
    WHERE SequenceNr = @Counter

    SET @Counter = @Counter + 1

    --PRINT 'Position: ' + CAST(@PosX AS VARCHAR(4)) + ', ' + CAST(@PosY AS VARCHAR(4))

    INSERT ##Positions (X, Y) VALUES (@PosX, @PosY)

END

SELECT X + Y AS Part1 FROM ##Positions WHERE ID IN (SELECT MAX(ID) FROM ##Positions)



;WITH cte_HorizontalLines AS (
    SELECT P1.ID
    , P1.X
    , CASE WHEN P1.Y < P2.Y THEN P1.Y ELSE P2.Y END AS Y1
    , CASE WHEN P1.Y < P2.Y THEN P2.Y ELSE P1.Y END AS Y2
    FROM ##Positions P1
    INNER JOIN ##Positions P2 ON P1.ID = P2.ID - 1 AND P1.X = P2.X
), cte_VerticalLines AS (
    SELECT P1.ID
    , P1.Y
    , CASE WHEN P1.X < P2.X THEN P1.X ELSE P2.X END AS X1
    , CASE WHEN P1.X < P2.X THEN P2.X ELSE P1.X END AS X2
    FROM ##Positions P1
    INNER JOIN ##Positions P2 ON P1.ID = P2.ID - 1 AND P1.Y = P2.Y
)
SELECT TOP 1 ABS(H.X) + ABS(V.Y) AS Part2
FROM cte_HorizontalLines H
INNER JOIN cte_VerticalLines V ON H.X BETWEEN V.X1 + 1 AND V.X2 - 1 AND V.Y BETWEEN H.Y1 + 1 AND H.Y2 - 1 -- Disregard the corners
ORDER BY CASE WHEN H.ID < V.ID THEN H.ID ELSE V.ID END


DROP TABLE ##Directions
DROP TABLE ##Positions

