USE Test_WME

--DECLARE @Input INT = 1362

    --Find x*x + 3*x + 2*x*y + y + y*y.
    --Add the office designer's favorite number (your puzzle input).
    --Find the binary representation of that sum; count the number of bits that are 1.
    --    If the number of bits that are 1 is even, it's an open space.
    --    If the number of bits that are 1 is odd, it's a wall.

    --Target 31,39
CREATE TABLE ##Grid (ID INT IDENTITY(1,1), X INT, Y INT, IsWall BIT, StepsToReach INT)

CREATE UNIQUE INDEX Ind_Grid ON ##Grid(X, Y)

;WITH cte_Nr AS (
    SELECT TOP 51 ROW_NUMBER() OVER (ORDER BY (SELECT 0)) - 1 AS Nr FROM sys.messages
)
INSERT ##Grid (X, Y)
SELECT X.Nr, Y.Nr 
FROM cte_Nr X
CROSS APPLY cte_Nr Y


DECLARE @Input INT = 1362

UPDATE G
SET IsWall = LEN(REPLACE(dbo.udf_int2bin(X*X + 3*X + 2*X*Y + Y + Y*Y + @Input), '0','')) % 2
FROM ##Grid G

UPDATE ##Grid
SET StepsToReach = 0
WHERE X = 1 AND Y = 1



WHILE (SELECT StepsToReach FROM ##Grid WHERE X = 31 AND Y = 39) IS NULL
BEGIN

    UPDATE G
    SET G.StepsToReach = G2.StepsToReach + 1
    --SELECT * 
    FROM ##Grid G
    INNER JOIN ##Grid G2 ON (G.X = G2.X AND ABS(G.Y - G2.Y) = 1) OR (ABS(G.X - G2.X) = 1 AND G.Y = G2.Y)
    WHERE G.StepsToReach IS NULL AND G.IsWall = 0 AND G2.StepsToReach IS NOT NULL

END

SELECT * FROM ##Grid WHERE StepsToReach IS NOT NULL


-- 82 is goed voor part 1

SELECT * FROM ##Grid WHERE StepsToReach <= 50

--138 for part 2 is goed


/*

CREATE FUNCTION udf_int2bin (@IncomingNumber int)

RETURNS varchar(200)

as

BEGIN

DECLARE @BinNumber VARCHAR(200)

SET @BinNumber =''

WHILE @IncomingNumber <> 0

BEGIN

SET @BinNumber = SUBSTRING('0123456789', (@IncomingNumber % 2) + 1, 1) + @BinNumber

SET @IncomingNumber = @IncomingNumber / 2

END

RETURN @BinNumber

END 

*/



DECLARE @X INT
DECLARE @Y INT
DECLARE @MinX INT
DECLARE @MaxX INT
DECLARE @MaxY INT
DECLARE @Str NVARCHAR(MAX) = ''

SELECT @X = MIN(X), @Y = MIN(Y), @MaxX = MAX(X), @MaxY = MAX(Y) FROM ##Grid
SET @MinX = @X

WHILE (@Y <= @MaxY)
BEGIN

    SET @Str = ''

    WHILE (@X <= @MaxX)
    BEGIN
    
        SELECT @Str = @Str + (CASE WHEN G.IsWall = 1 THEN '*' ELSE ' ' END)
        FROM ##Grid G
        WHERE G.X = @X AND G.Y = @Y

        SET @X = @X + 1

    END

    PRINT @Str

    SET @Y = @Y + 1
    SET @X = @MinX
END



