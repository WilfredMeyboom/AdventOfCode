USE Test_WME

SET NOCOUNT ON

DECLARE @year VARCHAR(4) = '2023'
DECLARE @day VARCHAR(2)  = '24'

EXEC dbo.GetInput @year = @year, @day = @day
EXEC dbo.ParseInput @year = @year, @day = @day 

--SELECT TOP 10 * FROM ##Input
--SELECT TOP 10 * FROM ##InputInts
--SELECT TOP 10 * FROM ##InputNumbered
--SELECT TOP 10 * FROM ##InputGrid
--
--SELECT TOP 10 * FROM ##InputSplitCust
  
DECLARE @XMin BIGINT = 200000000000000
DECLARE @XMax BIGINT = 400000000000000
DECLARE @YMin BIGINT = 200000000000000
DECLARE @YMax BIGINT = 400000000000000

--SET @XMin = 7
--SET @XMax = 27
--SET @YMin = 7
--SET @YMax = 27


/*
-- Definition of 1 line:
y1 = ax1 + b
y2 = ax2 + b
x2 = x1 + dx
y2 = y2 + dy

y1-ax1 = y2 - ax2 <=> (y1-y2)/(x1-x2) = a
x1-x2 = x1-x1-dx
y1-y2 = y1-y1-dy
=> a = dy/dx

b = y1/(ax1) = y1/x1 * (dx/dy)


*/

CREATE TABLE ##HailStones (ID INT IDENTITY(1,1), HailStoneNr INT, x BIGINT, y BIGINT, dx BIGINT, dy BIGINT, a DECIMAL(28,10), b DECIMAL(28,10))

INSERT ##HailStones
(
    HailStoneNr,
    x,
    y,
    dx,
    dy,
    a,
    b
)
SELECT RowNr
,      CAST([1] AS BIGINT) AS X
,      CAST([2] AS BIGINT) AS Y
,      CAST([5] AS BIGINT) AS dX
,      CAST([6] AS BIGINT) AS dY

,      1.0 * CAST([6] AS BIGINT) / CAST([5] AS BIGINT) AS a
,      1.0 * CAST([2] AS BIGINT) - 1.0 * (CAST([6] AS BIGINT) * CAST([1] AS BIGINT) / (1.0 * CAST([5] AS BIGINT))) b
FROM (
    SELECT RowNr, PieceNr, Piece 
    FROM ##InputSplit
) Sub
PIVOT (
    MAX(Piece)
    FOR PieceNr IN ([1],[2],[5],[6])
) Pvt

;WITH cte_XY AS (
    SELECT HS.HailStoneNr AS Stone1
    ,      HS.x AS x1
    ,      HS.y AS y1
    ,      HS.dx AS dx1
    ,      HS.dy AS dy1
    ,      HS.a AS a1
    ,      HS.b AS b1
    ,      HS2.HailStoneNr AS Stone2
    ,      HS2.x AS x2
    ,      HS2.y AS y2
    ,      HS2.dx AS dx2
    ,      HS2.dy AS dy2
    ,      HS2.a AS a2
    ,      HS2.b AS b2
    ,      (HS2.b - HS.b)/(HS.a - HS2.a) AS X
    ,      (HS2.b * HS.a - HS.b * HS2.a) / (HS.a - HS2.a) AS Y
    ,      @XMin AS XMin
    ,      @XMax AS XMax
    ,      @YMin AS YMin
    ,      @YMax AS YMax
    FROM ##HailStones HS
    INNER JOIN ##HailStones HS2 ON HS2.ID < HS.ID 
                               AND HS2.a <> HS.a --Disregard parallel lines
), cte_Correctness AS (
    SELECT cte_XY.Stone1,
           cte_XY.x1,
           cte_XY.y1,
           cte_XY.dx1,
           cte_XY.dy1,
           cte_XY.a1,
           cte_XY.b1,
           cte_XY.Stone2,
           cte_XY.x2,
           cte_XY.y2,
           cte_XY.dx2,
           cte_XY.dy2,
           cte_XY.a2,
           cte_XY.b2,
           cte_XY.X,
           cte_XY.Y,
           cte_XY.XMin,
           cte_XY.XMax,
           cte_XY.YMin,
           cte_XY.YMax
    ,      CASE WHEN X BETWEEN XMin AND XMax THEN 1 ELSE 0 END AS XInRange
    ,      CASE WHEN Y BETWEEN YMin AND YMax THEN 1 ELSE 0 END AS YInRange
    ,      CASE WHEN (X > x1 AND dx1 > 0) OR (X < x1 AND dx1 < 0) THEN 1 ELSE 0 END AS x1InFuture
    ,      CASE WHEN (X > x2 AND dx2 > 0) OR (X < x2 AND dx2 < 0) THEN 1 ELSE 0 END AS x2InFuture
    ,      CASE WHEN (Y > y1 AND dy1 > 0) OR (Y < y1 AND dy1 < 0) THEN 1 ELSE 0 END AS y1InFuture
    ,      CASE WHEN (Y > y2 AND dy2 > 0) OR (Y < y2 AND dy2 < 0) THEN 1 ELSE 0 END AS y2InFuture
    FROM cte_XY
)
SELECT SUM(
            CASE WHEN c.XInRange = 1
             AND c.YInRange = 1
             AND c.x1InFuture = 1
             AND c.x2InFuture = 1
             AND c.y1InFuture = 1
             AND c.y2InFuture = 1
            THEN 1 ELSE 0 END
            ) AS Part1
FROM cte_Correctness c

--14771 is too low
--14799 is correct -> Changed DECIMAL(28,2) to DECIMAL(28,10)

DROP TABLE ##HailStones
/*

SELECT CAST(270392223533306 AS BIGINT) + 463714142194108 + 273041846061920

--1007148211789334 too low
--1007148211789625
*/