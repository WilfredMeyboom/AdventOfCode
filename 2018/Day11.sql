
CREATE TABLE #NrList (Nr INT)

INSERT #NrList
SELECT TOP (300) ROW_NUMBER() OVER (ORDER BY (SELECT 0)) FROM sys.messages

SELECT * FROM #NrList

CREATE TABLE #FuelCells (ID INT IDENTITY(1,1) PRIMARY KEY, X INT, Y INT, RackID INT, PowerLevel INT)

INSERT #FuelCells (X, Y)
SELECT L1.Nr, L2.Nr
FROM #NrList L1
CROSS APPLY #NrList L2


--Find the fuel cell's rack ID, which is its X coordinate plus 10.
UPDATE #FuelCells
SET RackID = X + 10

--Begin with a power level of the rack ID times the Y coordinate.
UPDATE #FuelCells
SET PowerLevel = RackID * Y

--Increase the power level by the value of the grid serial number (your puzzle input).
DECLARE @Input INT = 3031
UPDATE #FuelCells
SET PowerLevel = PowerLevel + @Input

--Set the power level to itself multiplied by the rack ID.
UPDATE #FuelCells
SET PowerLevel = PowerLevel * RackID

--Keep only the hundreds digit of the power level (so 12345 becomes 3; numbers with no hundreds digit become 0).

UPDATE #FuelCells
SET PowerLevel = CAST(RIGHT('000' + CAST(PowerLevel AS VARCHAR(20)), 3) AS INT) / 100


--Subtract 5 from the power level
UPDATE #FuelCells
SET PowerLevel = PowerLevel - 5


SELECT FC1.X, FC1.Y, SUM(FC2.PowerLevel) AS TotalPower
FROM #FuelCells FC1
INNER JOIN #FuelCells FC2 ON FC1.X BETWEEN FC2.X - 2 AND FC2.X
                         AND FC1.Y BETWEEN FC2.Y - 2 AND FC2.Y
GROUP BY FC1.X, FC1.Y
ORDER BY TotalPower DESC

--23,78 is fout

DECLARE @Size INT = 0
DECLARE @X INT = 0
DECLARE @Y INT = 0
DECLARE @BestX INT = 0
DECLARE @BestY INT = 0
DECLARE @PowerLevel INT = 0
DECLARE @BestPowerLevel INT = 0
DECLARE @BestSize INT = 0


WHILE (@Size < 31)
BEGIN

    SET @Size = @Size + 1

    SELECT TOP(1) 
           @X = FC1.X
    ,      @Y = FC1.Y
    ,      @PowerLevel = SUM(FC2.PowerLevel)
    FROM #FuelCells FC1
    INNER JOIN #FuelCells FC2 ON FC1.X BETWEEN FC2.X - (@Size -1) AND FC2.X
                             AND FC1.Y BETWEEN FC2.Y - (@Size -1) AND FC2.Y
    GROUP BY FC1.X, FC1.Y
    ORDER BY SUM(FC2.PowerLevel) DESC

    PRINT CAST(@X AS VARCHAR(5)) + ' | ' + 
          CAST(@Y AS VARCHAR(5)) + ' | ' + 
          CAST(@Size AS VARCHAR(5)) + ' | ' +
          CAST(@PowerLevel AS VARCHAR(5)) 

    IF (@PowerLevel > @BestPowerLevel)
    BEGIN
        SET @BestPowerLevel = @PowerLevel
        SET @BestSize = @Size
        SET @BestX = @X
        SET @BestY = @Y
    END
END

SELECT @BestX, @BestY, @BestSize, @BestPowerLevel

--234 | 108 | 16 | 160