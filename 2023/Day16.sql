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


CREATE TABLE ##LightFronts (ID INT IDENTITY(1,1), RowNr INT, ColNr INT, Dir CHAR, Attempt INT)
CREATE TABLE ##Energized (ID INT IDENTITY(1,1), RowNr INT, ColNr INT, Dir CHAR, Step INT, Attempt INT)

DECLARE @Step INT = 0

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

WHILE (SELECT COUNT(1) FROM ##LightFronts LF) > 0
BEGIN

    INSERT ##Energized (RowNr, ColNr, Dir, Step, Attempt)
    SELECT LF.RowNr, LF.ColNr, LF.Dir, @Step, LF.Attempt 
    FROM ##LightFronts LF
    LEFT JOIN ##Energized E ON E.RowNr = LF.RowNr AND E.ColNr = LF.ColNr AND E.Dir = LF.Dir AND E.Attempt = LF.Attempt
    WHERE E.ID IS NULL

    SET @Step = @Step + 1


    INSERT ##LightFronts (RowNr, ColNr, Dir, Attempt)
    SELECT LF.RowNr, LF.ColNr, '*', LF.Attempt
    FROM ##LightFronts LF
    INNER JOIN ##InputGrid IG ON LF.RowNr = IG.RowNr AND LF.ColNr = IG.ColNr
    WHERE (IG.Val = '|' AND LF.Dir IN ('W', 'E')) OR (IG.Val = '-' AND LF.Dir IN ('N', 'S'))
 
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

    UPDATE LF
    SET LF.RowNr = CASE WHEN Dir = 'N' THEN LF.RowNr - 1
                        WHEN Dir = 'S' THEN LF.RowNr + 1
                        ELSE LF.RowNr END
    ,   LF.ColNr = CASE WHEN Dir = 'W' THEN LF.ColNr - 1
                        WHEN Dir = 'E' THEN LF.ColNr + 1
                        ELSE LF.ColNr END
    FROM ##LightFronts LF

    DELETE LF
    FROM ##LightFronts LF 
    LEFT JOIN ##InputGrid IG ON LF.RowNr = IG.RowNr AND LF.ColNr = IG.ColNr
    LEFT JOIN ##Energized E ON E.RowNr = LF.RowNr AND E.ColNr = LF.ColNr AND E.Dir = LF.Dir AND E.Attempt = LF.Attempt
    WHERE IG.Ind IS NULL OR E.ID IS NOT NULL

END


;WITH cte_PerAttempt AS (
    SELECT Attempt, RowNr, ColNr FROM ##Energized E GROUP BY Attempt, RowNr, ColNr 
)
SELECT TOP (1) COUNT(1) AS Part1
FROM cte_PerAttempt
WHERE Attempt = (SELECT Attempt FROM ##Energized E WHERE RowNr = 0 AND ColNr = 0 AND Dir = 'E')
GROUP BY Attempt


;WITH cte_PerAttempt AS (
    SELECT Attempt, RowNr, ColNr FROM ##Energized E GROUP BY Attempt, RowNr, ColNr 
)
SELECT TOP (1) COUNT(1) AS Part2
FROM cte_PerAttempt
GROUP BY Attempt
ORDER BY 1 DESC

/*


DROP TABLE ##LightFronts
DROP TABLE ##Energized


*/
