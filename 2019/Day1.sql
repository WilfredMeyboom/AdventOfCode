use Test_WME

CREATE TABLE #Input (Nr NVARCHAR(MAX));

BULK INSERT #Input
FROM 'C:\Source\AdventOfCode\input1.txt'
WITH (ROWTERMINATOR = '0x0A');


SELECT * FROM #Input
SELECT SUM( Nr/3 -2 ) FROM #Input

-- 3362507 for part 1

;WITH cte_AddedFuel AS (
    SELECT Nr/3 -2  AS AddedFuel
    FROM #Input
    UNION ALL
    SELECT AddedFuel/3 -2
    FROM cte_AddedFuel
    WHERE AddedFuel > 0
)
SELECT SUM(AddedFuel)
FROM cte_AddedFuel
WHERE AddedFuel > 0

-- 5040874

DROP TABLE #Input


