USE Test_WME

SET NOCOUNT ON

CREATE TABLE ##Input (Line NVARCHAR(MAX));

BULK INSERT ##Input
FROM 'C:\Source\AdventOfCode\2017\input19.txt'
WITH (ROWTERMINATOR = '0x0A');


CREATE TABLE ##Grid (ID INT IDENTITY(1,1), X INT, Y INT, Val CHAR)


;WITH cte_grid AS (
    SELECT 1 AS X
    ,      ROW_NUMBER() OVER (ORDER BY (SELECT 0)) AS Y
    ,      LEFT(Line, 1) AS [Char]
    ,      SUBSTRING(Line, 2, LEN(Line)) AS Remainder
    FROM ##Input
    UNION ALL
    SELECT X + 1 AS X
    ,      Y
    ,      LEFT(Remainder, 1) AS [Char]
    ,      SUBSTRING(Remainder, 2, LEN(Remainder)) AS Remainder
    FROM cte_grid
    WHERE LEN(Remainder) > 0
)
INSERT ##Grid(X, Y, Val)
SELECT X, Y, [Char]
FROM cte_grid 
WHERE [Char] NOT IN (' ', CHAR(13))
OPTION (MAXRECURSION 205)

DECLARE @X INT
DECLARE @Y INT = 1
DECLARE @Dir INT = 180
--Starting point
SELECT @X = X FROM ##Grid WHERE Y = @Y

DECLARE @Counter INT = 0
DECLARE @Finished BIT = 0
DECLARE @Solution VARCHAR(50) = ''
DECLARE @CurrentSpace CHAR
DECLARE @TurnDone BIT = 0

WHILE @Finished = 0 AND @Counter < 40000
BEGIN

    SET @CurrentSpace = NULL
    SELECT @CurrentSpace = Val FROM ##Grid WHERE @X = X AND @Y = Y

    IF @CurrentSpace IS NULL SET @Finished = 1
    
    -- Space can be - | + or a letter
    IF @CurrentSpace = '+'
    -- We need to turn
    BEGIN

        -- THEY'RE MAKING A RIGHT TURN! #BubbaJ
        SET @Dir = (@Dir + 90) % 360
    
        -- Check if there is a road ahead
        IF NOT EXISTS (SELECT Val FROM ##Grid WHERE X = CASE WHEN @Dir IN (0, 180) THEN @X
                                                         WHEN @Dir = 90 THEN @X + 1
                                                         WHEN @Dir = 270 THEN @X - 1
                                                    END
                                            AND
                                                Y = CASE WHEN @Dir IN (90, 270) THEN @Y
                                                         WHEN @Dir = 0 THEN @Y - 1
                                                         WHEN @Dir = 180 THEN @Y + 1
                                                    END
                  )
            -- No? Then we need to head in the other direction
            SET @Dir = (@Dir + 180) % 360

    
    END
    ELSE 
    -- Currentspace is a letter, store it
    IF @CurrentSpace NOT IN ('|', '-') SET @Solution = @Solution + @CurrentSpace
    

    --Move a step
    IF @Dir = 0 SET @Y = @Y - 1
    IF @Dir = 180 SET @Y = @Y + 1
    IF @Dir = 90 SET @X = @X + 1
    IF @Dir = 270 SET @X = @X - 1
        
    --IF @Counter % 10 = 0 PRINT CAST(@X AS VARCHAR(4)) + ' , ' + CAST(@Y AS VARCHAR(4)) + ' at ' + CAST(GETDATE() AS VARCHAR(50))

    SET @Counter = @Counter + 1
END

PRINT @Solution + ' in ' + CAST(@Counter-1 AS VARCHAR(6)) + ' steps'


/*

DROP TABLE ##Input
DROP TABLE ##Grid

*/



