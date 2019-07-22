USE Test_WME

/*
DECLARE @Target INT = 325489


--DECLARE @Target INT = 6

DECLARE @MaxSide INT
DECLARE @Area INT

;WITH cte_SquareSize AS (
    SELECT 1 AS Side
    ,      1 AS Area
    UNION ALL
    SELECT Side + 1
    ,      (Side + 1) * (Side + 1)
    FROM cte_SquareSize
    WHERE Area < @Target
)
SELECT @MaxSide = MAX(Side), @Area = MAX(Area) FROM cte_SquareSize OPTION (MAXRECURSION 10000)

SELECT @MaxSide
     , @Area
     , @MaxSide / 2
     , CASE WHEN (@Area - @Target) % @MaxSide - (@MaxSide / 2) > 0 THEN (@Area - @Target) % @MaxSide - (@MaxSide / 2) 
                                                                   ELSE (@Area - @Target) % @MaxSide 
            END
     , (@MaxSide / 2) + CASE WHEN (@Area - @Target) % @MaxSide - (@MaxSide / 2) > 0 THEN (@Area - @Target) % @MaxSide - (@MaxSide / 2) 
                                                                   ELSE (@Area - @Target) % @MaxSide 
            END

*/
/*
  -> X
|
V Y

17 16 15 14 13
18 05 04 03 12
19 06 01 02 11
20 07 08 09 10
21 22 23 24 25
*/



CREATE TABLE #Grid (Id INT IDENTITY(1,1), x INT, y INt, SumValue INT)

INSERT #Grid (x, y, SumValue) VALUES (0,0,1)

DECLARE @Target INT = 325489

DECLARE @xPos INT = 0
DECLARE @yPos INT = 0

DECLARE @direction CHAR = 'S'
DECLARE @turn BIT

WHILE ((SELECT MAX(SumValue) FROM #Grid) < @Target)
BEGIN


    SET @turn = 1

    --Turn 90°?
    SELECT @turn = 0
    FROM #Grid
    WHERE x = @xPos + CASE WHEN @direction = 'N' THEN -1 
                           WHEN @direction = 'W' THEN 0  
                           WHEN @direction = 'S' THEN 1 
                           WHEN @direction = 'E' THEN 0 END
      AND y = @yPos + CASE WHEN @direction = 'N' THEN 0 
                           WHEN @direction = 'W' THEN 1 
                           WHEN @direction = 'S' THEN 0 
                           WHEN @direction = 'E' THEN -1 END
    
    SELECT @direction = CASE WHEN @direction = 'N' THEN 'W'
                             WHEN @direction = 'W' THEN 'S'
                             WHEN @direction = 'S' THEN 'E'
                             WHEN @direction = 'E' THEN 'N' END
    WHERE @turn = 1

    SELECT @xPos = @xPos + CASE WHEN @direction = 'N' THEN 0
                                WHEN @direction = 'W' THEN -1  
                                WHEN @direction = 'S' THEN 0 
                                WHEN @direction = 'E' THEN 1 END,
           @yPos = @yPos + CASE WHEN @direction = 'N' THEN -1 
                                WHEN @direction = 'W' THEN 0 
                                WHEN @direction = 'S' THEN 1 
                                WHEN @direction = 'E' THEN 0 END
    
    INSERT #Grid (x, y, SumValue)
    SELECT @xPos, @yPos, SUM(SumValue)
    FROM #Grid
    WHERE x IN (@xPos -1, @xPos, @xPos + 1)
      AND y IN (@yPos -1, @yPos, @yPos + 1)

END


SELECT * FROM #Grid