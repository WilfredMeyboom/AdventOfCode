USE Test_WME

SET NOCOUNT ON

DECLARE @year VARCHAR(4) = '2023'
DECLARE @day VARCHAR(2)  = '8'

EXEC dbo.GetInput @year = @year, @day = @day
EXEC dbo.ParseInput @year = @year, @day = @day,  @SplitCustom = ' =(),'

--SELECT TOP 10 * FROM ##Input
--SELECT TOP 10 * FROM ##InputInts
--SELECT TOP 10 * FROM ##InputNumbered
--SELECT TOP 10 * FROM ##InputGrid
--SELECT TOP 10 * FROM ##InputSplitCust

CREATE TABLE ##Instructions (Nr INT, Instr CHAR)

--Seperate the instructions from the rest of the data
INSERT ##Instructions (Nr, Instr) 
SELECT ColNr, Val FROM ##InputGrid WHERE RowNr = 0

CREATE CLUSTERED INDEX Ind_Instr ON ##Instructions (Nr)

CREATE TABLE ##Connections (ID INT IDENTITY(1,1), Src CHAR(3), TrgLeft CHAR(3), TrgRight CHAR(3), TrgLeftID INT, TrgRightID INT)

-- Create a table for the connections
INSERT ##Connections (Src, TrgLeft, TrgRight)
SELECT [1], [2], [3]
FROM (
    SELECT RowNr, PieceNr, Piece FROM ##InputSplitCust WHERE RowNr <> 1
) Sub
PIVOT (
    MAX(Piece)
    FOR PieceNr IN ([1],[2],[3])
) Pvt

-- And reduce this table to IDs (which is better for joining)
UPDATE C
SET TrgLeftID = CL.ID
,   TrgRightID = CR.ID
FROM ##Connections C
LEFT JOIN ##Connections CL ON C.TrgLeft  = CL.Src
LEFT JOIN ##Connections CR ON C.TrgRight = CR.Src

CREATE CLUSTERED INDEX Ind_Conn ON ##Connections (ID) 

DECLARE @End INT
DECLARE @Pos INT
DECLARE @Counter INT = 0
DECLARE @Cycle INT = 0
DECLARE @Len INT

SELECT @Pos = ID FROM ##Connections WHERE Src = 'AAA'
SELECT @End = ID FROM ##Connections WHERE Src = 'ZZZ'
SELECT @Len = COUNT(1) FROM ##Instructions

-- Start moving according to the instructions and the connections till we reach the end point
-- Keep track of the number of times we cycle through all instructions and on which instruction we are at any time
WHILE @Pos <> @End
BEGIN

    SELECT @Pos = CASE WHEN Instr = 'L' THEN TrgLeftID ELSE TrgRightID END
    FROM ##Connections
    CROSS APPLY (SELECT Instr FROM ##Instructions WHERE Nr = @Counter) Sub
    WHERE ID = @Pos
    
    SET @Counter = @Counter + 1

    IF @Counter >= @Len
    BEGIN
        SET @Counter = 0
        SET @Cycle = @Cycle + 1
    END

END

-- The combination of the cycle and the counter gives the number of steps we had to take
SELECT @Cycle * @Len + @Counter AS Part1

SET @Counter = 0
SET @Cycle = 0

CREATE TABLE ##Nodes (Src CHAR(3), PosID INT)
CREATE TABLE ##Results (Src CHAR(3), Trg CHAR(3), Cnt BIGINT, Cyc BIGINT)

-- Instead of one point, we use a table of points and update them simultaneously
INSERT ##Nodes (Src, PosID)
SELECT Src, ID FROM ##Connections WHERE Src LIKE '%A'

-- The answer will probably be BIG, so lets generate some data points and store every time a point reaches its endpoint
-- (Assuming every point has its own routes on the map)
WHILE @Counter + @Cycle * @Len < 50000
BEGIN

    UPDATE N
    SET N.PosID = CASE WHEN Instr = 'L' THEN C.TrgLeftID ELSE C.TrgRightID END
    FROM ##Nodes N
    INNER JOIN ##Connections C ON N.PosID = C.ID
    CROSS APPLY (SELECT Instr FROM ##Instructions WHERE Nr = @Counter) Sub
    
    SET @Counter = @Counter + 1

    IF @Counter >= @Len
    BEGIN
        SET @Counter = 0
        SET @Cycle = @Cycle + 1
    END

    INSERT ##Results (Src, Trg, Cnt, Cyc)
    SELECT N.Src, C.Src, @Counter, @Cycle
    FROM ##Nodes N
    INNER JOIN ##Connections C ON N.PosID = C.ID
    WHERE C.Src LIKE '%Z'

END

-- Now, lets look at the results and specifically to the number of steps between each time a point hits it endpoint
;With cte_1 AS (
    SELECT Src
    ,      Trg
    ,      LEAD(Cyc * @Len + Cnt) OVER (PARTITION BY Src, Trg ORDER BY Cyc, Cnt) - (Cyc * @Len + Cnt) AS Diff
    ,      LEAD(Cyc) OVER (PARTITION BY Src, Trg ORDER BY Cyc) - (Cyc) AS DiffWithoutLen
    FROM ##Results
)
SELECT *
FROM cte_1
WHERE Diff IS NOT NULL
GROUP BY Src, Trg, Diff, DiffWithoutLen
ORDER BY Src

-- So we need to find the lowest common multiple (LCM) for the Diff numbers
-- Interestingly the Diff numbers are the length of the instructions (@Len = 277) times various prime numbers (DiffWithoutLen)
-- Which means the LCM will be the multiple of these prime numbers times @Len (because 277 is also a prime number)

SELECT CAST(277 AS BIGINT) * 47 * 73 * 71 * 79 * 59 * 43 AS Part2


/*

DROP TABLE ##Nodes
DROP TABLE ##Connections
DROP TABLE ##Instructions
DROP TABLE ##Results

*/

