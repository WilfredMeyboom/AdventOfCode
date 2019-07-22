use Test_WME

CREATE TABLE Input (Nr NVARCHAR(MAX));

BULK INSERT Input
FROM 'D:\Wilfred\AdventOfCode\input6.txt'
WITH (ROWTERMINATOR = '0x0A');


SELECT * FROM Input

CREATE TABLE #Points (ID INT IDENTITY, x INT, y INT)


INSERT #Points (x,y)
SELECT SUBSTRING(Nr, 1, CHARINDEX(',', Nr) - 1), SUBSTRING(Nr,CHARINDEX(',', Nr) + 1, LEN(Nr)) FROM Input

SELECT MIN(x), MAX(x), MIN(y), MAX(y) FROM #Points

SELECT TOP(500) ROW_NUMBER() OVER (ORDER BY (SELECT 0)) AS Nr
INTO #TableOfNrs
FROM sys.messages 

SELECT * FROM #TableOfNrs

CREATE TABLE #Grid (ID INT IDENTITY, x INT, y INT, ClosestId INT)

;WITH cte_Boundaries AS (
SELECT MIN(x)-1 AS MinX, MAX(x) + 1 AS MaxX, MIN(y) - 1 AS MinY, MAX(y) + 1 AS MaxY FROM #Points
)
INSERT #Grid (x, y)
SELECT T1.Nr, T2.Nr
FROM #TableOfNrs T1
CROSS APPLY #TableOfNrs T2
CROSS APPLY cte_Boundaries cB
WHERE T1.Nr BETWEEN cB.MinX AND cB.MaxX
AND T2.Nr BETWEEN cB.MinY AND cB.MaxY

;WITH cte_Distances AS (
    SELECT G.ID AS GridID, P.ID AS PointID, ABS(G.x - P.x) + ABS(G.y - P.y) AS Distance
    FROM #Grid G
    CROSS APPLY #Points P
), cte_ClosestPoints AS (
    SELECT GridID, MIN(Distance) AS Closest
    FROM cte_Distances
    GROUP BY GridID
), cte_Duplicates AS (
    SELECT D.GridID
    FROM cte_Distances D
    INNER JOIN cte_ClosestPoints P ON D.GridID = P.GridID AND D.Distance = P.Closest
    GROUP BY D.GridID
    HAVING COUNT(1) > 1
)
UPDATE G
SET ClosestId = Sub.PointID
FROM #Grid G
INNER JOIN (
    SELECT D.GridID, D.PointID
    FROM cte_Distances D
    INNER JOIN cte_ClosestPoints P ON D.GridID = P.GridID AND D.Distance = P.Closest
    LEFT JOIN cte_Duplicates DUP ON DUP.GridID = D.GridID
    WHERE DUP.GridID IS NULL
) Sub ON Sub.GridID = G.ID


;WITH cte_Boundaries AS (
    SELECT MIN(x)-1 AS MinX, MAX(x) + 1 AS MaxX, MIN(y) - 1 AS MinY, MAX(y) + 1 AS MaxY FROM #Points
), cte_Infinite AS (
    SELECT DISTINCT ClosestId
    FROM #Grid G
    CROSS APPLY cte_Boundaries cB
    WHERE G.x = cB.MinX
       OR G.x = cB.MaxX
       OR G.y = cB.MinY
       OR G.y = cB.MaxY
)
SELECT g.ClosestId, COUNT(1) AS Area
FROM #Grid G
LEFT JOIN cte_Infinite cI ON G.ClosestId = cI.ClosestId
WHERE cI.ClosestId IS NULL
GROUP BY g.ClosestId
ORDER BY Area DESC


;WITH cte_Distances AS (
    SELECT G.ID AS GridID, P.ID AS PointID, ABS(G.x - P.x) + ABS(G.y - P.y) AS Distance
    FROM #Grid G
    CROSS APPLY #Points P
)
SELECT GridId, SUM(Distance)
FROM cte_Distances
GROUP BY GridID
HAVING SUM(Distance) < 10000


DROP TABLE #TableOfNrs
DROP TABLE Input