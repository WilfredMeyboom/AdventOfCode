use Test_WME

DECLARE @Input BIGINT = 3005290


CREATE TABLE ##Elves (ElfNr INT)

INSERT ##Elves
SELECT TOP (@Input) ROW_NUMBER() OVER (ORDER BY (SELECT 0)) FROM sys.messages T1 CROSS APPLY sys.messages T2

--SELECT TOP 10 * FROM ##Elves

CREATE INDEX UQ_Elves ON ##Elves (ElfNr)

DECLARE @PreviousCount INT = @Input
/*
WHILE (SELECT COUNT(1) FROM ##Elves) > 1
BEGIN 

    SELECT @PreviousCount = COUNT(1) FROM ##Elves

    ;WITH cte_Elf AS (
        SELECT ROW_NUMBER() OVER (ORDER BY ElfNr) AS TempNr
        ,      ElfNr 
        FROM ##Elves
    )
    DELETE E   
    FROM ##Elves E 
    INNER JOIN cte_Elf cE ON E.ElfNr = cE.ElfNr
    WHERE cE.TempNr % 2 = 0

    IF @PreviousCount % 2 = 1 DELETE FROM ##Elves WHERE ElfNr = (SELECT MIN(ElfNr) FROM ##Elves)


END
*/


--Part II


--Analyse

DECLARE @Counter INT = 1
DECLARE @ElvesLeft INT = @Input

--WHILE (SELECT MAX(ElfNr) FROM ##Elves) >= @Counter
--BEGIN 

--    SELECT @ElvesLeft = COUNT(1) FROM ##Elves

--    ;WITH cte_Elf AS (
--        SELECT ROW_NUMBER() OVER (ORDER BY ElfNr) - 1 AS TempNr
--        ,      ElfNr 
--        FROM ##Elves
--    ), cte_KilledElf AS (
--        SELECT ce2.ElfNr
--        FROM cte_Elf ce1
--        INNER JOIN cte_Elf ce2 ON (ce1.TempNr + (@ElvesLeft / 2)) % @ElvesLeft = ce2.TempNr 
--        WHERE ce1.ElfNr = @Counter
--    )
--    DELETE E 
--    FROM ##Elves E 
--    WHERE E.ElfNr = (SELECT ElfNr FROM cte_KilledElf)
    
--    SELECT @Counter = MIN(ElfNr) FROM ##Elves WHERE ElfNr > @Counter

--END

--    SELECT * FROM ##Elves

/*

Ok, het blijkt dus dat die lijst in twee helften verdeeld en per lijst een MOD 3 pakt

*/

--DECLARE @ElvesLeft INT = @Input

WHILE (SELECT COUNT(1) FROM ##Elves) > 2
BEGIN

    SELECT @ElvesLeft = COUNT(1) FROM ##Elves

    IF @ElvesLeft % 3 = 0
    BEGIN
        ;WITH cte_Elf AS (
            SELECT ROW_NUMBER() OVER (ORDER BY ElfNr) AS TempNr
            ,      ElfNr 
            FROM ##Elves
        )
        DELETE E   
        FROM ##Elves E 
        INNER JOIN cte_Elf cE ON E.ElfNr = cE.ElfNr
        WHERE cE.TempNr % 3 <> 0
    END
    ELSE
    BEGIN
        ;WITH cte_Elf AS (
            SELECT ROW_NUMBER() OVER (ORDER BY ElfNr) AS TempNr
            ,      ElfNr 
            FROM ##Elves
        )
        DELETE E   
        FROM ##Elves E 
        INNER JOIN cte_Elf cE ON E.ElfNr = cE.ElfNr
        WHERE (cE.TempNr % 3 <> @ElvesLeft % 3 AND TempNr < @ElvesLeft / 2)
           OR (cE.TempNr % 3 = 1 AND @ElvesLeft % 3 = 1 AND TempNr > @ElvesLeft / 2)
           OR (cE.TempNr % 3 = 2 AND @ElvesLeft % 3 = 2 AND TempNr > @ElvesLeft / 2)
           OR (cE.TempNr % 3 = 0 AND TempNr > @ElvesLeft / 2)          
    END

--    SELECT * FROM ##Elves

END


SELECT * FROM ##Elves

-- 1816277 is correct for part 1

-- 1410967 is correct for part 2

DROP TABLE ##Elves
/*

2 Elves -> Elf 1
3 Elves -> Elf 3
4 Elves -> Elf 1
5 Elves -> Elf 3
6 Elves -> Elf 5
7 Elves -> Elf 7
8 Elves -> Elf 1
9 Elves -> Elf 3


2 Elves -> Elf 1
3 Elves -> Elf 3
4 Elves -> Elf 1
5 Elves -> Elf 2
6 Elves -> Elf 3
7 Elves -> Elf 5
8 Elves -> Elf 7
9 Elves -> Elf 9


*/

