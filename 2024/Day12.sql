USE Test_WME

SET NOCOUNT ON

DECLARE @year VARCHAR(4) = '2024'
DECLARE @day VARCHAR(2)  = '12'

EXEC dbo.GetInput @year = @year, @day = @day
EXEC dbo.ParseInput @year = @year, @day = @day 

--SELECT TOP 10 * FROM ##Input
--SELECT TOP 10 * FROM ##InputInts
--SELECT TOP 10 * FROM ##InputNumbered
--SELECT TOP 10 * FROM ##InputGrid
--SELECT TOP 10 * FROM ##InputSplit
--SELECT TOP 10 * FROM ##InputSplitCust

CREATE TABLE ##Grid (ID INT IDENTITY(1,1), RowNr INT, ColNr INT, Val CHAR(1), GroupNr INT)

INSERT ##Grid (RowNr, ColNr, Val, GroupNr)
SELECT RowNr, ColNr, Val, ROW_NUMBER() OVER (ORDER BY (SELECT 0))
FROM ##InputGrid

CREATE UNIQUE INDEX UQ_Grid ON ##Grid (RowNr, ColNr)

DECLARE @RowCount INT = 1

WHILE @RowCount > 0
BEGIN

    UPDATE G
    SET GroupNr = G2.GroupNr
    FROM ##Grid G
    INNER JOIN ##Grid G2 ON ((G.ColNr = G2.ColNr AND ABS(G.RowNr - G2.RowNr) = 1)
                          OR (G.RowNr = G2.RowNr AND ABS(G.ColNr - G2.ColNr) = 1))
                        AND G.Val = G2.Val AND G.GroupNr > G2.GroupNr

    SET @RowCount = @@ROWCOUNT
END

DECLARE @MaxRow INT
DECLARE @MaxCol INT

SELECT @MaxRow = MAX(RowNr), @MaxCol = MAX(ColNr) FROM ##Grid

;WITH cte_Fences AS (
    SELECT G.GroupNr, COUNT(1) AS NrOfFences 
    FROM ##Grid G
    INNER JOIN ##Grid G2 ON ((G.ColNr = G2.ColNr AND ABS(G.RowNr - G2.RowNr) = 1)
                          OR (G.RowNr = G2.RowNr AND ABS(G.ColNr - G2.ColNr) = 1))
                        AND G.Val <> G2.Val
    GROUP BY G.GroupNr
), cte_Size AS (
    SELECT GroupNr, COUNT(1) AS Size
    FROM ##Grid
    GROUP BY GroupNr
), cte_Borders AS (
    SELECT GroupNr
    ,      SUM(CASE WHEN G.ColNr IN (0, @MaxCol) THEN 1 ELSE 0 END)
         + SUM(CASE WHEN G.RowNr IN (0, @MaxRow) THEN 1 ELSE 0 END) AS NrOfBorders
    FROM ##Grid G
    GROUP BY G.GroupNr
)
SELECT SUM((F.NrOfFences + B.NrOfBorders) * S.Size) AS Part1
FROM cte_Fences F
INNER JOIN cte_Size S ON F.GroupNr = S.GroupNr
INNER JOIN cte_Borders B ON B.GroupNr = F.GroupNr


CREATE TABLE ##Fences (ID INT IDENTITY(1,1), GroupNr INT, FromRowNr INT, ToRowNr INT, FromColNr INT, ToColNr INT, Dir CHAR)

INSERT ##Fences (GroupNr, FromColNr, ToColNr, FromRowNr, ToRowNr, Dir)
SELECT G1.GroupNr
, CASE WHEN G1.ColNr < G2.ColNr
       THEN G1.ColNr
       ELSE G1.ColNr - 1 END AS FromCol
, CASE WHEN G1.ColNr > G2.ColNr
       THEN G1.ColNr - 1
       ELSE G1.ColNr END AS ToCol
, CASE WHEN G1.RowNr < G2.RowNr
       THEN G1.RowNr 
       ELSE G1.RowNr - 1 END AS FromRow
, CASE WHEN G1.RowNr > G2.RowNr
       THEN G1.RowNr - 1
       ELSE G1.RowNr END AS ToRow
