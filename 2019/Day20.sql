USE Test_WME

SET NOCOUNT ON

CREATE TABLE #Input (Nr NVARCHAR(MAX));

BULK INSERT #Input
FROM 'C:\Source\AdventOfCode\2019\input20.txt'
WITH (ROWTERMINATOR = '0x0A');

CREATE TABLE ##Donut (ID INT IDENTITY(1,1), x INT, y INT, val CHAR(2), UNIQUE(x,y))

;WITH cte_Grid AS (
    SELECT 1 AS x
    ,      ROW_NUMBER() OVER (ORDER BY(SELECT 0)) AS y
    ,      LEFT(Nr, 1) AS val
    ,      SUBSTRING(Nr, 2, LEN(Nr)) AS Rest
    FROM #Input
    UNION ALL
    SELECT X + 1
    ,      Y
    ,      LEFT(Rest, 1)
    ,      SUBSTRING(Rest, 2, LEN(Rest))
    FROM cte_Grid
    WHERE LEN(Rest) > 0
)
INSERT ##Donut(x, y, val)
SELECT x, y, val
FROM cte_Grid
WHERE val <> '#'
OPTION (MAXRECURSION 20000)

DROP TABLE #Input

DELETE FROM ##Donut WHERE val = ' ' OR val = ''

;WITH cte_Portals AS (
    SELECT val, x, y FROM ##Donut WHERE val <> '.'
), cte_PortalLocs AS (
    SELECT RTRIM(P1.val) + RTRIM(P2.val) AS PortalName
    , CASE WHEN DP1.val IS NOT NULL THEN P1.x ELSE P2.x END AS x
    , CASE WHEN DP1.val IS NOT NULL THEN P1.y ELSE P2.y END AS y
    FROM cte_Portals P1
    INNER JOIN cte_Portals P2 ON (P1.x - P2.x = 1 AND P1.y = P2.y)
                              OR (P1.y - P2.y = 1 AND P1.x = P2.x)
    LEFT JOIN ##Donut DP1 ON DP1.val = '.' AND ((ABS(DP1.x - P1.x) = 1 AND DP1.y = P1.y) OR (ABS(DP1.y - P1.y) = 1 AND DP1.x = P1.x))
    LEFT JOIN ##Donut DP2 ON DP2.val = '.' AND ((ABS(DP2.x - P2.x) = 1 AND DP2.y = P2.y) OR (ABS(DP2.y - P2.y) = 1 AND DP2.x = P2.x))
)
UPDATE D
SET D.val = cPL.PortalName
--SELECT *
FROM ##Donut D
INNER JOIN cte_PortalLocs cPL ON D.x = cPL.x AND D.y = cPL.y

DELETE FROM ##Donut WHERE val <> '.' AND LEN(val) = 1

--SELECT * FROM ##Donut

CREATE TABLE ##Portals(ID INT IDENTITY(1,1), PortalName CHAR(2), fromX INT, fromY INT, toX INT, toY INT, LevelChange INT)
INSERT ##Portals(PortalName, fromX, fromY, LevelChange)
SELECT val, x, y
,      CASE WHEN x BETWEEN 20 AND 100 AND y BETWEEN 20 AND 100 THEN 1 ELSE -1 END AS LevelChange
FROM ##Donut WHERE LEN(val) > 1 AND val NOT IN ('AA','ZZ')

UPDATE FP
SET toX = TP.fromX
,   toY = TP.fromY
FROM ##Portals FP
INNER JOIN ##Portals TP ON FP.PortalName = TP.PortalName AND FP.ID <> TP.ID

CREATE TABLE ##DonutRoute(ID INT IDENTITY(1,1), x INT, y INT, z INT, nrOfSteps INT, UNIQUE(x,y,z))
INSERT ##DonutRoute(x,y,z,nrOfSteps) SELECT x,y,0,-1 FROM ##Donut WHERE val = 'AA'

SET NOCOUNT ON

DECLARE @DestX INT
DECLARE @DestY INT
DECLARE @DestZ INT = 0
DECLARE @Counter INT = 0

SELECT @DestX = x, @DestY = y FROM ##Donut WHERE val = 'ZZ'

