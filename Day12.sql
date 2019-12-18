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
CREATE TABLE ##EnergyState (Steps BIGINT, Energy BIGINT)


DECLARE @Counter INT = 0

WHILE @Counter < 100000--1000
BEGIN

    ;WITH cte_speedChanges AS (
        SELECT S.ID, --S.x, S.y, S.z, 
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

    --For part 2
    ;WITH cte_EnergyPerPlanet AS (
        SELECT (ABS(x) + ABS(y) + ABS(z)) * (ABS(vx) + ABS(vy) + ABS(vz)) AS Energy
        FROM ##Moons
    )
    INSERT ##EnergyState (Steps, Energy)
    SELECT @Counter, SUM(Energy)
    FROM cte_EnergyPerPlanet
  
    INSERT ##MoonsHistory
    SELECT *, @Counter FROM ##Moons

    SET @Counter = @Counter + 1

END

/* For part 1
SELECT * FROM ##Moons

;WITH cte_EnergyPerPlanet AS (
    SELECT (ABS(x) + ABS(y) + ABS(z)) * (ABS(vx) + ABS(vy) + ABS(vz)) AS Energy
    FROM ##Moons
)
SELECT SUM(Energy)
FROM cte_EnergyPerPlanet
*/

--DROP TABLE ##EnergyState
DROP TABLE ##Moons

--10189 Is correct for part 1



--SELECT DISTINCT M1.ID, M1.x, M1.Steps
--FROM ##MoonsHistory M1
--WHERE M1.ID = 1
--ORDER BY M1.Steps

;WITH cte_FocusMoon AS (
    SELECT M1.steps, M1.x, M1.vx, MIN(M2.steps - M1.steps) AS MinSteps
    FROM ##MoonsHistory M1
    INNER JOIN ##MoonsHistory M2 ON M1.x = M2.x AND M1.vx = M2.vx
                                AND M1.ID = M2.ID
                                AND M1.steps < M2.steps
    WHERE M1.ID = 1
    GROUP BY M1.steps, M1.x, M1.vx
)
SELECT *
FROM ##MoonsHistory M1
INNER JOIN ##MoonsHistory M2 ON M1.x = M2.x AND M1.vx = M2.vx
                            AND M1.ID = M2.ID
                            AND M1.steps < M2.steps
INNER JOIN cte_FocusMoon cFM ON cFM.steps = M1.steps
                            AND cFM.MinSteps = (M2.steps - M1.steps)
WHERE M1.ID = 1 
ORDER BY M1.steps


