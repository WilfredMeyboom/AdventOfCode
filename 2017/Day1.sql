use Test_WME

CREATE TABLE Input (Nrs NVARCHAR(MAX));

BULK INSERT Input
FROM 'D:\Wilfred\AdventOfCode\2017\input1.txt'
WITH (ROWTERMINATOR = '0x0A');


--SELECT LEN(Nrs) FROM Input --2040

CREATE TABLE #Nrs (ID INT IDENTITY(1,1), Nr INT)


    ;WITH cte_Split AS (
        SELECT 1 AS RowLvl,
               LEFT(Nrs, 1) AS Letter,
               SUBSTRING(Nrs, 2, LEN(Nrs)) AS Remainder
        FROM input
        UNION ALL
        SELECT RowLvl + 1,
            LEFT(Remainder, 1),
            SUBSTRING(Remainder, 2, LEN(Remainder)) 
        FROM cte_Split 
        WHERE LEN(Remainder) > 0
     )
     INSERT #Nrs (Nr)
     SELECT Letter FROM cte_Split
     OPTION (MAXRECURSION 10000)



--DROP TABLE Input
--DROP TABLE #Nrs

SELECT SUM(CASE WHEN T1.Nr = T2.Nr THEN T1.NR ELSE 0 END)
FROM #Nrs T1
INNER JOIN #Nrs T2 ON T1.ID = T2.ID - 1 OR (T1.ID = 2040 AND T2.ID = 1)
--ORDER BY T1.ID


DECLARE @ListLen INT 
SELECT @ListLen = COUNT(1) FROM #Nrs

SELECT SUM(CASE WHEN T1.Nr = T2.Nr THEN T1.NR ELSE 0 END)
FROM #Nrs T1
INNER JOIN #Nrs T2 ON T1.ID = T2.ID + (@ListLen / 2) OR T1.ID = T2.ID - (@ListLen / 2)

