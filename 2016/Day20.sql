use Test_WME

SET NOCOUNT ON

CREATE TABLE ##Input (Line NVARCHAR(MAX));

BULK INSERT ##Input
FROM 'D:\Wilfred\AdventOfCode\2016\input20.txt'
WITH (ROWTERMINATOR = '0x0A');

CREATE TABLE ##Ranges (ID INT IDENTITY(1,1), StartRange BIGINT, EndRange BIGINT)

INSERT ##Ranges
SELECT LEFT(Line, CHARINDEX('-', Line) -1 )
,      SUBSTRING(Line, CHARINDEX('-', Line) + 1, LEN(Line))
FROM ##Input 


SELECT *
FROM ##Ranges R1
LEFT JOIN ##Ranges R2 ON (R2.StartRange BETWEEN R1.StartRange AND R1.EndRange AND R2.EndRange > R1.EndRange)
                      OR R1.EndRange + 1 = R2.StartRange
WHERE R2.ID IS NULL
ORDER BY R1.StartRange

SELECT MAX(EndRange) FROM ##Ranges --4294967295 (Dit +1 is too high)

SELECT * FROM ##Ranges WHERE 1732730 BETWEEN StartRange AND EndRange

;WITH cte_EndRanges AS (
    SELECT DISTINCT R1.EndRange + 1 AS NewStart
    FROM ##Ranges R1
    LEFT JOIN ##Ranges R2 ON R1.EndRange BETWEEN R2.StartRange AND R2.EndRange AND R1.ID <> R2.ID
    WHERE R2.ID IS NULL
), cte_Mins AS (
    SELECT cER.NewStart, ISNULL(MIN(R.StartRange - cER.NewStart),0) AS Mins
    FROM cte_EndRanges cER
    LEFT JOIN ##Ranges R ON R.StartRange >= cER.NewStart
    GROUP BY cER.NewStart
)
SELECT SUM(Mins)
FROM cte_Mins

--1015326737 Niet goed voor part 2

--146 is the correct answer for part 2

/*


DROP TABLE ##Ranges
DROP TABLE ##Input

*/


