USE Test_WME

SET NOCOUNT ON

DECLARE @year VARCHAR(4) = '2024'
DECLARE @day VARCHAR(2)  = '7'

EXEC dbo.GetInput @year = @year, @day = @day
EXEC dbo.ParseInput @year = @year, @day = @day 

--SELECT TOP 10 * FROM ##Input
--SELECT TOP 10 * FROM ##InputInts
--SELECT TOP 10 * FROM ##InputNumbered
--SELECT TOP 10 * FROM ##InputGrid
--SELECT TOP 10 * FROM ##InputSplit
--SELECT TOP 10 * FROM ##InputSplitCust


/*


;WITH cte_Op AS (
    SELECT 'Add' AS Op UNION SELECT 'Mul'
), cte_Calc AS (
    SELECT I1.RowNr
    ,      CAST(I1.Piece AS BIGINT) AS TargetValue
    ,      CAST(I2.Piece AS BIGINT) AS CurrentValue
    ,      2 AS CurrentPiece
    FROM ##InputSplit I1
    INNER JOIN ##InputSplit I2 ON I1.RowNr = I2.RowNr AND I2.PieceNr = 2
    WHERE I1.PieceNr = 1

    UNION ALL

    SELECT cC.RowNr
    ,      cC.TargetValue
    ,      CASE WHEN O.Op = 'Add' THEN cC.CurrentValue + CAST(I.Piece AS BIGINT)
                                  ELSE cC.CurrentValue * CAST(I.Piece AS BIGINT)
                                  END
    ,      CurrentPiece + 1
    FROM cte_Calc cC
    CROSS APPLY cte_Op O
    INNER JOIN ##InputSplit I ON cC. RowNr = I.RowNr AND I.PieceNr = cC.CurrentPiece + 1
    WHERE I.Ind IS NOT NULL AND CurrentValue < TargetValue
)
SELECT SUM(DISTINCT TargetValue) AS Part1
FROM cte_Calc
WHERE TargetValue = CurrentValue

*/

-- 9 min
-- 1985268524462 part1

CREATE TABLE ##Calibrations (ID INT IDENTITY(1,1), TargetValue BIGINT, CurrentValue BIGINT, PieceNr INT, RowNr INT, Ops VARCHAR(50))

INSERT ##Calibrations (TargetValue, CurrentValue, PieceNr, RowNr, Ops)
SELECT CAST(I1.Piece AS BIGINT)
,      CAST(I2.Piece AS BIGINT)
,      2
,      I1.RowNr
,      ''
FROM ##InputSplit I1
INNER JOIN ##InputSplit I2 ON I1.RowNr = I2.RowNr AND I2.PieceNr = 2
WHERE I1.PieceNr = 1

DECLARE @I INT = 2
DECLARE @Iterations INT
SELECT @Iterations = MAX(PieceNr) FROM ##InputSplit

CREATE TABLE ##Result (ID INT IDENTITY(1,1), RowNr INT, Ops VARCHAR(50))

WHILE @I <= @Iterations
BEGIN

    INSERT ##Calibrations (TargetValue, CurrentValue, PieceNr, RowNr, Ops)
    SELECT C.TargetValue, C.CurrentValue * CAST(I.Piece AS BIGINT), I.PieceNr, C.RowNr, C.Ops + 'M'
    FROM ##Calibrations C
    INNER JOIN ##InputSplit I ON C.RowNr = I.RowNr AND I.PieceNr = C.PieceNr + 1
    WHERE C.CurrentValue < C.TargetValue
    UNION
    SELECT C.TargetValue, CAST((CAST(C.CurrentValue AS VARCHAR(100)) + I.Piece) AS BIGINT), I.PieceNr, C.RowNr, C.Ops + 'C'
    FROM ##Calibrations C
    INNER JOIN ##InputSplit I ON C.RowNr = I.RowNr AND I.PieceNr = C.PieceNr + 1
    WHERE C.CurrentValue < C.TargetValue

    UPDATE C
    SET CurrentValue = C.CurrentValue + CAST(I.Piece AS BIGINT) 
    ,   PieceNr = C.PieceNr + 1
    ,   Ops = C.Ops + 'A'
    FROM ##Calibrations C
    INNER JOIN ##InputSplit I ON C.RowNr = I.RowNr AND I.PieceNr = C.PieceNr + 1
    WHERE C.CurrentValue < C.TargetValue AND C.PieceNr = @I

    INSERT ##Result (RowNr, Ops)
    SELECT RowNr, Ops
    FROM ##Calibrations
    WHERE CurrentValue = TargetValue

    DELETE FROM ##Calibrations
    WHERE RowNr IN (SELECT DISTINCT RowNr
                    FROM ##Calibrations
                    WHERE CurrentValue = TargetValue)

    SET @I = @I + 1
