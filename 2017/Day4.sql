use Test_WME

CREATE TABLE Input (Txt NVARCHAR(MAX));

BULK INSERT Input
FROM 'D:\Wilfred\AdventOfCode\2017\input4.txt'
WITH (ROWTERMINATOR = '0x0A');


--SELECT * FROM Input 




CREATE TABLE #Txts (ID INT IDENTITY(1,1), Line INT, Word NVARCHAR(50))


    ;WITH cte_Split AS (
        SELECT 1 AS RowLvl,
               ROW_NUMBER() OVER (ORDER BY (SELECT 0)) AS LineNr,
               LEFT(Txt, CHARINDEX(' ', Txt)) AS Word,
               SUBSTRING(Txt, CHARINDEX(' ', Txt) + 1, LEN(Txt)) + ' ' AS Remainder
        FROM input
        UNION ALL
        SELECT RowLvl + 1,
            LineNr,
            LEFT(Remainder, CHARINDEX(' ', Remainder)),
            SUBSTRING(Remainder, CHARINDEX(' ', Remainder) + 1, LEN(Remainder)) 
        FROM cte_Split 
        WHERE LEN(LTRIM(Remainder)) > 0
     )
     INSERT #Txts (Line, Word)
     SELECT LineNr, Word--, Remainder
     FROM cte_Split
     OPTION (MAXRECURSION 10000)


--DROP TABLE Input
--DROP TABLE #Nrs

SELECT DISTINCT T1.Line FROM #Txts T1
EXCEPT
SELECT DISTINCT T1.Line
FROM #Txts T1
INNER JOIN #Txts T2 ON T1.Word = T2.Word AND T1.Line = T2.Line AND T1.ID <> T2.ID



;WITH cte_SortedWords AS (
    SELECT Line,
      ID,
      Word, 
      (
        SELECT
          chr
        FROM
          (SELECT TOP(LEN(Word)) 
             SUBSTRING(Word,ROW_NUMBER() OVER(ORDER BY 1/0),1)
           FROM sys.messages) A(Chr)
           ORDER by chr
           FOR XML PATH(''), type).value('.', 'varchar(max)'
          ) SortedCol
    FROM #Txts
)
SELECT DISTINCT T1.Line FROM #Txts T1
EXCEPT
SELECT DISTINCT T1.Line
FROM cte_SortedWords T1
INNER JOIN cte_SortedWords T2 ON T1.SortedCol = T2.SortedCol AND T1.Line = T2.Line AND T1.ID <> T2.ID