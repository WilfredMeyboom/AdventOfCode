USE Test_WME

SET NOCOUNT ON

DECLARE @year VARCHAR(4) = '2022'
DECLARE @day VARCHAR(2)  = '18'

EXEC dbo.GetInput @year = @year, @day = @day
EXEC dbo.ParseInput @year = @year, @day = @day 

--SELECT TOP 10 * FROM ##Input
--SELECT TOP 10 * FROM ##InputInts
--SELECT TOP 10 * FROM ##InputNumbered
--SELECT TOP 10 * FROM ##InputGrid
--SELECT TOP 10 * FROM ##InputSplit
--SELECT TOP 10 * FROM ##InputSplitCust
  
CREATE TABLE ##Cubes (ID INT IDENTITY(1,1), CubeNr INT, X INT, Y INT, Z INT)

INSERT ##Cubes
(
    CubeNr,
    X,
    Y,
    Z
)
SELECT RowNr AS CubeNr, [1] AS X, [2] AS Y, [3] AS Z 
FROM
(
    SELECT RowNr, Piece, PieceNr FROM ##InputSplit
) T
PIVOT (
    MAX(Piece) FOR PieceNr IN ([1],[2],[3])
) PVT

DECLARE @Part1 INT

;WITH cte_Sides AS (
    SELECT C_Base.CubeNr, 6-SUM(CASE WHEN C_Con.ID IS NULL THEN 0 ELSE 1 END) AS Freesides
    FROM ##Cubes C_Base
    LEFT JOIN ##Cubes C_Con ON (C_Base.X = C_Con.X AND C_Base.Y = C_Con.Y AND ABS(C_Base.Z - C_Con.Z) = 1)
                             OR (C_Base.X = C_Con.X AND ABS(C_Base.Y - C_Con.Y) = 1 AND C_Base.Z = C_Con.Z)
                             OR (ABS(C_Base.X - C_Con.X) = 1 AND C_Base.Y = C_Con.Y AND C_Base.Z = C_Con.Z)
    GROUP BY C_Base.CubeNr
)
SELECT @Part1 = SUM(FreeSides)
FROM cte_Sides
    
SELECT @Part1 AS Part1

DECLARE @MinX INT
DECLARE @MaxX INT
DECLARE @MinY INT
DECLARE @MaxY INT
DECLARE @MinZ INT
DECLARE @MaxZ INT

SELECT @MinX = MIN(x) - 1, @MaxX = MAX(X) + 1, @MinY = MIN(y) - 1, @MaxY = MAX(y) + 1, @MinZ = MIN(z) - 1, @MaxZ = MAX(z) + 1 FROM ##Cubes C

CREATE TABLE ##AllCubes (ID INT IDENTITY(1,1), X INT, y INT, z INT, val INT)

-- Val = 0 -> undetermined
-- Val = 1 -> lava
-- Val = 2 -> water

;WITH cte_X AS (
    SELECT TOP(@MaxX - @MinX + 1) @MinX + ROW_NUMBER() OVER (ORDER BY (SELECT 0)) - 1 AS x FROM sys.messages M
), cte_Y AS (
    SELECT TOP(@MaxY - @MinY + 1) @MinY + ROW_NUMBER() OVER (ORDER BY (SELECT 0)) - 1 AS y FROM sys.messages M
), cte_Z AS (
    SELECT TOP(@MaxZ - @MinZ + 1) @MinZ + ROW_NUMBER() OVER (ORDER BY (SELECT 0)) - 1 AS z FROM sys.messages M
)
INSERT ##AllCubes
(
    X,
    y,
    z,
    val
)
SELECT X, Y, Z, 0
FROM cte_X
CROSS APPLY cte_Y
CROSS APPLY cte_Z

--Mark all known cubes
UPDATE AL 
SET Val = 1
FROM ##AllCubes AL
INNER JOIN ##Cubes C ON C.X = AL.X AND C.Y = AL.y AND C.Z = AL.z

--Mark water cubes
UPDATE AL 
SET Val = 2
FROM ##AllCubes AL
WHERE X = @MinX
   OR X = @MaxX
   OR Y = @MinY
   OR Y = @MaxY
   OR Z = @MinZ
   OR Z = @MaxZ

-- Let the water flow...
WHILE @@ROWCOUNT > 0
BEGIN

    UPDATE C_Empty
    SET Val = 2
    FROM ##AllCubes C_Empty
    INNER JOIN ##AllCubes C_Water ON (C_Water.X = C_Empty.X AND C_Water.Y = C_Empty.Y AND ABS(C_Water.Z - C_Empty.Z) = 1)
                             OR (C_Water.X = C_Empty.X AND ABS(C_Water.Y - C_Empty.Y) = 1 AND C_Water.Z = C_Empty.Z)
                             OR (ABS(C_Water.X - C_Empty.X) = 1 AND C_Water.Y = C_Empty.Y AND C_Water.Z = C_Empty.Z)
    WHERE C_Empty.Val = 0 AND C_Water.Val = 2

END

-- Reduce the free sides with any side that is now touching an empty cube
SELECT @Part1 - COUNT(1) AS Part2 
FROM ##Cubes C
INNER JOIN ##AllCubes AC ON (C.X = AC.X AND C.Y = AC.Y AND ABS(C.Z - AC.Z) = 1)
                         OR (C.X = AC.X AND ABS(C.Y - AC.Y) = 1 AND C.Z = AC.Z)
                         OR (ABS(C.X - AC.X) = 1 AND C.Y = AC.Y AND C.Z = AC.Z)
WHERE AC.val = 0


DROP TABLE ##Cubes
DROP TABLE ##AllCubes
