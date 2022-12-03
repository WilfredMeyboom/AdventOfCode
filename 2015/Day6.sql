USE Test_WME

SET NOCOUNT ON

DECLARE @year VARCHAR(4) = '2015'
DECLARE @day VARCHAR(2)  = '6'

EXEC dbo.GetInput @year = @year, @day = @day
EXEC dbo.ParseInput @year = @year, @day = @day 

--SELECT TOP 10 * FROM ##InputNumbered
--SELECT TOP 10 * FROM ##InputGrid
--SELECT TOP 10 * FROM ##InputInts
--SELECT TOP 10 * FROM ##InputSplit
--SELECT TOP 10 * FROM ##InputSplitCust

CREATE TABLE ##Instructions (ID INT IDENTITY(1,1), InstrNr INT, Instr VARCHAR(10), XTop INT, YTop INT, XBottom INT, YBottom INT)

;WITH cte_ScrubbedInput AS (
    SELECT ROW_NUMBER() OVER (ORDER BY (SELECT 0)) LineNr
    ,      CASE WHEN Line LIKE 'turn on%' THEN 'on'
                WHEN Line LIKE 'turn off%' THEN 'off'
                WHEN Line LIKE 'toggle%' THEN 'toggle'
           END AS Instr
    ,      REPLACE(REPLACE(REPLACE(LEFT(Line, CHARINDEX('through', Line) - 2), 'turn on', ''), 'turn off', ''), 'toggle', '') AS TopCorner
    ,      SUBSTRING(Line, CHARINDEX('through', Line) + 8, LEN(Line)) AS BottomCorner
    FROM ##Input
)
INSERT ##Instructions (InstrNr, Instr, XTop, YTop, XBottom, YBottom)
SELECT LineNr
,      Instr
,      LEFT(TopCorner, CHARINDEX(',', TopCorner) -1) AS XTop
,      SUBSTRING(TopCorner, CHARINDEX(',', TopCorner) +1, LEN(TopCorner)) AS YTop
,      LEFT(BottomCorner, CHARINDEX(',', BottomCorner) -1) AS XBottom
,      SUBSTRING(BottomCorner, CHARINDEX(',', BottomCorner) +1, LEN(BottomCorner)) AS YBottom
FROM cte_ScrubbedInput

CREATE TABLE ##Grid (ID INT IDENTITY(1,1), X INT, Y INT, Lit INT, Intensity INT)

CREATE UNIQUE INDEX UQ_Grid ON ##Grid (X, Y)

;WITH cte_Nrs AS (
    SELECT TOP(1000) ROW_NUMBER() OVER (ORDER BY (SELECT 0)) - 1 AS Nr FROM sys.messages
)
INSERT ##Grid (X, Y, Lit, Intensity)
SELECT X.Nr, Y.Nr, 0, 0
FROM cte_Nrs X
CROSS APPLY cte_Nrs Y

DECLARE @Instr VARCHAR(10)
DECLARE @XTop INT
DECLARE @XBottom INT
DECLARE @YTop INT
DECLARE @YBottom INT

DECLARE InstrCursor CURSOR FOR
SELECT Instr, XTop, YTop, XBottom, YBottom FROM ##Instructions ORDER BY InstrNr

OPEN InstrCursor

FETCH NEXT FROM InstrCursor INTO @Instr, @XTop, @YTop, @XBottom, @YBottom

WHILE @@FETCH_STATUS = 0
BEGIN

    UPDATE ##Grid
    SET Lit = 0
    , Intensity = CASE WHEN Intensity > 0 THEN Intensity - 1 ELSE 0 END
    WHERE @Instr = 'off'
      AND X BETWEEN @XTop AND @XBottom
      AND Y BETWEEN @YTop AND @YBottom


    UPDATE ##Grid
    SET Lit = 1
    , Intensity = Intensity + 1 
    WHERE @Instr = 'on'
      AND X BETWEEN @XTop AND @XBottom
      AND Y BETWEEN @YTop AND @YBottom

    UPDATE ##Grid
    SET Lit = CASE WHEN Lit = 0 THEN 1 ELSE 0 END
    , Intensity = Intensity + 2
    WHERE @Instr = 'toggle'
      AND X BETWEEN @XTop AND @XBottom
      AND Y BETWEEN @YTop AND @YBottom
    
    FETCH NEXT FROM InstrCursor INTO @Instr, @XTop, @YTop, @XBottom, @YBottom

END


CLOSE InstrCursor
DEALLOCATE InstrCursor


SELECT SUM(Lit) AS Part1, SUM(Intensity) AS Part2 FROM ##Grid 


-- 377891 is correct for part 1

-- 14110788 is correct for part 2


DROP TABLE ##Grid
DROP TABLE ##Instructions
