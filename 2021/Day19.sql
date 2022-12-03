USE Test_WME

SET NOCOUNT ON

DECLARE @year VARCHAR(4) = '2021'
DECLARE @day VARCHAR(2)  = '19'

IF EXISTS (SELECT * FROM tempdb.sys.tables WHERE name = '##Input') DROP TABLE ##Input
CREATE TABLE ##Input (Line NVARCHAR(MAX) NULL);

IF EXISTS (SELECT * FROM tempdb.sys.tables WHERE name = '##InputNumbered') DROP TABLE ##InputNumbered
CREATE TABLE ##InputNumbered (Ind INT NOT NULL, Line NVARCHAR(MAX) NULL);

IF EXISTS (SELECT * FROM tempdb.sys.tables WHERE name = '##InputGrid') DROP TABLE ##InputGrid
CREATE TABLE ##InputGrid (Ind INT IDENTITY(1,1), RowNr INT, ColNr INT, Val CHAR);

IF EXISTS (SELECT * FROM tempdb.sys.tables WHERE name = '##InputInts') DROP TABLE ##InputInts
CREATE TABLE ##InputInts (Ind INT NOT NULL, Val BIGINT);

IF EXISTS (SELECT * FROM tempdb.sys.tables WHERE name = '##InputSplit') DROP TABLE ##InputSplit
CREATE TABLE ##InputSplit (Ind INT IDENTITY(1,1), RowNr INT, PieceNr INT, Piece VARCHAR(MAX));

IF EXISTS (SELECT * FROM tempdb.sys.tables WHERE name = '##InputSplitCust') DROP TABLE ##InputSplitCust
CREATE TABLE ##InputSplitCust (Ind INT IDENTITY(1,1), RowNr INT, PieceNr INT, Piece VARCHAR(MAX));

EXEC dbo.GetInput @year = @year, @day = @day
EXEC dbo.ParseInput @year = @year, @day = @day, @SplitCustom = '= .,'

--SELECT * FROM ##InputNumbered
--SELECT TOP 10 * FROM ##InputGrid
--SELECT TOP 10 * FROM ##InputInts
--SELECT * FROM ##InputSplit
--SELECT TOP 10 * FROM ##InputSplitCust

CREATE TABLE ##Beacons (ID INT IDENTITY(1,1), ScannerNr INT, BeaconNr INT, X INT, Y INT, Z INT)

;WITH cte_Scanners AS (
    SELECT REPLACE(REPLACE(Line, '--- scanner ',''), ' ---', '') ScannerNr
    , Ind
    , ISNULL(LEAD(Ind) OVER (ORDER BY Ind), 99999) NextInd
    FROM ##InputNumbered 
    WHERE LINE LIKE '%scanner%' GROUP BY Ind, Line
)
INSERT ##Beacons (ScannerNr, BeaconNr, X, Y, Z)
SELECT CAST(c.ScannerNr AS INT) AS ScannerNr
,      ROW_NUMBER() OVER (PARTITION BY c.ScannerNr ORDER BY c.ScannerNr) AS BeaconNr
,      TRY_CAST(Ix.Piece AS BIGINT) AS x
,      TRY_CAST(Iy.Piece AS BIGINT) AS y
,      TRY_CAST(Iz.Piece AS BIGINT) AS z
--INTO ##Coords
FROM ##InputSplit Ix
INNER JOIN ##InputSplit Iy ON Ix.RowNr = Iy.RowNr AND Iy.PieceNr = 2
INNER JOIN ##InputSplit Iz ON Ix.RowNr = Iz.RowNr AND Iz.PieceNr = 3
INNER JOIN cte_Scanners c ON Ix.RowNr > c.Ind AND Ix.RowNr < c.NextInd 
WHERE Ix.PieceNr = 1

CREATE TABLE ##InternalDistances (ID INT IDENTITY(1,1), ScannerNr INT, BeaconNr INT, X INT, Y INT, Z INT, Dist BIGINT)

