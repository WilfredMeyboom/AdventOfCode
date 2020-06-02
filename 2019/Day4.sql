use Test_WME

SET NOCOUNT ON

DECLARE @StartValue INT = 165432
DECLARE @EndValue INT = 707912

CREATE TABLE ##Numbers (Number INT, Digit1 INT, Digit2 INT, Digit3 INT, Digit4 INT, Digit5 INT, Digit6 INT, AdjacentSameDigits INT, NeverDecrease INT, ExactlyTwoAdjacentSameDigits INT)

INSERT ##Numbers (Number)
SELECT TOP(@EndValue - @StartValue + 1) ROW_NUMBER() OVER (ORDER BY (SELECT 0)) + @StartValue - 1
FROM sys.messages S1
CROSS APPLY sys.messages S2


UPDATE ##Numbers
SET Digit1 = CAST(SUBSTRING(CAST(Number AS VARCHAR(6)),1, 1) AS INT)
,   Digit2 = CAST(SUBSTRING(CAST(Number AS VARCHAR(6)),2, 1) AS INT)
,   Digit3 = CAST(SUBSTRING(CAST(Number AS VARCHAR(6)),3, 1) AS INT)
,   Digit4 = CAST(SUBSTRING(CAST(Number AS VARCHAR(6)),4, 1) AS INT)
,   Digit5 = CAST(SUBSTRING(CAST(Number AS VARCHAR(6)),5, 1) AS INT)
,   Digit6 = CAST(SUBSTRING(CAST(Number AS VARCHAR(6)),6, 1) AS INT)



UPDATE ##Numbers
SET AdjacentSameDigits = CASE WHEN Digit1 = Digit2 
                                OR Digit2 = Digit3
                                OR Digit3 = Digit4 
                                OR Digit4 = Digit5 
                                OR Digit5 = Digit6 THEN 1 ELSE 0 END 

UPDATE ##Numbers
SET NeverDecrease = CASE WHEN Digit1 <= Digit2 
                          AND Digit2 <= Digit3
                          AND Digit3 <= Digit4 
                          AND Digit4 <= Digit5 
                          AND Digit5 <= Digit6 THEN 1 ELSE 0 END 


SELECT * FROM ##Numbers WHERE AdjacentSameDigits = 1 AND NeverDecrease = 1

--1716 is correct for part 1

;WITH cte_ExactlyTwo AS (
    SELECT Number, Digit
    FROM   
       (SELECT Number, Digit1, Digit2, Digit3, Digit4, Digit5, Digit6
       FROM ##Numbers) p  
    UNPIVOT  
       (Digit FOR OriginalNumber IN   
          (Digit1, Digit2, Digit3, Digit4, Digit5, Digit6)
    )AS unpvt
    GROUP BY Number, Digit
    HAVING COUNT(1) = 2
)
UPDATE N
SET ExactlyTwoAdjacentSameDigits = 1
FROM ##Numbers N 
INNER JOIN cte_ExactlyTwo cET ON N.Number = cET.Number

UPDATE ##Numbers
SET ExactlyTwoAdjacentSameDigits = 0
WHERE ExactlyTwoAdjacentSameDigits IS NULL


SELECT * FROM ##Numbers WHERE AdjacentSameDigits = 1 AND NeverDecrease = 1 AND ExactlyTwoAdjacentSameDigits = 1

-- 1163 is correct for part 2
