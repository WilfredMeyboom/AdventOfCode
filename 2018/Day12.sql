SET NOCOUNT ON

CREATE TABLE #Notes (ID INT IDENTITY(1,1), Pattern VARCHAR(5), Consequence CHAR(1))

INSERT #Notes (Pattern, Consequence)  VALUES
('####.','#'),('##.#.','.'),('.##.#','.'),('..##.','.'),('.....','.'),('.#.#.','#'),('.###.','.'),('.#.##','.'),('#.#.#','.'),('.#...','#'),('#..#.','#'),('....#','.'),('###..','.'),('##..#','#'),('#..##','#'),('..#..','.'),
('#####','.'),('.####','#'),('#.##.','#'),('#.###','#'),('...#.','.'),('###.#','.'),('#.#..','#'),('##...','#'),('...##','#'),('.#..#','.'),('#....','.'),('#...#','.'),('.##..','#'),('..###','.'),('##.##','.'),('..#.#','#')
/*
INSERT #Notes (Pattern, Consequence)  VALUES 
('...##','#'),('..#..','#'),('.#...','#'),('.#.#.','#'),('.#.##','#'),('.##..','#'),('.####','#'),('#.#.#','#'),('#.###','#'),('##.#.','#'),('##.##','#'),('###..','#'),('###.#','#'),('####.','#')
*/

CREATE TABLE #Plants (ID BIGINT IDENTITY(1,1), Nr BIGINT PRIMARY KEY, Plant CHAR(1), SurroundingPattern VARCHAR(5))

DECLARE @InitialState VARCHAR(200) = '##.#..########..##..#..##.....##..###.####.###.##.###...###.##..#.##...#.#.#...###..###.###.#.#'
--DECLARE @InitialState VARCHAR(200) = '#..#.#..##......###...###'

;WITH cte_Plants AS (
    SELECT LEFT(@InitialState, 1) AS Plant
    ,      SUBSTRING(@InitialState, 2, LEN(@InitialState)) AS Remainder
    UNION ALL
    SELECT LEFT(Remainder, 1)
    ,      SUBSTRING(Remainder, 2, LEN(Remainder))
    FROM cte_Plants
    WHERE LEN(Remainder) > 0
)
INSERT #Plants (Nr, Plant)
SELECT ROW_NUMBER() OVER (ORDER BY (SELECT 0)) -1
,      Plant        
FROM cte_Plants

