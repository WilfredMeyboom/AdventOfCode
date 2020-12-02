use Test_WME

CREATE TABLE ##Input (Nr NVARCHAR(MAX));

BULK INSERT ##Input
FROM 'C:\Users\a-wilfred.meyboom\Documents\SQL Server Management Studio\AoC\input2.txt'
WITH (ROWTERMINATOR = '0x0A');

CREATE TABLE ##Passwords (ID INT IDENTITY(1,1), StartInt INT, StopInt INT, Letter CHAR, Pass VARCHAR(100), OrigLine VARCHAR(250))

INSERT ##Passwords(StartInt, StopInt, Letter, Pass, OrigLine)
SELECT LEFT(Nr, CHARINDEX('-', Nr) -1) AS StartInt
, SUBSTRING(Nr, CHARINDEX('-', Nr) + 1, CHARINDEX(' ', Nr) - CHARINDEX('-', Nr)) AS StopInt
, LTRIM(RTRIM(SUBSTRING(Nr, CHARINDEX(' ', Nr), CHARINDEX(':', Nr) - CHARINDEX(' ', Nr)))) AS Letter
, LTRIM(RTRIM(SUBSTRING(Nr, CHARINDEX(':', Nr) + 1, LEN(Nr)))) AS Pass
, Nr
--,*
--, LEN(SUBSTRING(Nr, CHARINDEX(':', Nr) + 1, LEN(Nr))) - LEN(REPLACE(SUBSTRING(Nr, CHARINDEX(':', Nr) + 1, LEN(Nr)), LTRIM(RTRIM(SUBSTRING(Nr, CHARINDEX(' ', Nr), CHARINDEX(':', Nr) - CHARINDEX(' ', Nr)))), '')) AS OccurenceLetter
FROM ##Input

;WITH cte_OccurencePerPass AS (
    SELECT * 
    , LEN(Pass) - LEN(REPLACE(Pass, Letter, '')) AS OccurenceLetter
    FROM ##Passwords
)
SELECT SUM(CASE WHEN OccurenceLetter BETWEEN StartInt AND StopInt THEN 1 ELSE 0 END) AS Valid
FROM cte_OccurencePerPass



--SELECT *
--FROM ##Passwords
--WHERE StopInt <= StartInt
-- 0

--436 is too low
--458 is correct for part 1

;WITH cte_PerLetter AS (
    SELECT *
    ,   CASE WHEN SUBSTRING(Pass, StartInt, 1) = Letter THEN 1 ELSE 0 END
      + CASE WHEN SUBSTRING(Pass, StopInt, 1) = Letter THEN 1 ELSE 0 END AS Cnt
    FROM ##Passwords
)
SELECT *
FROM cte_PerLetter
WHERE Cnt = 1


DROP TABLE ##Passwords
DROP TABLE ##Input
