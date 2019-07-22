use Test_WME

SET NOCOUNT ON

CREATE TABLE ##Input (Line NVARCHAR(MAX));

BULK INSERT ##Input
FROM 'D:\Wilfred\AdventOfCode\2016\input03.txt'
WITH (ROWTERMINATOR = '0x0A');

CREATE TABLE ##Triangles (ID INT IDENTITY(1,1), Side1 INT, Side2 INT, Side3 INT)

;WITH cte_Trimmed AS (
    SELECT LTRIM(RTRIM(Line)) AS Line
    FROM ##Input
), cte_FirstSplit AS (
    SELECT LEFT(Line, CHARINDEX(' ', Line) -1 ) AS FirstNr
    ,      LTRIM(SUBSTRING(Line, CHARINDEX(' ', Line) + 1, LEN(Line))) AS Remainder
    , Line
    FROM cte_Trimmed
)
INSERT ##Triangles (Side1, Side2, Side3)
SELECT FirstNr
,      LEFT(Remainder, CHARINDEX(' ', Remainder) -1 ) AS SecondNr
,      SUBSTRING(Remainder, CHARINDEX(' ', Remainder) + 1, LEN(Line)) AS ThirdNr
FROM cte_FirstSplit



SELECT COUNT(1) FROM ##Triangles WHERE Side1 + Side2 > Side3 AND Side1 + Side3 > Side2 AND Side2 + Side3 > Side1
--253 is wrong
--770 is too low
--862 Correct for part 1

;WITH cte_Sides AS (
    SELECT Side1 AS Side FROM ##Triangles 
    UNION ALL
    SELECT Side2 FROM ##Triangles 
    UNION ALL
    SELECT Side3 FROM ##Triangles 
), cte_TriangleSides AS (
    SELECT (ROW_NUMBER() OVER (ORDER BY (SELECT 0)) - 1) / 3 AS TriangleNr
    ,      (ROW_NUMBER() OVER (ORDER BY (SELECT 0)) - 1) % 3 AS SideNr
    ,      Side
    FROM cte_Sides
), cte_Triangles AS (
    SELECT S1.TriangleNr, S1.Side AS Side1, S2.Side AS Side2, S3.Side AS Side3
    FROM cte_TriangleSides S1
    INNER JOIN cte_TriangleSides S2 ON S1.TriangleNr = S2.TriangleNr
    INNER JOIN cte_TriangleSides S3 ON S2.TriangleNr = S3.TriangleNr
    WHERE S1.SideNr = 0
      AND S2.SideNr = 1
      AND S3.SideNr = 2
)
SELECT COUNT(1) FROM cte_Triangles WHERE Side1 + Side2 > Side3 AND Side1 + Side3 > Side2 AND Side2 + Side3 > Side1

--1577 is correct for part 2

/*

DROP TABLE ##Triangles
DROP TABLE ##Input

*/

