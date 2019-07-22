use Test_WME

SET NOCOUNT ON

CREATE TABLE ##Input (Line NVARCHAR(MAX));

BULK INSERT ##Input
FROM 'D:\Wilfred\AdventOfCode\2015\input5.txt'
WITH (ROWTERMINATOR = '0x0A');


CREATE TABLE ##Letters (ID INT IDENTITY(1,1), LineNr INT, CharNr INT, Letter CHAR)

;WITH cte_Letters AS (
    SELECT ROW_NUMBER() OVER (ORDER BY (SELECT 0)) AS LineNr
    ,      1 AS CharNr
    ,      LEFT(Line, 1) AS Letter
    ,      SUBSTRING(Line, 2, LEN(Line)) AS Remainder
    FROM ##Input
    UNION ALL
    SELECT LineNr
    ,      CharNr + 1
    ,      LEFT(Remainder, 1)
    ,      SUBSTRING(Remainder, 2, LEN(Remainder))
    FROM cte_Letters
    WHERE LEN(Remainder) > 0

)
INSERT ##Letters (LineNr, CharNr, Letter)
SELECT LineNr, CharNr, Letter
FROM cte_Letters



;WITH cte_ForbiddenLines AS (
    SELECT L1.LineNr 
    FROM ##Letters L1
    INNER JOIN ##Letters L2 ON L1.LineNr = L2.LineNr AND L1.CharNr + 1 = L2.CharNr
    WHERE (L1.Letter = 'a' AND L2.Letter = 'b')
       OR (L1.Letter = 'c' AND L2.Letter = 'd')
       OR (L1.Letter = 'p' AND L2.Letter = 'q')
       OR (L1.Letter = 'x' AND L2.Letter = 'y')
    GROUP BY L1.LineNr
), cte_TwiceInARow AS (
    SELECT L1.LineNr
    FROM ##Letters L1
    INNER JOIN ##Letters L2 ON L1.LineNr = L2.LineNr AND L1.CharNr + 1 = L2.CharNr
    WHERE L1.Letter = L2.Letter 
    GROUP BY L1.LineNr
), cte_Atleast3Vowels AS (
    SELECT LineNr
    FROM ##Letters
    WHERE Letter IN ('a','e','i','o','u')
    GROUP BY LineNr
    HAVING COUNT(1) >= 3
)
SELECT * 
FROM cte_Atleast3Vowels T1
INNER JOIN cte_TwiceInARow T2 ON T1.LineNr = T2.LineNr
LEFT JOIN cte_ForbiddenLines T3 ON T3.LineNr = T1.LineNr
WHERE T3.LineNr IS NULL

--258 is correct for part 1



--    It contains a pair of any two letters that appears at least twice in the string without overlapping, like xyxy (xy) or aabcdefgaa (aa), but not like aaa (aa, but it overlaps).
--    It contains at least one letter which repeats with exactly one letter between them, like xyx, abcdefeghi (efe), or even aaa.

;WITH cte_TwiceInARow AS (
    SELECT L1.LineNr, L1.CharNr, L1.Letter, L2.Letter AS SecondLetter
    FROM ##Letters L1
    INNER JOIN ##Letters L2 ON L1.LineNr = L2.LineNr AND L1.CharNr + 1 = L2.CharNr
), cte_TwiceTwiceInARow AS (
    SELECT T1.LineNr
    FROM cte_TwiceInARow T1
    INNER JOIN cte_TwiceInARow T2 ON T1.LineNr = T2.LineNr AND T1.CharNr < T2.CharNr - 1 AND T1.Letter = T2.Letter AND T1.SecondLetter = T2.SecondLetter
    GROUP BY T1.LineNr
), cte_TwiceOneInBetween AS (
    SELECT L1.LineNr
    FROM ##Letters L1
    INNER JOIN ##Letters L2 ON L1.LineNr = L2.LineNr AND L1.CharNr + 1 = L2.CharNr
    INNER JOIN ##Letters L3 ON L1.LineNr = L3.LineNr AND L2.CharNr + 1 = L3.CharNr
    WHERE L1.Letter = L3.Letter
    GROUP BY L1.LineNr
)
SELECT * 
FROM cte_TwiceTwiceInARow T1
INNER JOIN cte_TwiceOneInBetween T2 ON T1.LineNr = T2.LineNr

--17 is incorrect for part 2
-- 1 is incorrect for part 2
-- 53 is correct for part 2


/*

DROP TABLE ##Letters
DROP TABLE ##Input

*/