use Test_WME

SET NOCOUNT ON

CREATE TABLE ##Input (Line NVARCHAR(MAX));

BULK INSERT ##Input
FROM 'D:\Wilfred\AdventOfCode\2015\input18.txt'
WITH (ROWTERMINATOR = '0x0A');

CREATE TABLE ##Lights (ID INT IDENTITY(1,1), X INT, Y INT, IsOn INT)

;WITH cte_Lights AS (
    SELECT 1 AS X
    ,      ROW_NUMBER() OVER (ORDER BY (SELECT 0)) AS Y
    ,      LEFT(Line, 1) AS Light
    ,      SUBSTRING(Line, 2, LEN(Line)) AS Remainder
    FROM ##Input
    UNION ALL
    SELECT X + 1
    ,      Y
    ,      LEFT(Remainder, 1)
    ,      SUBSTRING(Remainder, 2, LEN(Remainder))
    FROM cte_Lights
    WHERE LEN(Remainder) > 0
)
INSERT ##Lights (X, Y, IsOn)
SELECT X, Y, CASE WHEN Light = '#' THEN 1 ELSE 0 END
FROM cte_Lights

CREATE UNIQUE INDEX UQ_Lights ON ##Lights (X,Y)

--SELECT * FROM ##Lights ORDER BY X, Y

UPDATE L
SET L.IsOn = 1
FROM ##Lights L
WHERE (L.X = 1 AND L.Y = 1)
    OR (L.X = 1 AND L.Y = 100)
    OR (L.X = 100 AND L.Y = 1)
    OR (L.X = 100 AND L.Y = 100)

DECLARE @Counter INT = 0

WHILE @Counter < 100
BEGIN

    ;WITH cte_Neigbours AS (
        SELECT L1.ID, SUM(L2.IsOn) AS AreOn
        FROM ##Lights L1
        INNER JOIN ##Lights L2 ON (ABS(L1.X - L2.X) <= 1 AND ABS(L1.Y - L2.Y) <= 1) AND L1.ID <> L2.ID
        GROUP BY L1.ID
    )
    UPDATE L
    SET L.IsOn = CASE WHEN L.IsOn = 1 AND N.AreOn IN (2,3) THEN 1
                      WHEN L.IsOn = 0 AND N.AreOn = 3      THEN 1
                      ELSE 0 END
    FROM ##Lights L
    INNER JOIN cte_Neigbours N ON L.ID = N.ID

    UPDATE L
    SET L.IsOn = 1
    FROM ##Lights L
    WHERE (L.X = 1 AND L.Y = 1)
       OR (L.X = 1 AND L.Y = 100)
       OR (L.X = 100 AND L.Y = 1)
       OR (L.X = 100 AND L.Y = 100)

    SET @Counter = @Counter + 1

    PRINT @Counter

END


--SELECT * FROM ##Lights ORDER BY Y, X
SELECT SUM(IsOn) FROM ##Lights

-- 821 is correct for part 1
-- 865 is too low for part 2
-- 886 is correct for part 2



/* 


    A light which is on stays on when 2 or 3 neighbors are on, and turns off otherwise.
    A light which is off turns on if exactly 3 neighbors are on, and stays off otherwise.

DROP TABLE ##Lights

DROP TABLE ##Input

*/
