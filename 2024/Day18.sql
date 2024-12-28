USE Test_WME

SET NOCOUNT ON

DECLARE @year VARCHAR(4) = '2024'
DECLARE @day VARCHAR(2)  = '18'

EXEC dbo.GetInput @year = @year, @day = @day
EXEC dbo.ParseInput @year = @year, @day = @day 

--SELECT TOP 10 * FROM ##Input
--SELECT TOP 10 * FROM ##InputInts
--SELECT TOP 10 * FROM ##InputNumbered
--SELECT TOP 10 * FROM ##InputGrid
--SELECT TOP 10 * FROM ##InputSplit
--SELECT TOP 10 * FROM ##InputSplitCust

CREATE TABLE ##Bytes (ID INT IDENTITY(1,1), NS INT, X INT, Y INT)

INSERT ##Bytes (NS, X, Y)
SELECT Ind, LEFT(Line, CHARINDEX(',',Line)-1)
, SUBSTRING(Line, CHARINDEX(',',Line) + 1, LEN(Line))
FROM ##InputNumbered

CREATE TABLE ##Grid (ID INT IDENTITY(1,1), X INT, Y INT, Steps INT)

;WITH cte_Nrs AS (
    SELECT TOP 71 ROW_NUMBER() OVER (ORDER BY (SELECT 0)) - 1 AS Nr FROM sys.messages
)
INSERT ##Grid (X, Y)
SELECT X.Nr, Y.Nr
FROM cte_Nrs X
CROSS APPLY cte_Nrs Y

CREATE UNIQUE INDEX IX_Grid ON ##Grid (X,Y)

;WITH cte_FirstKB AS (
    SELECT TOP 1024 X, Y
    FROM ##Bytes
    ORDER BY NS
)
DELETE FROM G
FROM ##Grid G
INNER JOIN cte_FirstKB c ON G.X = c.X AND G.Y = c.Y

UPDATE ##Grid
SET Steps = 0
WHERE X = 0 AND Y = 0

DECLARE @Cnt INT = 1
DECLARE @MaxX INT 
DECLARE @MaxY INT

SELECT @MaxX = MAX(X), @MaxY = MAX(Y) FROM ##Grid

WHILE (SELECT Steps FROM ##Grid WHERE X = @MaxX AND Y = @MaxY) IS NULL
BEGIN
    
    UPDATE G
    SET Steps = G2.Steps + 1
    FROM ##Grid G
    INNER JOIN ##Grid G2 ON (G.X = G2.X AND ABS(G.Y - G2.Y) = 1)
                         OR (G.Y = G2.Y AND ABS(G.X - G2.X) = 1)
    WHERE G.Steps IS NULL AND G2.Steps IS NOT NULL

    SET @Cnt = @Cnt + 1

    IF @Cnt % 100 = 0 PRINT 'Cnt: ' + CAST(@Cnt AS VARCHAR(6)) + ' at: ' + CAST(GETDATE() AS VARCHAR(50))

END

SELECT Steps AS Part1
FROM ##Grid
WHERE X = @MaxX AND Y = @MaxY


ALTER TABLE ##Bytes ADD PassOrBlock VARCHAR(10)

UPDATE ##Bytes SET PassOrBlock = 'Pass' WHERE NS = 1024
UPDATE ##Bytes SET PassOrBlock = 'Blocked' WHERE NS = 3450

DECLARE @MaxPass INT
DECLARE @MinBlock INT

SELECT @MaxPass = MAX(NS)  FROM ##Bytes WHERE PassOrBlock = 'Pass'
SELECT @MinBlock = MIN(NS) FROM ##Bytes WHERE PassOrBlock = 'Blocked'

DECLARE @CurrentNS INT

WHILE @MinBlock - @MaxPass > 1
BEGIN

    SET @CurrentNS = (@MinBlock + @MaxPass) / 2

    DELETE FROM ##Grid

    ;WITH cte_Nrs AS (
        SELECT TOP 71 ROW_NUMBER() OVER (ORDER BY (SELECT 0)) - 1 AS Nr FROM sys.messages
    )
    INSERT ##Grid (X, Y)
    SELECT X.Nr, Y.Nr
    FROM cte_Nrs X
    CROSS APPLY cte_Nrs Y

    ;WITH cte_toRemove AS (
        SELECT X, Y
        FROM ##Bytes
        WHERE NS <= @CurrentNS
    )
    DELETE FROM G
    FROM ##Grid G
    INNER JOIN cte_toRemove c ON G.X = c.X AND G.Y = c.Y

    UPDATE ##Grid
    SET Steps = 0
    WHERE X = 0 AND Y = 0

    SET @Cnt = 1

    WHILE (SELECT Steps FROM ##Grid WHERE X = @MaxX AND Y = @MaxY) IS NULL AND @Cnt > 0
    BEGIN
    
        UPDATE G
        SET Steps = G2.Steps + 1
        FROM ##Grid G
        INNER JOIN ##Grid G2 ON (G.X = G2.X AND ABS(G.Y - G2.Y) = 1)
                             OR (G.Y = G2.Y AND ABS(G.X - G2.X) = 1)
        WHERE G.Steps IS NULL AND G2.Steps IS NOT NULL

        SET @Cnt = @@ROWCOUNT

    END

    IF (SELECT Steps FROM ##Grid WHERE X = @MaxX AND Y = @MaxY) IS NOT NULL
    BEGIN
        UPDATE ##Bytes SET PassOrBlock = 'Pass' WHERE NS = @CurrentNS
        PRINT 'Run completed NS ' + CAST(@CurrentNS AS VARCHAR(10)) + ' Pass at ' + CAST(GETDATE() AS VARCHAR(50))
    END
    ELSE
    BEGIN
        UPDATE ##Bytes SET PassOrBlock = 'Blocked' WHERE NS = @CurrentNS
        PRINT 'Run completed NS ' + CAST(@CurrentNS AS VARCHAR(10)) + ' Blocked at ' + CAST(GETDATE() AS VARCHAR(50))
    END

    SELECT @MaxPass = MAX(NS)  FROM ##Bytes WHERE PassOrBlock = 'Pass'
    SELECT @MinBlock = MIN(NS) FROM ##Bytes WHERE PassOrBlock = 'Blocked'

END

SELECT CAST(X AS VARCHAR(3)) + ',' + CAST(Y AS VARCHAR(3)) AS Part2
FROM ##Bytes
WHERE NS = @MinBlock

-- 52,28 is correct for part 2
-- (NS = 2579)


/*
DROP TABLE ##Bytes
DROP TABLE ##Grid
*/

/*
Run completed NS 2237 Pass at Dec 18 2024  9:11PM
Run completed NS 2843 Pass at Dec 18 2024  9:31PM
Run completed NS 3146 Blocked at Dec 18 2024  9:31PM
Run completed NS 2994 Blocked at Dec 18 2024  9:31PM
Run completed NS 2918 Blocked at Dec 18 2024  9:31PM
Run completed NS 2880 Blocked at Dec 18 2024  9:40PM
Run completed NS 2861 Pass at Dec 18 2024 10:08PM
Run completed NS 2870 Pass at Dec 18 2024 10:35PM
Run completed NS 2875 Pass at Dec 18 2024 11:02PM
Run completed NS 2877 Pass at Dec 18 2024 11:30PM
Run completed NS 2878 Pass at Dec 18 2024 11:55PM
Run completed NS 2879 Blocked at Dec 19 2024 12:05AM
*/