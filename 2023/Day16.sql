USE Test_WME

SET NOCOUNT ON

DECLARE @year VARCHAR(4) = '2023'
DECLARE @day VARCHAR(2)  = '16'

EXEC dbo.GetInput @year = @year, @day = @day
EXEC dbo.ParseInput @year = @year, @day = @day 

--SELECT TOP 10 * FROM ##Input
--SELECT TOP 10 * FROM ##InputInts
--SELECT TOP 10 * FROM ##InputNumbered
--SELECT TOP 10 * FROM ##InputGrid
--SELECT TOP 10 * FROM ##InputSplit
--SELECT TOP 10 * FROM ##InputSplitCust
  
CREATE UNIQUE INDEX IX_InputGrid_UQ ON ##InputGrid (RowNr, ColNr)

-- We need to keep track of the first space of each light beam (i.d. the light front)
CREATE TABLE ##LightFronts (ID INT IDENTITY(1,1), RowNr INT, ColNr INT, Dir CHAR, Attempt INT)

-- And we need to store every visited space
CREATE TABLE ##Energized (ID INT IDENTITY(1,1), RowNr INT, ColNr INT, Dir CHAR, Attempt INT)

-- Create light beams all along the borders facing inward (and give them a number called attempt)
;WITH cte_GridSize AS (
    SELECT MIN(RowNr) AS FirstRow
    ,      MIN(ColNr) AS FirstCol
    ,      MAX(RowNr) AS LastRow
    ,      MAX(ColNr) AS LastCol
    FROM ##InputGrid
), cte_StartingPoints AS (
    SELECT RowNr, ColNr, 'S' AS Dir
    FROM ##InputGrid IG
    INNER JOIN cte_GridSize c ON IG.RowNr = c.FirstRow
    UNION
    SELECT RowNr, ColNr, 'N'
    FROM ##InputGrid IG
    INNER JOIN cte_GridSize c ON IG.RowNr = c.LastRow
    UNION
    SELECT RowNr, ColNr, 'E'
    FROM ##InputGrid IG
    INNER JOIN cte_GridSize c ON IG.ColNr = c.FirstCol
    UNION
    SELECT RowNr, ColNr, 'W'
    FROM ##InputGrid IG
    INNER JOIN cte_GridSize c ON IG.ColNr = c.LastCol
)
INSERT ##LightFronts (RowNr, ColNr, Dir, Attempt) 
SELECT RowNr, ColNr, Dir, ROW_NUMBER() OVER (ORDER BY (SELECT 0)) AS Attempt
FROM cte_StartingPoints

-- Remeber which attempt is the one we're looking at in Part 1
DECLARE @AttemptPart1 INT
SELECT @AttemptPart1 = Attempt FROM ##LightFronts WHERE RowNr = 0 AND ColNr = 0 AND Dir = 'E'

-- Keep going until all lightfronts have finished
WHILE (SELECT COUNT(1) FROM ##LightFronts LF) > 0
BEGIN

    -- Store the space where each light front is on now (per attempt) if it wasn't energized before
    INSERT ##Energized (RowNr, ColNr, Dir, Attempt)
    SELECT LF.RowNr, LF.ColNr, LF.Dir, LF.Attempt 
    FROM ##LightFronts LF
    LEFT JOIN ##Energized E ON E.RowNr = LF.RowNr AND E.ColNr = LF.ColNr AND E.Dir = LF.Dir AND E.Attempt = LF.Attempt
    WHERE E.ID IS NULL

    -- If a light front is on a splitter, create a second light front with an arbitrary direction *
    INSERT ##LightFronts (RowNr, ColNr, Dir, Attempt)
    SELECT LF.RowNr, LF.ColNr, '*', LF.Attempt
    FROM ##LightFronts LF
    INNER JOIN ##InputGrid IG ON LF.RowNr = IG.RowNr AND LF.ColNr = IG.ColNr
    WHERE (IG.Val = '|' AND LF.Dir IN ('W', 'E')) OR (IG.Val = '-' AND LF.Dir IN ('N', 'S'))
 
    -- Change the direction of the light fronts if they hit a mirror or if they hit a splitter
    -- Give any newly created light fronts (as a result of the splitter) an opposite direction to the original light front
    UPDATE LF
    SET Dir = CASE WHEN IG.Val = '-' AND LF.Dir IN ('N','S') THEN 'W'
                   WHEN IG.Val = '-' AND LF.Dir = '*' THEN 'E' 
                   WHEN IG.Val = '|' AND LF.Dir IN ('W','E') THEN 'N'
                   WHEN IG.Val = '|' AND LF.Dir = '*' THEN 'S'

                   WHEN IG.Val = '/' AND LF.Dir = 'N' THEN 'E'
                   WHEN IG.Val = '/' AND LF.Dir = 'S' THEN 'W'
                   WHEN IG.Val = '/' AND LF.Dir = 'W' THEN 'S'
                   WHEN IG.Val = '/' AND LF.Dir = 'E' THEN 'N'

                   WHEN IG.Val = '\' AND LF.Dir = 'N' THEN 'W'
                   WHEN IG.Val = '\' AND LF.Dir = 'S' THEN 'E'
                   WHEN IG.Val = '\' AND LF.Dir = 'W' THEN 'N'
                   WHEN IG.Val = '\' AND LF.Dir = 'E' THEN 'S'
                   ELSE Dir END
    FROM ##LightFronts LF
    INNER JOIN ##InputGrid IG ON LF.RowNr = IG.RowNr AND LF.ColNr = IG.ColNr
    WHERE IG.Val <> '.'

    -- Move all light fronts one step in the direction they're facing
    UPDATE LF
    SET LF.RowNr = CASE WHEN Dir = 'N' THEN LF.RowNr - 1
                        WHEN Dir = 'S' THEN LF.RowNr + 1
                        ELSE LF.RowNr END
    ,   LF.ColNr = CASE WHEN Dir = 'W' THEN LF.ColNr - 1
                        WHEN Dir = 'E' THEN LF.ColNr + 1
                        ELSE LF.ColNr END
    FROM ##LightFronts LF

    -- Delete all light fronts that leave the grid, they have done their job
    -- And delete all light fronts that are standing on a space they have previously visited in the same direction (beams can get stuck in a loop, delete them if this happens)
    DELETE LF
    FROM ##LightFronts LF 
    LEFT JOIN ##InputGrid IG ON LF.RowNr = IG.RowNr AND LF.ColNr = IG.ColNr
    LEFT JOIN ##Energized E ON E.RowNr = LF.RowNr AND E.ColNr = LF.ColNr AND E.Dir = LF.Dir AND E.Attempt = LF.Attempt
    WHERE IG.Ind IS NULL OR E.ID IS NOT NULL

END

-- Give the result for the attempt we're looking at for Part 1
;WITH cte_PerAttempt AS (
    SELECT Attempt, RowNr, ColNr FROM ##Energized E GROUP BY Attempt, RowNr, ColNr 
)
SELECT TOP (1) COUNT(1) AS Part1
FROM cte_PerAttempt
WHERE Attempt = @AttemptPart1 
GROUP BY Attempt

-- And now let's look at all results and find the best attempt for Part 2
;WITH cte_PerAttempt AS (
    SELECT Attempt, RowNr, ColNr FROM ##Energized E GROUP BY Attempt, RowNr, ColNr 
)
SELECT TOP (1) COUNT(1) AS Part2
FROM cte_PerAttempt
GROUP BY Attempt
ORDER BY 1 DESC

-- Runtime 7 min

/*

DROP TABLE ##LightFronts
DROP TABLE ##Energized

*/
