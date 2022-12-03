USE Test_WME

SET NOCOUNT ON

DECLARE @year VARCHAR(4) = '2015'
DECLARE @day VARCHAR(2)  = '7'

EXEC dbo.GetInput @year = @year, @day = @day
EXEC dbo.ParseInput @year = @year, @day = @day 


CREATE TABLE ##Gates (ID INT IDENTITY(1,1), Gate VARCHAR(10), Input1 VARCHAR(5), Input2 VARCHAR(5), Output VARCHAR(5))

INSERT ##Gates(Gate, Input1, Output)
SELECT 'SET', LEFT(Line, CHARINDEX(' ', Line) - 1), SUBSTRING(Line, CHARINDEX('->', Line) + 3, LEN(Line)) FROM ##Input WHERE Line NOT LIKE '%AND%' AND Line NOT LIKE '%OR%' AND Line NOT LIKE '%NOT%' AND Line NOT LIKE '%LSHIFT%' AND Line NOT LIKE '%RSHIFT%' 

INSERT ##Gates(Gate, Input1, Input2, Output)
SELECT 'AND', LEFT(Line, CHARINDEX(' ', Line) - 1), SUBSTRING(Line, CHARINDEX('AND', Line) + 3, LEN(Line) - CHARINDEX('->', Line)), SUBSTRING(Line, CHARINDEX('->', Line) + 3, LEN(Line)) FROM ##Input WHERE Line LIKE '%AND%' 

INSERT ##Gates(Gate, Input1, Input2, Output)
SELECT 'OR', LEFT(Line, CHARINDEX(' ', Line) - 1), SUBSTRING(Line, CHARINDEX('OR', Line) + 2, LEN(Line) - CHARINDEX('->', Line)), SUBSTRING(Line, CHARINDEX('->', Line) + 3, LEN(Line)) FROM ##Input WHERE Line LIKE '%OR%' 

INSERT ##Gates(Gate, Input1, Input2, Output)
SELECT 'LSHIFT', LEFT(Line, CHARINDEX(' ', Line) - 1), SUBSTRING(Line, CHARINDEX('LSHIFT', Line) + 6, LEN(Line) - CHARINDEX('->', Line) - 1), SUBSTRING(Line, CHARINDEX('->', Line) + 3, LEN(Line)) FROM ##Input WHERE Line LIKE '%LSHIFT%' 
UNION 
SELECT 'RSHIFT', LEFT(Line, CHARINDEX(' ', Line) - 1), SUBSTRING(Line, CHARINDEX('RSHIFT', Line) + 6, LEN(Line) - CHARINDEX('->', Line) - 1), SUBSTRING(Line, CHARINDEX('->', Line) + 3, LEN(Line)) FROM ##Input WHERE Line LIKE '%RSHIFT%' 

INSERT ##Gates(Gate, Input1, Output)
SELECT 'NOT', SUBSTRING(Line, CHARINDEX('NOT', Line) + 3, LEN(Line) - CHARINDEX('->', Line)), SUBSTRING(Line, CHARINDEX('->', Line) + 3, LEN(Line)) FROM ##Input WHERE Line LIKE '%NOT%' 


UPDATE ##Gates
SET Input1 = LTRIM(RTRIM(Input1))
,   Input2 = LTRIM(RTRIM(Input2))
,   Output = LTRIM(RTRIM(Output))


CREATE TABLE ##Outputs (ID INT IDENTITY(1,1), Name VARCHAR(5), Value INT)

INSERT ##Outputs (Name) 
SELECT DISTINCT Output FROM ##Gates

