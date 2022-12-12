USE Test_WME

DECLARE @year VARCHAR(4) = '2022'
DECLARE @day VARCHAR(2)  = '9'

EXEC dbo.GetInput @year = @year, @day = @day
EXEC dbo.ParseInput @year = @year, @day = @day 

--SELECT TOP 10 * FROM ##Input
--SELECT TOP 10 * FROM ##InputInts
--SELECT TOP 10 * FROM ##InputNumbered
--SELECT TOP 10 * FROM ##InputGrid
--SELECT TOP 10 * FROM ##InputSplit
--SELECT TOP 10 * FROM ##InputSplitCust
 
DECLARE @Dir VARCHAR(1)
DECLARE @Amount INT
DECLARE @Counter INT

CREATE TABLE ##Tail(ID INT IDENTITY(1,1), x INT, y INT) -- For Part1

CREATE TABLE ##Tail9(ID INT IDENTITY(1,1), x INT, y INT) -- For Part2

CREATE TABLE ##Rope(ID INT IDENTITY(1,1), PartNr INT , x INT, y INT)

INSERT ##Rope (PartNr, x, y)
SELECT TOP 10 ROW_NUMBER() OVER( ORDER BY (SELECT 0)) -1 ,0,0 FROM sys.messages M -- Create the rope

DECLARE moveCursor CURSOR FAST_FORWARD READ_ONLY FOR SELECT LEFT(Line,1), CAST(SUBSTRING(Line,3,LEN(Line)) AS INT) FROM ##InputNumbered ORDER BY Ind

OPEN moveCursor

FETCH NEXT FROM moveCursor INTO @Dir, @Amount

WHILE @@FETCH_STATUS = 0
BEGIN
    
    SET @Counter = 0 

    WHILE @Counter < @Amount
    BEGIN
        
        -- Make the head move
        IF @Dir = 'U' UPDATE ##Rope SET Y = Y + 1 WHERE Partnr = 0
        IF @Dir = 'D' UPDATE ##Rope SET Y = Y - 1 WHERE Partnr = 0
        IF @Dir = 'L' UPDATE ##Rope SET X = X - 1 WHERE Partnr = 0
        IF @Dir = 'R' UPDATE ##Rope SET X = X + 1 WHERE Partnr = 0

        WHILE EXISTS(SELECT 1 FROM ##Rope R INNER JOIN ##Rope R2 ON R2.PartNr = R.PartNr + 1 AND (ABS(R2.x - R.x) > 1 OR ABS(R2.y - R.y) > 1))
        BEGIN

            UPDATE R
            SET R.x = CASE WHEN ABS(R.x - R2.x) > 1 THEN R.x + CASE WHEN R2.x > R.x THEN 1 ELSE -1 END ELSE R2.x END
            ,   R.y = CASE WHEN ABS(R.y - R2.y) > 1 THEN R.y + CASE WHEN R2.y > R.y THEN 1 ELSE -1 END ELSE R2.y END
            FROM ##Rope R
            INNER JOIN ##Rope R2 ON R2.PartNr = R.PartNr - 1
            WHERE ABS(R.x - R2.x) > 1 OR ABS(R.y - R2.y) > 1 

        END

        INSERT ##Tail (x,y) SELECT x,y FROM ##Rope R WHERE r.PartNr = 1
        INSERT ##Tail9 (x,y) SELECT x,y FROM ##Rope R WHERE r.PartNr = 9

        SET @Counter = @Counter + 1

    END

    FETCH NEXT FROM moveCursor INTO @Dir, @Amount
END

CLOSE moveCursor
DEALLOCATE moveCursor


;WITH cte_Part1 AS (
    SELECT DISTINCT x,y FROM ##Tail T
), cte_Part2 AS (
    SELECT DISTINCT x,y FROM ##Tail9 T
)
SELECT T1.Part1, T2.Part2
FROM (SELECT COUNT(1) AS Part1 FROM cte_Part1) T1
CROSS APPLY (SELECT COUNT(1) AS Part2 FROM cte_Part2) T2


DROP TABLE ##Tail
DROP TABLE ##Tail9
DROP TABLE ##Rope
