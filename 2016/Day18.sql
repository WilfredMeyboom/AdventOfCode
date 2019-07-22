USE Test_WME

SET NOCOUNT ON

DECLARE @Input VARCHAR(200) = '......^.^^.....^^^^^^^^^...^.^..^^.^^^..^.^..^.^^^.^^^^..^^.^.^.....^^^^^..^..^^^..^^.^.^..^^..^^^..'

CREATE TABLE Grid (ID BIGINT IDENTITY(1,1), X INT, Y BIGINT, Spot CHAR)

CREATE INDEX UQ_Grid ON Grid (X,Y)

CREATE TABLE Tiles (ID INT IDENTITY(1,1), SafeTiles INT)

;WITH cte_Spots AS (
    SELECT LEFT(@Input, 1) AS Spot
    ,      1 AS X
    ,      1 AS Y
    ,      SUBSTRING(@Input, 2, LEN(@Input)) AS Remainder
    UNION ALL
    SELECT LEFT(Remainder, 1) AS Spot
    ,      X + 1 AS X
    ,      1 AS Y
    ,      SUBSTRING(Remainder, 2, LEN(Remainder)) AS Remainder
    FROM cte_Spots
    WHERE LEN(Remainder) > 0
)
INSERT Grid (X, Y, Spot)
SELECT X, Y, Spot
FROM cte_Spots

DECLARE @Y BIGINT = 1
DECLARE @MaxX INT
SELECT @MaxX = MAX(X) FROM Grid

INSERT Tiles (SafeTiles) SELECT COUNT(1) FROM Grid WHERE Spot = '.'

WHILE (SELECT MAX(Y) FROM Grid) < 400000
BEGIN

    --Add walls
    INSERT Grid (X, Y, Spot) VALUES (0, @Y, '.')
    INSERT Grid (X, Y, Spot) VALUES (@MaxX + 1, @Y, '.')

    SET @Y = @Y + 1

    INSERT Grid (X, Y, Spot)
    SELECT GMid.X
    ,      @Y
    ,      CASE WHEN GMid.Spot = GLeft.Spot AND GMid.Spot = GRight.Spot THEN '.'
                WHEN GMid.Spot <> GLeft.Spot AND GLeft.Spot = GRight.Spot THEN '.'
                ELSE '^'
           END
    FROM Grid GMid
    INNER JOIN Grid GLeft ON GMid.Y = GLeft.Y AND GMid.X = GLeft.X + 1
    INNER JOIN Grid GRight ON GMid.Y = GRight.Y AND GMid.X = GRight.X - 1
    WHERE GMid.Y = @Y - 1

    DELETE FROM Grid WHERE Y = @Y - 1

    INSERT Tiles (SafeTiles) SELECT COUNT(1) FROM Grid WHERE Spot = '.'

END


--SELECT COUNT(1) FROM Grid WHERE X BETWEEN 1 AND 100 AND Spot = '.'

-- 1963 is correct for part 1

--SELECT Y, COUNT(1) FROM Grid WHERE X BETWEEN 1 AND 100 AND Spot = '.' GROUP BY Y ORDER BY Y

SELECT SUM(SafeTiles) FROM Tiles
--SELECT * FROM Tiles

--199101


--20009568 Is correct for part 2

/*

DROP TABLE Grid
DROP TABLE Tiles

    
*/