INSERT ##InternalDistances (ScannerNr, BeaconNr, X, Y, Z, Dist)
SELECT b1.ScannerNr
,      b1.BeaconNr
,      b1.X, b1.Y, b1.Z
,      CAST(ABS(b1.X-b2.X) AS BIGINT) * ABS(b1.Y-b2.Y) * ABS(b1.Z-b2.Z)
--INTO ##Distances
FROM ##Beacons b1
INNER JOIN ##Beacons b2 ON b1.ScannerNr = b2.ScannerNr AND b2.BeaconNr <> b1.BeaconNr

CREATE TABLE ##RelatedPoints (ID INT IDENTITY(1,1), 
                              ScannerNr1 INT, BeaconNr1 INT, X1 INT, Y1 INT, Z1 INT, 
                              ScannerNr2 INT, BeaconNr2 INT, X2 INT, Y2 INT, Z2 INT, 
                              XXM INT, XYM INT, XZM INT, YXM INT, YYM INT, YZM INT, ZXM INT, ZYM INT, ZZM INT,
                              XXA INT, XYA INT, XZA INT, YXA INT, YYA INT, YZA INT, ZXA INT, ZYA INT, ZZA INT)


;WITH cte_PointToPoint AS (
    SELECT D.ScannerNr AS ScannerNr1, D.BeaconNr AS BeaconNr1, D.X AS X1, D.Y AS Y1, D.Z AS Z1
    ,      D2.ScannerNr AS ScannerNr2, D2.BeaconNr AS BeaconNr2, D2.x AS X2, D2.y AS Y2, D2.z AS Z2
    FROM ##InternalDistances D
    INNER JOIN ##InternalDistances D2 ON D2.Dist = D.Dist AND D2.ScannerNr <> D.ScannerNr
    GROUP BY D.x,D.y,D.z,D2.x,D2.y,D2.z, D.ScannerNr, D.BeaconNr, D2.ScannerNr, D2.BeaconNr
    HAVING COUNT(1) > 10
)
INSERT ##RelatedPoints
(
    ScannerNr1, BeaconNr1, X1, Y1, Z1,
    ScannerNr2, BeaconNr2, X2, Y2, Z2,
    XXM, XYM, XZM, YXM, YYM, YZM, ZXM, ZYM, ZZM,
    XXA, XYA, XZA, YXA, YYA, YZA, ZXA, ZYA, ZZA
)
SELECT ScannerNr1, BeaconNr1, X1, Y1, Z1,
       ScannerNr2, BeaconNr2, X2, Y2, Z2, 
       X1-X2 XXM, X1-Y2 XYM, X1-Z2 XZM,Y1-X2 YXM,Y1-Y2 YYM,Y1-Z2 YZM,Z1-X2 ZXM,Z1-Y2 ZYM,Z1-Z2 ZZM, 
       X1+X2 XXA, X1+Y2 XYA, X1+Z2 XZA,Y1+X2 YXA,Y1+Y2 YYA,Y1+Z2 YZA,Z1+X2 ZXA,Z1+Y2 ZYA,Z1+Z2 ZZA
--INTO ##Points
FROM cte_PointToPoint cPP
ORDER BY ScannerNr1, ScannerNr2, BeaconNr1, BeaconNr2


CREATE TABLE ##Projections (ID INT IDENTITY(1,1), ScannerNr1 INT, ScannerNr2 INT, X INT, Y INT, Z INT, NewAxis1 CHAR, Dir1 VARCHAR(8), NewAxis2 CHAR, Dir2 VARCHAR(8), NewAxis3 CHAR, Dir3 VARCHAR(8))

