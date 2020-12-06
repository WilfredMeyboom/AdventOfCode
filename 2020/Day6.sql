use Test_WME

SET NOCOUNT ON

CREATE TABLE ##Input (Line NVARCHAR(MAX));

BULK INSERT ##Input
FROM 'C:\Source\AdventOfCode\2020\input6.txt'
WITH (ROWTERMINATOR = '0x0A');

SELECT ROW_NUMBER() OVER (ORDER BY (SELECT 0)) AS ID, * 
INTO ##NumberedInput
FROM ##Input

INSERT ##NumberedInput (ID, Line)
SELECT MAX(ID) + 1, NULL FROM ##NumberedInput

;WITH cte_BlankLines AS (
    SELECT ID AS CurrentID
    , ROW_NUMBER() OVER (ORDER BY ID) AS GroupID
    , ISNULL(LAG(ID) OVER (ORDER BY ID), 0) AS PrevID 
    FROM ##NumberedInput 
    WHERE Line IS NULL    
), cte_Answers AS 
(
    SELECT cBL.GroupID
    ,      NI.ID AS PersonID
    ,      NI.Line AS Anwsers
    ,      LEFT(Line, 1) AS Answer
    ,      SUBSTRING(Line, 2, LEN(Line)) AS Rest
    FROM ##NumberedInput NI
    INNER JOIN cte_BlankLines cBL ON NI.ID BETWEEN cBL.PrevID AND cBL.CurrentID
    WHERE Line IS NOT NULL

    UNION ALL

    SELECT GroupID
    ,      PersonID
    ,      Anwsers
    ,      LEFT(Rest, 1) AS Answer
    ,      SUBSTRING(Rest, 2, LEN(Rest)) AS Rest
    FROM cte_Answers
    WHERE LEN(Rest) > 0
)
SELECT GroupID, PersonID, Answer
INTO ##Answers
FROM cte_Answers
ORDER BY GroupID, PersonID, Answer


SELECT GroupID, Answer
FROM ##Answers
GROUP BY GroupID, Answer

--6335 is correct for part 1

;WITH cte_AnswerCountPerGroup AS (
    SELECT GroupID, Answer, COUNT(1) AS Nr
    FROM ##Answers
    GROUP BY GroupID, Answer
), cte_CountPerGroup AS
(
    SELECT GroupID, COUNT(1) AS Nr
    FROM (
        SELECT GroupID, PersonID FROM ##Answers GROUP BY GroupID, PersonID
        ) T
    GROUP BY GroupID
)
SELECT *
FROM cte_CountPerGroup CPG
INNER JOIn cte_AnswerCountPerGroup ACPG ON CPG.GroupID = ACPG.GroupID
                                       AND CPG.Nr = ACPG.Nr

--3392 is correct for Part 2

/*
DROP TABLE ##Input
DROP TABLE ##NumberedInput
DROP TABLE ##Answers
*/

