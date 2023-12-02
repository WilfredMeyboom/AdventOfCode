SET NOCOUNT ON

--DECLARE @Input VARCHAR(10) = 'abc'
DECLARE @Input VARCHAR(10) = 'ahsbgdzn'

-- Let's start with 50000 hashes and see if this is enough to cover the 64 keys
;WITH cte_counter AS (
    SELECT TOP 50000 
        ROW_NUMBER() OVER (ORDER BY (SELECT 0)) AS RowNumber
    ,   @Input + CAST(ROW_NUMBER() OVER (ORDER BY (SELECT 0)) AS VARCHAR(20)) AS Input
    FROM sys.messages
)
SELECT RowNumber
,      Input
,      LOWER(CONVERT(CHAR(32), HASHBYTES('MD5', Input), 2)) AS MD5Hash -- Special convert to cast the hash to a char
,      CAST(NULL AS CHAR(1)) ThreeLetterChar -- Reserve a column to store the letter that shows three times in sequence (if any)
,      CAST(NULL AS CHAR(1)) FiveLetterChar -- Reserve a column to store the letter that shows five times in sequence (if any)
INTO ##Hashes
FROM cte_counter

-- Start a recursive cte to count the number of the same of sequential letters in a hash
;WITH cte_Rec AS 
(
    SELECT RowNumber
    ,      1 AS LetterNr
    ,      LEFT(CAST(MD5Hash AS VARCHAR(32)),1) AS Letter
    ,      SUBSTRING(MD5Hash, 2, LEN(MD5Hash)) AS LeftOver
    ,      1 AS SeqLetters
    ,      MD5Hash
    FROM ##Hashes

    UNION ALL

    SELECT RowNumber
    ,      LetterNr + 2
    ,      LEFT(CAST(LeftOver AS VARCHAR(32)),1) 
    ,      SUBSTRING(LeftOver, 2, LEN(LeftOver)) 
    ,      CASE WHEN Letter = LEFT(CAST(LeftOver AS VARCHAR(32)),1) THEN SeqLetters + 1 ELSE 1 END
    ,      MD5Hash
    FROM cte_Rec
    WHERE LEN(LeftOver) > 0

), cte_results AS (
    -- Just keep the hashes that have 3 or 5 times the same letter in a row. 
    -- If a hash has multiple times the same letter in a row only look at the first occurence
    -- And pivot so we have both letters (3 times and 5 times) in one row
    SELECT RowNumber, [3] AS ThreeLetterChar, [5] AS FiveLetterChar
    FROM (
        SELECT DISTINCT RowNumber, FIRST_VALUE(Letter) OVER (PARTITION BY RowNumber, SeqLetters ORDER BY LetterNr) AS Letter, SeqLetters
        FROM cte_Rec
        WHERE SeqLetters IN (3,5)
        ) AS Src
        PIVOT (
            MIN(Letter)
            FOR SeqLetters IN ([3], [5])
        ) AS Pvt
    WHERE [3] IS NOT NULL OR [5] IS NOT NULL   
)
-- Store the results in the hashes table
UPDATE H
SET ThreeLetterChar = cR.ThreeLetterChar
,   FiveLetterChar = cR.FiveLetterChar
FROM ##Hashes H
INNER JOIN cte_results cR ON H.RowNumber = cR.RowNumber

-- Find the 64th viable hash and which original row number is associated with that
;WITH cte_ViableHashes AS (
    SELECT ROW_NUMBER() OVER (ORDER BY H1.RowNumber) AS RN, H1.*
    FROM ##Hashes H1
    INNER JOIN ##Hashes H2 ON H2.RowNumber BETWEEN H1.RowNumber + 1 AND H1.RowNumber + 1000
                          AND H1.ThreeLetterChar = H2.FiveLetterChar
)
SELECT RowNumber AS Part1
FROM cte_ViableHashes
WHERE RN = 64


-- For part 2 we need to hash the hashes 16 times
DECLARE @Counter INT = 0 

UPDATE ##Hashes
SET ThreeLetterChar = NULL
,   FiveLetterChar = NULL

WHILE @Counter < 2016
BEGIN
    
    UPDATE ##Hashes
    SET MD5Hash = LOWER(CONVERT(CHAR(32), HASHBYTES('MD5', MD5Hash), 2))

    SET @Counter = @Counter + 1
END

-- And after this: rinse and repeat
-- Start a recursive cte to count the number of the same of sequential letters in a hash
;WITH cte_Rec AS 
(
    SELECT RowNumber
    ,      1 AS LetterNr
    ,      LEFT(CAST(MD5Hash AS VARCHAR(32)),1) AS Letter
    ,      SUBSTRING(MD5Hash, 2, LEN(MD5Hash)) AS LeftOver
    ,      1 AS SeqLetters
    ,      MD5Hash
    FROM ##Hashes

    UNION ALL

    SELECT RowNumber
    ,      LetterNr + 2
    ,      LEFT(CAST(LeftOver AS VARCHAR(32)),1) 
    ,      SUBSTRING(LeftOver, 2, LEN(LeftOver)) 
    ,      CASE WHEN Letter = LEFT(CAST(LeftOver AS VARCHAR(32)),1) THEN SeqLetters + 1 ELSE 1 END
    ,      MD5Hash
    FROM cte_Rec
    WHERE LEN(LeftOver) > 0

), cte_results AS (
    -- Just keep the hashes that have 3 or 5 times the same letter in a row. 
    -- If a hash has multiple times the same letter in a row only look at the first occurence
    -- And pivot so we have both letters (3 times and 5 times) in one row
    SELECT RowNumber, [3] AS ThreeLetterChar, [5] AS FiveLetterChar
    FROM (
        SELECT DISTINCT RowNumber, FIRST_VALUE(Letter) OVER (PARTITION BY RowNumber, SeqLetters ORDER BY LetterNr) AS Letter, SeqLetters
        FROM cte_Rec
        WHERE SeqLetters IN (3,5)
        ) AS Src
        PIVOT (
            MIN(Letter)
            FOR SeqLetters IN ([3], [5])
        ) AS Pvt
    WHERE [3] IS NOT NULL OR [5] IS NOT NULL   
)
-- Store the results in the hashes table
UPDATE H
SET ThreeLetterChar = cR.ThreeLetterChar
,   FiveLetterChar = cR.FiveLetterChar
FROM ##Hashes H
INNER JOIN cte_results cR ON H.RowNumber = cR.RowNumber

-- Find the 64th viable hash and which original row number is associated with that
;WITH cte_ViableHashes AS (
    SELECT ROW_NUMBER() OVER (ORDER BY H1.RowNumber) AS RN, H1.*
    FROM ##Hashes H1
    INNER JOIN ##Hashes H2 ON H2.RowNumber BETWEEN H1.RowNumber + 1 AND H1.RowNumber + 1000
                          AND H1.ThreeLetterChar = H2.FiveLetterChar
)
SELECT RowNumber AS Part2
FROM cte_ViableHashes
WHERE RN = 64


/*
    DROP TABLE ##Hashes
*/




