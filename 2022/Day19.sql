USE Test_WME

SET NOCOUNT ON

DECLARE @year VARCHAR(4) = '2022'
DECLARE @day VARCHAR(2)  = '19'

EXEC dbo.GetInput @year = @year, @day = @day
EXEC dbo.ParseInput @year = @year, @day = @day 

--SELECT TOP 10 * FROM ##Input
--SELECT TOP 10 * FROM ##InputInts
--SELECT TOP 10 * FROM ##InputNumbered
--SELECT TOP 10 * FROM ##InputGrid
--SELECT TOP 100 * FROM ##InputSplit
--SELECT TOP 10 * FROM ##InputSplitCust
  
CREATE TABLE ##Blueprints (ID INT IDENTITY(1,1), BluePrintNr INT, RobotType VARCHAR(20), OreCost INT, ClayCost INT, ObsidianCost INT)

INSERT ##Blueprints
(
    BluePrintNr,
    RobotType,
    OreCost,
    ClayCost,
    ObsidianCost
)

SELECT I.RowNr AS BluePrintnNr, 'ore' AS RobotType, CAST(Piece AS INT) AS OreCost, 0 AS ClayCost, 0 AS ObsidianCost FROM ##InputSplit I WHERE PieceNr = 7 UNION 
SELECT I.RowNr AS BluePrintnNr, 'clay' AS RobotType, CAST(Piece AS INT) AS OreCost, 0 AS ClayCost, 0 AS ObsidianCost FROM ##InputSplit I WHERE PieceNr = 13 UNION
SELECT I.RowNr AS BluePrintnNr, 'obsidian' AS RobotType, CAST(I.Piece AS INT) AS OreCost, CAST(I2.Piece AS INT) AS ClayCost, 0 AS ObsidianCost FROM ##InputSplit I INNER JOIN ##InputSplit I2 ON I.RowNr = I2.RowNr AND I2.PieceNr = 22 WHERE I.PieceNr = 19 UNION
SELECT I.RowNr AS BluePrintnNr, 'geode' AS RobotType, CAST(I.Piece AS INT) AS OreCost, 0 AS ClayCost, CAST(I2.Piece AS INT) AS ObsidianCost FROM ##InputSplit I INNER JOIN ##InputSplit I2 ON I.RowNr = I2.RowNr AND I2.PieceNr = 31 WHERE I.PieceNr = 28


DECLARE @Time INT = 2
DECLARE @LaggingGeodes INT = 1

CREATE TABLE ##Results (ID INT IDENTITY(1,1), BluePrintNr INT, TimeInMin INT, Ore INT, Clay INT, Obsidian INT, Geode INT, OreRobots INT, ClayRobots INT, ObsidianRobots INT, GeodeRobots INT)

INSERT ##Results
(
    BluePrintNr,
    TimeInMin,
    Ore,
    Clay,
    Obsidian,
    Geode,
    OreRobots,
    ClayRobots,
    ObsidianRobots,
    GeodeRobots
)
SELECT DISTINCT B.BluePrintNr
,      @Time
,      2 AS Ore
,      0 AS Clay
,      0 AS Obsidian
,      0 AS Geode
,      1 AS OreRobots
,      0 AS ClayRobots
,      0 AS ObsidianRobots
,      0 AS GeodeRobots
FROM ##Blueprints B

