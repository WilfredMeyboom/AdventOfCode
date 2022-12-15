USE Test_WME

DECLARE @year VARCHAR(4) = '2022'
DECLARE @day VARCHAR(2)  = '15'

EXEC dbo.GetInput @year = @year, @day = @day
EXEC dbo.ParseInput @year = @year, @day = @day, @SplitCustom = '=:,'

--SELECT TOP 10 * FROM ##Input
--SELECT TOP 10 * FROM ##InputInts
--SELECT TOP 10 * FROM ##InputNumbered
--SELECT TOP 10 * FROM ##InputGrid
--SELECT TOP 10 * FROM ##InputSplit
--SELECT TOP 10 * FROM ##InputSplitCust
  
CREATE TABLE ##Coords (ID INT IDENTITY(1,1), Nr INT, SensorX INT, SensorY INT, BeaconX INT, BeaconY iNt)

INSERT ##Coords
(
    Nr,
    SensorX,
    SensorY,
    BeaconX,
    BeaconY
)
SELECT RowNr, [2],[4],[6],[8] FROM (
    SELECT RowNr, PieceNr, Piece FROM ##InputSplitCust WHERE PieceNr IN (2,4,6,8)
) T
PIVOT(
    MAX(Piece) FOR PieceNr IN ([2],[4],[6],[8])
) pvt

DECLARE @TargetLine INT = 10

DECLARE @Line AS TABLE (ID INT IDENTITY(1,1), StartX INT, EndX INT) 
DECLARE @StartX INT
DECLARE @EndX INT

DECLARE intervalCursor CURSOR FAST_FORWARD FOR
SELECT CASE WHEN ManhattanDist - DistToTarget < 0 THEN 0 ELSE SensorX - ManhattanDist + DistToTarget END AS OnTargetX
,      CASE WHEN ManhattanDist - DistToTarget < 0 THEN 0 ELSE SensorX + ManhattanDist - DistToTarget END AS OnTargetY
FROM (
    SELECT ID, Nr, C.SensorX, C.SensorY, C.BeaconX, C.BeaconY
    , ABS(C.SensorX - C.BeaconX) + ABS(C.SensorY - C.BeaconY) AS ManhattanDist 
    , CASE WHEN C.SensorY > @TargetLine THEN C.SensorY - @TargetLine ELSE @TargetLine - C.SensorY END AS DistToTarget
    FROM ##Coords C
) T

OPEN intervalCursor

FETCH NEXT FROM intervalCursor INTO @StartX, @EndX

WHILE @@FETCH_STATUS = 0
BEGIN

SELECT @StartX, @EndX, * FROM @Line L

    IF @StartX <> 0 OR @EndX <> 0
    BEGIN
        
        IF EXISTS (SELECT 1 FROM @Line L WHERE @StartX BETWEEN L.StartX AND L.EndX OR @EndX BETWEEN L.StartX AND L.EndX)
        BEGIN
            
            UPDATE @Line
            SET StartX = @StartX
            WHERE @EndX BETWEEN StartX AND EndX AND StartX > @StartX
            
            UPDATE @Line
            SET EndX = @EndX
            WHERE @StartX BETWEEN StartX AND EndX AND EndX < @EndX

        END
        ELSE IF EXISTS (SELECT 1 FROM @Line L WHERE L.StartX > @StartX AND L.EndX < @EndX)
        BEGIN
            UPDATE @Line
            SET StartX = @StartX
            ,   EndX = @EndX
            WHERE StartX > @StartX AND EndX < @EndX
        END
        ELSE
            INSERT @Line (StartX, EndX) SELECT @StartX, @EndX


    END

    FETCH NEXT FROM intervalCursor INTO @StartX, @EndX

END

CLOSE intervalCursor
DEALLOCATE intervalCursor

SELECT *, L.EndX - L.StartX FROM @Line L

SELECT SUM(L.EndX - L.StartX) FROM @Line L



DROP TABLE ##Coords