WHILE NOT EXISTS (SELECT 1 FROM ##DonutRoute WHERE x = @DestX AND y = @DestY AND z = @DestZ)
BEGIN

    INSERT ##DonutRoute(x, y, z, nrOfSteps)
    SELECT D.x, D.y, DR.z, MIN(DR.nrOfSteps + 1)
    FROM ##DonutRoute DR
    INNER JOIN ##Donut D ON (ABS(DR.x - D.x) = 1 AND DR.y = D.y)
                         OR (ABS(DR.y - D.y) = 1 AND DR.x = D.x)
    LEFT JOIN ##DonutRoute Al ON D.x = Al.x AND D.y = Al.y AND DR.z = Al.z
    WHERE Al.nrOfSteps IS NULL AND (D.val <> 'ZZ' OR DR.z = 0)
    GROUP BY D.x, D.y, DR.z

    /* Part 1
    INSERT ##DonutRoute(x, y, nrOfSteps)
    SELECT DP.x, DP.y, DR.nrOfSteps - 1 --Stepping through a portal is a free movement
    FROM ##DonutRoute DR
    INNER JOIN ##Donut D ON D.x = DR.x AND D.y = DR.y AND D.val <> '.'
    INNER JOIN ##Donut DP ON D.x <> DP.x AND D.y <> DP.y  AND D.val = DP.val
    LEFT JOIN ##DonutRoute Al ON DP.x = Al.x AND DP.y = Al.y
    WHERE Al.nrOfSteps IS NULL
    */ 
    
    INSERT ##DonutRoute (x, y, z, nrOfSteps)
    SELECT P.toX, P.toY, DR.z + P.LevelChange, Dr.nrOfSteps - 1 --Stepping through a portal is a free movement
    FROM ##DonutRoute DR
    INNER JOIN ##Portals P ON DR.x = P.fromX AND DR.y = P.fromY
    LEFT JOIN ##DonutRoute Al ON P.toX = Al.x AND P.toY = Al.y AND DR.z + P.LevelChange = Al.z
    WHERE Al.nrOfSteps IS NULL AND (DR.z <> 0 OR (P.fromX BETWEEN 20 AND 100 AND P.fromY BETWEEN 20 AND 100)) 

    SET @Counter = @Counter + 1
    --IF (@Counter % 100 = 0) PRINT '100 iterations done ' + CAST(GETDATE() AS VARCHAR(50)) 


END

SELECT DR.ID, DR.x, DR.y, DR.nrOfSteps - 1 AS nrOfSteps FROM ##DonutRoute DR
INNER JOIN ##Donut D ON DR.x = D.x AND DR.y = D.y
WHERE DR.x = @DestX AND DR.y = @DestY 

/*
DROP TABLE ##Donut
DROP TABLE ##DonutRoute
DROP TABLE ##Portals
*/

--576 is too high for part 1
--552 is correct for part 1


--SELECT * FROM ##DonutRoute

--DROP TABLE ##PortalRoute
--DROP TABLE ##PortaLDist
--DROP TABLE ##PortalDistCum

CREATE TABLE ##PortalRoute (ID INT IDENTITY(1,1), FromPortal CHAR(2), xs INT, ys INT, x INT, y INT, Dist INT)

INSERT ##PortalRoute (FromPortal, xs, ys, x, y, Dist)
SELECT val, x, y, x, y, -1
FROM ##Donut WHERE val <> '.'

DECLARE @RW INT = 1

WHILE @RW > 0
BEGIN

    INSERT ##PortalRoute (FromPortal, xs, ys, x, y, Dist)
    SELECT R.FromPortal, R.xs, R.ys, D.x, D.y, R.Dist + 1
    FROM ##PortalRoute R
    INNER JOIN ##Donut D ON (ABS(R.x - D.x) = 1 AND R.y = D.y)
                         OR (ABS(R.y - D.y) = 1 AND R.x = D.x)
    LEFT JOIN ##PortalRoute Al ON D.x = Al.x AND D.y = Al.y and Al.FromPortal = R.FromPortal
    WHERE Al.ID IS NULL

    SET @RW = @@ROWCOUNT

END


CREATE TABLE ##PortalDist (ID INT IDENTITY(1,1), fromPortal CHAR(2), toPortal CHAR(2), dist INT, depthChange INT)

INSERT ##PortalDist (fromPortal, toPortal, dist, depthChange)
SELECT PR.FromPortal, P.Val AS ToPortal, PR.Dist - 1 AS Dist
--For the example
--, CASE WHEN P.x BETWEEN 7 AND 40 AND P.y BETWEEN 7 AND 32 AND PR.xs BETWEEN 7 AND 40 AND PR.ys BETWEEN 7 AND 32 THEN 0
--       WHEN P.x BETWEEN 7 AND 40 AND P.y BETWEEN 7 AND 32 THEN 1
--       WHEN PR.xs BETWEEN 7 AND 40 AND PR.ys BETWEEN 7 AND 32 THEN -1
--       ELSE 0 END
, CASE WHEN P.x BETWEEN 20 AND 100 AND P.y BETWEEN 20 AND 100 AND PR.xs BETWEEN 20 AND 100 AND PR.ys BETWEEN 20 AND 100 THEN 0
       WHEN P.x BETWEEN 20 AND 100 AND P.y BETWEEN 20 AND 100 THEN 1
       WHEN PR.xs BETWEEN 20 AND 100 AND PR.ys BETWEEN 20 AND 100 THEN -1
       ELSE 0 END
FROM ##PortalRoute PR
INNER JOIN ##Donut P ON PR.x = P.x AND PR.y = P.y AND val NOT IN  ('.', 'AA')
WHERE PR.Dist > -1 AND PR.FromPortal <> 'ZZ'

--SELECT * FROM ##PortalDist

CREATE TABLE ##PortalDistCum (ID INT IDENTITY(1,1), fromPortal CHAR(2), toPortal CHAR(2), dist INT, depth INT)
INSERT ##PortalDistCum (fromPortal, toPortal, dist, depth)
SELECT fromPortal, toPortal, dist, 1
FROM ##PortalDist 
WHERE fromPortal = 'AA' AND depthChange > 0


WHILE NOT EXISTS (SELECT 1 FROM ##PortalDistCum WHERE toPortal = 'ZZ')
BEGIN




    INSERT ##PortalDistCum (fromPortal, toPortal, dist, depth)
    SELECT PDC.toPortal AS fromPortal
    ,      PD.toPortal
    ,      MIN(PDC.dist + PD.dist + 1) AS dist
    ,      PDC.depth + PD.depthChange AS depth
    FROM ##PortalDistCum PDC
    INNER JOIN ##PortalDist PD ON PDC.toPortal = PD.fromPortal
    LEFT JOIN ##PortalDistCum Al ON PD.fromPortal = Al.fromPortal 
                                AND PD.toPortal = Al.toPortal
                                AND Al.depth = PDC.depth + PD.depthChange
    LEFT JOIN ##PortalDistCum Al2 ON PD.fromPortal = Al2.toPortal
                                AND PD.toPortal = Al2.fromPortal 
                                AND Al2.depth = PDC.depth   
    WHERE Al.ID IS NULL 
      AND Al2.ID IS NULL 
      AND PDC.depth + PD.depthChange >= 0 
      AND (PD.toPortal <> 'ZZ' OR PDC.depth + PD.depthChange = 0)
    GROUP BY PDC.toPortal, PD.toPortal, PDC.depth + PD.depthChange


END

SELECT * FROM ##PortalDistCum ORDER BY fromPortal

SELECT * FROM ##PortalDistCum WHERE toPortal = 'ZZ'
--SELECT * FROM ##PortalDistCum WHERE fromPortal = 'FX' AND depth = 2
--SELECT * FROM ##PortalDistCum WHERE fromPortal = 'KC' AND depth = 3
--SELECT * FROM ##PortalDistCum WHERE fromPortal = 'HZ' AND depth = 4
--SELECT * FROM ##PortalDistCum WHERE fromPortal = 'BW' AND depth = 5
--SELECT * FROM ##PortalDistCum WHERE fromPortal = 'CI' AND depth = 6
--SELECT * FROM ##PortalDistCum WHERE fromPortal = 'FR' AND depth = 7
--SELECT * FROM ##PortalDistCum WHERE fromPortal = 'MN' AND depth = 8


--6492 is correct for part 2






