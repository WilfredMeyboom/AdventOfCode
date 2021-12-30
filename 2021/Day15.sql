USE Test_WME

SET NOCOUNT ON

DECLARE @year VARCHAR(4) = '2021'
DECLARE @day VARCHAR(2)  = '15'

EXEC dbo.GetInput @year = @year, @day = @day
EXEC dbo.ParseInput @year = @year, @day = @day

--SELECT TOP 10 * FROM ##InputNumbered
--SELECT TOP 10 * FROM ##InputGrid
--SELECT TOP 10 * FROM ##InputInts
--SELECT * FROM ##InputSplit
--SELECT TOP 10 * FROM ##InputSplitCust

DECLARE @NrOfPointsUpdated INT = 1

CREATE TABLE ##ResultFront (ID INT IDENTITY(1,1), x INT, y INT, Risk INT)
CREATE TABLE ##ResultBackup (ID INT IDENTITY(1,1), x INT, y INT, Risk INT, UNIQUE (x,y))

DECLARE @MaxX INT
DECLARE @MaxY INT

DECLARE @GridSize INT = 5

SELECT @MaxX = MAX(RowNr) + 1, @MaxY = MAX(ColNr) + 1 FROM ##InputGrid

INSERT ##ResultFront (x, y, Risk)
SELECT 0, 0, 0 -- Starting point

DECLARE @Counter INT = -1

WHILE @NrOfPointsUpdated > 0
BEGIN

    ;WITH cte_ds AS (
        SELECT 0 dX, 1 dY UNION SELECT 1, 0 
    )
    INSERT ##ResultFront (x, y, Risk)
    SELECT R.x + c.dX AS x
    ,      R.y + c.dY AS y
    ,      MIN(R.Risk + (CAST(IG.Val AS INT) + (R.x + c.dX)/@MaxX + (R.y + c.dY)/@MaxY - 1) % 9 + 1)
    FROM ##ResultFront R
    CROSS APPLY cte_ds c
    INNER JOIN ##InputGrid IG ON (IG.RowNr = ((R.x + c.dX) % @MaxX) AND IG.ColNr = ((R.y + c.dY) % @MaxY) ) 
                              OR (IG.ColNr = ((R.y + c.dY) % @MaxY) AND IG.RowNr = ((R.x + c.dX) % @MaxX) ) 
    WHERE R.x < @MaxX * @GridSize AND R.y < @MaxY * @GridSize
    GROUP BY R.x + c.dX, R.y + c.dY

    SET @NrOfPointsUpdated = @@ROWCOUNT

    SET @Counter = @Counter + 1

    DELETE FROM ##ResultFront WHERE x + y = @Counter AND @NrOfPointsUpdated > 0

    IF @NrOfPointsUpdated > 0
        INSERT ##ResultBackup (x, y, Risk)
        SELECT x, y, Risk FROM ##ResultFront R

END

SELECT Risk AS Part1 FROM ##ResultBackup WHERE x = @MaxX - 1 AND y = @MaxY- 1


DELETE FROM ##ResultBackup WHERE x = 500
DELETE FROM ##ResultBackup WHERE y = 500

SET @Counter = 0

SELECT @MaxX = MAX(RowNr) + 1, @MaxY = MAX(ColNr) + 1 FROM ##InputGrid

SET @NrOfPointsUpdated = 1

