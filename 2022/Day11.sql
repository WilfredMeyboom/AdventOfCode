USE Test_WME

SET NOCOUNT ON

DECLARE @year VARCHAR(4) = '2022'
DECLARE @day VARCHAR(2)  = '11'

EXEC dbo.GetInput @year = @year, @day = @day
EXEC dbo.ParseInput @year = @year, @day = @day 

--SELECT TOP 10 * FROM ##Input
--SELECT TOP 10 * FROM ##InputInts
--SELECT TOP 10 * FROM ##InputNumbered
--SELECT TOP 10 * FROM ##InputGrid
--SELECT TOP 1000 * FROM ##InputSplit
--SELECT TOP 10 * FROM ##InputSplitCust
  
CREATE TABLE ##Monkey (ID INT IDENTITY(1,1), Monkey INT, Op1 VARCHAR(3), Op2 CHAR(1), Op3 VARCHAR(3), Test INT, ToMonkey1 INT, ToMonkey2 INT)
CREATE TABLE ##Items (ID INT IDENTITY(1,1), WorryLevel BIGINT, Monkey INT)
CREATE TABLE ##Rounds (ID INT IDENTITY(1,1), RoundNr INT, Monkey INT, NrOfItems INT)

-- Parse monkey information
;WITH cte_Pivot AS (
    SELECT RowNr, [1],[2],[3],[4],[5],[6],[7],[8],[9],[10]

    FROM (
        SELECT RowNr, PieceNr, Piece FROM ##InputSplit
    ) T
    PIVOT (
        MAX(Piece) FOR PieceNr IN ([1],[2],[3],[4],[5],[6],[7],[8],[9],[10])
    ) PVT
)
INSERT ##Monkey
(
    Monkey,
    Op1,
    Op2,
    Op3,
    Test,
    ToMonkey1,
    ToMonkey2
)
SELECT T.[2], T2.[4], T2.[5], T2.[6], T3.[4],T4.[6],T5.[6] FROM cte_Pivot T 
INNER JOIN cte_Pivot T2 ON T.RowNr = T2.Rownr - 2
INNER JOIN cte_Pivot T3 ON T.RowNr = T3.Rownr - 3
INNER JOIN cte_Pivot T4 ON T.RowNr = T4.Rownr - 4
INNER JOIN cte_Pivot T5 ON T.RowNr = T5.Rownr - 5
WHERE T.[1] = 'Monkey'