, CASE WHEN G1.ColNr < G2.ColNr THEN 'E'
       WHEN G1.ColNr > G2.ColNr THEN 'W'
       WHEN G1.RowNr < G2.RowNr THEN 'S'
       WHEN G1.RowNr > G2.RowNr THEN 'N' END AS Dir
FROM ##Grid G1
INNER JOIN ##Grid G2 ON ((G1.ColNr = G2.ColNr AND ABS(G1.RowNr - G2.RowNr) = 1)
                      OR (G1.RowNr = G2.RowNr AND ABS(G1.ColNr - G2.ColNr) = 1))
                     AND G1.Val <> G2.Val 

INSERT ##Fences (FromRowNr, ToRowNr, FromColNr, ToColNr, GroupNr, Dir)
SELECT -1 AS FromRow, -1 AS ToRow, ColNr -1 AS FromCol, ColNr AS ToCol, GroupNr, 'N' AS Dir FROM ##Grid WHERE RowNr = 0
UNION
SELECT RowNr-1 AS FromRow, RowNr AS ToRow, -1 AS FromCol, -1 AS ToCol, GroupNr, 'W' AS Dir FROM ##Grid WHERE ColNr = 0
UNION
SELECT @MaxRow AS FromRow, @MaxRow AS ToRow, ColNr -1 AS FromCol, ColNr AS ToCol, GroupNr, 'E' AS Dir FROM ##Grid WHERE RowNr = @MaxRow
UNION
SELECT RowNr-1 AS FromRow, RowNr AS ToRow, @MaxCol AS FromCol, @MaxCol AS ToCol, GroupNr, 'S' AS Dir FROM ##Grid WHERE ColNr = @MaxCol

SET @RowCount = 1

WHILE @RowCount > 0
BEGIN

    UPDATE F1
    SET ToColNr = F2.ToColNr
    ,   ToRowNr = F2.ToRowNr
    --SELECT * 
    FROM ##Fences F1
    INNER JOIN ##Fences F2 ON F1.GroupNr = F2.GroupNr AND F1.ID <> F2.ID AND F1.Dir = F2.Dir
                          AND ((F1.ToColNr = F1.FromColNr AND F2.FromColNr = F2.ToColNr AND F1.ToColNr = F2.ToColNr AND F1.ToRowNr BETWEEN F2.FromRowNr AND F2.ToRowNr)
                            OR (F1.ToRowNr = F1.FromRowNr AND F2.FromRowNr = F2.ToRowNr AND F1.ToRowNr = F2.ToRowNr AND F1.ToColNr BETWEEN F2.FromColNr AND F2.ToColNr))

    SET @RowCount = @@ROWCOUNT

    DELETE FROM F1
    FROM ##Fences F1 
    INNER JOIN ##Fences F2 ON F1.ID <> F2.ID AND F1.GroupNr = F2.GroupNr AND F1.Dir = F2.Dir
                          AND ((F1.ToColNr = F1.FromColNr AND F2.FromColNr = F2.ToColNr AND F1.ToColNr = F2.ToColNr AND F1.FromRowNr > F2.FromRowNr AND F1.ToRowNr <= F2.ToRowNr)
                            OR (F1.ToRowNr = F1.FromRowNr AND F2.FromRowNr = F2.ToRowNr AND F1.ToRowNr = F2.ToRowNr AND F1.FromColNr > F2.FromColNr AND F1.ToColNr <= F2.ToColNr))

END


;WITH cte_Fences AS (
    SELECT F.GroupNr, COUNT(1) AS NrOfFences 
    FROM ##Fences F
    GROUP BY F.GroupNr
), cte_Size AS (
    SELECT GroupNr, COUNT(1) AS Size
    FROM ##Grid
    GROUP BY GroupNr
)
SELECT SUM(F.NrOfFences * S.Size) AS Part2
FROM cte_Fences F
INNER JOIN cte_Size S ON F.GroupNr = S.GroupNr

--SELECT * FROM ##Fences ORDER BY GroupNr

--880828 is too low

/*

DROP TABLE ##Fences
DROP TABLE ##Grid

*/