WHILE @NrOfPointsUpdated > 0
BEGIN

    -- Take one step to the left
    ;WITH cte_NewRisk AS (
        SELECT RB2.x, RB2.y, MIN(RB.Risk + (CAST(IG.Val AS INT) + (RB2.x)/@MaxX + (RB2.y)/@MaxY - 1) % 9 + 1) AS NewRisk
        FROM ##ResultBackup RB
        INNER JOIN ##ResultBackup RB2 ON RB2.x = RB.x - 1 AND RB2.y = RB.y
        INNER JOIN ##InputGrid IG ON (IG.RowNr = ((RB2.x) % @MaxX) AND IG.ColNr = ((RB2.y) % @MaxY) ) 
                                  OR (IG.ColNr = ((RB2.y) % @MaxY) AND IG.RowNr = ((RB2.x) % @MaxX) ) 
        WHERE RB.Risk + (CAST(IG.Val AS INT) + (RB2.x)/@MaxX + (RB2.y)/@MaxY - 1) % 9 + 1 < RB2.Risk
        GROUP BY RB2.x, RB2.y
    )
    UPDATE R
    SET Risk = cN.NewRisk
    FROM ##ResultBackup R
    INNER JOIN cte_NewRisk cN ON cN.x = R.x AND cN.y = R.y

    SET @NrOfPointsUpdated = @@ROWCOUNT

    --Take one step up
    ;WITH cte_NewRisk AS (
        SELECT RB2.x, RB2.y, MIN(RB.Risk + (CAST(IG.Val AS INT) + (RB2.x)/@MaxX + (RB2.y)/@MaxY - 1) % 9 + 1) AS NewRisk
        FROM ##ResultBackup RB
        INNER JOIN ##ResultBackup RB2 ON RB2.y = RB.y - 1 AND RB2.x = RB.x
        INNER JOIN ##InputGrid IG ON (IG.RowNr = ((RB2.x) % @MaxX) AND IG.ColNr = ((RB2.y) % @MaxY) ) 
                                  OR (IG.ColNr = ((RB2.y) % @MaxY) AND IG.RowNr = ((RB2.x) % @MaxX) ) 
        WHERE RB.Risk + (CAST(IG.Val AS INT) + (RB2.x)/@MaxX + (RB2.y)/@MaxY - 1) % 9 + 1 < RB2.Risk
        GROUP BY RB2.x, RB2.y
    )
    UPDATE R
    SET Risk = cN.NewRisk
    FROM ##ResultBackup R
    INNER JOIN cte_NewRisk cN ON cN.x = R.x AND cN.y = R.y

    SET @NrOfPointsUpdated = @NrOfPointsUpdated + @@ROWCOUNT

    --Take one step to the right
    ;WITH cte_NewRisk AS (
        SELECT RB2.x, RB2.y, MIN(RB.Risk + (CAST(IG.Val AS INT) + (RB2.x)/@MaxX + (RB2.y)/@MaxY - 1) % 9 + 1) AS NewRisk
        FROM ##ResultBackup RB
        INNER JOIN ##ResultBackup RB2 ON RB2.x = RB.x + 1 AND RB2.y = RB.y
        INNER JOIN ##InputGrid IG ON (IG.RowNr = ((RB2.x) % @MaxX) AND IG.ColNr = ((RB2.y) % @MaxY) ) 
                                  OR (IG.ColNr = ((RB2.y) % @MaxY) AND IG.RowNr = ((RB2.x) % @MaxX) ) 
        WHERE RB.Risk + (CAST(IG.Val AS INT) + (RB2.x)/@MaxX + (RB2.y)/@MaxY - 1) % 9 + 1 < RB2.Risk
        GROUP BY RB2.x, RB2.y
    )
    UPDATE R
    SET Risk = cN.NewRisk
    FROM ##ResultBackup R
    INNER JOIN cte_NewRisk cN ON cN.x = R.x AND cN.y = R.y

    SET @NrOfPointsUpdated = @NrOfPointsUpdated + @@ROWCOUNT

    --And finally take one step down
    ;WITH cte_NewRisk AS (
        SELECT RB2.x, RB2.y, MIN(RB.Risk + (CAST(IG.Val AS INT) + (RB2.x)/@MaxX + (RB2.y)/@MaxY - 1) % 9 + 1) AS NewRisk
        FROM ##ResultBackup RB
        INNER JOIN ##ResultBackup RB2 ON RB2.y = RB.y + 1 AND RB2.x = RB.x
        INNER JOIN ##InputGrid IG ON (IG.RowNr = ((RB2.x) % @MaxX) AND IG.ColNr = ((RB2.y) % @MaxY) ) 
                                  OR (IG.ColNr = ((RB2.y) % @MaxY) AND IG.RowNr = ((RB2.x) % @MaxX) ) 
        WHERE RB.Risk + (CAST(IG.Val AS INT) + (RB2.x)/@MaxX + (RB2.y)/@MaxY - 1) % 9 + 1 < RB2.Risk
        GROUP BY RB2.x, RB2.y
    )
    UPDATE R
    SET Risk = cN.NewRisk
    FROM ##ResultBackup R
    INNER JOIN cte_NewRisk cN ON cN.x = R.x AND cN.y = R.y

    SET @NrOfPointsUpdated = @NrOfPointsUpdated + @@ROWCOUNT

    SET @Counter = @Counter + 1

    --PRINT CAST(@Counter AS VARCHAR(10)) + ' ' + CAST(GETDATE() AS VARCHAR(50)) + ' ' + CAST(@NrOfPointsUpdated AS VARCHAR(10))

END

SELECT Risk AS Part2 FROM ##ResultBackup WHERE x = (@MaxX * @GridSize) - 1 AND y = (@MaxY * @GridSize)- 1

--Runtime ~ 15 min

DROP TABLE ##ResultFront
DROP TABLE ##ResultBackup


--2825 is correct for part 2