use Test_WME

CREATE TABLE Input (Nr NVARCHAR(MAX));

BULK INSERT Input
FROM 'D:\Wilfred\AdventOfCode\2017\input6.txt'
WITH (ROWTERMINATOR = '\t');

SELECT * FROM Input

--UPDATE Input
--SET Nr = '3'
--WHERE Nr LIKE '3%'

CREATE TABLE #Banks (ID INT IDENTITY(1,1), BankID INT, BlockCount INT)

INSERT #Banks (BankId, BlockCount)
SELECT ROW_NUMBER() OVER (ORDER BY (SELECT 0)), CAST(LTRIM(Nr) AS INT) FROM Input

CREATE TABLE #BanksMemory (ID INT IDENTITY(1,1), CycleID INT, BankID INT, BlockCount INT)

CREATE TABLE #Distribution (ID INT IDENTITY(1,1), BankID INT, BlockCount INT)

INSERT #Distribution (BankID)
SELECT TOP (16) ROW_NUMBER() OVER (ORDER BY (SELECT 0)) FROM sys.messages

DECLARE @Cycle INT = 1
DECLARE @MaxID INT
DECLARE @MatchFound BIT = 0
DECLARE @BlocksToDistribute INT = 0

WHILE NOT (@MatchFound = 1)
BEGIN

    INSERT #BanksMemory (CycleID, BankID, BlockCount)
    SELECT @Cycle,  BankID, BlockCount FROM #Banks

    SET @Cycle = @Cycle + 1

    SELECT TOP(1) @MaxID = BankID, @BlocksToDistribute = BlockCount FROM #Banks ORDER BY BlockCount DESC, BankID

    UPDATE #Banks
    SET BlockCount = 0
    WHERE BankID = @MaxID

    DELETE FROM #Distribution

    INSERT #Distribution (BankID, BlockCount)
    SELECT BankID
    ,   @BlocksToDistribute / 16 + CASE WHEN (BankID BETWEEN (@MaxID + 1) AND @MaxID + @BlocksToDistribute % 16) 
                                          OR (BankID BETWEEN (@MaxID - 15) AND @MaxID + (@BlocksToDistribute % 16) - 16) THEN 1 ELSE 0 END
    FROM #Banks
    WHERE (BankID BETWEEN (@MaxID + 1) AND @MaxID + @BlocksToDistribute) 
       OR (BankID BETWEEN (@MaxID - 15) AND @MaxID + @BlocksToDistribute - 16) 
        
    --SELECT * FROM #Distribution
    --SELECT * FROM #Banks

    UPDATE B
    SET BlockCount = B.BlockCount + D.BlockCount
    FROM #Banks B
    INNER JOIN #Distribution D ON B.BankID = D.BankID

    --SELECT * FROM #Distribution
    --SELECT * FROM #Banks

    SELECT @MatchFound = 1
    FROM #Banks B
    INNER JOIN #BanksMemory BM ON B.BankID = BM.BankID AND B.BlockCount = BM.BlockCount
    GROUP BY BM.CycleID
    HAVING COUNT(1) = 16

END

    SELECT BM.CycleID 
    FROM #Banks B
    INNER JOIN #BanksMemory BM ON B.BankID = BM.BankID AND B.BlockCount = BM.BlockCount
    GROUP BY BM.CycleID
    HAVING COUNT(1) = 16

SELECT MAX(CycleID) - 4290 FROM #BanksMemory


DROP TABLE #Banks
DROP TABLE #BanksMemory
DROP TABLE #Distribution

DROP TABLE Input