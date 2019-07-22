use Test_WME

CREATE TABLE Input (Writing NVARCHAR(MAX));

BULK INSERT Input
FROM 'D:\Wilfred\AdventOfCode\input4.txt'
WITH (ROWTERMINATOR = '0x0A');


--SELECT * FROM Input ORDER BY 1

CREATE TABLE #GuardTimes (ID INT IDENTITY(1,1), GuardID INT, ShiftStart DATETIME2, SleepStart DATETIME2, SleepEnd DATETIME2)

DECLARE @Guard INT
DECLARE @Time DATETIME2
DECLARE @ShiftTime DATETIME2
DECLARE @ID INT

DECLARE @String NVARCHAR(MAX)

DECLARE TimesCursor CURSOR
FOR SELECT Writing FROM Input ORDER BY 1

OPEN TimesCursor

FETCH NEXT FROM TimesCursor INTO @String

WHILE @@FETCH_STATUS = 0
BEGIN
    
    SET @Time = CAST(SUBSTRING(@String, 2, 16) AS DATETIME2)
    
    IF (CHARINDEX('#', @String) > 0)
    BEGIN
        SET @Guard = SUBSTRING(@String, CHARINDEX('#', @String) + 1, CHARINDEX(' ', SUBSTRING(@String, CHARINDEX('#', @String), LEN(@String) - CHARINDEX('#', @String))) -1)
        
        SET @ShiftTime = @Time
    END       

    ELSE
    BEGIN

        IF EXISTS (SELECT 1 WHERE @String LIKE '%falls asleep%') 
        BEGIN

                INSERT #GuardTimes (GuardId, ShiftStart, SleepStart)
                VALUES (@Guard, @ShiftTime, @Time)

                SET @ID = @@IDENTITY

        END
        ELSE
        BEGIN
            UPDATE #GuardTimes
            SET SleepEnd = @Time
            WHERE ID = @ID
        END

    END

    FETCH NEXT FROM TimesCursor INTO @String

END

SELECT GuardId, SUM(DATEDIFF(MINUTE, SleepStart, SleepEnd)) FROM #GuardTimes GROUP BY GuardId ORDER BY 2 DESC
SELECT * FROM #GuardTimes WHERE GuardID = 1657 --AND ShiftStart = '1518-07-05 23:53:00.0000000'

CREATE TABLE #Minutes (Minute INT)

;WITH Nums(Number) AS (
    SELECT 0 AS Number
    UNION ALL
    SELECT Number+1 FROM Nums where Number<59
)
INSERT INTO #Minutes(Minute)
SELECT Number FROM Nums 


SELECT Minute, 
       SUM(CASE WHEN Minute BETWEEN DATEPART(MINUTE, SleepStart) AND DATEPART(MINUTE, SleepEnd) -1 THEN 1 ELSE 0 END) AS AsleepValue
FROM #GuardTimes
CROSS APPLY #Minutes
WHERE GuardID = 2851
GROUP BY Minute
ORDER BY 2 DESC

SELECT 2851 * 44

SELECT GuardId, Minute, 
       SUM(CASE WHEN Minute BETWEEN DATEPART(MINUTE, SleepStart) AND DATEPART(MINUTE, SleepEnd) -1 THEN 1 ELSE 0 END) AS AsleepValue,
       GuardId * Minute
FROM #GuardTimes
CROSS APPLY #Minutes
GROUP BY GuardId, Minute
ORDER BY 3 DESC, 2, 1



CLOSE TimesCursor
DEALLOCATE TimesCursor

--DROP TABLE #Minutes
--DROP TABLE #GuardTimes
DROP TABLE Input

