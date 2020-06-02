use Test_WME

CREATE TABLE #Input (Nr NVARCHAR(MAX));

BULK INSERT #Input
FROM 'C:\Source\AdventOfCode\input10.txt'
WITH (ROWTERMINATOR = '0x0A');

CREATE TABLE ##Asteroids (ID INT IDENTITY(1,1), x INT, y INT, Val CHAR)

;WITH cte_Pixels AS (
    SELECT 0 AS x
    ,      ROW_NUMBER() OVER (ORDER BY (SELECT 0)) - 1 AS y
    ,      SUBSTRING(Nr, 1, 1) AS Val
    ,      SUBSTRING(Nr, 2, LEN(Nr)) AS Rest
    FROM #Input
    UNION ALL
    SELECT x + 1
    ,      y
    ,      SUBSTRING(Rest, 1, 1) AS Val
    ,      SUBSTRING(Rest, 2, LEN(Rest)) AS Rest
    FROM cte_Pixels
    WHERE LEN(Rest) > 0
)
INSERT ##Asteroids(x, y, Val)
SELECT x, y, Val
FROM cte_Pixels
OPTION (MAXRECURSION 20000)

DROP TABLE #Input

--DROP TABLE ##Asteroids

;WITH cte_Angles AS (
SELECT A1.x, A1.y
,   CASE WHEN A1.x = A2.x AND A1.y > A2.y THEN -180
         WHEN A1.x = A2.x AND A1.y < A2.y THEN 180
         ELSE (CAST(A2.y AS DECIMAL(18,8)) - A1.y)/(CAST(A2.x AS DECIMAL(18,8)) - A1.x) END AS Angle
,   CASE WHEN A1.x > A2.x THEN 'W' ELSE 'E' END AS GeneralDirection
FROM ##Asteroids A1
INNER JOIN ##Asteroids A2 ON A1.ID <> A2.ID
                         AND A2.Val = '#'
WHERE A1.Val = '#'
GROUP BY A1.x, A1.y
,   CASE WHEN A1.x = A2.x AND A1.y > A2.y THEN -180
         WHEN A1.x = A2.x AND A1.y < A2.y THEN 180
         ELSE (CAST(A2.y AS DECIMAL(18,8)) - A1.y)/(CAST(A2.x AS DECIMAL(18,8)) - A1.x) END
,   CASE WHEN A1.x > A2.x THEN 'W' ELSE 'E' END
)
SELECT x, y, COUNT(1)
FROM cte_Angles
GROUP BY x, y
ORDER BY 3 DESC
-- 22 is incorrect for part 1
-- 272 is too low for part 1
-- 276 is correct for part 1

SELECT A1.x, A1.y
,   CASE WHEN A1.x = A2.x AND A1.y > A2.y THEN -180
         WHEN A1.x = A2.x AND A1.y < A2.y THEN 180
         ELSE (CAST(A2.y AS DECIMAL(18,8)) - A1.y)/(CAST(A2.x AS DECIMAL(18,8)) - A1.x) END AS Angle
,   CASE WHEN A1.x > A2.x THEN 'W' 
         WHEN A1.x < A2.x THEN 'E' 
         WHEN A1.y < A2.y THEN 'A' --Actually N
         ELSE 'S' END AS GeneralDirection
FROM ##Asteroids A1
INNER JOIN ##Asteroids A2 ON A1.ID <> A2.ID
                         AND A2.Val = '#'
WHERE A1.x = 17 AND A1.y = 22
GROUP BY A1.x, A1.y
,   CASE WHEN A1.x = A2.x AND A1.y > A2.y THEN -180
         WHEN A1.x = A2.x AND A1.y < A2.y THEN 180
         ELSE (CAST(A2.y AS DECIMAL(18,8)) - A1.y)/(CAST(A2.x AS DECIMAL(18,8)) - A1.x) END
,   CASE WHEN A1.x > A2.x THEN 'W' 
         WHEN A1.x < A2.x THEN 'E' 
         WHEN A1.y < A2.y THEN 'A' --Actually N
         ELSE 'S' END
ORDER BY GeneralDirection, Angle DESC

-- 200 th asteroid has angle = 1.1764705882352941176 W
-- 200 th asteroid has angle = 0.25	W (previous 200th was incorrect due to incorrect sorting)

SELECT *
,   CASE WHEN A1.x = A2.x AND A1.y > A2.y THEN -180
         WHEN A1.x = A2.x AND A1.y < A2.y THEN 180
         ELSE (CAST(A2.y AS DECIMAL(18,8)) - A1.y)/(CAST(A2.x AS DECIMAL(18,8)) - A1.x) END AS Angle
FROM ##Asteroids A1
INNER JOIN ##Asteroids A2 ON A1.ID <> A2.ID
                         AND A2.Val = '#'
WHERE A1.x = 17 AND A1.y = 22
AND A1.x > A2.x
AND CASE WHEN A1.x = A2.x AND A1.y > A2.y THEN -180
         WHEN A1.x = A2.x AND A1.y < A2.y THEN 180
         ELSE (CAST(A2.y AS DECIMAL(18,8)) - A1.y)/(CAST(A2.x AS DECIMAL(18,8)) - A1.x) END = 0.25

-- x = 0 & y = 2 --> 2 is incorrect for part 2
-- x = 13 & y = 21 --> 1321 is correct for part 2