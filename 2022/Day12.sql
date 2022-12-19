USE Test_WME

DECLARE @year VARCHAR(4) = '2022'
DECLARE @day VARCHAR(2)  = '12'

EXEC dbo.GetInput @year = @year, @day = @day
EXEC dbo.ParseInput @year = @year, @day = @day 

--SELECT TOP 10 * FROM ##Input
--SELECT TOP 10 * FROM ##InputInts
--SELECT TOP 10 * FROM ##InputNumbered
--SELECT TOP 10 * FROM ##InputGrid
--SELECT TOP 10 * FROM ##InputSplit
--SELECT TOP 10 * FROM ##InputSplitCust
  
  

CREATE TABLE ##Grid (ID INT IDENTITY(1,1), x INT, y INT, Steps INT, Val CHAR)
CREATE UNIQUE INDEX ind_Grid ON ##Grid (x,y)

DECLARE @StartX INT
DECLARE @StartY INT

SELECT @StartX = RowNr, @StartY = ColNr FROM ##InputGrid WHERE ASCII(Val) = 83

INSERT ##Grid(x,y,steps, Val)
SELECT RowNr
,      ColNr
,      CASE WHEN ASCII(Val) = 69 THEN 0 ELSE NULL END
,      CASE WHEN ASCII(Val) = 83 THEN 'a' ELSE CASE WHEN ASCII(Val) = 69 THEN 'z' ELSE Val END END -- Change 'S' to '`' which has ascii value 96
FROM ##inputGrid

WHILE @@ROWCOUNT > 0
BEGIN

    UPDATE G 
    SET Steps = G2.Steps + 1
    FROM ##Grid G
    INNER JOIN ##Grid G2 ON ((G.x = G2.x AND ABS(G.y - G2.y) = 1) OR (G.y = G2.y AND ABS(G.x - G2.x) = 1))
                         AND (ASCII(G2.Val) - ASCII(G.Val)) <= 1
                         AND G2.Steps IS NOT NULL
    WHERE G.Steps IS NULL
    

END

SELECT Steps AS Part1
FROM ##Grid
WHERE @StartX = x AND @StartY = y

SELECT MIN(Steps) AS Part2
FROM ##Grid
WHERE Val = 'a'

--352 is correct for part 1

--345 is correct for part 2

DROP TABLE ##Grid

-- Runtime: 00:06:51