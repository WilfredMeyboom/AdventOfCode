USE Test_WME

SET NOCOUNT ON

DECLARE @year VARCHAR(4) = '2024'
DECLARE @day VARCHAR(2)  = '16'

EXEC dbo.GetInput @year = @year, @day = @day
EXEC dbo.ParseInput @year = @year, @day = @day 

--SELECT TOP 10 * FROM ##Input
--SELECT TOP 10 * FROM ##InputInts
--SELECT TOP 10 * FROM ##InputNumbered
--SELECT TOP 10 * FROM ##InputGrid
--SELECT TOP 10 * FROM ##InputSplit
--SELECT TOP 10 * FROM ##InputSplitCust

CREATE TABLE ##Grid (ID INT IDENTITY(1,1), RowNr INT, ColNr INT, Steps INT, Dir INT, Turns INT)

INSERT ##Grid (RowNr, ColNr, Steps, Dir, Turns)
SELECT RowNr, ColNr
, CASE WHEN Val = 'S' THEN 0 ELSE NULL END
, CASE WHEN Val = 'S' THEN 90 ELSE NULL END
, CASE WHEN Val = 'S' THEN 0 ELSE NULL END
FROM ##InputGrid
WHERE Val <> '#'

CREATE UNIQUE INDEX IX_Grid ON ##Grid(RowNr, ColNr)
CREATE INDEX IX_GridSteps ON ##Grid (Steps)

DECLARE @RowCount INT = 1
DECLARE @Cnt INT = 1


WHILE @RowCount > 0
BEGIN

    UPDATE G
    SET Steps = G2.Steps + 1
--SELECT *
    ,   Dir  = CASE WHEN G.RowNr < G2.RowNR THEN 0
                    WHEN G.ColNr > G2.ColNR THEN 90
                    WHEN G.RowNr > G2.RowNR THEN 180
                    WHEN G.ColNr < G2.ColNR THEN 270
               END
    ,   Turns = G2.Turns + CASE WHEN (G.RowNr < G2.RowNR AND G2.Dir = 0) 
                                  OR (G.ColNr > G2.ColNR AND G2.Dir = 90)
                                  OR (G.RowNr > G2.RowNR AND G2.Dir = 180)
                                  OR (G.ColNr < G2.ColNR AND G2.Dir = 270)
                                THEN 0 ELSE 1
                           END
    FROM ##Grid G
    INNER JOIN ##Grid G2 ON ((G.RowNr = G2.RowNr AND ABS(G.ColNr - G2.ColNr) = 1) OR
                             (G.ColNr = G2.ColNr AND ABS(G.RowNr - G2.RowNr) = 1)) AND G2.Steps IS NOT NULL
    WHERE G.Steps IS NULL 
    OR (G.Turns > G2.Turns + CASE WHEN (G.RowNr < G2.RowNR AND G2.Dir = 0) 
                                  OR (G.ColNr > G2.ColNR AND G2.Dir = 90)
                                  OR (G.RowNr > G2.RowNR AND G2.Dir = 180)
                                  OR (G.ColNr < G2.ColNR AND G2.Dir = 270)
                                THEN 0 ELSE 1
                           END)
    OR (G.Turns > G2.Turns + CASE WHEN (G.RowNr < G2.RowNR AND G2.Dir = 0) 
                                  OR (G.ColNr > G2.ColNR AND G2.Dir = 90)
                                  OR (G.RowNr > G2.RowNR AND G2.Dir = 180)
                                  OR (G.ColNr < G2.ColNR AND G2.Dir = 270)
                                THEN 0 ELSE 1
                           END
                       AND G.Steps > G2.Steps)

    SET @RowCount = @@ROWCOUNT

    SET @Cnt = @Cnt + 1

    IF @Cnt % 100 = 0 PRINT '@Cnt: ' + CAST(@Cnt AS VARCHAR(10)) + ' at: ' + CAST(GETDATE() AS VARCHAR(50))

END



--WHILE @RowCount > 0
--BEGIN