IF ((SELECT Plant FROM #Plants WHERE Nr = (SELECT MIN(Nr) FROM #Plants)) = '#' 
 OR (SELECT Plant FROM #Plants WHERE Nr = (SELECT MIN(Nr) FROM #Plants) + 1) = '#'
 OR (SELECT Plant FROM #Plants WHERE Nr = (SELECT MIN(Nr) FROM #Plants) + 2) = '#'
 OR (SELECT Plant FROM #Plants WHERE Nr = (SELECT MIN(Nr) FROM #Plants) + 3) = '#')
INSERT #Plants (Nr, Plant) SELECT MIN(Nr) -1, '.' FROM #Plants UNION SELECT MIN(Nr) -2, '.' FROM #Plants UNION SELECT MIN(Nr) -3, '.' FROM #Plants UNION SELECT MIN(Nr) -4, '.' FROM #Plants 

IF ((SELECT Plant FROM #Plants WHERE Nr = (SELECT MAX(Nr) FROM #Plants)) = '#' 
 OR (SELECT Plant FROM #Plants WHERE Nr = (SELECT MAX(Nr) FROM #Plants) - 1) = '#'
 OR (SELECT Plant FROM #Plants WHERE Nr = (SELECT MAX(Nr) FROM #Plants) - 2) = '#'
 OR (SELECT Plant FROM #Plants WHERE Nr = (SELECT MAX(Nr) FROM #Plants) - 3) = '#')
INSERT #Plants (Nr, Plant) SELECT MAX(Nr) +1, '.' FROM #Plants UNION SELECT MAX(Nr) +2, '.' FROM #Plants UNION SELECT MAX(Nr) +3, '.' FROM #Plants UNION SELECT MAX(Nr) +4, '.' FROM #Plants


;WITH cte_Patterns AS (
    SELECT Mid.Nr, L2.Plant + L1.Plant + Mid.Plant + R1.Plant + R2.Plant AS Pattern
    FROM #Plants Mid
    INNER JOIN #Plants L1 ON Mid.Nr = L1.Nr + 1
    INNER JOIN #Plants L2 ON Mid.Nr = L2.Nr + 2
    INNER JOIN #Plants R1 ON Mid.Nr = R1.Nr - 1
    INNER JOIN #Plants R2 ON Mid.Nr = R2.Nr - 2
)
UPDATE P
SET SurroundingPattern = cP.Pattern
FROM #Plants P
INNER JOIN cte_Patterns cP ON P.Nr = cP.Nr

--SELECT * FROM #Plants ORDER BY Nr

DECLARE @Step BIGINT = 0
DECLARE @PrevValue BIGINT = 0
DECLARE @Value BIGINT = 0

WHILE (@Step < 50000000000)
BEGIN
    
    ;WITH cte_Generation AS (
        SELECT P.Nr, N.Consequence
        FROM #Plants P 
        INNER JOIN #Notes N ON N.Pattern = P.SurroundingPattern
    )
    UPDATE P
    SET Plant = ISNULL(G.Consequence, '.')
    FROM #Plants P
    LEFT JOIN cte_Generation G ON G.Nr = P.Nr

    IF ((SELECT Plant FROM #Plants WHERE Nr = (SELECT MIN(Nr) FROM #Plants)) = '#' 
     OR (SELECT Plant FROM #Plants WHERE Nr = (SELECT MIN(Nr) FROM #Plants) + 1) = '#'
     OR (SELECT Plant FROM #Plants WHERE Nr = (SELECT MIN(Nr) FROM #Plants) + 2) = '#'
     OR (SELECT Plant FROM #Plants WHERE Nr = (SELECT MIN(Nr) FROM #Plants) + 3) = '#')
    INSERT #Plants (Nr, Plant) SELECT MIN(Nr) -1, '.' FROM #Plants UNION SELECT MIN(Nr) -2, '.' FROM #Plants UNION SELECT MIN(Nr) -3, '.' FROM #Plants UNION SELECT MIN(Nr) -4, '.' FROM #Plants 

    IF ((SELECT Plant FROM #Plants WHERE Nr = (SELECT MAX(Nr) FROM #Plants)) = '#' 
     OR (SELECT Plant FROM #Plants WHERE Nr = (SELECT MAX(Nr) FROM #Plants) - 1) = '#'
     OR (SELECT Plant FROM #Plants WHERE Nr = (SELECT MAX(Nr) FROM #Plants) - 2) = '#'
     OR (SELECT Plant FROM #Plants WHERE Nr = (SELECT MAX(Nr) FROM #Plants) - 3) = '#')
    INSERT #Plants (Nr, Plant) SELECT MAX(Nr) +1, '.' FROM #Plants UNION SELECT MAX(Nr) +2, '.' FROM #Plants UNION SELECT MAX(Nr) +3, '.' FROM #Plants UNION SELECT MAX(Nr) +4, '.' FROM #Plants

    ;WITH cte_Patterns AS (
        SELECT Mid.Nr, L2.Plant + L1.Plant + Mid.Plant + R1.Plant + R2.Plant AS Pattern
        FROM #Plants Mid
        INNER JOIN #Plants L1 ON Mid.Nr = L1.Nr + 1
        INNER JOIN #Plants L2 ON Mid.Nr = L2.Nr + 2
        INNER JOIN #Plants R1 ON Mid.Nr = R1.Nr - 1
        INNER JOIN #Plants R2 ON Mid.Nr = R2.Nr - 2
    )
    UPDATE P
    SET SurroundingPattern = cP.Pattern
    FROM #Plants P
    INNER JOIN cte_Patterns cP ON P.Nr = cP.Nr


    SET @Step = @Step + 1

    IF @Step % 1000 = 0 
    BEGIN
        
        SELECT @Value = SUM(CASE WHEN Plant = '#' THEN Nr ELSE 0 END) FROM #Plants
                
        PRINT CAST(@Step AS VARCHAR(20))      + '|' + 
              CAST(@Value AS VARCHAR(20))     + '|' + 
              CAST(@PrevValue AS VARCHAR(20)) + '|' + 
              CAST(@Value - @PrevValue AS VARCHAR(20))

        SET @PrevValue = @Value

    END
    --SELECT Plant FROM #Plants ORDER BY Nr
END


/*
SELECT * FROM #Plants ORDER BY Nr


SELECT SUM(CASE WHEN Plant = '#' THEN Nr ELSE 0 END)
FROM #Plants
*/
--1967 too low

/*

DROP TABLE #Notes
DROP TABLE #Plants

*/

/*

1000|45120|0|45120
2000|90120|45120|45000
3000|135120|90120|45000
4000|180120|135120|45000

*/

SELECT (4000 - 1000) * 45 + 45120

SELECT (50000000000 - 1000) * 45 + 45120

--2249999955045120 Too high