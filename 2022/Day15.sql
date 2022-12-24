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
  
CREATE TABLE ##Coords (ID INT IDENTITY(1,1), Nr INT, SensorX INT, SensorY INT, BeaconX INT, BeaconY INT)

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

DECLARE @TargetLine INT = 2000000

DECLARE @Lines TABLE (ID INT IDENTITY(1,1), LineLeft BIGINT, LineRight BIGINT)

;WITH cte_Dist AS (
    SELECT ID, Nr, C.SensorX, C.SensorY, C.BeaconX, C.BeaconY
    , ABS(C.SensorX - C.BeaconX) + ABS(C.SensorY - C.BeaconY) AS ManhattanDist 
    , CASE WHEN C.SensorY > @TargetLine THEN C.SensorY - @TargetLine ELSE @TargetLine - C.SensorY END AS DistToTarget
    FROM ##Coords C
)
INSERT @Lines (LineLeft, LineRight)
SELECT SensorX - ManhattanDist + DistToTarget AS OnTargetLineLeft
,      SensorX + ManhattanDist - DistToTarget AS OnTargetLineRight
FROM cte_Dist
WHERE ManhattanDist >= DistToTarget 

DECLARE @ConsolidationDone INT = 0
DECLARE @RowCount INT

WHILE @ConsolidationDone = 0
BEGIN

    SELECT @RowCount = COUNT(1) FROM @Lines

    UPDATE L
    SET LineLeft = CASE WHEN L.LineLeft < L2.LineLeft THEN L.LineLeft ELSE L2.LineLeft END
    ,   LineRight = CASE WHEN L.LineRight > L2.LineRight THEN L.LineRight ELSE L2.LineRight END  
    FROM @Lines L
    INNER JOIN @Lines L2 ON (L.LineRight BETWEEN L2.LineLeft AND L2.LineRight
                         OR L.LineLeft BETWEEN L2.LineLeft AND L2.LineRight)
                         AND L.ID <> L2.ID


    DELETE L
    FROM @Lines L
    INNER JOIN @Lines L2 ON L2.LineLeft = L.LineLeft AND L2.LineRight = L.LineRight AND L2.ID < L.ID

    IF @RowCount = (SELECT COUNT(1) FROM @Lines) SET @ConsolidationDone = 1
END


SELECT LineRight - LineLeft AS Part1 FROM @Lines

-- Diamond shapes are hard to handles. Let's rotate the coordinate system so we have squares
CREATE TABLE ##Rects (ID INT IDENTITY(1,1), CornerX BIGINT, CornerY BIGINT, OppCornerX BIGINT, OppCornerY BIGINT)

;WITH cte_Sensors AS (
    SELECT ID, Nr, C.SensorX, C.SensorY
    , ABS(C.SensorX - C.BeaconX) + ABS(C.SensorY - C.BeaconY) AS ManhattanDist 
    FROM ##Coords C
), cte_Diamonds AS (
    SELECT c.ID
    ,      c.SensorX - c.ManhattanDist AS TopPointDiamondX
    ,      c.SensorY                   AS TopPointDiamondY
    ,      c.SensorX + c.ManhattanDist AS BottomPointDiamondX
    ,      c.SensorY                   AS BottomPointDiamondY
    FROM cte_Sensors c
)
INSERT ##Rects (CornerX, CornerY, OppCornerX, OppCornerY)
SELECT TopPointDiamondX + TopPointDiamondY AS CornerX
,      TopPointDiamondY - TopPointDiamondX AS CornerY
,      BottomPointDiamondX + BottomPointDiamondY AS OppCornerX
,      BottomPointDiamondY - BottomPointDiamondX AS OppCornerY
FROM cte_Diamonds

/*
    Conversion matrix:
    ( cos θ   -sin θ)
    ( sin θ    cos θ) 
    
    For 45° this becomes:

    1/2 * √2 * ( 1  -1 )
               ( 1   1 )

    The factor (1/2 * √2) is not relevant which means to convert a point (x,y) we get the new coordinates by:
    x_new = x + y
    y_new = y - x

    So the ##Rects table now contains two corners per square
*/

CREATE TABLE ##PossibleSolutions (ID INT IDENTITY(1,1), x BIGINT, y BIGINT)

-- Search a point between the lines of squares. Since it is exactly one point the difference between the two lines will be 2
;WITH cte_Xlines AS (
    SELECT CornerX AS X FROM ##Rects R UNION 
    SELECT OppCornerX FROM ##Rects R 
), cte_YLines AS (
    SELECT CornerY AS Y FROM ##Rects R UNION 
    SELECT OppCornerY FROM ##Rects R  
)
INSERT ##PossibleSolutions (x, y)
SELECT (x1.X + x2.X) / 2 AS XSol, (y1.Y + y2.Y) / 2 AS YSol 
FROM cte_XLines x1
INNER JOIN cte_Xlines x2 ON x2.X - x1.X = 2
CROSS APPLY cte_YLines y1 
INNER JOIN cte_YLines y2 ON y2.Y - y1.Y = 2

-- Converting back works similarly but with an angle of -45°
SELECT x AS xConverted
,      y AS yConverted    
,      (x - y) / 2 AS xOriginal
,      (x + y) / 2 AS yOriginal
,      CAST((x - y) / 2 AS BIGINT) * 4000000 + (x + y) / 2 AS Part2
FROM ##PossibleSolutions PS


DROP TABLE ##Coords
DROP TABLE ##Rects
DROP TABLE ##PossibleSolutions


/*

11374534948438 is the correct answer
 x = 2843633
 y = 2948438

 SELECT CAST(2843633 AS BIGINT) * 4000000 + 2948438 AS Part2

 -- Converted coordinates
 SELECT 2843633+2948438 --X + Y     5792071
 SELECT 2948438-2843633 --Y - X     104805

*/


