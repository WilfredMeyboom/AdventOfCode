USE Test_WME

SET NOCOUNT ON

DECLARE @year VARCHAR(4) = '2024'
DECLARE @day VARCHAR(2)  = '14'

EXEC dbo.GetInput @year = @year, @day = @day
EXEC dbo.ParseInput @year = @year, @day = @day 

--SELECT TOP 10 * FROM ##Input
--SELECT TOP 10 * FROM ##InputInts
--SELECT TOP 10 * FROM ##InputNumbered
--SELECT TOP 10 * FROM ##InputGrid
--SELECT TOP 10 * FROM ##InputSplit
--SELECT TOP 10 * FROM ##InputSplitCust

CREATE TABLE ##Robots (ID INT IDENTITY(1,1), robotNr INT, pX INT, pY INT, vX INT, vY INT)

INSERT ##Robots (RobotNr, pX, pY, vX, vY)
SELECT RowNr, REPLACE([1], 'p=','') AS pX, [2] AS pY, REPLACE([3],'v=','') AS vX, [4] AS vY
FROM (
    SELECT RowNr, PieceNr, Piece FROM ##InputSplit
    ) Src
PIVOT (
    MAX(Piece) 
    FOR PieceNr IN ([1], [2], [3], [4])
) PVT

DECLARE @Cnt BIGINT = 0
DECLARE @SizeX INT = 101
DECLARE @SizeY INT = 103

WHILE @Cnt < 100
BEGIN
    
    UPDATE ##Robots
    SET pX = (pX + vX + @SizeX) % @SizeX
    ,   pY = (pY + vY + @SizeY) % @SizeY

    SET @Cnt = @Cnt + 1


END

;WITH cte_CountPerQ AS (
    SELECT SUM(CASE WHEN pX < @SizeX / 2 AND pY < @SizeY / 2 THEN 1 ELSE 0 END) AS FirstQ
    ,      SUM(CASE WHEN pX > @SizeX / 2 AND pY < @SizeY / 2 THEN 1 ELSE 0 END) AS SecondQ
    ,      SUM(CASE WHEN pX < @SizeX / 2 AND pY > @SizeY / 2 THEN 1 ELSE 0 END) AS ThirdQ
    ,      SUM(CASE WHEN pX > @SizeX / 2 AND pY > @SizeY / 2 THEN 1 ELSE 0 END) AS FourthQ
    FROM ##Robots 
)
SELECT FirstQ * SecondQ * ThirdQ * FourthQ AS Part1
FROM cte_CountPerQ

DECLARE @EasterEggFound INT = 0

--SET @Cnt = 0

WHILE @EasterEggFound = 0
BEGIN

    UPDATE ##Robots
    SET pX = (pX + vX + @SizeX) % @SizeX
    ,   pY = (pY + vY + @SizeY) % @SizeY

    SET @Cnt = @Cnt + 1

    IF EXISTS (SELECT 1 FROM ##Robots GROUP BY pX HAVING COUNT(1) >= 25)
        IF EXISTS (SELECT 1 FROM ##Robots GROUP BY pY HAVING COUNT(1) >= 25)
            SET @EasterEggFound = 1

    IF @Cnt % 10000 = 0 PRINT 'Cnt: ' + CAST(@Cnt AS VARCHAR(20)) + ' at: ' + CAST(GETDATE() AS VARCHAR(50))

END

PRINT @Cnt

/*

DROP TABLE ##Robots


*/
--6393 too low

SELECT * FROM ##Robots


--DECLARE @SizeX INT = 101
--DECLARE @SizeY INT = 103

--UPDATE ##Robots
--SET pX = (pX + vX + @SizeX) % @SizeX
--,   pY = (pY + vY + @SizeY) % @SizeY