END

SELECT SUM(CAST(Piece AS BIGINT)) AS Part2
FROM ##InputSplit I
INNER JOIN (SELECT DISTINCT RowNr FROM ##Result) R ON I.RowNr = R.RowNr
WHERE PieceNr = 1


-- 30 min
-- 114789098519656 is too low
-- 150077713310053 is too high

--DROP TABLE ##Calibrations
--DROP TABLE ##Result

SELECT * FROM ##Result order BY RowNR
SELECT DISTINCT RowNr FROM ##Result order BY RowNR

SELECT * FROM ##Calibrations 
SELECT * FROM ##InputSplit 

SELECT SUM(CAST(Piece AS BIGINT)) AS Part2
FROM ##InputSplit I
INNER JOIN (SELECT DISTINCT RowNr FROM Result) R ON I.RowNr = R.RowNr
WHERE PieceNr = 1


CREATE TABLE ##TempResults (ID INT IDENTITY(1,1), RowNr INT, Result BIGINT)
--DROP TABLE ##TempResults
INSERT ##TempResults (RowNr, Result)
SELECT I1.RowNr, CAST(I1.Piece AS BIGINT)
FROM InputSplit I1
INNER JOIN Result R ON I1.RowNr = R.RowNr
WHERE I1.PieceNr = 2
GROUP BY I1.RowNr, I1.Piece

DECLARE @J INT = 2

WHILE @J < 13
BEGIN

    ;WITH cte_Ops AS (
        SELECT *, ROW_NUMBER() OVER (PARTITION BY RowNr ORDER BY ID) Rn
        FROM Result
    )
    UPDATE TR
    SET Result = CASE WHEN SUBSTRING(R.Ops, @J-1, 1) = 'A' THEN Result + CAST(I.Piece AS BIGINT)
                      WHEN SUBSTRING(R.Ops, @J-1, 1) = 'M' THEN Result * CAST(I.Piece AS BIGINT)
                      WHEN SUBSTRING(R.Ops, @J-1, 1) = 'C' THEN CAST(CAST(Result AS VARCHAR(100)) + I.Piece AS BIGINT) 
                ELSE Result
                END 
    FROM ##TempResults TR
    INNER JOIN InputSplit I ON TR.RowNr = I.RowNr AND I.PieceNr = @J + 1
    INNER JOIN cte_Ops R ON R.RowNr = TR.RowNr AND R.Rn = 1

    SET @J = @J + 1
END

SELECT SUM(Result) FROM ##TempResults TR
LEFT JOIN InputSplit I ON I.RowNr = TR.RowNr
WHERE PieceNr = 1 AND I.Piece <> TR.Result

select * from inputsplit where piecenr = 1 order by len(piece) desc ,piece desc
SELECT DISTINCT RowNR FROM REsult OrDER BY 1

SELECT MAX(PieceNr) FROM inputsplit
SELECT POWER(3,12)

SELECT * FROM Result R
INNER JOIN InputSplit I ON LEN(R.Ops) + 1 < I.PieceNr - 1 AND I.RowNr = R.RowNr


-- 150077710195188 is correct for part2 

--;WITH cte_Op AS (
--    SELECT 'Add' AS Op UNION SELECT 'Mul' UNION SELECT 'Com'
--), cte_Calc AS (
--    SELECT I1.RowNr
--    ,      CAST(I1.Piece AS BIGINT) AS TargetValue
--    ,      CAST(I2.Piece AS BIGINT) AS CurrentValue
--    ,      2 AS CurrentPiece
--    FROM ##InputSplit I1
--    INNER JOIN ##InputSplit I2 ON I1.RowNr = I2.RowNr AND I2.PieceNr = 2
--    WHERE I1.PieceNr = 1

--    UNION ALL

--    SELECT cC.RowNr
--    ,      cC.TargetValue
--    ,      CASE WHEN O.Op = 'Add' THEN cC.CurrentValue + CAST(I.Piece AS BIGINT)
--                WHEN O.Op = 'Mul' THEN cC.CurrentValue * CAST(I.Piece AS BIGINT)
--                                  ELSE CAST((CAST(cC.CurrentValue AS VARCHAR(50)) + I.Piece) AS BIGINT)
--                                  END
--    ,      CurrentPiece + 1
--    FROM cte_Calc cC
--    CROSS APPLY cte_Op O
--    INNER JOIN ##InputSplit I ON cC. RowNr = I.RowNr AND I.PieceNr = cC.CurrentPiece + 1
--    WHERE I.Ind IS NOT NULL AND CurrentValue < TargetValue
--)
--SELECT SUM(DISTINCT TargetValue) AS Part2
--FROM cte_Calc
--WHERE TargetValue = CurrentValue

