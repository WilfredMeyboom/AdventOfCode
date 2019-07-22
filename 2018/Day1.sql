use Test_WME

CREATE TABLE Input (Nr NVARCHAR(MAX));

BULK INSERT Input
FROM 'D:\temp\AdventOfCode\input.txt'
WITH (ROWTERMINATOR = '0x0A');

SELECT SUM(CAST(Nr AS INT)) FROM Input -- Day 1 Task 1


CREATE TABLE Calibration (Id INT IDENTITY(1,1), Nr INT)

DECLARE @RowFound BIT = 0 
DECLARE @Iteration INT = 0

WHILE (@RowFound = 0)
BEGIN
    SET @Iteration = @Iteration + 1
--    PRINT @Iteration

    INSERT INTO Calibration (Nr)
    SELECT CAST(Nr AS INT) 
    FROM Input

    ;WITH cte_RT AS 
    (
        SELECT Id, Nr, SUM(Nr) OVER (ORDER BY Id) AS RunningTotal 
        FROM Calibration
    )
    SELECT @RowFound = 1
    FROM cte_RT T1 
    INNER JOIN cte_RT T2 ON T1.RunningTotal = T2.RunningTotal 
                        AND T1.Id < T2.Id

END

;WITH cte_RT AS 
(
    SELECT Id, Nr, SUM(Nr) OVER (ORDER BY Id) AS RunningTotal 
    FROM Calibration
)
SELECT T1.RunningTotal, T1.Id, T2.Id, @Iteration
FROM cte_RT T1 
INNER JOIN cte_RT T2 ON T1.RunningTotal = T2.RunningTotal 
                    AND T1.Id < T2.Id
  -- Day 1 Task 2

SELECT Id, Nr, SUM(Nr) OVER (ORDER BY Id) AS RunningTotal FROM Calibration 

--DROP TABLE Input
--DROP TABLE Calibration


--80598
--80598