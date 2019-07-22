USE Test_WME

CREATE TABLE ##Input (Line NVARCHAR(MAX));

BULK INSERT ##Input
FROM 'D:\Wilfred\AdventOfCode\2017\input11.txt'
WITH (ROWTERMINATOR = '0x0A');


SELECT * FROM ##Input

CREATE TABLE ##Directions (ID INT IDENTITY(1,1), Direction CHAR(2))

;WITH cte_Direction AS (
    SELECT LEFT(Line, CHARINDEX(',', Line) - 1) AS Direction
    ,      SUBSTRING(Line, CHARINDEX(',', Line) + 1, LEN(Line)) + ',' AS Remainder
    FROM ##Input
    UNION ALL
    SELECT LEFT(Remainder, CHARINDEX(',', Remainder) - 1)
    ,      SUBSTRING(Remainder, CHARINDEX(',', Remainder) + 1, LEN(Remainder))
    FROM cte_Direction
    WHERE LEN(Remainder) > 0
)
INSERT ##Directions (Direction)
SELECT Direction
FROM cte_Direction OPTION (MAXRECURSION 8300)

/*
   Y   X    Z
       N
   NW     NE
       %  
   SW     SE
       S

    Dus als % = (0,0,0) 

    Naar N = (X+0, Y-1, Z+1)
    Naar S = (X+0, Y+1, Z-1)
    Naar NW = (X-1, Y+0, Z+1)
    Naar NE = (X+1, Y-1, Z+0)
    Naar SW = (X-1, Y+1, Z+0)
    Naar SE = (X+1, Y+0, Z-1)

*/


DECLARE @Direction VARCHAR(2) = ''
DECLARE @CurrentX INT = 0
DECLARE @CurrentY INT = 0
DECLARE @CurrentZ INT = 0
DECLARE @CurrentDist INT = 0
DECLARE @MaxDist INT = 0


DECLARE DirectionCursor CURSOR FOR
SELECT Direction FROM ##Directions ORDER BY ID

OPEN DirectionCursor

FETCH NEXT FROM DirectionCursor INTO @Direction
  

WHILE @@FETCH_STATUS = 0
BEGIN

    SELECT @CurrentX = @CurrentX + CASE WHEN @Direction IN ('N','S') THEN 0
                                        WHEN @Direction IN ('NW','SW') THEN -1
                                        WHEN @Direction IN ('NE','SE') THEN 1
                                   END
    ,      @CurrentY = @CurrentY + CASE WHEN @Direction IN ('NW','SE') THEN 0
                                        WHEN @Direction IN ('N','NE') THEN -1
                                        WHEN @Direction IN ('S','SW') THEN 1
                                   END
    ,      @CurrentZ = @CurrentZ + CASE WHEN @Direction IN ('NE','SW') THEN 0
                                        WHEN @Direction IN ('S','SE') THEN -1
                                        WHEN @Direction IN ('N','NW') THEN  1
                                   END

/*
   Naar N = (X+0, Y-1, Z+1)
    Naar S = (X+0, Y+1, Z-1)
    Naar NW = (X-1, Y+0, Z+1)
    Naar NE = (X+1, Y-1, Z+0)
    Naar SW = (X-1, Y+1, Z+0)
    Naar SE = (X+1, Y+0, Z-1)
*/
    SELECT @CurrentDist = (ABS(@CurrentX) + ABS(@CurrentY) + ABS(@CurrentZ)) / 2
    IF @CurrentDist > @MaxDist SET @MaxDist = @CurrentDist

    FETCH NEXT FROM DirectionCursor INTO @Direction

END

SELECT @CurrentX, @CurrentY, @CurrentZ, (ABS(@CurrentX) + ABS(@CurrentY) + ABS(@CurrentZ)) / 2, @MaxDist

CLOSE DirectionCursor
DEALLOCATE DirectionCursor



DROP TABLE ##Directions
DROP TABLE ##Input