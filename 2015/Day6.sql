use Test_WME

SET NOCOUNT ON

CREATE TABLE ##Input (Line NVARCHAR(MAX));

BULK INSERT ##Input
FROM 'D:\Wilfred\AdventOfCode\2015\input6.txt'
WITH (ROWTERMINATOR = '0x0A');

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

CREATE TABLE ##Grid (ID INT IDENTITY(1,1), X INT, Y INT, Lit INT)

CREATE UNIQUE INDEX UQ_Grid ON ##Grid (X, Y)

;WITH cte_Nrs AS (
    SELECT TOP(1000) ROW_NUMBER() OVER (ORDER BY (SELECT 0)) - 1 AS Nr FROM sys.messages
)
INSERT ##Grid (X, Y, Lit)
SELECT X.Nr, Y.Nr, 0
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
    SET Lit = Lit - 1
    WHERE @Instr = 'off'
      AND X BETWEEN @XTop AND @XBottom
      AND Y BETWEEN @YTop AND @YBottom
      AND Lit > 0

    UPDATE ##Grid
    SET Lit = Lit + 1
    WHERE @Instr = 'on'
      AND X BETWEEN @XTop AND @XBottom
      AND Y BETWEEN @YTop AND @YBottom

    UPDATE ##Grid
    SET Lit = Lit + 2
    WHERE @Instr = 'toggle'
      AND X BETWEEN @XTop AND @XBottom
      AND Y BETWEEN @YTop AND @YBottom
    
    FETCH NEXT FROM InstrCursor INTO @Instr, @XTop, @YTop, @XBottom, @YBottom

END


CLOSE InstrCursor
DEALLOCATE InstrCursor


SELECT SUM(Lit) FROM ##Grid 


-- 375002 is incorrect for part 1
-- 377891 is correct for part 1

-- 14110788 is correct for part 2


/*

DROP TABLE ##Grid
DROP TABLE ##Instructions
DROP TABLE ##Input

*/

--SELECT * FROM ##Instructions WHERE YTop > YBottom