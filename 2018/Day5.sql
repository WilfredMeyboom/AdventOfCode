
use Test_WME

CREATE TABLE Input (Nr NVARCHAR(MAX));

BULK INSERT Input
FROM 'D:\Wilfred\AdventOfCode\input5.txt'
WITH (ROWTERMINATOR = '0x0A');

--SELECT *, LEN(Nr) FROM Input

CREATE TABLE #Letters (Id INT IDENTITY(1,1), Letter CHAR)

    ;WITH cte_Split AS (
        SELECT 1 AS RowLvl,
               LEFT(Nr, 1) AS Letter,
               SUBSTRING(Nr, 2, LEN(Nr)) AS Remainder
               FROM Input
        UNION ALL
        SELECT RowLvl + 1,
            LEFT(Remainder, 1),
            SUBSTRING(Remainder, 2, LEN(Remainder)) 
        FROM cte_Split
        WHERE LEN(Remainder) > 25000
     )
     INSERT #Letters (Letter)
     SELECT Letter FROM cte_Split OPTION (MAXRECURSION 30000)


DECLARE @Part2 VARCHAR(MAX)

SELECT @Part2 = SUBSTRING(Nr, 25001, 25000) FROM Input

    ;WITH cte_Split AS (
        SELECT 1 AS RowLvl,
               LEFT(@Part2, 1) AS Letter,
               SUBSTRING(@Part2, 2, LEN(@Part2)) AS Remainder
        UNION ALL
        SELECT RowLvl + 1,
            LEFT(Remainder, 1),
            SUBSTRING(Remainder, 2, LEN(Remainder)) 
        FROM cte_Split
        WHERE LEN(Remainder) > 0
     )
     INSERT #Letters (Letter)
     SELECT Letter FROM cte_Split OPTION (MAXRECURSION 30000)

SELECT * FROM #Letters
WHERE Id IN (23802, 26263)

/*
SELECT @@ROWCOUNT

DECLARE @Offset INT = 1

WHILE (@@ROWCOUNT > 0)
BEGIN

SET @Offset = CASE WHEN @Offset = 1 THEN 0 ELSE 1 END    

    ;WITH cte_NumberSet AS (
        SELECT Id,
               Letter,
               ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS Nr
        FROM #Letters
    ), cte_ToBeDeleted AS (
        SELECT NS1.Id AS Id1, NS2.Id AS Id2
        FROM cte_NumberSet NS1
        INNER JOIN cte_NumberSet NS2 ON NS1.Nr = NS2.Nr - 1
        WHERE ABS(ASCII(NS1.Letter) - ASCII(NS2.Letter)) = 32
        AND NS1.Nr % 2 = @Offset
   )
   DELETE FROM #Letters
   WHERE Id IN (SELECT Id1 FROM cte_ToBeDeleted)
   OR Id IN (SELECT Id2 FROM cte_ToBeDeleted)

END

SELECT * FROM #Letters
*/
--DROP TABLE Input
--DROP TABLE #Letters

CREATE TABLE #Alphabet (Letter CHAR)
INSERT #Alphabet VALUES ('a'),('b'),('c'),('d'),('e'),('f'),('g'),('h'),('i'),('j'),('k'),('l'),('m'),('n'),('o'),('p'),('q'),('r'),('s'),('t'),('u'),('v'),('w'),('x'),('y'),('z')

CREATE TABLE #LettersPerPolymer (Id INT IDENTITY(1,1), PolymerId CHAR, Letter CHAR)

INSERT #LettersPerPolymer (PolymerId, Letter)
SELECT A.Letter, L.Letter
FROM #Letters L
CROSS APPLY #Alphabet A
ORDER BY A.Letter, L.Id

DELETE FROM #LettersPerPolymer WHERE PolymerId = Letter

--SELECT * FROM #LettersPerPolymer

SELECT @@ROWCOUNT

DECLARE @Offset INT = 1

WHILE (@@ROWCOUNT > 0)
BEGIN

SET @Offset = CASE WHEN @Offset = 1 THEN 0 ELSE 1 END    

    ;WITH cte_NumberSet AS (
        SELECT Id,
               PolymerId,
               Letter,
               ROW_NUMBER() OVER (PARTITION BY PolymerId ORDER BY Id) AS Nr
        FROM #LettersPerPolymer
    ), cte_ToBeDeleted AS (
        SELECT NS1.Id AS Id1, NS2.Id AS Id2
        FROM cte_NumberSet NS1
        INNER JOIN cte_NumberSet NS2 ON NS1.Nr = NS2.Nr - 1 AND NS1.PolymerId = NS2.PolymerId
        WHERE ABS(ASCII(NS1.Letter) - ASCII(NS2.Letter)) = 32
        AND NS1.Nr % 2 = @Offset
   )
   DELETE FROM #LettersPerPolymer
   WHERE Id IN (SELECT Id1 FROM cte_ToBeDeleted)
   OR Id IN (SELECT Id2 FROM cte_ToBeDeleted)

END


SELECT PolymerId, COUNT(1) FROM #LettersPerPolymer GROUP BY PolymerId ORDER BY 2