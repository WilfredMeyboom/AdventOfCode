USE Test_WME

SET NOCOUNT ON

DECLARE @year VARCHAR(4) = '2023'
DECLARE @day VARCHAR(2)  = '17'

EXEC dbo.GetInput @year = @year, @day = @day
EXEC dbo.ParseInput @year = @year, @day = @day 

--SELECT TOP 10 * FROM ##Input
--SELECT TOP 10 * FROM ##InputInts
--SELECT TOP 10 * FROM ##InputNumbered
--SELECT TOP 10 * FROM ##InputSplit
--SELECT TOP 10 * FROM ##InputSplitCust

CREATE UNIQUE INDEX IX_InputGrid_UQ ON ##InputGrid (RowNr, ColNr)
  

CREATE TABLE ##OutputGrid (ID INT IDENTITY(1,1), RowNr INT, ColNr INT, HeatLoss INT, TotalHeatLoss INT, Last3Moves CHAR(3), Step INT)

CREATE NONCLUSTERED INDEX IX_OutputGrid_RowNrColNr ON ##OutputGrid (RowNr, ColNr) INCLUDE ([TotalHeatLoss])
GO

INSERT ##OutputGrid
(
    RowNr,
    ColNr,
    HeatLoss,
    TotalHeatLoss,
    Last3Moves,
    Step
)
SELECT 0,0,0,0,'',0

DECLARE @Step INT = 0
DECLARE @Count INT = 1


WHILE @Count > 0 --AND @Step < 10
BEGIN

    INSERT ##OutputGrid (RowNr, ColNr, TotalHeatLoss, HeatLoss, Last3Moves, Step/*, FollowedRoute*/)
    SELECT DISTINCT 
           IG.RowNr
    ,      IG.ColNr
    ,      OG.TotalHeatLoss + IG.Val
    ,      IG.Val
    ,      RIGHT(OG.Last3Moves + CASE WHEN OG.RowNr = IG.RowNr + 1 THEN 'N'
                                        WHEN OG.RowNr = IG.RowNr - 1 THEN 'S'
                                        WHEN OG.ColNr = IG.ColNr + 1 THEN 'W'
                                        WHEN OG.ColNr = IG.ColNr - 1 THEN 'E'
                                   END, 3)
    ,      OG.Step + 1
    FROM ##OutputGrid OG
    INNER JOIN ##InputGrid IG ON (OG.RowNr = IG.RowNr + 1 AND OG.ColNr = IG.ColNr AND Last3Moves <> 'NNN' AND RIGHT(Last3Moves, 1) <> 'S')
                              OR (OG.RowNr = IG.RowNr - 1 AND OG.ColNr = IG.ColNr AND Last3Moves <> 'SSS' AND RIGHT(Last3Moves, 1) <> 'N')
                              OR (OG.RowNr = IG.RowNr AND OG.ColNr = IG.ColNr + 1 AND Last3Moves <> 'WWW' AND RIGHT(Last3Moves, 1) <> 'E')
                              OR (OG.RowNr = IG.RowNr AND OG.ColNr = IG.ColNr - 1 AND Last3Moves <> 'EEE' AND RIGHT(Last3Moves, 1) <> 'W')
    WHERE OG.Step = @Step
    
    SET @Count = @@ROWCOUNT

    SET @Step = @Step + 1

    DELETE FROM OG
    FROM ##OutputGrid OG
    INNER JOIN ##OutputGrid OG2 ON OG2.RowNr = OG.RowNr AND OG2.ColNr = OG.ColNr 
                               AND (OG2.TotalHeatLoss + 9 < OG.TotalHeatLoss         -- If another direction is nine cheaper we don't need this path
                                OR (OG2.TotalHeatLoss < OG.TotalHeatLoss AND OG.Last3Moves = OG2.Last3Moves) -- If there is a cheaper path with the same direction, we don't need this path
                                OR (OG2.TotalHeatLoss = OG.TotalHeatLoss AND OG.Last3Moves = OG2.Last3Moves AND OG.Step > OG2.Step)) -- If there is a path with the same heatloss from the same direction but where we arrived earlier, we don't need this latest path

END

;WITH cte_Max AS (
    SELECT MAX(RowNr) MaxRowNr, MAX(ColNr) MaxColNr FROM ##InputGrid OG
)
SELECT MIN(OG.TotalHeatLoss) AS Part1
FROM ##OutputGrid OG 
CROSS APPLY cte_Max c
WHERE RowNr = c.MaxRowNr AND ColNr = c.MaxColNr


CREATE TABLE ##OutputGrid2 (ID INT IDENTITY(1,1), RowNr INT, ColNr INT, HeatLoss INT, TotalHeatLoss INT, Dir CHAR, Step INT)

CREATE NONCLUSTERED INDEX IX_OutputGrid2_RowNrColNr ON ##OutputGrid2 (RowNr, ColNr) INCLUDE ([TotalHeatLoss])
GO


INSERT ##OutputGrid2
(
    RowNr,
    ColNr,
    HeatLoss,
    TotalHeatLoss,
    Dir,
    Step
)
SELECT 0,0,0,0,'',0

DECLARE @Count INT = 1
DECLARE @Step INT = 0

--WHILE @Count > 0
--BEGIN

    ;WITH cte_To10 AS (
        SELECT TOP 7 ROW_NUMBER() OVER (ORDER BY (SELECT 0)) + 3 AS Nr FROM sys.messages
    ), cte_Move AS (
        SELECT OG.RowNr AS StartRow
        , OG.ColNr AS StartCol
        , IG.RowNr AS EndRow
        , IG.ColNr AS EndCol
        FROM ##OutputGrid2 OG
        CROSS APPLY cte_To10 c
        INNER JOIN ##InputGrid IG ON (OG.RowNr = IG.RowNr + c.Nr AND OG.ColNr = IG.ColNr AND Dir <> 'S')
                                  OR (OG.RowNr = IG.RowNr - c.Nr AND OG.ColNr = IG.ColNr AND Dir <> 'N')
                                  OR (OG.RowNr = IG.RowNr AND OG.ColNr = IG.ColNr + c.Nr AND Dir <> 'E')
                                  OR (OG.RowNr = IG.RowNr AND OG.ColNr = IG.ColNr - c.Nr AND Dir <> 'W')
        WHERE Step = @Step
    )
    SELECT * --StartRow, EndRow, StartCol, EndCol, SUM(CAST(IG2.Val AS INT)) AS AccumulatedHeatLoss
    FROM cte_Move M
    INNER JOIN ##InputGrid IG2 ON (IG2.RowNr BETWEEN StartRow AND EndRow OR IG2.RowNr BETWEEN EndRow AND StartRow) 
                              AND (IG2.ColNr BETWEEN StartCol AND EndCol OR IG2.ColNr BETWEEN EndCol AND StartCol)
    GROUP BY StartRow, EndRow, StartCol, EndCol

--END

/*

Vanaf een punt (x,y) bewegen we 4,5,6,7,8,9 en 10 stappen in een richting
Deze richting is of een draai linksom of een draai rechtsom
Voor elke stap (1 t/m 10) berekenen we de total heatloss. Als deze hoger is dan een bestaande waarde dan is dit een richting die overbodig is



*/


/*

DROP TABLE ##OutputGrid

*/


-- Runtime 1 h 54 min
-- Hij komt op 1023
-- Hij heeft 362 steps nodig

-- 1023 is correct
