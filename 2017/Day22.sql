USE Test_WME

SET NOCOUNT ON

CREATE TABLE ##Input (Line NVARCHAR(MAX));

BULK INSERT ##Input
FROM 'D:\Wilfred\AdventOfCode\2017\input22.txt'
WITH (ROWTERMINATOR = '0x0A');


CREATE TABLE ##Grid (ID INT IDENTITY(1,1), X INT, Y INT, Node CHAR(1))

;WITH cte_Grid AS (
    SELECT -12 AS X
    ,      ROW_NUMBER() OVER (ORDER BY (SELECT 0)) -13 AS Y
    ,      LEFT(Line, 1) AS Node
    ,      SUBSTRING(Line, 2, LEN(Line)) AS Remainder
    FROM ##Input
    UNION ALL
    SELECT X + 1 AS X
    ,      Y
    ,      LEFT(Remainder, 1) AS Node
    ,      SUBSTRING(Remainder, 2, LEN(Remainder)) AS Remainder
    FROM cte_Grid
    WHERE LEN(Remainder) > 0
)
INSERT ##Grid (X, Y, Node)
SELECT X, Y, Node FROM cte_Grid

ALTER TABLE ##Grid ADD CONSTRAINT UQ_XY UNIQUE (X, Y)


DECLARE @PosX INT = 0
DECLARE @PosY INT = 0
DECLARE @Direction INT = 0

DECLARE @Counter INT = 0
DECLARE @CurrentNode CHAR(1) = '.'
DECLARE @Infections INT = 0

WHILE @Counter < 10000000 -- Part 1: 10000
BEGIN

    SELECT @CurrentNode = Node
    FROM ##Grid
    WHERE X = @PosX AND Y = @PosY

/* Part 1
    SET @Direction = (@Direction + CASE WHEN @CurrentNode = '#' THEN 90 ELSE 270 END) % 360
*/

    SET @Direction = (@Direction + CASE WHEN @CurrentNode = '#' THEN 90 
                                        WHEN @CurrentNode = 'F' THEN 180
                                        WHEN @CurrentNode = '.' THEN 270
                                        ELSE 0 END
                     ) % 360

    SET @Infections = @Infections + CASE WHEN @CurrentNode = 'W' THEN 1 ELSE 0 END

    UPDATE G
    -- Part 1: SET Node = CASE WHEN Node = '#' THEN '.' ELSE '#' END
    SET Node = CASE WHEN Node = '.' THEN 'W' 
                    WHEN Node = 'W' THEN '#' 
                    WHEN Node = '#' THEN 'F' 
                    WHEN Node = 'F' THEN '.' 
    END
    FROM ##Grid G
    WHERE X = @PosX AND Y = @PosY

    SET @PosX = @PosX + CASE WHEN @Direction = 90 THEN 1 
                             WHEN @Direction = 270 THEN -1
                             ELSE 0
                             END
                             
    SET @PosY = @PosY + CASE WHEN @Direction = 180 THEN 1 
                             WHEN @Direction = 0 THEN -1
                             ELSE 0
                             END
    
    IF NOT EXISTS(SELECT 1 FROM ##Grid WHERE X = @PosX AND Y = @PosY)
    BEGIN

        IF ((SELECT COUNT(1) FROM ##Grid) % 500 = 0) PRINT 'Round: ' + CAST(@Counter AS NVARCHAR(10)) + ' X, Y: ' + CAST(@PosX AS VARCHAR(5)) + ',' + CAST(@PosY AS VARCHAR(5)) + ' Direction: ' + CAST(@Direction AS VARCHAR(4)) + ' Infections: ' + CAST(@Infections AS VARCHAR(8))

        INSERT ##Grid (X, Y, Node) VALUES (@PosX, @PosY, '.')
    END

    SET @Counter = @Counter + 1
END


SELECT @Infections
SELECT * FROM ##Grid


/*

--4998 too low?
--5460 Correct for Part 1

--2511702

DROP TABLE ##Grid
DROP TABLE ##Input


*/


/*

DECLARE @X INT
DECLARE @Y INT = 1
DECLARE @MaxX INT 
DECLARE @Str VARCHAR(MAX) = ''
SELECT @MaxX = MAX(X) FROM ##Grid
SELECT @Y = MIN(Y) FROM ##Grid

WHILE @Y < (SELECT MAX(Y) FROM ##Grid)
BEGIN

    SELECT @X = MIN(X) FROM ##Grid
    SELECT @MaxX = MAX(X) FROM ##Grid
    SET @Str = ''

    WHILE @X < @MaxX
    BEGIN
        
        SELECT @Str = @Str + Node FROM ##Grid WHERE X = @X AND Y = @Y

        SET @X = @X + 1

    END

    PRINT @Str

    SET @Y = @Y + 1

END 


*/
