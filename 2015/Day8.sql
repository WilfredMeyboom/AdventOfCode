use Test_WME

SET NOCOUNT ON

CREATE TABLE ##Input (Line NVARCHAR(MAX));

BULK INSERT ##Input
FROM 'D:\Wilfred\AdventOfCode\2015\input8.txt'
WITH (ROWTERMINATOR = '0x0A');

--SELECT * FROM ##Input
--SELECT SUM(LEN(Line)) FROM ##Input

;WITH cte_RemoveQuotes AS (
    SELECT ROW_NUMBER() OVER (ORDER BY (SELECT 0)) AS RowNr
    , SUBSTRING(Line, 2, LEN(Line) - 2) AS Line
    , LEN(Line) AS OriginalLength
    , Line AS OriginalLine
    FROM ##Input
), cte_Escaped AS (
    SELECT RowNr
    , REPLACE(REPLACE(REPLACE(Line, '\\x', '\\*'), '\"', '"'), '\\', '\') AS Line
    , OriginalLength
    , OriginalLine
    FROM cte_RemoveQuotes
), cte_Hex AS (
    SELECT RowNr
    ,   1 AS Iteration
    ,   CASE WHEN CHARINDEX('\x', Line) > 0 THEN 
            REPLACE(Line, SUBSTRING(Line, CHARINDEX('\x', Line), 4), CHAR(CONVERT(INT, CONVERT(VARBINARY, SUBSTRING(Line, CHARINDEX('\x', Line) + 2, 2), 2)))) ELSE Line END AS Line
    ,       OriginalLength
    ,   OriginalLine
    FROM cte_Escaped
    UNION ALL
    SELECT RowNr
    ,   Iteration + 1
    ,   CASE WHEN CHARINDEX('\x', Line) > 0 THEN 
            REPLACE(Line, SUBSTRING(Line, CHARINDEX('\x', Line), 4), CHAR(CONVERT(INT, CONVERT(VARBINARY, SUBSTRING(Line, CHARINDEX('\x', Line) + 2, 2), 2)))) ELSE Line END AS Line
    ,       OriginalLength
    ,   OriginalLine
    FROM cte_Hex
    WHERE CHARINDEX('\x', Line) > 0 
)
SELECT *, LEN(REPLACE(REPLACE(REPLACE(Line, '\\x', '\\*'), '\"', '"'), '\\', '\')), REPLACE(REPLACE(REPLACE(Line, '\\x', '\\*'), '\"', '"'), '\\', '\')
--SUM(OriginalLength), SUM(LEN(Line))
FROM cte_Hex cH
INNER JOIN (SELECT RowNr, MAX(Iteration) AS MaxIter FROM cte_Hex GROUP BY RowNr) Sub ON cH.RowNr = Sub.RowNr AND cH.Iteration = Sub.MaxIter
--ORDER BY cH.RowNr, cH.Iteration
WHERE Line LIKE N'%*%'

SELECT 6489 - (5127 - 9) --Correctie voor \\*, maar geen iteraties daarna
SELECT 6489 - 5114 

-- 1362 is too low for Part 1
-- 1375 is too high for Part 1
-- 1384 is too high for Part 1

-- 1371 is correct for Part 1


SELECT SUM(LEN('"' + REPLACE(REPLACE(Line, '\', '\\'), '"', '\"') + '"'))
FROM ##Input

SELECT 8606 - 6489

--2117 is correct for part 2

/*

DROP TABLE ##Input


*/


