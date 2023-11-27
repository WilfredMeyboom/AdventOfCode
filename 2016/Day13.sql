USE Test_WME

    --Find x*x + 3*x + 2*x*y + y + y*y.
    --Add the office designer's favorite number (your puzzle input).
    --Find the binary representation of that sum; count the number of bits that are 1.
    --    If the number of bits that are 1 is even, it's an open space.
    --    If the number of bits that are 1 is odd, it's a wall.

    -- Target 31,39 for part 1

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
SET IsWall = LEN(REPLACE(dbo.Decimal2Binary(X*X + 3*X + 2*X*Y + Y + Y*Y + @Input, 0), '0','')) % 2
FROM ##Grid G

UPDATE ##Grid
SET StepsToReach = 0
WHERE X = 1 AND Y = 1


WHILE (SELECT StepsToReach FROM ##Grid WHERE X = 31 AND Y = 39) IS NULL
BEGIN

    UPDATE G
    SET G.StepsToReach = G2.StepsToReach + 1
    FROM ##Grid G
    INNER JOIN ##Grid G2 ON (G.X = G2.X AND ABS(G.Y - G2.Y) = 1) OR (ABS(G.X - G2.X) = 1 AND G.Y = G2.Y)
    WHERE G.StepsToReach IS NULL AND G.IsWall = 0 AND G2.StepsToReach IS NOT NULL

END

SELECT StepsToReach AS Part1 FROM ##Grid WHERE X = 31 AND Y = 39

SELECT COUNT(1) AS Part2 FROM ##Grid WHERE StepsToReach <= 50


/*

CREATE OR ALTER FUNCTION [dbo].[Decimal2Binary] (@dec AS BIGINT, @returnLength INT = 0) RETURNS VARCHAR(32)
AS
BEGIN

    DECLARE @res VARCHAR(32) = ''
    DECLARE @ind INT = 31

    WHILE @ind >= 0
    BEGIN
        
        IF @dec >= POWER(CAST(2 AS BIGINT),@ind)
        BEGIN
            SET @dec = @dec - POWER(CAST(2 AS BIGINT),@ind)
            SET @res = @res + '1'
        END
        ELSE
        BEGIN
            SET @res = @res + '0'
        END
        
        SET @ind = @ind - 1
    END

    --Resultstring is always 32 bits
    --Returnlength is allowed to reduce the resultstring as long as no significant bits are cut off

    IF 33 - CHARINDEX('1', @res) > @returnLength SET @returnLength = 33 - CHARINDEX('1', @res) 

    --RETURN @Res
    RETURN RIGHT(@res, @returnLength)

END

*/


/*

DROP TABLE ##Grid

*/