;WITH cte_Scanner AS (
    SELECT ScannerNr1, ScannerNr2, xxm AS Val, 'x' AS NewAxis, 'x' AS CurrentAxis, 'Same' AS Dir FROM ##RelatedPoints GROUP BY ScannerNr1, ScannerNr2, xxm HAVING COUNT(1) >= 10 UNION 
    SELECT ScannerNr1, ScannerNr2, xym AS Val, 'y' AS NewAxis, 'x' AS CurrentAxis, 'Same' AS Dir FROM ##RelatedPoints GROUP BY ScannerNr1, ScannerNr2, xym HAVING COUNT(1) >= 10 UNION 
    SELECT ScannerNr1, ScannerNr2, xzm AS Val, 'z' AS NewAxis, 'x' AS CurrentAxis, 'Same' AS Dir FROM ##RelatedPoints GROUP BY ScannerNr1, ScannerNr2, xzm HAVING COUNT(1) >= 10 UNION 
    SELECT ScannerNr1, ScannerNr2, yxm AS Val, 'x' AS NewAxis, 'y' AS CurrentAxis, 'Same' AS Dir FROM ##RelatedPoints GROUP BY ScannerNr1, ScannerNr2, yxm HAVING COUNT(1) >= 10 UNION 
    SELECT ScannerNr1, ScannerNr2, yym AS Val, 'y' AS NewAxis, 'y' AS CurrentAxis, 'Same' AS Dir FROM ##RelatedPoints GROUP BY ScannerNr1, ScannerNr2, yym HAVING COUNT(1) >= 10 UNION 
    SELECT ScannerNr1, ScannerNr2, yzm AS Val, 'z' AS NewAxis, 'y' AS CurrentAxis, 'Same' AS Dir FROM ##RelatedPoints GROUP BY ScannerNr1, ScannerNr2, yzm HAVING COUNT(1) >= 10 UNION 
    SELECT ScannerNr1, ScannerNr2, zxm AS Val, 'x' AS NewAxis, 'z' AS CurrentAxis, 'Same' AS Dir FROM ##RelatedPoints GROUP BY ScannerNr1, ScannerNr2, zxm HAVING COUNT(1) >= 10 UNION 
    SELECT ScannerNr1, ScannerNr2, zym AS Val, 'y' AS NewAxis, 'z' AS CurrentAxis, 'Same' AS Dir FROM ##RelatedPoints GROUP BY ScannerNr1, ScannerNr2, zym HAVING COUNT(1) >= 10 UNION 
    SELECT ScannerNr1, ScannerNr2, zzm AS Val, 'z' AS NewAxis, 'z' AS CurrentAxis, 'Same' AS Dir FROM ##RelatedPoints GROUP BY ScannerNr1, ScannerNr2, zzm HAVING COUNT(1) >= 10 UNION 
    SELECT ScannerNr1, ScannerNr2, xxa AS Val, 'x' AS NewAxis, 'x' AS CurrentAxis, 'Opposite' AS Dir FROM ##RelatedPoints GROUP BY ScannerNr1, ScannerNr2, xxa HAVING COUNT(1) >= 10 UNION 
    SELECT ScannerNr1, ScannerNr2, xya AS Val, 'y' AS NewAxis, 'x' AS CurrentAxis, 'Opposite' AS Dir FROM ##RelatedPoints GROUP BY ScannerNr1, ScannerNr2, xya HAVING COUNT(1) >= 10 UNION 
    SELECT ScannerNr1, ScannerNr2, xza AS Val, 'z' AS NewAxis, 'x' AS CurrentAxis, 'Opposite' AS Dir FROM ##RelatedPoints GROUP BY ScannerNr1, ScannerNr2, xza HAVING COUNT(1) >= 10 UNION 
    SELECT ScannerNr1, ScannerNr2, yxa AS Val, 'x' AS NewAxis, 'y' AS CurrentAxis, 'Opposite' AS Dir FROM ##RelatedPoints GROUP BY ScannerNr1, ScannerNr2, yxa HAVING COUNT(1) >= 10 UNION 
    SELECT ScannerNr1, ScannerNr2, yya AS Val, 'y' AS NewAxis, 'y' AS CurrentAxis, 'Opposite' AS Dir FROM ##RelatedPoints GROUP BY ScannerNr1, ScannerNr2, yya HAVING COUNT(1) >= 10 UNION 
    SELECT ScannerNr1, ScannerNr2, yza AS Val, 'z' AS NewAxis, 'y' AS CurrentAxis, 'Opposite' AS Dir FROM ##RelatedPoints GROUP BY ScannerNr1, ScannerNr2, yza HAVING COUNT(1) >= 10 UNION 
    SELECT ScannerNr1, ScannerNr2, zxa AS Val, 'x' AS NewAxis, 'z' AS CurrentAxis, 'Opposite' AS Dir FROM ##RelatedPoints GROUP BY ScannerNr1, ScannerNr2, zxa HAVING COUNT(1) >= 10 UNION 
    SELECT ScannerNr1, ScannerNr2, zya AS Val, 'y' AS NewAxis, 'z' AS CurrentAxis, 'Opposite' AS Dir FROM ##RelatedPoints GROUP BY ScannerNr1, ScannerNr2, zya HAVING COUNT(1) >= 10 UNION 
    SELECT ScannerNr1, ScannerNr2, zza AS Val, 'z' AS NewAxis, 'z' AS CurrentAxis, 'Opposite' AS Dir FROM ##RelatedPoints GROUP BY ScannerNr1, ScannerNr2, zza HAVING COUNT(1) >= 10
)
INSERT ##Projections (ScannerNr1, ScannerNr2, X, Y, Z, NewAxis1, Dir1, NewAxis2, Dir2, NewAxis3, Dir3)
SELECT c1.ScannerNr1, c1.ScannerNr2, 
       c1.Val AS X, c2.Val AS Y, c3.Val Z, 
       c1.NewAxis AS NewAxis1, c1.Dir AS Dir1, 
       c2.NewAxis AS NewAxis2, c2.Dir AS Dir2, 
       c3.NewAxis AS NewAxis3, c3.Dir AS Dir3
