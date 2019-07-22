use Test_WME

CREATE TABLE Input (Nrs NVARCHAR(MAX));

BULK INSERT Input
FROM 'D:\Wilfred\AdventOfCode\2017\input2.txt'
WITH (ROWTERMINATOR = '0x0A');


--SELECT * FROM Input 




CREATE TABLE #Nrs (ID INT IDENTITY(1,1), Line INT, Nr INT)


    ;WITH cte_Split AS (
        SELECT 1 AS RowLvl,
               ROW_NUMBER() OVER (ORDER BY (SELECT 0)) AS LineNr,
               LEFT(Nrs, CHARINDEX(CHAR(9), Nrs)) AS Letter,
               SUBSTRING(Nrs, CHARINDEX(CHAR(9), Nrs) + 1, LEN(Nrs)) + CHAR(9) AS Remainder
        FROM input
        UNION ALL
        SELECT RowLvl + 1,
            LineNr,
            LEFT(Remainder, CHARINDEX(CHAR(9), Remainder)),
            SUBSTRING(Remainder, CHARINDEX(CHAR(9), Remainder) + 1, LEN(Remainder)) 
        FROM cte_Split 
        WHERE RowLvl < 16
     )
     INSERT #Nrs (Line, Nr)
     SELECT LineNr, CAST(REPLACE(Letter, '	', '') AS INT)--, Remainder
     FROM cte_Split
     OPTION (MAXRECURSION 1000)


--DROP TABLE Input
--DROP TABLE #Nrs

;WITH cte_1 AS (
SELECT Line, MAX(Nr) - MIN(Nr) AS Diff, MIN(Nr) MinNr, MAX(Nr) MaxNr FROM #Nrs GROUP BY Line
)
SELECT SUM(Diff) FROM cte_1


--SELECT * FROM input
--SELECT Line, MAX(Nr) - MIN(Nr) AS Diff, MIN(Nr), MAX(Nr) FROM #Nrs GROUP BY Line
--SELECT * FROM #Nrs WHERE Line = 2

SELECT SUM(T1.Nr / T2.Nr)
FROM #Nrs T1
INNER JOIN #Nrs T2 ON T1.Line = T2.Line AND T1.Nr % T2.Nr = 0 AND T1.Nr <> T2.Nr