-- Get the initial item information
INSERT ##Items
(
    WorryLevel,
    Monkey
)
SELECT CAST(Piece AS BIGINT), (RowNr - 1) / 7
FROM ##InputSplit
WHERE RowNr IN (SELECT RowNr FROM ##InputSplit WHERE Piece = 'items') AND Piecenr > 2

-- We're gonna need a fresh set of items for part 2
SELECT * 
INTO ##Items2
FROM ##Items



DECLARE @Round INT = 1
DECLARE @CurrentMonkey INT = 0

WHILE @Round <= 20 
BEGIN
    
    SET @CurrentMonkey = 0

    WHILE @CurrentMonkey <= (SELECT MAX(Monkey) FROM ##Monkey M)
    BEGIN

        INSERT ##Rounds
        (
            RoundNr,
            Monkey,
            NrOfItems
        )
        SELECT @Round, Monkey, COUNT(1) FROM ##Items I WHERE I.Monkey = @CurrentMonkey GROUP BY Monkey

        UPDATE I
        SET WorryLevel = CASE WHEN M.op2 = '+' THEN CAST(CASE WHEN M.Op1 = 'old' THEN I.WorryLevel ELSE M.Op1 END AS BIGINT) + CAST(CASE WHEN M.Op3 = 'old' THEN I.WorryLevel ELSE M.Op3 END AS BIGINT) 
                              WHEN M.op2 = '*' THEN CAST(CASE WHEN M.Op1 = 'old' THEN I.WorryLevel ELSE M.Op1 END AS BIGINT) * CAST(CASE WHEN M.Op3 = 'old' THEN I.WorryLevel ELSE M.Op3 END AS BIGINT) 
                         END / 3 -- This is different in part 1 
        FROM ##Items I 
        INNER JOIN ##Monkey M ON I.Monkey = M.Monkey
        WHERE I.Monkey = @CurrentMonkey

        UPDATE I
        SET Monkey = CASE WHEN I.WorryLevel % M.Test = 0 THEN M.ToMonkey1 ELSE M.ToMonkey2 END
        FROM ##Items I 
        INNER JOIN ##Monkey M ON I.Monkey = M.Monkey
        WHERE I.Monkey = @CurrentMonkey

        SET @CurrentMonkey = @CurrentMonkey + 1

    END
    SET @Round = @Round + 1

END

;WITH cte_PerMonkey AS (
    SELECT SUM(R.NrOfItems) AS NrOfItems, MonKey 
    FROM ##Rounds R 
    GROUP BY R.Monkey
)
SELECT MAX(c1.NrOfItems * c2.NrOfItems) AS Part1
FROM cte_PerMonkey c1
INNER JOIN cte_PerMonkey c2 ON c1.Monkey <> c2.Monkey

--Reset the rounds
TRUNCATE TABLE ##Rounds

-- The problem is that the worrylevel will go beyond the range of a BIGINT
-- To prevent this from happening, while still keeping the behaviour of the number the same
-- we'll take the modulo of the worrylevel with the common divisor of the test values (which just happen to be prime numbers ;) )
DECLARE @WorryVSTest BIGINT 

;WITH cte_WorryCorrection AS
(
    SELECT Monkey, Test, Test AS TestSingle
    FROM ##Monkey WHERE Monkey = 0

    UNION ALL

    SELECT M.Monkey, WC.Test * M.Test, M.Test
    FROM cte_WorryCorrection WC
    INNER JOIN ##Monkey M ON WC.Monkey = M.Monkey - 1
)
SELECT @WorryVSTest = MAX(Test)
FROM cte_WorryCorrection

SET @Round = 1
SET @CurrentMonkey = 0

WHILE @Round <= 10000 
BEGIN
    
    SET @CurrentMonkey = 0

    WHILE @CurrentMonkey <= (SELECT MAX(Monkey) FROM ##Monkey M)
    BEGIN

        INSERT ##Rounds
        (
            RoundNr,
            Monkey,
            NrOfItems
        )
        SELECT @Round, Monkey, COUNT(1) FROM ##Items2 I WHERE I.Monkey = @CurrentMonkey GROUP BY Monkey

        UPDATE I
        SET WorryLevel = CASE WHEN M.op2 = '+' THEN CAST(CASE WHEN M.Op1 = 'old' THEN I.WorryLevel ELSE M.Op1 END AS BIGINT) + CAST(CASE WHEN M.Op3 = 'old' THEN I.WorryLevel ELSE M.Op3 END AS BIGINT) 
                              WHEN M.op2 = '*' THEN CAST(CASE WHEN M.Op1 = 'old' THEN I.WorryLevel ELSE M.Op1 END AS BIGINT) * CAST(CASE WHEN M.Op3 = 'old' THEN I.WorryLevel ELSE M.Op3 END AS BIGINT) 
                         END % @WorryVSTest -- This is the difference with part 1, this keeps the worry level under control while keeping the behaviour of the number unchanged
        FROM ##Items2 I 
        INNER JOIN ##Monkey M ON I.Monkey = M.Monkey
        WHERE I.Monkey = @CurrentMonkey

        UPDATE I
        SET Monkey = CASE WHEN I.WorryLevel % M.Test = 0 THEN M.ToMonkey1 ELSE M.ToMonkey2 END
        FROM ##Items2 I 
        INNER JOIN ##Monkey M ON I.Monkey = M.Monkey
        WHERE I.Monkey = @CurrentMonkey

        SET @CurrentMonkey = @CurrentMonkey + 1

    END

    SET @Round = @Round + 1

END


;WITH cte_PerMonkey AS (
    SELECT SUM(R.NrOfItems) AS NrOfItems, MonKey 
    FROM ##Rounds R 
    GROUP BY R.Monkey
)
SELECT MAX(CAST(c1.NrOfItems AS BIGINT) * CAST(c2.NrOfItems AS BIGINT)) AS Part2
FROM cte_PerMonkey c1
INNER JOIN cte_PerMonkey c2 ON c1.Monkey <> c2.Monkey

DROP TABLE ##Items
DROP TABLE ##Items2
DROP TABLE ##Monkey
DROP TABLE ##Rounds





