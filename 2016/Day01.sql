use Test_WME

SET NOCOUNT ON

CREATE TABLE ##Input (Line NVARCHAR(MAX));

BULK INSERT ##Input
FROM 'D:\Wilfred\AdventOfCode\2016\input01.txt'
WITH (ROWTERMINATOR = '0x0A');

--SELECT * FROM ##Input

CREATE TABLE ##Directions (ID INT IDENTITY(1,1), SequenceNr INT, Turn CHAR(1), Dist INT)

;WITH cte_Directions AS (
    SELECT LTRIM(RTRIM(LEFT(Line, CHARINDEX(',', Line) - 1))) AS Direction
    ,      SUBSTRING(Line, CHARINDEX(',', Line) + 1, LEN(Line)) + ',' AS Remainder
    ,      1 AS SequenceNr
    FROM ##Input 
    UNION ALL
    SELECT LTRIM(RTRIM(LEFT(Remainder, CHARINDEX(',', Remainder) - 1))) AS Direction
    ,      SUBSTRING(Remainder, CHARINDEX(',', Remainder) + 1, LEN(Remainder)) AS Remainder
    ,      SequenceNr + 1
    FROM cte_Directions
    WHERE LEN(Remainder) > 0
)
INSERT ##Directions (SequenceNr, Turn, Dist)
SELECT SequenceNr
,      LEFT(Direction, 1)
,      CAST(SUBSTRING(Direction, 2, LEN(Direction)) AS INT)
FROM cte_Directions OPTION (MAXRECURSION 10000)


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

--SELECT 61 + 85

/*

DROP TABLE ##Directions
DROP TABLE ##Input

*/

--SELECT * 
--FROM ##Positions P1 
--INNER JOIN ##Positions P2 ON P1.X = P2.X AND P1.Y = P2.Y AND P1.ID < P2.ID

--184 is wrong for part 2

--Visualisatie met excel geeft 2 lijnen die elkaar kruisen
-- (-34,4) - (-34, 198)
-- (-94, 97) - (97,97)

--> -34,97

SELECT 34+97

--131 is correct for part 2