WHILE ((SELECT COUNT(1) FROM ##Outputs WHERE Value IS NULL) > 0)
BEGIN

    ;WITH cte_Update AS (
        SELECT G.Gate, ISNULL(CAST(O1.Value AS VARCHAR(15)), G.Input1) AS I1, ISNULL(CAST(O2.Value AS VARCHAR(15)), G.Input2) AS I2, G.Output 
        FROM ##Gates G
            LEFT JOIN ##Outputs O1 ON G.Input1 = O1.Name
            LEFT JOIN ##Outputs O2 ON G.Input2 = O2.Name
            INNER JOIN ##Outputs O3 ON G.Output = O3.Name
        WHERE O3.Value IS NULL
            AND TRY_CAST(ISNULL(CAST(O1.Value AS VARCHAR(15)), G.Input1) AS INT) IS NOT NULL
            AND (TRY_CAST(ISNULL(CAST(O2.Value AS VARCHAR(15)), G.Input2) AS INT) IS NOT NULL OR Gate IN ('NOT','SET'))
    )
    UPDATE O
    SET O.Value = CASE WHEN T.Gate = 'AND' THEN CAST(T.I1 AS INT) & CAST(T.I2 AS INT)
                       WHEN T.Gate = 'OR' THEN CAST(T.I1 AS INT) | CAST(T.I2 AS INT)
                       WHEN T.Gate = 'NOT' THEN CASE WHEN ~CAST(T.I1 AS INT) >= 0 THEN ~CAST(T.I1 AS INT) ELSE 65536 + ~CAST(T.I1 AS INT) END
                       --WHEN T.Gate = 'LSHIFT' THEN dbo.Binary2Decimal(SUBSTRING(dbo.Decimal2Binary(CAST(T.I1 AS INT), 16), CAST(T.I2 AS INT) + 1, 32) + LEFT(dbo.Decimal2Binary(CAST(T.I1 AS INT), 16), CAST(T.I2 AS INT)))
                       --WHEN T.Gate = 'RSHIFT' THEN dbo.Binary2Decimal(SUBSTRING(dbo.Decimal2Binary(CAST(T.I1 AS INT), 16), 16 - CAST(T.I2 AS INT) + 1, 32) + LEFT(dbo.Decimal2Binary(CAST(T.I1 AS INT), 16), 16 - CAST(T.I2 AS INT)))

                       WHEN T.Gate = 'LSHIFT' THEN dbo.Binary2Decimal(SUBSTRING(dbo.Decimal2Binary(CAST(T.I1 AS INT), 16), CAST(T.I2 AS INT) + 1, 32) + LEFT('0000000000000000', CAST(T.I2 AS INT)))
                       WHEN T.Gate = 'RSHIFT' THEN dbo.Binary2Decimal(LEFT('0000000000000000', 16 - CAST(T.I2 AS INT) + 1) + LEFT(dbo.Decimal2Binary(CAST(T.I1 AS INT), 16), 16 - CAST(T.I2 AS INT)))

                       WHEN T.Gate = 'SET' THEN T.I1
           END
    FROM ##Outputs O
    INNER JOIN cte_Update T ON O.Name = T.Output

END

SELECT [Name], [Value] AS Part1 FROM ##Outputs WHERE Name = 'a'

--3176 is correct for part 1

-- Prep for part 2

UPDATE G 
SET Input1 = T.Part1
FROM ##Gates G
CROSS APPLY (SELECT [Value] AS Part1 FROM ##Outputs WHERE [Name] = 'a') T
WHERE G.Output = 'b'

UPDATE ##Outputs SET [Value] = NULL

--Rinse, repeat

--SELECT * FROM ##Gates WHERE Gate = 'SET'

WHILE ((SELECT COUNT(1) FROM ##Outputs WHERE Value IS NULL) > 0)
BEGIN

    ;WITH cte_Update AS (
        SELECT G.Gate, ISNULL(CAST(O1.Value AS VARCHAR(15)), G.Input1) AS I1, ISNULL(CAST(O2.Value AS VARCHAR(15)), G.Input2) AS I2, G.Output 
        FROM ##Gates G
            LEFT JOIN ##Outputs O1 ON G.Input1 = O1.Name
            LEFT JOIN ##Outputs O2 ON G.Input2 = O2.Name
            INNER JOIN ##Outputs O3 ON G.Output = O3.Name
        WHERE O3.Value IS NULL
            AND TRY_CAST(ISNULL(CAST(O1.Value AS VARCHAR(15)), G.Input1) AS INT) IS NOT NULL
            AND (TRY_CAST(ISNULL(CAST(O2.Value AS VARCHAR(15)), G.Input2) AS INT) IS NOT NULL OR Gate IN ('NOT','SET'))
    )
    UPDATE O
    SET O.Value = CASE WHEN T.Gate = 'AND' THEN CAST(T.I1 AS INT) & CAST(T.I2 AS INT)
                       WHEN T.Gate = 'OR' THEN CAST(T.I1 AS INT) | CAST(T.I2 AS INT)
                       WHEN T.Gate = 'NOT' THEN CASE WHEN ~CAST(T.I1 AS INT) >= 0 THEN ~CAST(T.I1 AS INT) ELSE 65536 + ~CAST(T.I1 AS INT) END
                       --WHEN T.Gate = 'LSHIFT' THEN dbo.Binary2Decimal(SUBSTRING(dbo.Decimal2Binary(CAST(T.I1 AS INT), 16), CAST(T.I2 AS INT) + 1, 32) + LEFT(dbo.Decimal2Binary(CAST(T.I1 AS INT), 16), CAST(T.I2 AS INT)))
                       --WHEN T.Gate = 'RSHIFT' THEN dbo.Binary2Decimal(SUBSTRING(dbo.Decimal2Binary(CAST(T.I1 AS INT), 16), 16 - CAST(T.I2 AS INT) + 1, 32) + LEFT(dbo.Decimal2Binary(CAST(T.I1 AS INT), 16), 16 - CAST(T.I2 AS INT)))

                       WHEN T.Gate = 'LSHIFT' THEN dbo.Binary2Decimal(SUBSTRING(dbo.Decimal2Binary(CAST(T.I1 AS INT), 16), CAST(T.I2 AS INT) + 1, 32) + LEFT('0000000000000000', CAST(T.I2 AS INT)))
                       WHEN T.Gate = 'RSHIFT' THEN dbo.Binary2Decimal(LEFT('0000000000000000', 16 - CAST(T.I2 AS INT) + 1) + LEFT(dbo.Decimal2Binary(CAST(T.I1 AS INT), 16), 16 - CAST(T.I2 AS INT)))

                       WHEN T.Gate = 'SET' THEN T.I1
           END
    FROM ##Outputs O
    INNER JOIN cte_Update T ON O.Name = T.Output

END

SELECT [Name], [Value] AS Part2 FROM ##Outputs WHERE Name = 'a'

--14710 is correct for part 2

DROP TABLE ##Outputs
DROP TABLE ##Gates


