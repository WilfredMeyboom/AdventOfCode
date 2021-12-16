USE Test_WME

SET NOCOUNT ON

DECLARE @year VARCHAR(4) = '2021'
DECLARE @day VARCHAR(2)  = '11'

EXEC dbo.GetInput @year = @year, @day = @day
EXEC dbo.ParseInput @year = @year, @day = @day 

--SELECT TOP 10 * FROM ##InputNumbered
--SELECT * FROM ##InputGrid
--SELECT TOP 10 * FROM ##InputInts
--SELECT TOP 10 * FROM ##InputSplit
--SELECT TOP 10 * FROM ##InputSplitCust

CREATE TABLE ##Grid (ID INT IDENTITY(1,1), RowNr INT, ColNr INT, Val INT, HasFlashed INT)

INSERT ##Grid(RowNr, ColNr, Val, HasFlashed)
SELECT RowNr, ColNr, CAST(Val AS INT), 0
FROM ##InputGrid IG
WHERE TRY_CAST(Val AS INT) IS NOT NULL


DECLARE @Counter INT = 0
DECLARE @Flashes BIGINT = 0
DECLARE @RowCount INT = 1

WHILE @Counter < 100
BEGIN

    --Step 1. Time passes...
    UPDATE ##Grid
    SET Val = Val + 1

    SET @RowCount = 1
   
    --Step 2. Check for flashes and we need to do this in a while loop because of possible chain reactions
    WHILE @RowCount > 0
    BEGIN

        UPDATE ##Grid SET HasFlashed = 1 WHERE Val > 9 AND HasFlashed = 0 -- HasFlashed has 3 statuses: 0 not flashed yet, 1 flashing, 2 has already flashed

        ;WITH cte_Adj AS (
            SELECT G.RowNr, G.ColNr, COUNT(1) AS Adj
            FROM ##Grid G
            INNER JOIN ##Grid IG ON ABS(G.RowNr - IG.RowNr) <= 1 AND ABS(G.ColNr -IG.ColNr) <= 1 AND G.Id <> IG.Id
            WHERE IG.Val > 9 AND IG.HasFlashed = 1
            GROUP BY G.RowNr, G.ColNr
        )
        UPDATE G
        SET G.Val = G.Val + Adj
        FROM ##Grid G
        INNER JOIN cte_Adj c ON c.ColNr = G.ColNr AND c.RowNr = G.RowNr
        WHERE G.HasFlashed = 0

        SELECT @RowCount = COUNT(1) FROM ##Grid G WHERE Val > 9 AND G.HasFlashed = 1

        UPDATE ##Grid SET HasFlashed = 2 WHERE Val > 9 AND HasFlashed = 1

    END

    SELECT @Flashes = (@Flashes + COUNT(1)) FROM ##Grid IG WHERE Val > 9

    UPDATE ##Grid
    SET Val = 0, HasFlashed = 0
    WHERE Val > 9
    
    SET @Counter = @Counter + 1

END

SELECT @Flashes AS Part1


--Let's continue with the state of the grid after part 1 

DECLARE @Size INT
SELECT @Size = COUNT(1) FROM ##Grid

SET @Flashes = 0

-- No change in the flashing logic just check if all squids flashed at the same time
WHILE @Flashes < @Size
BEGIN

    UPDATE ##Grid
    SET Val = Val + 1

    SET @RowCount = 1
  
    WHILE @RowCount > 0
    BEGIN

        UPDATE ##Grid SET HasFlashed = 1 WHERE Val > 9 AND HasFlashed = 0

        ;WITH cte_Adj AS (
            SELECT G.RowNr, G.ColNr, COUNT(1) AS Adj
            FROM ##Grid G
            INNER JOIN ##Grid IG ON ABS(G.RowNr - IG.RowNr) <= 1 AND ABS(G.ColNr -IG.ColNr) <= 1 AND G.Id <> IG.Id
            WHERE IG.Val > 9 AND IG.HasFlashed = 1
            GROUP BY G.RowNr, G.ColNr
        )
        UPDATE G
        SET G.Val = G.Val + Adj
        FROM ##Grid G
        INNER JOIN cte_Adj c ON c.ColNr = G.ColNr AND c.RowNr = G.RowNr
        WHERE G.HasFlashed = 0

        SELECT @RowCount = COUNT(1) FROM ##Grid G WHERE Val > 9 AND G.HasFlashed = 1

        UPDATE ##Grid SET HasFlashed = 2 WHERE Val > 9 AND HasFlashed = 1

    END

    SELECT @Flashes = COUNT(1) FROM ##Grid IG WHERE Val > 9

    UPDATE ##Grid
    SET Val = 0, HasFlashed = 0
    WHERE Val > 9
    
    SET @Counter = @Counter + 1

END


SELECT @Counter AS Part2

DROP TABLE ##Grid