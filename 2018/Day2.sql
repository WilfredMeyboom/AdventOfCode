/*
use Test_WME

CREATE TABLE Input (Nr NVARCHAR(MAX));

BULK INSERT Input
FROM 'D:\temp\AdventOfCode\input2.txt'
WITH (ROWTERMINATOR = '0x0A');

--SELECT *, LEN(Nr) FROM Input

CREATE TABLE #BoxLetters (Box INT, LetterNr INT, Letter CHAR)
DECLARE @Box INT = 0

DECLARE @BoxNr NVARCHAR(50)

DECLARE BoxCursor CURSOR
FOR SELECT Nr FROM Input

OPEN BoxCursor

FETCH NEXT FROM BoxCursor INTO @boxNr
WHILE @@FETCH_STATUS = 0  
BEGIN

--SELECT @BoxNr
    SET @Box = @Box + 1

    ;WITH cte_Split AS (
        SELECT 1 AS RowLvl,
               LEFT(@BoxNr, 1) AS Letter,
               SUBSTRING(@BoxNr, 2, LEN(@BoxNr)) AS Remainder
        UNION ALL
        SELECT RowLvl + 1,
            LEFT(Remainder, 1),
            SUBSTRING(Remainder, 2, LEN(Remainder)) 
        FROM cte_Split
        WHERE LEN(Remainder) > 0
     )
     INSERT #BoxLetters
     SELECT @Box, RowLvl, Letter FROM cte_Split


    FETCH NEXT FROM BoxCursor INTO @boxNr
END

CLOSE BoxCursor
DEALLOCATE BoxCursor

DROP TABLE Input


--DROP TABLE #BoxLetters
*/

;WITH cte_Exact3Letters AS (
    SELECT DISTINCT BL1.Box, BL1.Letter
    FROM #BoxLetters BL1
    INNER JOIN #BoxLetters BL2 ON BL1.Box = BL2.Box
                              AND BL1.Letter = BL2.Letter
                              AND BL1.LetterNr < BL2.LetterNr
    INNER JOIN #BoxLetters BL3 ON BL2.Box = BL3.Box
                             AND BL2.Letter = BL3.Letter
                             AND BL2.LetterNr < BL3.LetterNr
), cte_Exact2Letters AS (
SELECT DISTINCT BL1.Box 
    FROM #BoxLetters BL1
    INNER JOIN #BoxLetters BL2 ON BL1.Box = BL2.Box
                              AND BL1.Letter = BL2.Letter
                              AND BL1.LetterNr < BL2.LetterNr
    LEFT JOIN cte_Exact3Letters c3 ON c3.Box = BL1.Box
                                  AND c3.Letter = BL1.Letter
    WHERE c3.Box IS NULL
)
SELECT C3.Nr3 * C2.Nr2
FROM (SELECT COUNT(1) AS Nr3 FROM cte_Exact3Letters) c3
CROSS APPLY (SELECT COUNT(1) AS Nr2 FROM cte_Exact2Letters) c2

;WITH cte_MostSimilar AS (
SELECT TOP (1) BL1.Box AS Box1
,      BL2.Box AS Box2
,      SUM(CASE WHEN Bl1.Letter = BL2.Letter THEN 1 ELSE 0 END) AS Correctness
FROM #BoxLetters BL1
INNER JOIN #BoxLetters BL2 ON BL1.LetterNr = BL2.LetterNr
                          AND BL1.Box < BL2.Box
GROUP BY BL1.Box, BL2.Box
HAVING SUM(CASE WHEN Bl1.Letter = BL2.Letter THEN 1 ELSE 0 END) = 25
)
SELECT *
FROM #BoxLetters BL
INNER JOIN cte_MostSimilar cMS ON BL.Box = cMS.Box1 OR BL.Box = cMS.Box2
ORDER BY Box, LetterNr
