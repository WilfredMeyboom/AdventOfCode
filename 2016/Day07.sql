use Test_WME

SET NOCOUNT ON

CREATE TABLE ##Input (Line NVARCHAR(MAX));

BULK INSERT ##Input
FROM 'D:\Wilfred\AdventOfCode\2016\input07.txt'
WITH (ROWTERMINATOR = '0x0A');

CREATE TABLE ##IPS (ID INT IDENTITY, LineNr INT, LetterNr INT, Letter CHAR(1))

;WITH cte_Letters AS (

    SELECT ROW_NUMBER() OVER (ORDER BY (SELECT 0)) AS LineNr
    ,      1 AS LetterNr
    ,      LEFT(Line, 1) AS Letter
    ,      SUBSTRING(Line, 2, LEN(Line)) AS Remainder
    FROM ##Input
    UNION ALL
    SELECT LineNr
    ,      LetterNr + 1
    ,      LEFT(Remainder, 1) 
    ,      SUBSTRING(Remainder, 2, LEN(Remainder))
    FROM cte_Letters
    WHERE LEN(Remainder) > 0
)
INSERT ##IPS (LineNr, LetterNr, Letter)
SELECT LineNr, LetterNr, Letter FROM cte_Letters
OPTION (MAXRECURSION 30000)



;WITH cte_1is4 AS (
    SELECT I1.LineNr, I1.LetterNr, I1.Letter
    FROM ##IPS I1
    INNER JOIN ##IPS I2 ON I1.LineNr = I2.LineNr 
                       AND I1.Letter = I2.Letter 
                       AND I1.LetterNr = I2.LetterNr - 3
), cte_2is3 AS (
    SELECT I1.LineNr, I1.LetterNr, I1.Letter
    FROM ##IPS I1
    INNER JOIN ##IPS I2 ON I1.LineNr = I2.LineNr 
                       AND I1.Letter = I2.Letter 
                       AND I1.LetterNr = I2.LetterNr - 1
), cte_ABBA AS (
    SELECT I1.LineNr, I1.LetterNr
    FROM cte_1is4 I1
    INNER JOIN cte_2is3 I2 ON I1.LineNr = I2.LineNr 
                          AND I1.LetterNr = I2.LetterNr - 1 
                          AND I1.Letter <> I2.Letter
), cte_Brackets AS (
    SELECT StartBracket.linenr,
           StartBracket.letternr AS StartPos,
           EndBracket.letternr AS EndPos
    FROM   (SELECT ROW_NUMBER()
                     OVER (
                       PARTITION BY linenr, letter
                       ORDER BY linenr, letter, letternr) AS RowNr,
                   linenr,
                   letternr
            FROM   ##ips
            WHERE  letter IN ( '[' )) StartBracket
            INNER JOIN (SELECT ROW_NUMBER()
                                OVER (
                                  PARTITION BY linenr, letter
                                  ORDER BY linenr, letter, letternr) AS RowNr,
                              linenr,
                              letternr
                       FROM   ##ips
                       WHERE  letter IN ( ']' )) EndBracket
                   ON StartBracket.linenr = EndBracket.linenr
                      AND StartBracket.rownr = EndBracket.rownr  
)
SELECT cA.LineNr, SUM(CASE WHEN cB.LineNr IS NOT NULL THEN 1 ELSE 0 END) AS Invalid
FROM cte_ABBA cA
LEFT JOIN cte_Brackets cB ON cA.LineNr = cB.LineNr AND cA.LetterNr BETWEEN cB.StartPos AND cB.EndPos
GROUP BY cA.LineNr
ORDER BY 2


--> 115 snoopable (correct for 1)



;WITH cte_1is3 AS (
    SELECT I1.LineNr, I1.LetterNr, I2.Letter AS InnerLetter, I3.Letter AS OuterLetter
    FROM ##IPS I1
    INNER JOIN ##IPS I2 ON I1.LineNr = I2.LineNr 
                       AND I1.Letter <> I2.Letter 
                       AND I1.LetterNr = I2.LetterNr - 1
    INNER JOIN ##IPS I3 ON I1.LineNr = I3.LineNr 
                       AND I1.Letter = I3.Letter 
                       AND I1.LetterNr = I3.LetterNr - 2
    WHERE I2.Letter NOT IN ('[', ']')
), cte_Brackets AS (
    SELECT StartBracket.linenr,
           StartBracket.letternr AS StartPos,
           EndBracket.letternr AS EndPos
    FROM   (SELECT ROW_NUMBER()
                     OVER (
                       PARTITION BY linenr, letter
                       ORDER BY linenr, letter, letternr) AS RowNr,
                   linenr,
                   letternr
            FROM   ##ips
            WHERE  letter IN ( '[' )) StartBracket
            INNER JOIN (SELECT ROW_NUMBER()
                                OVER (
                                  PARTITION BY linenr, letter
                                  ORDER BY linenr, letter, letternr) AS RowNr,
                              linenr,
                              letternr
                       FROM   ##ips
                       WHERE  letter IN ( ']' )) EndBracket
                   ON StartBracket.linenr = EndBracket.linenr
                      AND StartBracket.rownr = EndBracket.rownr  
), cte_InBrackets AS (
    SELECT cA.LineNr
    ,      cA.LetterNr
    ,      cA.InnerLetter
    ,      cA.OuterLetter
    ,      CASE WHEN cB.LineNr IS NOT NULL THEN 1 ELSE 0 END AS IsInsideBrackets
    FROM cte_1is3 cA
    LEFT JOIN cte_Brackets cB ON cA.LineNr = cB.LineNr 
                             AND cA.LetterNr BETWEEN cB.StartPos AND cB.EndPos
)
SELECT cIB0.LineNr
FROM cte_InBrackets cIB0
INNER JOIN cte_InBrackets cIB1 ON cIB0.LineNr = cIB1.LineNr
                              AND cIB0.OuterLetter = cIB1.InnerLetter
                              AND cIB0.InnerLetter = cIB1.OuterLetter
                              AND cIB0.IsInsideBrackets < cIB1.IsInsideBrackets
GROUP BY cIB0.LineNr
ORDER BY cIB0.LineNr



/*

DROP TABLE ##IPS
DROP TABLE ##Input

*/

--SELECT * FROM ##Input