--    UPDATE G
--    SET Steps = G2.Steps + 1
--    --SELECT * 
--    FROM ##Grid G
--    INNER JOIN ##Grid G2 ON ((G.RowNr = G2.RowNr AND ABS(G.ColNr - G2.ColNr) = 1) OR
--                             (G.ColNr = G2.ColNr AND ABS(G.RowNr - G2.RowNr) = 1)) 
--                        AND G2.Steps IS NOT NULL
--    WHERE G.Steps IS NULL

--    SET @RowCount = @@ROWCOUNT
--END
/*
DROP TABLE Day16_Grid
CREATE TABLE Day16_Grid (ID INT IDENTITY(1,1), RowNr INT, ColNr INT, Steps INT, Dir INT, Turns INT)

INSERT Day16_Grid (RowNr, ColNr, Steps, Dir, Turns)
SELECT RowNr, ColNr, Steps, Dir, Turns
FROM ##Grid

CREATE UNIQUE INDEX IX_Grid ON Day16_Grid(RowNr, ColNr)
*/
--SELECT * FROM ##Grid


SELECT Steps + 1000 * Turns AS Part1--, *
FROM ##Grid G
INNER JOIN ##InputGrid IG ON G.ColNr = IG.ColNr AND G.RowNr = IG.RowNr
WHERE IG.Val = 'E'

-- Runtime: 
-- 2:42:21


;WITH cte_Path AS (
    SELECT G.RowNr, G.ColNr, G.Steps, G.Turns, G.Dir AS CurrentDir, G.Dir AS PrevDir
    FROM ##Grid G
    INNER JOIN ##InputGrid IG ON G.ColNr = IG.ColNr AND G.RowNr = IG.RowNr
    WHERE IG.Val = 'E'

    UNION ALL

    SELECT G.RowNr, G.ColNr, G.Steps, G.Turns, G.Dir, cS.CurrentDir
    FROM ##Grid G
    INNER JOIN cte_Path cS ON G.Steps = cS.Steps - 1 
                          AND ((G.RowNr = cS.RowNr AND ABS(G.ColNr - cS.ColNr) = 1) OR
                               (G.ColNr = cS.ColNr AND ABS(G.RowNr - cS.RowNr) = 1)) 
                          AND G.Turns <= cS.Turns + CASE WHEN G.Dir = cS.PrevDir THEN 1 ELSE 0 END

), cte_Cells AS (
    SELECT RowNr, ColNr
    FROM cte_Path
    GROUP BY RowNr, ColNr
--    ORDER BY RowNr, ColNr
)
SELECT COUNT(1) AS Part2
FROM cte_Cells
OPTION (MAXRECURSION 20000)
--484 is too low
--569 is too high

/*

DROP TABLE ##Grid

*/


/*

;WITH cte_Path AS (
    SELECT G.RowNr, G.ColNr, G.Steps, G.Turns, G.Dir AS CurrentDir, G.Dir AS PrevDir
    FROM Day16_Grid G
    INNER JOIN ##InputGrid IG ON G.ColNr = IG.ColNr AND G.RowNr = IG.RowNr
    WHERE IG.Val = 'E'

    UNION ALL

    SELECT G.RowNr, G.ColNr, G.Steps, G.Turns, G.Dir, cS.CurrentDir
    FROM Day16_Grid G
    INNER JOIN cte_Path cS ON G.Steps = cS.Steps - 1 
                          AND ((G.RowNr = cS.RowNr AND ABS(G.ColNr - cS.ColNr) = 1) OR
                               (G.ColNr = cS.ColNr AND ABS(G.RowNr - cS.RowNr) = 1)) 
                          AND G.Turns <= cS.Turns + CASE WHEN G.Dir = cS.PrevDir THEN 1 ELSE 0 END

), cte_Cells AS (
    SELECT RowNr, ColNr
    FROM cte_Path
    GROUP BY RowNr, ColNr
--    ORDER BY RowNr, ColNr
)
SELECT COUNT(1) AS Part2
FROM cte_Cells
OPTION (MAXRECURSION 20000)

*/