use Test_WME

CREATE TABLE #Input (Name NVARCHAR(MAX));

BULK INSERT #Input
FROM 'D:\Wilfred\AdventOfCode\input10.txt'
WITH (ROWTERMINATOR = '0x0A');

CREATE TABLE #Stars (ID INT IDENTITY(1,1), TimeStep BIGINT, X BIGINT, Y BIGINT, VX BIGINT, VY BIGINT)

;WITH cte_Scrubbed AS (
    SELECT REPLACE(REPLACE(REPLACE(Name, 'Position=<',''), '> velocity=<', '|'), '>','') AS X_V
    ,      LEFT(REPLACE(REPLACE(REPLACE(Name, 'Position=<',''), '> velocity=<', '|'), '>',''), CHARINDEX('|', REPLACE(REPLACE(REPLACE(Name, 'Position=<',''), '> velocity=<', '|'), '>','')) -1) AS XY
    ,      SUBSTRING(REPLACE(REPLACE(REPLACE(Name, 'Position=<',''), '> velocity=<', '|'), '>',''), CHARINDEX('|', REPLACE(REPLACE(REPLACE(Name, 'Position=<',''), '> velocity=<', '|'), '>','')) + 1, LEN(Name)) AS V
    FROM #Input
)
INSERT #Stars (TimeStep, X, Y, VX, VY)
SELECT 0
,   CAST(LEFT(XY, CHARINDEX(',', XY) - 1) AS BIGINT) AS X
,   CAST(SUBSTRING(XY, CHARINDEX(',', XY) + 1, LEN(XY)) AS BIGINT) AS Y
,   CAST(LEFT(V, CHARINDEX(',', V) -1) AS BIGINT) AS VX
,   CAST(SUBSTRING(V, CHARINDEX(',', V) + 1, LEN(V)) AS BIGINT) AS VY
FROM cte_Scrubbed

DECLARE @PrevArea BIGINT = 0
DECLARE @Area BIGINT = 1


SELECT @Area = ABS(MAX(X) - MIN(X)) * ABS(MAX(Y) - MIN(Y))
FROM #Stars
SET @PrevArea = @Area

WHILE (@PrevArea >= @Area)
BEGIN
    
    SET @PrevArea = @Area
    
    UPDATE #Stars
    SET TimeStep = TimeStep + 1
    ,   X = X + VX
    ,   Y = Y + VY

    SELECT @Area = ABS(MAX(X) - MIN(X)) * ABS(MAX(Y) - MIN(Y))
    FROM #Stars
    

END

/*

DROP TABLE #Stars
DROP TABLE #Input

*/


-- Turn back time
    UPDATE #Stars
    SET TimeStep = TimeStep - 1
    ,   X = X - VX
    ,   Y = Y - VY


-- LRGPBHEZ

SELECT MAX(X) - MIN(X), MAX(Y) - MIN(Y) FROM #Stars

CREATE TABLE #Nrs (Nr INT)

INSERT #Nrs
SELECT TOP (1000) ROW_NUMBER() OVER (ORDER BY (SELECT 0)) FROM sys.messages 

CREATE TABLE #Grid (X INT, Y INT)

INSERT #Grid
SELECT NX.Nr, NY.Nr
FROM #Nrs NX
CROSS APPLY #Nrs NY
WHERE NX.Nr BETWEEN (SELECT MIN(X) FROM #Stars) AND (SELECT MAX(X) FROM #Stars) 
  AND NY.Nr BETWEEN (SELECT MIN(Y) FROM #Stars) AND (SELECT MAX(Y) FROM #Stars) 


--DROP TABLE #Nrs


DECLARE @X INT
DECLARE @Y INT
DECLARE @MinX INT
DECLARE @MaxX INT
DECLARE @MaxY INT
DECLARE @Str NVARCHAR(MAX) = ''

SELECT @X = MIN(X), @Y = MIN(Y), @MaxX = MAX(X), @MaxY = MAX(Y) FROM #Grid
SET @MinX = @X

WHILE (@Y <= @MaxY)
BEGIN

    SET @Str = ''

    WHILE (@X <= @MaxX)
    BEGIN
    
        SELECT @Str = @Str + (CASE WHEN S.ID IS NOT NULL THEN '*' ELSE ' ' END)
        FROM #Grid G
        LEFT JOIN #Stars S ON G.X = S.X AND G.Y = S.Y
        WHERE G.X = @X AND G.Y = @Y
        GROUP BY CASE WHEN S.ID IS NOT NULL THEN '*' ELSE ' ' END

        SET @X = @X + 1

    END

    PRINT @Str

    SET @Y = @Y + 1
    SET @X = @MinX
END


