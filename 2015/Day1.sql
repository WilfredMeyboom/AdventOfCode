use Test_WME

SET NOCOUNT ON

CREATE TABLE ##Input (Line NVARCHAR(MAX));

BULK INSERT ##Input
FROM 'D:\Wilfred\AdventOfCode\2015\input1.txt'
WITH (ROWTERMINATOR = '0x0A');

SELECT *, LEN(Line), LEN(REPLACE(Line, '(', '')) FROM ##Input

SELECT 7000 - (3384*2)

-- 232 is correct for part 1


;WITH cte_Floors AS (
    SELECT 0 AS PreviousFloor
    ,      CASE WHEN LEFT(Line, 1) = '(' THEN 1 ELSE -1 END AS CurrentFloor
    ,      SUBSTRING(Line, 2, LEN(Line)) AS Remainder
    FROM ##Input
    UNION ALL
    SELECT CurrentFloor AS PreviousFloor
    ,      CurrentFloor + CASE WHEN LEFT(Remainder, 1) = '(' THEN 1 ELSE -1 END AS CurrentFloor
    ,      SUBSTRING(Remainder, 2, LEN(Remainder)) AS Remainder
    FROM cte_Floors
    WHERE LEN(Remainder) > 0

)
SELECT ROW_NUMBER() OVER (ORDER BY (SELECT 0)), *, LEN(Remainder)
FROM cte_Floors
--WHERE CurrentFloor = -1
OPTION (MAXRECURSION 8000)


--1783 is correct for part 2

/*

DROP TABLE ##Input

*/


