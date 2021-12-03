USE Test_WME


IF EXISTS (SELECT * FROM tempdb.sys.tables WHERE name LIKE '%Input%') DROP TABLE ##Input
CREATE TABLE ##Input (Line NVARCHAR(MAX));

BULK INSERT ##Input
FROM 'C:\Source\AdventOfCode\2021\Input1.txt'
WITH (ROWTERMINATOR = '0x0A');

--SELECT ROW_NUMBER() OVER (ORDER BY(SELECT 0)) AS RN, Line FROM ##Input



;WITH cte_input AS (
    SELECT ROW_NUMBER() OVER (ORDER BY(SELECT 0)) AS RN, CAST(Line AS INT) AS Line FROM ##Input
)
SELECT COUNT(1) --* 
FROM cte_input c1
LEFT JOIN cte_input c2 ON c1.rn + 1= c2.rn
WHERE ISNULL(c1.Line,0) < c2.Line
ORDER BY 1

--1215 is correct for part 1

;WITH cte_input AS (
    SELECT ROW_NUMBER() OVER (ORDER BY(SELECT 0)) AS RN, CAST(Line AS INT) AS Line FROM ##Input
), cte_slidingwindow AS (
    SELECT c1.rn,C1.Line + c2.Line + c3.Line AS Line FROM cte_input c1
    LEFT JOIN cte_input c2 ON c1.rn + 1= c2.rn
    LEFT JOIN cte_input c3 ON c2.rn + 1= c3.rn
)
SELECT COUNT(1) --*
FROM cte_slidingwindow c1
LEFT JOIN cte_slidingwindow c2 ON c1.rn + 1= c2.rn
WHERE c1.Line < c2.Line
ORDER BY 1

--1150 is correct for part 2

DROP TABLE ##Input

