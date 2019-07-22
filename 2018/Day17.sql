use Test_WME

SET NOCOUNT ON

CREATE TABLE ##Input (Name NVARCHAR(MAX));

BULK INSERT ##Input
FROM 'D:\Wilfred\AdventOfCode\input17.txt'
WITH (ROWTERMINATOR = '0x0A');

CREATE TABLE ##Clay (ID INT IDENTITY(1,1), X1 INT, X2 INT, Y1 INT, Y2 INT)


;WITH cte_Scrubbed AS (
    SELECT LEFT(Name, 1) AS FirstChar
    ,      SUBSTRING(Name, 3, CHARINDEX(',', Name) -3) AS FirstValue
    ,      SUBSTRING(Name, CHARINDEX(',', Name) + 4, CHARINDEX('.', Name) - CHARINDEX(',', Name) - 4) AS SecondValue
    ,      RIGHT(Name, LEN(Name) - CHARINDEX('.', Name) - 1) AS ThirdValue
    , Name
    FROM ##Input 
)
INSERT ##Clay
SELECT CASE WHEN FirstChar = 'x' THEN FirstValue  ELSE SecondValue END AS X1
,      CASE WHEN FirstChar = 'x' THEN FirstValue  ELSE ThirdValue  END AS X2
,      CASE WHEN FirstChar = 'x' THEN SecondValue ELSE FirstValue  END AS Y1
,      CASE WHEN FirstChar = 'x' THEN ThirdValue  ELSE FirstValue  END AS Y2
FROM cte_Scrubbed


--SELECT * FROM ##Clay WHERE Y1 > Y2 OR X1 > X2

CREATE TABLE ##Grid (ID INT IDENTITY(1,1), X INT, Y INT, Status CHAR)

;WITH cte_Nrs AS (
    SELECT TOP 2000 ROW_NUMBER() OVER (ORDER BY (SELECT 0)) AS Nr FROM sys.messages
)
INSERT ##Grid (X, Y, Status)
SELECT X.Nr, Y.Nr, 'S'
FROM cte_Nrs X
CROSS APPLY cte_Nrs Y
CROSS APPLY (SELECT MIN(X1)-1 MinX, MAX(X2)+1 MaxX, 0 MinY, MAX(Y2)+1 MaxY FROM ##Clay) Lim
WHERE X.Nr BETWEEN MinX AND MaxX AND Y.Nr BETWEEN MinY AND MaxY

--553200

-- S = Empty / Sand
-- x = Source
-- C = Clay
-- P = Space water passed through
-- W = Water

UPDATE G
SET Status = 'C'
FROM ##Grid G
INNER JOIN ##Clay C ON G.X BETWEEN C.X1 AND C.X2 AND G.Y BETWEEN C.Y1 AND C.Y2

UPDATE ##Grid 
SET Status = 'P'
WHERE X = 500 AND Y = 0

DECLARE @RowsUpdated INT = 0 

WHILE (@RowsUpdated > 0)
BEGIN
    
    SET @RowsUpdated = 0

    UPDATE G
    SET Status = 'P'
    FROM ##Grid G
    INNER JOIN ##Grid G2 ON G.X = G2.X AND G.Y = G2.Y - 1
    WHERE G2.Status = 'P' AND G.Status = 'S'

    SET @RowsUpdated = @RowsUpdated + @@ROWCOUNT

    UPDATE G
    SET Status = 'W'
    FROM ##Grid G
    INNER JOIN ##Grid G2 ON G.X = G2.X AND G.Y = G2.Y - 1
    WHERE G2.Status = 'C' AND G.Status = 'P'

    SET @RowsUpdated = @RowsUpdated + @@ROWCOUNT


END



/*

DROP TABLE ##Grid
DROP TABLE ##Clay
DROP TABLE ##Input




*/


/*


--SELECT 500-MIN(X) FROM ##Grid

DECLARE @X INT
DECLARE @Y INT = 1
DECLARE @MaxX INT 
DECLARE @Str VARCHAR(MAX) = ''
SELECT @MaxX = MAX(X) FROM ##Grid

WHILE @Y < (SELECT MAX(Y) FROM ##Grid)
BEGIN

    SELECT @X = MIN(X) FROM ##Grid
    SET @Str = ''

    WHILE @X < @MaxX
    BEGIN
        
        SELECT @Str = @Str + ISNULL(Status,' ') FROM ##Grid WHERE X = @X AND Y = @Y

        SET @X = @X + 1

    END

    PRINT @Str

    SET @Y = @Y + 1

END 


*/