WHILE @Time < 24
BEGIN

    INSERT ##Results
    (
        BluePrintNr,
        TimeInMin,
        Ore,
        Clay,
        Obsidian,
        Geode,
        OreRobots,
        ClayRobots,
        ObsidianRobots,
        GeodeRobots
    )   
    SELECT DISTINCT P.BluePrintNr
    ,      P.TimeInMin + 1
    ,      P.Ore + P.OreRobots - CASE WHEN B.RobotType = 'ore'      AND P.Ore - B.OreCost >= 0 THEN B.OreCost                                                             -- Check whether we have enough to build a certain type of bot. If yes, build it and reduce the materials
                                      WHEN B.RobotType = 'clay'     AND P.Ore - B.OreCost >= 0 THEN B.OreCost                                                             -- Check whether we have enough to build a certain type of bot. If yes, build it and reduce the materials
                                      WHEN B.RobotType = 'obsidian' AND P.Ore - B.OreCost >= 0 AND P.Clay - B.ClayCost >= 0 THEN B.OreCost                                -- Check whether we have enough to build a certain type of bot. If yes, build it and reduce the materials
                                      WHEN B.RobotType = 'geode'    AND P.Ore - B.OreCost >= 0 AND P.Obsidian - B.ObsidianCost >= 0 THEN B.OreCost ELSE 0 END             -- Check whether we have enough to build a certain type of bot. If yes, build it and reduce the materials
    ,      P.Clay + P.ClayRobots - CASE WHEN B.RobotType = 'obsidian' AND P.Ore - B.OreCost >= 0 AND P.Clay - B.ClayCost >= 0 THEN B.ClayCost ELSE 0 END                  -- Check whether we have enough to build a certain type of bot. If yes, build it and reduce the materials
    ,      P.Obsidian + P.ObsidianRobots - CASE WHEN B.RobotType = 'geode' AND P.Ore - B.OreCost >= 0 AND P.Obsidian - B.ObsidianCost >= 0 THEN B.ObsidianCost ELSE 0 END -- Check whether we have enough to build a certain type of bot. If yes, build it and reduce the materials
    ,      P.Geode + P.GeodeRobots
    ,      P.OreRobots +      CASE WHEN B.RobotType = 'ore'      AND P.Ore - B.OreCost >= 0 THEN 1 ELSE 0 END
    ,      P.ClayRobots +     CASE WHEN B.RobotType = 'clay'     AND P.Ore - B.OreCost >= 0 THEN 1 ELSE 0 END
    ,      P.ObsidianRobots + CASE WHEN B.RobotType = 'obsidian' AND P.Ore - B.OreCost >= 0 AND P.Clay - B.ClayCost >= 0 THEN 1 ELSE 0 END
    ,      P.GeodeRobots +    CASE WHEN B.RobotType = 'geode'    AND P.Ore - B.OreCost >= 0 AND P.Obsidian - B.ObsidianCost >= 0 THEN 1 ELSE 0 END
    FROM ##Results P
    INNER JOIN ##Blueprints B ON B.BluePrintNr = P.BluePrintNr
    WHERE P.TimeInMin = @Time

    DELETE FROM R 
    FROM ##Results R
    INNER JOIN (SELECT BluePrintNr, MAX(Geode) AS MaxGeode FROM ##Results GROUP BY BluePrintNr) R2 ON R2.BluePrintNr = R.BluePrintNr
    WHERE R.Geode < R2.MaxGeode - @LaggingGeodes -- Arbitrary limit to keep the number of permutations under control

    SET @Time = @Time + 1

END

SELECT R.BluePrintNr, MAX(R.Geode) AS MaxGeodes
FROM ##Results R
WHERE TimeInMin = 24
GROUP BY R.BluePrintNr


;WITH cte_Maxes AS (
    SELECT R.BluePrintNr, MAX(R.Geode) AS MaxGeodes
    FROM ##Results R
    WHERE TimeInMin = 24
    GROUP BY R.BluePrintNr
)
SELECT SUM(c.BluePrintNr*c.MaxGeodes) AS Part1
FROM cte_Maxes c

DELETE FROM ##Results WHERE BluePrintNr > 3

DECLARE @Time INT = 24
DECLARE @LaggingGeodes INT = 1

WHILE @Time < 32
BEGIN

    INSERT ##Results
    (
        BluePrintNr,
        TimeInMin,
        Ore,
        Clay,
        Obsidian,
        Geode,
        OreRobots,
        ClayRobots,
        ObsidianRobots,
        GeodeRobots
    )   
    SELECT DISTINCT P.BluePrintNr
    ,      P.TimeInMin + 1
    ,      P.Ore + P.OreRobots - CASE WHEN B.RobotType = 'ore'      AND P.Ore - B.OreCost >= 0 THEN B.OreCost                                                             -- Check whether we have enough to build a certain type of bot. If yes, build it and reduce the materials
                                      WHEN B.RobotType = 'clay'     AND P.Ore - B.OreCost >= 0 THEN B.OreCost                                                             -- Check whether we have enough to build a certain type of bot. If yes, build it and reduce the materials
                                      WHEN B.RobotType = 'obsidian' AND P.Ore - B.OreCost >= 0 AND P.Clay - B.ClayCost >= 0 THEN B.OreCost                                -- Check whether we have enough to build a certain type of bot. If yes, build it and reduce the materials
                                      WHEN B.RobotType = 'geode'    AND P.Ore - B.OreCost >= 0 AND P.Obsidian - B.ObsidianCost >= 0 THEN B.OreCost ELSE 0 END             -- Check whether we have enough to build a certain type of bot. If yes, build it and reduce the materials
    ,      P.Clay + P.ClayRobots - CASE WHEN B.RobotType = 'obsidian' AND P.Ore - B.OreCost >= 0 AND P.Clay - B.ClayCost >= 0 THEN B.ClayCost ELSE 0 END                  -- Check whether we have enough to build a certain type of bot. If yes, build it and reduce the materials
    ,      P.Obsidian + P.ObsidianRobots - CASE WHEN B.RobotType = 'geode' AND P.Ore - B.OreCost >= 0 AND P.Obsidian - B.ObsidianCost >= 0 THEN B.ObsidianCost ELSE 0 END -- Check whether we have enough to build a certain type of bot. If yes, build it and reduce the materials
    ,      P.Geode + P.GeodeRobots
    ,      P.OreRobots +      CASE WHEN B.RobotType = 'ore'      AND P.Ore - B.OreCost >= 0 THEN 1 ELSE 0 END
    ,      P.ClayRobots +     CASE WHEN B.RobotType = 'clay'     AND P.Ore - B.OreCost >= 0 THEN 1 ELSE 0 END
    ,      P.ObsidianRobots + CASE WHEN B.RobotType = 'obsidian' AND P.Ore - B.OreCost >= 0 AND P.Clay - B.ClayCost >= 0 THEN 1 ELSE 0 END
    ,      P.GeodeRobots +    CASE WHEN B.RobotType = 'geode'    AND P.Ore - B.OreCost >= 0 AND P.Obsidian - B.ObsidianCost >= 0 THEN 1 ELSE 0 END
    FROM ##Results P
    INNER JOIN ##Blueprints B ON B.BluePrintNr = P.BluePrintNr
    WHERE P.TimeInMin = @Time

    DELETE FROM R 
    FROM ##Results R
    INNER JOIN (SELECT BluePrintNr, MAX(Geode) AS MaxGeode FROM ##Results GROUP BY BluePrintNr) R2 ON R2.BluePrintNr = R.BluePrintNr
    WHERE R.Geode < R2.MaxGeode - @LaggingGeodes -- Arbitrary limit to keep the number of permutations under control

    SET @Time = @Time + 1

END

SELECT [1]*[2]*[3] AS Part2
FROM (
    SELECT R.BluePrintNr, MAX(R.Geode) AS MaxGeodes
    FROM ##Results R
    WHERE TimeInMin = 32
    GROUP BY R.BluePrintNr
) T
PIVOT (
    MAX(MaxGeodes) FOR BluePrintNr IN ([1],[2],[3])
) PVT

-- Runtime (for part1): 00:54:00
-- Runtime (for part2): 00:11:00

--DROP TABLE ##Blueprints
--DROP TABLE ##Results