USE Test_WME

SET NOCOUNT ON

DECLARE @year VARCHAR(4) = '2024'
DECLARE @day VARCHAR(2)  = '20'

EXEC dbo.GetInput @year = @year, @day = @day
EXEC dbo.ParseInput @year = @year, @day = @day 

--SELECT TOP 10 * FROM ##Input
--SELECT TOP 10 * FROM ##InputInts
--SELECT TOP 10 * FROM ##InputNumbered
--SELECT TOP 10 * FROM ##InputGrid
--SELECT TOP 10 * FROM ##InputSplit
--SELECT TOP 10 * FROM ##InputSplitCust

CREATE TABLE ##Race (ID INT IDENTITY(1,1), RowNr INT, ColNr INT, Steps INT)

INSERT ##Race (RowNr, ColNr, Steps)
SELECT RowNr, ColNr, CASE WHEN Val = 'S' THEN 0 ELSE NULL END FROM ##InputGrid WHERE Val <> '#'

CREATE UNIQUE INDEX IX_Race ON ##Race (RowNr, ColNr)

DECLARE @RowNr INT
DECLARE @ColNr INT
DECLARE @Cnt INT = 1

SELECT @RowNr = RowNr, @ColNr = ColNr
FROM ##Race
WHERE Steps = 0

WHILE EXISTS (SELECT 1 FROM ##Race WHERE Steps IS NULL)
BEGIN

    UPDATE ##Race
    SET Steps = @Cnt
    WHERE Steps IS NULL AND ((RowNr = @RowNr AND ABS(ColNr - @ColNr) = 1)
                          OR (ColNr = @ColNr AND ABS(RowNr - @RowNr) = 1)) 

    SELECT @RowNr = RowNr, @ColNr = ColNr
    FROM ##Race
    WHERE Steps = @Cnt

    SET @Cnt = @Cnt + 1

END


SELECT COUNT(1) AS Part1
FROM ##Race R1
INNER JOIN ##Race R2 ON ((R1.RowNr = R2.RowNr AND ABS(R1.ColNr - R2.ColNr) = 2)
                      OR (R1.ColNr = R2.ColNr AND ABS(R1.RowNr - R2.RowNr) = 2)) 
                     AND R1.Steps - (R2.Steps + 2) >= 100


SELECT --R1.ColNr, R1.RowNr, R2.ColNr, R2.RowNr, R2.Steps - R1.Steps - (ABS(R1.ColNr - R2.ColNr) + ABS(R1.RowNr - R2.RowNr)) AS Cheat
COUNT(1) AS Part2
FROM ##Race R1
INNER JOIN ##Race R2 ON ABS(R1.ColNr - R2.ColNr) + ABS(R1.RowNr - R2.RowNr) <= 20 AND R1.Steps < R2.Steps
WHERE R2.Steps - R1.Steps - (ABS(R1.ColNr - R2.ColNr) + ABS(R1.RowNr - R2.RowNr)) >= 100
--ORDER BY Cheat DESC

--310658 too low

--DROP TABLE ##Race
