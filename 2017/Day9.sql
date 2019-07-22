
use Test_WME

CREATE TABLE #Input (Line NVARCHAR(MAX));

BULK INSERT #Input
FROM 'D:\Wilfred\AdventOfCode\2017\input9.txt'
WITH (ROWTERMINATOR = '0x0A');

CREATE TABLE #Chars (ID INT IDENTITY(1,1), Char CHAR(1), IgnoreThis INT, InTrash INT, Value INT)

;WITH cte_Chars AS (
    SELECT LEFT(Line, 1) AS Char
    ,      SUBSTRING(Line, 2, LEN(Line)) AS Remainder
    ,      CASE WHEN LEFT(Line, 1) = '!' THEN 1 ELSE 0 END IgnoreNext
    ,      0 AS IgnoreThis
    ,      0 AS InTrash
    ,      1 AS Value
    FROM #Input
    UNION ALL
    SELECT LEFT(Remainder, 1)
    ,      SUBSTRING(Remainder, 2, LEN(Remainder))
    ,      CASE WHEN LEFT(Remainder, 1) = '!'  AND IgnoreNext = 0 THEN 1 ELSE 0 END IgnoreNext
    ,      IgnoreNext AS IgnoreThis
    ,      CASE WHEN LEFT(Remainder, 1) = '<' AND IgnoreNext = 0 AND InTrash = 0 THEN 1 
                WHEN LEFT(Remainder, 1) = '>' AND IgnoreNext = 0 AND InTrash = 1 THEN 0
                ELSE InTrash END AS InTrash
    ,      CASE WHEN LEFT(Remainder, 1) = '{' AND IgnoreNext = 0 AND InTrash = 0 THEN Value + 1
                WHEN LEFT(Remainder, 1) = '}' AND IgnoreNext = 0 AND InTrash = 0 THEN Value - 1
                ELSE Value END AS Value
    FROM cte_Chars
    WHERE LEN(Remainder) > 0
)
INSERT #Chars (Char, IgnoreThis, InTrash, Value)
SELECT Char
,      IgnoreThis 
,      InTrash
,      Value
FROM cte_Chars OPTION (MAXRECURSION 30000)

SELECT Sum(Value)
FROM #Chars
WHERE IgnoreThis = 0 AND InTrash = 0 AND Char = '{'
--1861445 Too high

SELECT COUNT(1) 
FROM #Chars 
WHERE InTrash = 1 
  AND IgnoreThis = 0 
  AND Char <> '!'
  AND ID NOT IN (
                SELECT C1.ID 
                FROM #Chars C1
                INNER JOIN #Chars C2 ON C1.ID = C2.ID + 1 
                WHERE C1.Char = '<' AND C1.InTrash = 1 AND C2.InTrash = 0
                )

DROP TABLE #Chars
DROP TABLE #Input