FROM cte_Scanner c1
INNER JOIN cte_Scanner c2 ON c2.ScannerNr1 = c1.ScannerNr1 AND c2.ScannerNr2 = c1.ScannerNr2 AND c2.CurrentAxis = 'y'
INNER JOIN cte_Scanner c3 ON c3.ScannerNr1 = c1.ScannerNr1 AND c3.ScannerNr2 = c1.ScannerNr2 AND c3.CurrentAxis = 'z'
WHERE c1.CurrentAxis = 'x'


CREATE TABLE ##BeaconsInS0 (ID INT IDENTITY(1,1), ScannerStart INT, ScannerNow INT, X INT, Y INT, Z INT)

INSERT ##BeaconsInS0(ScannerStart, ScannerNow, X, Y, Z)
SELECT 0, 0, X, Y, Z FROM ##Beacons B WHERE B.ScannerNr = 0

CREATE TABLE ##ConversionOrder (ID INT IDENTITY(1,1), ScannerSource INT, ScannerTarget INT)

WHILE ((SELECT COUNT (DISTINCT ScannerStart) FROM ##BeaconsInS0 WHERE ScannerNow = 0) < (SELECT COUNT (DISTINCT ScannerNr) FROM ##Beacons))
BEGIN

    INSERT ##ConversionOrder (ScannerSource, ScannerTarget)
    SELECT S.ScannerStart, P.ScannerNr2
    FROM (SELECT DISTINCT ScannerStart FROM ##BeaconsInS0) S 
    INNER JOIN ##Projections P ON P.ScannerNr1 = S.ScannerStart
    LEFT JOIN (SELECT DISTINCT ScannerStart FROM ##BeaconsInS0) S2 ON S2.ScannerStart = P.ScannerNr2
    WHERE S2.ScannerStart IS NULL -- Only take scanners not yet in the table

    INSERT ##BeaconsInS0 (ScannerStart, ScannerNow, X, Y, Z)
    SELECT B.Scannernr, B.ScannerNr, B.X, B.Y, B.Z
    FROM ##Beacons B
    INNER JOIN ##ConversionOrder CO ON B.ScannerNr = CO.ScannerTarget
    LEFT JOIN ##BeaconsInS0 BIS ON BIS.ScannerStart = B.ScannerNr
    WHERE BIS.ID IS NULL

    WHILE ((SELECT COUNT(DISTINCT ScannerNow) FROM ##BeaconsInS0 BIS) > 1) -- Keep going until all points are in the Scanner 0 reference frame
    BEGIN 
        
        UPDATE B
        SET B.ScannerNow = Sub.ScannerNr2
        ,   B.X = Sub.X_new
        ,   B.Y = Sub.Y_new
        ,   B.Z = Sub.Z_new
        FROM ##BeaconsInS0 B
        INNER JOIN (
            SELECT BIS.ID, P.ScannerNr2
            ,      CASE WHEN (P.Dir1 = 'Same' AND P.NewAxis1 = 'x') OR (P.Dir2 = 'Same' AND P.NewAxis2 = 'x') OR (P.Dir3 = 'Same' AND P.NewAxis3 = 'x') THEN -1 ELSE 1 END *
                    (CASE WHEN P.NewAxis1 = 'x' THEN P.X 
                          WHEN P.NewAxis2 = 'x' THEN P.Y 
                          WHEN P.NewAxis3 = 'x' THEN P.Z 
                    END - 
                    CASE WHEN P.NewAxis1 = 'x' THEN BIS.X 
                         WHEN P.NewAxis2 = 'x' THEN BIS.Y 
                         WHEN P.NewAxis3 = 'x' THEN BIS.Z 
                    END
                    ) AS X_new
            ,      CASE WHEN (P.Dir1 = 'Same' AND P.NewAxis1 = 'y') OR (P.Dir2 = 'Same' AND P.NewAxis2 = 'y') OR (P.Dir3 = 'Same' AND P.NewAxis3 = 'y') THEN -1 ELSE 1 END *
                    (CASE WHEN P.NewAxis1 = 'y' THEN P.X 
                          WHEN P.NewAxis2 = 'y' THEN P.Y 
                          WHEN P.NewAxis3 = 'y' THEN P.Z 
                    END - 
                    CASE WHEN P.NewAxis1 = 'y' THEN BIS.X 
                         WHEN P.NewAxis2 = 'y' THEN BIS.Y 
                         WHEN P.NewAxis3 = 'y' THEN BIS.Z 
                    END
                    ) AS Y_new
            ,      CASE WHEN (P.Dir1 = 'Same' AND P.NewAxis1 = 'z') OR (P.Dir2 = 'Same' AND P.NewAxis2 = 'z') OR (P.Dir3 = 'Same' AND P.NewAxis3 = 'z') THEN -1 ELSE 1 END *
                    (CASE WHEN P.NewAxis1 = 'z' THEN P.X 
                          WHEN P.NewAxis2 = 'z' THEN P.Y 
                          WHEN P.NewAxis3 = 'z' THEN P.Z 
                    END - 
                    CASE WHEN P.NewAxis1 = 'z' THEN BIS.X 
                         WHEN P.NewAxis2 = 'z' THEN BIS.Y 
                         WHEN P.NewAxis3 = 'z' THEN BIS.Z 
                    END
                    ) AS Z_new--,*
            FROM ##BeaconsInS0 BIS
            INNER JOIN ##ConversionOrder CO ON BIS.ScannerNow = CO.ScannerTarget
            INNER JOIN ##Projections P ON P.ScannerNr2 = CO.ScannerSource AND P.ScannerNr1 = CO.ScannerTarget
        ) Sub ON Sub.ID = B.ID
        
    END

END

;WITH cte_UniqueBeacons AS (
    SELECT X, Y, Z FROM ##BeaconsInS0 GROUP BY X, Y, Z
)
SELECT COUNT(1) AS Part1 FROM cte_UniqueBeacons


CREATE TABLE ##Scanners (ID INT IDENTITY(1,1), ScannerStart INT, ScannerNow INT, X INT, Y INT, Z INT)

INSERT ##Scanners (ScannerStart, ScannerNow, X, Y, Z)
SELECT ScannerNr, ScannerNr, 0, 0, 0
FROM ##Beacons B
GROUP BY ScannerNr

WHILE ((SELECT COUNT(DISTINCT ScannerNow) FROM ##Scanners BIS) > 1) -- Keep going until all points are in the Scanner 0 reference frame
BEGIN 
        
    UPDATE B
    SET B.ScannerNow = Sub.ScannerNr2
    ,   B.X = Sub.X_new
    ,   B.Y = Sub.Y_new
    ,   B.Z = Sub.Z_new
    FROM ##Scanners B
    INNER JOIN (
        SELECT BIS.ID, P.ScannerNr2
        ,      CASE WHEN (P.Dir1 = 'Same' AND P.NewAxis1 = 'x') OR (P.Dir2 = 'Same' AND P.NewAxis2 = 'x') OR (P.Dir3 = 'Same' AND P.NewAxis3 = 'x') THEN -1 ELSE 1 END *
                (CASE WHEN P.NewAxis1 = 'x' THEN P.X 
                        WHEN P.NewAxis2 = 'x' THEN P.Y 
                        WHEN P.NewAxis3 = 'x' THEN P.Z 
                END - 
                CASE WHEN P.NewAxis1 = 'x' THEN BIS.X 
                        WHEN P.NewAxis2 = 'x' THEN BIS.Y 
                        WHEN P.NewAxis3 = 'x' THEN BIS.Z 
                END
                ) AS X_new
        ,      CASE WHEN (P.Dir1 = 'Same' AND P.NewAxis1 = 'y') OR (P.Dir2 = 'Same' AND P.NewAxis2 = 'y') OR (P.Dir3 = 'Same' AND P.NewAxis3 = 'y') THEN -1 ELSE 1 END *
                (CASE WHEN P.NewAxis1 = 'y' THEN P.X 
                        WHEN P.NewAxis2 = 'y' THEN P.Y 
                        WHEN P.NewAxis3 = 'y' THEN P.Z 
                END - 
                CASE WHEN P.NewAxis1 = 'y' THEN BIS.X 
                        WHEN P.NewAxis2 = 'y' THEN BIS.Y 
                        WHEN P.NewAxis3 = 'y' THEN BIS.Z 
                END
                ) AS Y_new
        ,      CASE WHEN (P.Dir1 = 'Same' AND P.NewAxis1 = 'z') OR (P.Dir2 = 'Same' AND P.NewAxis2 = 'z') OR (P.Dir3 = 'Same' AND P.NewAxis3 = 'z') THEN -1 ELSE 1 END *
                (CASE WHEN P.NewAxis1 = 'z' THEN P.X 
                        WHEN P.NewAxis2 = 'z' THEN P.Y 
                        WHEN P.NewAxis3 = 'z' THEN P.Z 
                END - 
                CASE WHEN P.NewAxis1 = 'z' THEN BIS.X 
                        WHEN P.NewAxis2 = 'z' THEN BIS.Y 
                        WHEN P.NewAxis3 = 'z' THEN BIS.Z 
                END
                ) AS Z_new--,*
        FROM ##Scanners BIS
        INNER JOIN ##ConversionOrder CO ON BIS.ScannerNow = CO.ScannerTarget
        INNER JOIN ##Projections P ON P.ScannerNr2 = CO.ScannerSource AND P.ScannerNr1 = CO.ScannerTarget
    ) Sub ON Sub.ID = B.ID
        
END


;WITH cte_1 AS (
SELECT SC.X,
       SC.Y,
       SC.Z
FROM ##Scanners SC
GROUP BY SC.X,
         SC.Y,
         SC.Z
)
SELECT TOP (1) ABS(SC.x - SC2.x) + ABS(SC.y - SC2.y) + ABS(SC.z - SC2.z) AS Part2
FROM cte_1 SC
CROSS APPLY cte_1 SC2
ORDER BY 1 DESC


DROP TABLE ##Projections
DROP TABLE ##RelatedPoints
DROP TABLE ##InternalDistances
DROP TABLE ##Beacons
DROP TABLE ##BeaconsInS0
DROP TABLE ##ConversionOrder
DROP TABLE ##Scanners
