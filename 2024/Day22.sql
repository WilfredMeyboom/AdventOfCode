USE Test_WME

SET NOCOUNT ON

DECLARE @year VARCHAR(4) = '2024'
DECLARE @day VARCHAR(2)  = '22'

EXEC dbo.GetInput @year = @year, @day = @day
EXEC dbo.ParseInput @year = @year, @day = @day 

--SELECT TOP 10 * FROM ##Input
--SELECT TOP 10 * FROM ##InputInts
--SELECT TOP 10 * FROM ##InputNumbered
--SELECT TOP 10 * FROM ##InputGrid
--SELECT TOP 10 * FROM ##InputSplit
--SELECT TOP 10 * FROM ##InputSplitCust

CREATE TABLE ##SecretNumber (ID INT IDENTITY(1,1), StartSecretNr BIGINT, SecretNumber BIGINT)
CREATE TABLE ##SecretNumberHistory (ID INT IDENTITY(1,1), RefID INT, StartSecretNr BIGINT, SecretNumber BIGINT, Iteration INT)

INSERT ##SecretNumber (StartSecretNr, SecretNumber)
SELECT Line, Line FROM ##Input

DECLARE @Cnt INT = 0 

INSERT ##SecretNumberHistory (Iteration, RefID, StartSecretNr, SecretNumber)
SELECT @Cnt, ID, StartSecretNr, SecretNumber FROM ##SecretNumber

WHILE @Cnt < 2000
BEGIN
--Do work
    UPDATE ##SecretNumber
    SET SecretNumber = ((SecretNumber * 64) ^ SecretNumber) % 16777216

    UPDATE ##SecretNumber
    SET SecretNumber = ((SecretNumber / 32) ^ SecretNumber) % 16777216

    UPDATE ##SecretNumber
    SET SecretNumber = ((SecretNumber * 2048) ^ SecretNumber) % 16777216

    SET @Cnt = @Cnt + 1

    INSERT ##SecretNumberHistory (Iteration, RefID, StartSecretNr, SecretNumber)
    SELECT @Cnt, ID, StartSecretNr, SecretNumber FROM ##SecretNumber

END

SELECT SUM(SecretNumber) AS Part1 FROM ##SecretNumber
-- 19854248602 is correct for part1


;WITH cte_Seq AS (
    SELECT RefID
    ,      SecretNumber
    ,      Iteration
    ,      CAST(CAST(RIGHT(SecretNumber, 1) AS INT)
            - CAST(RIGHT(LEAD(SecretNumber) OVER (PARTITION BY RefID ORDER BY Iteration), 1) AS INT) AS VARCHAR(3)) +
    ','+   CAST(CAST(RIGHT(LEAD(SecretNumber) OVER (PARTITION BY RefID ORDER BY Iteration), 1) AS INT)
            - CAST(RIGHT(LEAD(SecretNumber, 2) OVER (PARTITION BY RefID ORDER BY Iteration), 1) AS INT) AS VARCHAR(3)) +
    ','+   CAST(CAST(RIGHT(LEAD(SecretNumber, 2) OVER (PARTITION BY RefID ORDER BY Iteration), 1) AS INT)
            - CAST(RIGHT(LEAD(SecretNumber, 3) OVER (PARTITION BY RefID ORDER BY Iteration), 1) AS INT) AS VARCHAR(3)) +
    ','+   CAST(CAST(RIGHT(LEAD(SecretNumber, 3) OVER (PARTITION BY RefID ORDER BY Iteration), 1) AS INT)
            - CAST(RIGHT(LEAD(SecretNumber, 4) OVER (PARTITION BY RefID ORDER BY Iteration), 1) AS INT) AS VARCHAR(3)) AS Seq
    ,      CAST(RIGHT(LEAD(SecretNumber, 4) OVER (PARTITION BY RefID ORDER BY Iteration), 1) AS INT) AS BananaProfit
    FROM ##SecretNumberHistory
), cte_NumberedSeq AS (
    SELECT RefID, Seq, BananaProfit
    , ROW_NUMBER() OVER (PARTITION BY RefID, Seq ORDER BY Iteration) AS RN
    FROM cte_Seq
    WHERE Seq IS NOT NULL
)
SELECT Seq, SUM(BananaProfit) AS Part2
FROM cte_NumberedSeq
WHERE RN = 1
GROUP BY Seq
ORDER BY 2 DESC


/*

13120 is too high
776 is too low

DROP TABLE ##SecretNumber
DROP TABLE ##SecretNumberHistory


*/

