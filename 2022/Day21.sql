USE Test_WME

SET NOCOUNT ON

DECLARE @year VARCHAR(4) = '2022'
DECLARE @day VARCHAR(2)  = '21'

EXEC dbo.GetInput @year = @year, @day = @day
EXEC dbo.ParseInput @year = @year, @day = @day 

--SELECT TOP 10 * FROM ##Input
--SELECT TOP 10 * FROM ##InputInts
--SELECT TOP 10 * FROM ##InputNumbered
--SELECT TOP 10 * FROM ##InputGrid
--SELECT TOP 1000 * FROM ##InputSplit
--SELECT TOP 10 * FROM ##InputSplitCust
  
CREATE TABLE ##Monkeys (ID INT IDENTITY(1,1), Monkey VARCHAR(20), FirstPart VARCHAR(20), Operator VARCHAR(5), SecondPart VARCHAR(20))

INSERT ##Monkeys
(
    Monkey,
    FirstPart,
    Operator,
    SecondPart
)
SELECT [1],[2],[3],[4]
FROM (
  SELECT RowNr, PieceNr, Piece FROM ##InputSplit
) T
PIVOT (
    MAX(Piece) FOR PieceNr IN ([1],[2],[3],[4])
) PVT


WHILE EXISTS (SELECT 1 FROM ##Monkeys M WHERE TRY_CAST(M.FirstPart AS BIGINT) IS NULL)
BEGIN
    UPDATE M
    SET FirstPart  = CASE WHEN M1.ID IS NOT NULL THEN M1.FirstPart ELSE M.FirstPart END
    ,   SecondPart = CASE WHEN M2.ID IS NOT NULL THEN M2.FirstPart ELSE M.SecondPart END
    FROM ##Monkeys M
    LEFT JOIN ##Monkeys M1 ON M.FirstPart = M1.Monkey AND TRY_CAST(M1.FirstPart AS BIGINT) IS NOT NULL AND M1.Operator IS NULL
    LEFT JOIN ##Monkeys M2 ON M.SecondPart = M2.Monkey AND TRY_CAST(M2.FirstPart AS BIGINT) IS NOT NULL AND M2.Operator IS NULL

    UPDATE M
    SET FirstPart = CASE WHEN Operator = '+' THEN TRY_CAST(M.FirstPart AS BIGINT) + TRY_CAST(M.SecondPart AS BIGINT)
                         WHEN Operator = '-' THEN TRY_CAST(M.FirstPart AS BIGINT) - TRY_CAST(M.SecondPart AS BIGINT)
                         WHEN Operator = '*' THEN TRY_CAST(M.FirstPart AS BIGINT) * TRY_CAST(M.SecondPart AS BIGINT)
                         WHEN Operator = '/' THEN TRY_CAST(M.FirstPart AS BIGINT) / TRY_CAST(M.SecondPart AS BIGINT) END
    ,   Operator = NULL
    ,   SecondPart = NULL
    FROM ##Monkeys M
    WHERE TRY_CAST(M.FirstPart AS BIGINT) IS NOT NULL AND TRY_CAST(M.SecondPart AS BIGINT) IS NOT NULL

END

SELECT FirstPart AS Part1 FROM ##Monkeys M WHERE Monkey = 'root'

TRUNCATE TABLE ##Monkeys

INSERT ##Monkeys
(
    Monkey,
    FirstPart,
    Operator,
    SecondPart
)
SELECT [1],[2],[3],[4]
FROM (
  SELECT RowNr, PieceNr, Piece FROM ##InputSplit
) T
PIVOT (
    MAX(Piece) FOR PieceNr IN ([1],[2],[3],[4])
) PVT

DELETE FROM ##Monkeys WHERE Monkey = 'humn'

WHILE @@ROWCOUNT > 0
BEGIN
    UPDATE M
    SET FirstPart  = CASE WHEN M1.ID IS NOT NULL THEN M1.FirstPart ELSE M.FirstPart END
    ,   SecondPart = CASE WHEN M2.ID IS NOT NULL THEN M2.FirstPart ELSE M.SecondPart END
    FROM ##Monkeys M
    LEFT JOIN ##Monkeys M1 ON M.FirstPart = M1.Monkey AND TRY_CAST(M1.FirstPart AS BIGINT) IS NOT NULL AND M1.Operator IS NULL
    LEFT JOIN ##Monkeys M2 ON M.SecondPart = M2.Monkey AND TRY_CAST(M2.FirstPart AS BIGINT) IS NOT NULL AND M2.Operator IS NULL

    UPDATE M
    SET FirstPart = CASE WHEN Operator = '+' THEN TRY_CAST(M.FirstPart AS BIGINT) + TRY_CAST(M.SecondPart AS BIGINT)
                         WHEN Operator = '-' THEN TRY_CAST(M.FirstPart AS BIGINT) - TRY_CAST(M.SecondPart AS BIGINT)
                         WHEN Operator = '*' THEN TRY_CAST(M.FirstPart AS BIGINT) * TRY_CAST(M.SecondPart AS BIGINT)
                         WHEN Operator = '/' THEN TRY_CAST(M.FirstPart AS BIGINT) / TRY_CAST(M.SecondPart AS BIGINT) END
    ,   Operator = NULL
    ,   SecondPart = NULL
    FROM ##Monkeys M
    WHERE TRY_CAST(M.FirstPart AS BIGINT) IS NOT NULL AND TRY_CAST(M.SecondPart AS BIGINT) IS NOT NULL

END

-- Remove all the monkeys we no longer need
DELETE FROM M
FROM ##Monkeys M
LEFT JOIN ##Monkeys M2 ON M.Monkey = M2.FirstPart OR M.Monkey = M2.SecondPart
WHERE M2.ID IS NULL AND M.Monkey <> 'root'

-- Set the root to 0 so we can start calculating in reverse order
UPDATE ##Monkeys
SET Monkey = 0, Operator = '-'
WHERE Monkey = 'root'

WHILE EXISTS (SELECT 1 FROM ##Monkeys WHERE TRY_CAST(Monkey AS BIGINT) IS NULL)
BEGIN

    UPDATE M
    SET Monkey = CASE WHEN Operator = '+' THEN TRY_CAST(M.Monkey AS BIGINT) - TRY_CAST(M.FirstPart AS BIGINT)
                      WHEN Operator = '-' THEN TRY_CAST(M.FirstPart AS BIGINT) - TRY_CAST(M.Monkey AS BIGINT)
                      WHEN Operator = '*' THEN TRY_CAST(M.Monkey AS BIGINT) / TRY_CAST(M.FirstPart AS BIGINT)
                      WHEN Operator = '/' THEN TRY_CAST(M.FirstPart AS BIGINT) / TRY_CAST(M.Monkey AS BIGINT) END
    ,   Operator = NULL
    ,   FirstPart = NULL
    FROM ##Monkeys M
    WHERE TRY_CAST(M.Monkey AS BIGINT) IS NOT NULL AND TRY_CAST(M.FirstPart AS BIGINT) IS NOT NULL AND Operator IS NOT NULL

    UPDATE M
    SET Monkey = CASE WHEN Operator = '+' THEN TRY_CAST(M.Monkey AS BIGINT) - TRY_CAST(M.SecondPart AS BIGINT)
                      WHEN Operator = '-' THEN TRY_CAST(M.Monkey AS BIGINT) + TRY_CAST(M.SecondPart AS BIGINT)
                      WHEN Operator = '*' THEN TRY_CAST(M.Monkey AS BIGINT) / TRY_CAST(M.SecondPart AS BIGINT)
                      WHEN Operator = '/' THEN TRY_CAST(M.Monkey AS BIGINT) * TRY_CAST(M.SecondPart AS BIGINT) END
    ,   Operator = NULL
    ,   SecondPart = NULL
    FROM ##Monkeys M
    WHERE TRY_CAST(M.Monkey AS BIGINT) IS NOT NULL AND TRY_CAST(M.SecondPart AS BIGINT) IS NOT NULL AND Operator IS NOT NULL


    UPDATE M
    SET Monkey = ISNULL(ISNULL(M1.Monkey, M2.Monkey), M.Monkey)
    FROM ##Monkeys M
    LEFT JOIN ##Monkeys M1 ON M.Monkey = M1.FirstPart AND M1.Operator IS NULL        
    LEFT JOIN ##Monkeys M2 ON M.Monkey = M2.SecondPart AND M2.Operator IS NULL
    

END

SELECT Monkey AS Part2 FROM ##Monkeys M WHERE M.FirstPart = 'humn' OR M.SecondPart = 'humn'


DROP TABLE ##Monkeys

