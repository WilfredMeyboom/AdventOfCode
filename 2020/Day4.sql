use Test_WME

SET NOCOUNT ON

CREATE TABLE ##Input (Line NVARCHAR(MAX));

BULK INSERT ##Input
FROM 'C:\Source\AdventOfCode\2020\input4.txt'
WITH (ROWTERMINATOR = '0x0A');

SELECT ROW_NUMBER() OVER (ORDER BY (SELECT 0)) AS ID, * 
INTO ##NumberedInput
FROM ##Input

INSERT ##NumberedInput (ID, Line)
SELECT MAX(ID) + 1, NULL FROM ##NumberedInput

;WITH cte_BlankLines AS (
    SELECT ID
    , ROW_NUMBER() OVER (ORDER BY ID) AS PassID
    , ISNULL(LAG(ID) OVER (ORDER BY ID), 0) AS PrevID FROM ##NumberedInput WHERE Line IS NULL    
)
SELECT PassID
,      LEFT(value, CHARINDEX(':', value) - 1) AS [Key]
,      SUBSTRING(value, CHARINDEX(':', value) + 1, LEN(value)) AS Val 
INTO ##PassData
FROM ##NumberedInput NI
INNER JOIN cte_BlankLines cBL ON NI.ID BETWEEN cBL.PrevID AND cBL.ID
CROSS APPLY STRING_SPLIT(Line, ' ')
WHERE Line IS NOT NULL


SELECT PassID, COUNT(1)
FROM ##PassData
WHERE [Key] <> 'Cid'
GROUP BY PassID
ORDER BY 2 DESC


/*
DROP TABLE ##Input
DROP TABLE ##NumberedInput
DROP TABLE ##PassData
*/

-- 259 is too low for part 1



ALTER TABLE ##PassData ADD IsValid INT

UPDATE ##PassData
SET IsValid = CASE WHEN Val BETWEEN 1920 AND 2002 THEN 1 ELSE 0 END
WHERE [Key] = 'byr'

UPDATE ##PassData
SET IsValid = CASE WHEN Val BETWEEN 2010 AND 2020 THEN 1 ELSE 0 END
WHERE [Key] = 'iyr'

UPDATE ##PassData
SET IsValid = CASE WHEN Val BETWEEN 2020 AND 2030 THEN 1 ELSE 0 END
WHERE [Key] = 'eyr'

UPDATE ##PassData
SET IsValid = CASE WHEN RIGHT(Val, 2) = 'cm' THEN 
                        CASE WHEN REPLACE(Val, 'cm', '') BETWEEN 150 AND 193 THEN 1 ELSE 0 END
                   WHEN RIGHT(Val, 2) = 'in' THEN  
                        CASE WHEN REPLACE(Val, 'in', '') BETWEEN 59 AND 76 THEN 1 ELSE 0 END
              ELSE 0 
              END
WHERE [Key] = 'hgt'

UPDATE ##PassData
SET IsValid = CASE WHEN LEN(Val) = 7 AND LEFT(Val, 1) = '#' THEN 
                        CASE WHEN (ASCII(SUBSTRING(Val, 2, 2)) BETWEEN 48 AND 57 OR ASCII(SUBSTRING(Val, 2, 2)) BETWEEN 97 AND 122)
                              AND (ASCII(SUBSTRING(Val, 3, 3)) BETWEEN 48 AND 57 OR ASCII(SUBSTRING(Val, 3, 3)) BETWEEN 97 AND 122)
                              AND (ASCII(SUBSTRING(Val, 4, 4)) BETWEEN 48 AND 57 OR ASCII(SUBSTRING(Val, 4, 4)) BETWEEN 97 AND 122)
                              AND (ASCII(SUBSTRING(Val, 5, 5)) BETWEEN 48 AND 57 OR ASCII(SUBSTRING(Val, 5, 5)) BETWEEN 97 AND 122)
                              AND (ASCII(SUBSTRING(Val, 6, 6)) BETWEEN 48 AND 57 OR ASCII(SUBSTRING(Val, 6, 6)) BETWEEN 97 AND 122)
                              AND (ASCII(SUBSTRING(Val, 7, 7)) BETWEEN 48 AND 57 OR ASCII(SUBSTRING(Val, 7, 7)) BETWEEN 97 AND 122)
                            THEN 1
                            ELSE 0 END
              ELSE 0 END
WHERE [Key] = 'hcl'

--a 97
--z 122
--0 48
--9 57

UPDATE ##PassData
SET IsValid = CASE WHEN Val IN ('amb','blu','brn','gry','grn','hzl','oth') THEN 1 ELSE 0 END
WHERE [Key] = 'ecl'

UPDATE ##PassData
SET IsValid = CASE WHEN LEN(Val) = 9 AND TRY_CAST(Val AS INT) IS NOT NULL THEN 1 ELSE 0 END
WHERE [Key] = 'pid'


SELECT PassID, COUNT(1)
FROM ##PassData
WHERE [Key] <> 'Cid' AND IsValid = 1
GROUP BY PassID
ORDER BY 2 DESC