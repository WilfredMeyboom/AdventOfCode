use Test_WME

SET NOCOUNT ON

CREATE TABLE ##Input (Name NVARCHAR(MAX));

BULK INSERT ##Input
FROM 'D:\Wilfred\AdventOfCode\input25.txt'
WITH (ROWTERMINATOR = '0x0A');


--SELECT * FROM ##Input


CREATE TABLE ##Points (ID INT IDENTITY(1,1), X INT, Y INT, Z INT, T INT, ConstellationNr INT)

INSERT ##Points (ConstellationNr, X, Y, Z, T)
SELECT ROW_NUMBER() OVER (ORDER BY (SELECT 0))
,      LEFT(Name, CHARINDEX(',', Name) - 1)
,      LEFT(SUBSTRING(Name, CHARINDEX(',', Name) + 1, LEN(Name)), CHARINDEX(',', SUBSTRING(Name, CHARINDEX(',', Name) + 1, LEN(Name))) - 1)
,      LEFT(SUBSTRING(SUBSTRING(Name, CHARINDEX(',', Name) + 1, LEN(Name)), CHARINDEX(',', SUBSTRING(Name, CHARINDEX(',', Name) + 1, LEN(Name))) + 1, LEN(Name)), CHARINDEX(',',SUBSTRING(SUBSTRING(Name, CHARINDEX(',', Name) + 1, LEN(Name)), CHARINDEX(',', SUBSTRING(Name, CHARINDEX(',', Name) + 1, LEN(Name))) + 1, LEN(Name))) - 1)
,      SUBSTRING(SUBSTRING(SUBSTRING(Name, CHARINDEX(',', Name) + 1, LEN(Name)), CHARINDEX(',', SUBSTRING(Name, CHARINDEX(',', Name) + 1, LEN(Name))) + 1, LEN(Name)), CHARINDEX(',',SUBSTRING(SUBSTRING(Name, CHARINDEX(',', Name) + 1, LEN(Name)), CHARINDEX(',', SUBSTRING(Name, CHARINDEX(',', Name) + 1, LEN(Name))) + 1, LEN(Name))) + 1, LEN(Name))
FROM ##Input


SELECT * FROM ##Points

DECLARE @PointsMovedToConst INT = 1

WHILE @PointsMovedToConst > 0
BEGIN

    UPDATE P
    SET ConstellationNr = P2.ConstellationNr
    FROM ##Points P
    INNER JOIN ##Points P2 ON ABS(P.X - P2.X) + ABS(P.Y - P2.Y) + ABS(P.Z - P2.Z) + ABS(P.T - P2.T) <= 3
                          AND P.ID <> P2.ID
                          AND P.ConstellationNr > P2.ConstellationNr

    SET @PointsMovedToConst = @@ROWCOUNT

END

SELECT ConstellationNr, COUNT(1) FROM ##Points GROUP BY ConstellationNr


SELECT * FROM ##Points WHERE ConstellationNr = 317
SELECT * FROM ##Points WHERE X BETWEEN -11 AND -5
                         AND Y BETWEEN -10 AND -4
                         AND Z BETWEEN -9 AND -3
                         AND T BETWEEN -8 AND -5

/*

DROP TABLE ##Points

DROP TABLE ##Input


*/



