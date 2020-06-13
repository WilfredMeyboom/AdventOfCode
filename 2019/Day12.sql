use Test_WME
GO

SET NOCOUNT ON

/*
<x=14, y=15, z=-2>
<x=17, y=-3, z=4>
<x=6, y=12, z=-13>
<x=-2, y=10, z=-8>
*/


CREATE TABLE ##Moons (ID INT IDENTITY(1,1), x INT, y INT, z INT, vx INT, vy INT, vz INT)
CREATE TABLE ##MoonsHistory (ID INT, x INT, y INT, z INT, vx INT, vy INT, vz INT, steps INT)

INSERT ##Moons (x, y, z, vx, vy, vz) VALUES
(14, 15, -2, 0, 0, 0),
(17, -3, 4, 0, 0, 0),
(6, 12, -13, 0, 0, 0),
(-2, 10, -8, 0, 0, 0)

--For part 2

DECLARE @Counter INT = 0

WHILE @Counter < 1000000--1000
BEGIN

    ;WITH cte_speedChanges AS (
        SELECT S.ID,
        SUM(CASE WHEN S.x < T.x THEN 1 WHEN S.x > T.x THEN -1 ELSE 0 END) AS vx,
        SUM(CASE WHEN S.y < T.y THEN 1 WHEN S.y > T.y THEN -1 ELSE 0 END) AS vy,
        SUM(CASE WHEN S.z < T.z THEN 1 WHEN S.z > T.z THEN -1 ELSE 0 END) AS vz
        FROM ##Moons S
        INNER JOIN ##Moons T ON S.ID <> T.ID
        GROUP BY S.ID
    )
    UPDATE M
    SET M.vx = M.vx + csC.vx,
        M.vy = M.vy + csC.vy,
        M.vz = M.vz + csC.vz
    FROM ##Moons M
    INNER JOIN cte_speedChanges csC ON M.ID = csC.ID

    UPDATE ##Moons
    SET x = x + vx,
        y = y + vy,
        z = z + vz
  
    INSERT ##MoonsHistory
    SELECT *, @Counter FROM ##Moons

    SET @Counter = @Counter + 1

END

-- For part 1

;WITH cte_EnergyPerPlanet AS (
    SELECT (ABS(x) + ABS(y) + ABS(z)) * (ABS(vx) + ABS(vy) + ABS(vz)) AS Energy
    FROM ##MoonsHistory
    WHERE steps = 999
)
SELECT SUM(Energy)
FROM cte_EnergyPerPlanet


DROP TABLE ##Moons

--10189 Is correct for part 1

--INSERT [dbo].[Day12_MoonsHistory] (ID , x , y , z , vx , vy , vz , steps)
--SELECT ID , x , y , z , vx , vy , vz , steps FROM ##MoonsHistory


;WITH cte_Max AS (
    SELECT ID, MAX(x*x + vx*vx) AS MaxXVX
    FROM Day12_MoonsHistory
    GROUP BY ID
)
SELECT T1.ID, T1.x, T1.vx, T1.steps, T1.steps - LAG(T1.steps, 1, 0) OVER (ORDER BY T1.ID, T1.steps)
FROM Day12_MoonsHistory T1
INNER JOIN cte_Max T2 ON T1.ID = T2.ID AND (T1.x * T1.x + T1.vx * T1.vx) = T2.MaxXVX
ORDER BY 1,2,3,4


;WITH cte_Max AS (
    SELECT ID, MAX(y*y + vy*vy) AS MaxyVy
    FROM Day12_MoonsHistory
    GROUP BY ID
)
SELECT T1.ID, T1.y, T1.vy, T1.steps, T1.steps - LAG(T1.steps, 1, 0) OVER (ORDER BY T1.ID, T1.steps)
FROM Day12_MoonsHistory T1
INNER JOIN cte_Max T2 ON T1.ID = T2.ID AND (T1.y * T1.y + T1.vy * T1.vy) = T2.MaxyVy
ORDER BY 1,2,3,4


;WITH cte_Max AS (
    SELECT ID, MAX(z*z + vz*vz) AS MaxzVz
    FROM Day12_MoonsHistory
    GROUP BY ID
)
SELECT T1.ID, T1.z, T1.vz, T1.steps, T1.steps - LAG(T1.steps, 1, 0) OVER (ORDER BY T1.ID, T1.steps)
FROM Day12_MoonsHistory T1
INNER JOIN cte_Max T2 ON T1.ID = T2.ID AND (T1.z * T1.z + T1.vz * T1.vz) = T2.MaxzVz
ORDER BY 1,2,3,4


--84032
--231614
--193052


---- DROP TABLE ##MoonsHistory

SELECT CAST(84032 AS BIGINT) * CAST(231614 AS BIGINT) * CAST(193052 AS BIGINT)

--https://www.calculatorsoup.com/calculators/math/lcm.php
--Calculate LCM (Least common multiple
--469671086427712 is correct for part 2


