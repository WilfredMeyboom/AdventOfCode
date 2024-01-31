USE Test_WME

SET NOCOUNT ON

DECLARE @year VARCHAR(4) = '2023'
DECLARE @day VARCHAR(2)  = '21'

EXEC dbo.GetInput @year = @year, @day = @day
EXEC dbo.ParseInput @year = @year, @day = @day 

--SELECT TOP 10 * FROM ##Input
--SELECT TOP 10 * FROM ##InputInts
--SELECT TOP 10 * FROM ##InputNumbered
--SELECT TOP 10 * FROM ##InputSplit
--SELECT TOP 10 * FROM ##InputSplitCust
  
DECLARE @StartRow INT
DECLARE @StartCol INT
DECLARE @Step INT = 0
DECLARE @Count INT = 1
DECLARE @GridSize INT

SELECT @StartRow = RowNr, @StartCol = ColNr FROM ##InputGrid WHERE Val = 'S'
UPDATE ##InputGrid SET Val = '.' WHERE Val = 'S'

SELECT @GridSize = MAX(RowNr) + 1 FROM ##InputGrid 

CREATE TABLE ##Steps (ID INT IDENTITY(1,1), RowNr INT, ColNr INT, Step INT)

CREATE UNIQUE INDEX IX_InputGrid ON ##InputGrid(RowNr, ColNr)
CREATE UNIQUE INDEX IX_Steps ON ##Steps(RowNr, ColNr)

INSERT ##Steps(RowNr, ColNr, Step)
SELECT @StartRow, @StartCol, @Step

WHILE @Step <= 64
BEGIN
    
    INSERT ##Steps(RowNr, ColNr, Step)
    SELECT DISTINCT I.RowNr, I.ColNr, @Step + 1
    FROM ##Steps S
    INNER JOIN ##InputGrid I ON ((ABS(S.ColNr - I.ColNr) = 1 AND S.RowNr = I.RowNr)
                                  OR ((S.ColNr = I.ColNr) AND ABS(S.RowNr - I.RowNr) = 1)
                                  )
                            AND I.Val = '.'
    LEFT JOIN ##Steps S2 ON S2.ColNr = I.ColNr AND S2.RowNr = I.RowNr
    WHERE S.Step = @Step AND S2.ID IS NULL

    SET @Count = @@ROWCOUNT

    SET @Step = @Step + 1

END

SELECT COUNT(1) AS Part1 FROM ##Steps S WHERE Step % 2 = 0 AND Step <= 64

--> Dus elk hoekpunt is 130 stappen
--SELECT COUNT(1) FROM ##Steps WHERE Step % 2 = 1 -- 7656
--SELECT COUNT(1) FROM ##Steps WHERE Step % 2 = 0 -- 7688

PRINT 'Start part2'

WHILE @Step <= @Gridsize * 10
BEGIN

    --DECLARE @GridSize INT = 131
    --DECLARE @Step INT = 130    

    ;WITH cte_Move AS (
        SELECT 0 AS dRow, 1 AS dCol UNION
        SELECT 1 AS dRow, 0 AS dCol UNION
        SELECT 0 AS dRow, -1 AS dCol UNION
        SELECT -1 AS dRow, 0 AS dCol

    )
    INSERT ##Steps(RowNr, ColNr, Step)
    SELECT DISTINCT S.RowNr + M.dRow, S.ColNr + M.dCol, @Step + 1
    FROM ##Steps S
    CROSS APPLY cte_Move M
    INNER JOIN ##InputGrid I ON (((S.ColNr + M.dCol) % @GridSize + @GridSize) % @GridSize = I.ColNr) 
                            AND (((S.RowNr + M.dRow) % @GridSize + @GridSize) % @GridSize = I.RowNr)
                            AND I.Val = '.'
    LEFT JOIN ##Steps S2 ON S2.RowNr = S.RowNr + M.dRow 
                        AND S2.ColNr = S.ColNr + M.dCol
    WHERE S.Step = @Step AND S2.ID IS NULL

    SET @Count = @@ROWCOUNT

    IF @Step % 131 = 65
    BEGIN
        SELECT @Count = COUNT(1) FROM ##Steps S WHERE Step % 2 = 0
        PRINT CAST(@Count AS VARCHAR(10)) + ' ' + CAST(@Step AS VARCHAR(10))
        SELECT @Count = COUNT(1) FROM ##Steps S WHERE Step % 2 = 1
        PRINT CAST(@Count AS VARCHAR(10)) + ' ' + CAST(@Step AS VARCHAR(10))
    END

    SET @Step = @Step + 1

END

SELECT * FROM ##Steps ORDER BY Step


-- 627960775905777






/*

DROP TABLE ##Steps

*/

/*

Bereikbare plekken VS Aantal stappen:
4032 65
-> 3877 65 (want oneven)
-> 34674 196 (want even)
35135 196
96926 327
-> 96159 327
-> 188332 458
189405 458
312572 589
-> 311193 589
-> 464742 720
466427 720
650970 851
-> 648979 851
-> 863904 982
866201 982
1112120 1113
-> 1109517 1113
-> 1385818 1244
1388727 1244

Wolfram Alpha geeft voor een quadratic fit van 34674 96159 188332 311193 464742 648979
3877 + 15453 x + 15344 x^2

Steps 26501365 geeft x = 202300 ((Steps - (Steps % 131)) / 131)

x = 202300 geeft
627960775905777



*/