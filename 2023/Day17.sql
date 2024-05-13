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
  

CREATE TABLE ##OutputGrid (ID INT IDENTITY(1,1), RowNr INT, ColNr INT, HeatLoss INT, TotalHeatLoss INT, Last3Moves CHAR(3), Step INT, FollowedRoute VARCHAR(MAX))

--CREATE NONCLUSTERED INDEX IX_OutputGrid_RowNrColNr ON ##OutputGrid (RowNr, ColNr)

DECLARE @Step INT = 0
DECLARE @Count INT = 1

INSERT ##OutputGrid
(
    RowNr,
    ColNr,
    HeatLoss,
    TotalHeatLoss,
    Last3Moves,
    Step,
    FollowedRoute
)
SELECT 0,0,0,0,'',0, '(0,0)'


WHILE @Count > 0
BEGIN

--DECLARE @Step INT = 0
--DECLARE @Count INT = 1


    INSERT ##OutputGrid (RowNr, ColNr, TotalHeatLoss, HeatLoss, Last3Moves, Step, FollowedRoute)
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
    ,      OG.FollowedRoute + '(' + CAST(IG.RowNr AS VARCHAR(3)) + ',' + CAST(IG.ColNr AS VARCHAR(3)) + ')'
    FROM ##OutputGrid OG
    INNER JOIN ##InputGrid IG ON (OG.RowNr = IG.RowNr + 1 AND OG.ColNr = IG.ColNr AND Last3Moves <> 'NNN')
                              OR (OG.RowNr = IG.RowNr - 1 AND OG.ColNr = IG.ColNr AND Last3Moves <> 'SSS')
                              OR (OG.RowNr = IG.RowNr AND OG.ColNr = IG.ColNr + 1 AND Last3Moves <> 'WWW')
                              OR (OG.RowNr = IG.RowNr AND OG.ColNr = IG.ColNr - 1 AND Last3Moves <> 'EEE')
    WHERE OG.Step = @Step
      AND OG.FollowedRoute NOT LIKE '%(' + CAST(IG.RowNr AS VARCHAR(3)) + ',' + CAST(IG.ColNr AS VARCHAR(3)) + ')%'

    
    SET @Count = @@ROWCOUNT

    --DELETE FROM ##OutputGrid
    --WHERE Step < @Step - 5

    SET @Step = @Step + 1

    DELETE FROM OG
    FROM ##OutputGrid OG
    INNER JOIN ##OutputGrid OG2 ON OG2.RowNr = OG.RowNr AND OG2.ColNr = OG.ColNr AND OG2.TotalHeatLoss + 9 < OG.TotalHeatLoss

    

END

;WITH cte_Max AS (
    SELECT MAX(RowNr) MaxRowNr, MAX(ColNr) MaxColNr FROM ##InputGrid OG
)
SELECT MIN(OG.TotalHeatLoss) AS Part1
FROM ##OutputGrid OG 
CROSS APPLY cte_Max c
WHERE RowNr = c.MaxRowNr AND ColNr = c.MaxColNr




DELETE FROM ##OutputGrid

DECLARE @Step INT = 0
DECLARE @Count INT = 1

INSERT ##OutputGrid
(
    RowNr,
    ColNr,
    HeatLoss,
    TotalHeatLoss,
    Last3Moves,
    Step,
    FollowedRoute
)
SELECT 0,0,0,0,'',0, '(0,0)'


WHILE @Count > 0
BEGIN

--DECLARE @Step INT = 0
--DECLARE @Count INT = 1


    ;WITH cte_
    INSERT ##OutputGrid (RowNr, ColNr, TotalHeatLoss, HeatLoss, Last3Moves, Step, FollowedRoute)
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
    ,      OG.FollowedRoute + '(' + CAST(IG.RowNr AS VARCHAR(3)) + ',' + CAST(IG.ColNr AS VARCHAR(3)) + ')'
    FROM ##OutputGrid OG
    INNER JOIN ##InputGrid IG ON (OG.RowNr = IG.RowNr + 1 AND OG.ColNr = IG.ColNr AND Last3Moves <> 'NNN')
                              OR (OG.RowNr = IG.RowNr - 1 AND OG.ColNr = IG.ColNr AND Last3Moves <> 'SSS')
                              OR (OG.RowNr = IG.RowNr AND OG.ColNr = IG.ColNr + 1 AND Last3Moves <> 'WWW')
                              OR (OG.RowNr = IG.RowNr AND OG.ColNr = IG.ColNr - 1 AND Last3Moves <> 'EEE')
    WHERE OG.Step = @Step
      AND OG.FollowedRoute NOT LIKE '%(' + CAST(IG.RowNr AS VARCHAR(3)) + ',' + CAST(IG.ColNr AS VARCHAR(3)) + ')%'

    
    SET @Count = @@ROWCOUNT

    --DELETE FROM ##OutputGrid
    --WHERE Step < @Step - 5

    SET @Step = @Step + 1

    DELETE FROM OG
    FROM ##OutputGrid OG
    INNER JOIN ##OutputGrid OG2 ON OG2.RowNr = OG.RowNr AND OG2.ColNr = OG.ColNr AND OG2.TotalHeatLoss + 9 < OG.TotalHeatLoss

    

END

;WITH cte_Max AS (
    SELECT MAX(RowNr) MaxRowNr, MAX(ColNr) MaxColNr FROM ##InputGrid OG
)
SELECT MIN(OG.TotalHeatLoss) AS Part1
FROM ##OutputGrid OG 
CROSS APPLY cte_Max c
WHERE RowNr = c.MaxRowNr AND ColNr = c.MaxColNr



/*

DROP TABLE ##OutputGrid

*/


-- 78 ~ 110 voor demo
-- 1047 Too high
-- 847 is ondergrens

-- 1023 is correct
