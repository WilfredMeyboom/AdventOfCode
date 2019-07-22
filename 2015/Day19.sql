use Test_WME

SET NOCOUNT ON

CREATE TABLE ##Input (Line NVARCHAR(MAX));

BULK INSERT ##Input
FROM 'D:\Wilfred\AdventOfCode\2015\input19.txt'
WITH (ROWTERMINATOR = '0x0A');

CREATE TABLE ##Instructions (ID INT IDENTITY(1,1), Input VARCHAR(10), Output VARCHAR(20))

INSERT ##Instructions (Input, Output)
SELECT LTRIM(RTRIM(LEFT(Line, CHARINDEX('=>', Line) - 1)))
,      LTRIM(RTRIM(SUBSTRING(Line, CHARINDEX('=>', Line) + 2, LEN(Line))))
FROM ##Input WHERE LEN(Line) < 20

--Solution to part 1 is lost
--Answer was 509

CREATE TABLE ##Results (ID INT IDENTITY(1,1), Line VARCHAR(500) /*COLLATE Latin1_General_CS_AS*/, Counter INT)

INSERT ##Results(Line, Counter)
SELECT Line, -1 FROM ##Input WHERE LEN(Line) > 20


DECLARE @Counter INT = 0

--SELECT * FROM ##Instructions 

WHILE (NOT EXISTS (SELECT 1 FROM ##Results WHERE Line = 'e')) AND @Counter < 1000
BEGIN
    
    --Transfer the molecules one step back
    INSERT ##Results (Line, Counter)
    SELECT DISTINCT REPLACE(Line, Output, Input) AS NewLine
    ,      @Counter
    FROM ##Results
    CROSS APPLY ##Instructions
    WHERE REPLACE(Line, Output, Input) NOT IN (SELECT Line FROM ##Results)
      AND Counter = @Counter - 1

    --Keep only the shortest results
    DELETE ##Results
    WHERE LEN(Line) > (SELECT MIN(LEN(Line)) FROM ##Results)

    SET @Counter = @Counter + 1

    PRINT CAST(@Counter AS VARCHAR(8)) + ' ' + CAST(GETDATE() AS VARCHAR(20))

END

-- This does not work. You get stuck on a single result


--SELECT LEN(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(Line,N'n',''), N'a',''), 'i', ''), 'r', ''), 'h', ''), 'g', '')) FROM ##Results  --In total 277 elements
SELECT LEN(Line) - LEN(REPLACE(Line, 'Ar', 'A')) FROM ##Results  -- 31 times Ar
SELECT LEN(Line) - LEN(REPLACE(Line, 'Rn', 'R')) FROM ##Results  -- 31 times Rn
SELECT LEN(Line) - LEN(REPLACE(Line, 'Y', '')) FROM ##Results  -- 8 times Y

SELECT 277 - (31 + 31) - 2*8 - 1 

;WITH cte_Cleaned AS (
    SELECT REPLACE(REPLACE(REPLACE(Line, 'Ar', ''), 'Rn', ''), 'Y', '') Line FROM ##Results
)
SELECT REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(Line,N'n',''), N'a',''), 'i', ''), 'r', ''), 'h', ''), 'g', '') FROM cte_Cleaned


--SELECT DISTINCT SUBSTRING(Input, 2, 1) FROM ##Instructions
SELECT * FROM ##Instructions
SELECT * FROM ##Results
--100 is too low
--150 is too low
--198 is too high

--190 is incorrect
--197 is incorrect
--196 is incorrect

-- 195 is apparently correct

/* 

DROP TABLE ##Results
DROP TABLE ##Instructions

DROP TABLE ##Input


--https://www.reddit.com/r/adventofcode/comments/3xflz8/day_19_solutions/
*/






