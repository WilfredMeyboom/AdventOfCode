USE Test_WME

SET NOCOUNT ON

DECLARE @year VARCHAR(4) = '2021'
DECLARE @day VARCHAR(2)  = '12'

EXEC dbo.GetInput @year = @year, @day = @day
EXEC dbo.ParseInput @year = @year, @day = @day, @SplitCustom = '-' 

--SELECT TOP 10 * FROM ##InputNumbered
--SELECT TOP 10 * FROM ##InputGrid
--SELECT TOP 10 * FROM ##InputInts
--SELECT TOP 10 * FROM ##InputSplit
--SELECT TOP 10 * FROM ##InputSplitCust

CREATE TABLE ##Paths (ID INT IDENTITY(1,1), RowNr INT, PieceNr INT, Piece VARCHAR(1024), IsLower INT)

INSERT ##Paths (RowNr, PieceNr, Piece, IsLower)
SELECT RowNr, PieceNr, Piece
, CASE WHEN ASCII(LEFT(Piece,1)) BETWEEN 65 AND 90 THEN 0 ELSE 1 END -- Check whether the piece is upper or lower case
FROM ##InputSplitCust ISC

UNION

-- Add the same paths but in the other direction to the paths table; exclude any path to the start or end
SELECT RowNr + 100, PieceNr % 2 +1, Piece, CASE WHEN ASCII(LEFT(Piece,1)) BETWEEN 65 AND 90 THEN 0 ELSE 1 END
FROM ##InputSplitCust ISC
WHERE RowNr NOT IN (
    SELECT RowNr 
    FROM ##InputSplitCust I 
    WHERE Piece IN ('start', 'end')
    )


-- Paths to 'start' should always begin with 'start', similarly paths to 'end' should always finish with 'end'
-- If it wasn't supplied this way, correct it
UPDATE ##Paths 
SET PieceNr = PieceNr % 2 +1
WHERE RowNr IN (
    SELECT RowNr FROM ##Paths WHERE (Piece = 'start' AND PieceNr = 2) OR (Piece = 'end' AND PieceNr = 1)
)

-- A Recursive cte joining paths conform the spec
;WITH cte_Caves AS (
    SELECT I2.Piece
    , CAST(I.Piece + ',' + I2.Piece AS VARCHAR(MAX)) AS Pad
    FROM ##Paths I
    INNER JOIN ##Paths I2 ON I.RowNr = I2.RowNr AND I2.PieceNr = 2
    WHERE I.Piece = 'start'
    AND I.PieceNr = 1

    UNION ALL

    SELECT I2.Piece
    , CAST(Pad + ',' + I2.Piece AS VARCHAR(MAX))
    FROM cte_Caves c
    INNER JOIN ##Paths I ON c.Piece = I.Piece AND I.PieceNr = 1
    INNER JOIN ##Paths I2 ON I.RowNr = I2.RowNr AND I2.PieceNr = 2
    WHERE Pad NOT LIKE ('%,' + I2.Piece + ',%') OR I2.IsLower = 0   -- Joining is allowed as long as it is a big cave or if the small cave isn't in the path yet
)
SELECT COUNT(1) AS Part1
FROM cte_Caves
WHERE Piece = 'end'

-- 4411 for Part1 is correct

;WITH cte_Caves AS (
    SELECT I2.Piece
    , CAST(I.Piece + ',' + I2.Piece AS VARCHAR(MAX)) AS Pad
    , 0 AS SmallCave
    , CAST('' AS VARCHAR(100)) AS ActualSmallCave
    FROM ##Paths I
    INNER JOIN ##Paths I2 ON I.RowNr = I2.RowNr AND I2.PieceNr = 2
    WHERE I.Piece = 'start'
    AND I.PieceNr = 1

    UNION ALL

    SELECT I2.Piece
    , CAST(Pad + ',' + I2.Piece AS VARCHAR(MAX))
    , CASE WHEN c.SmallCave = 1 OR I2.IsLower = 0 THEN c.SmallCave
           WHEN Pad LIKE ('%,' + I2.Piece + ',%') THEN 1 ELSE 0 END     -- If this cave is already in the path mark this path as having visited 1 small cave two times
    , CAST(CASE WHEN c.SmallCave = 1 OR I2.IsLower = 0 THEN c.ActualSmallCave
                WHEN Pad LIKE ('%,' + I2.Piece + ',%') 
                THEN I2.Piece ELSE '' END AS VARCHAR(100))
    FROM cte_Caves c
    INNER JOIN ##Paths I ON c.Piece = I.Piece AND I.PieceNr = 1
    INNER JOIN ##Paths I2 ON I.RowNr = I2.RowNr AND I2.PieceNr = 2
    WHERE I2.isLower = 0 OR 
        (Pad NOT LIKE ('%,' + I2.Piece + ',%') AND SmallCave = 1) OR 
        (SUBSTRING(Pad, CHARINDEX(',' + I2.Piece + ',', Pad) + 2, LEN(Pad)) NOT LIKE ('%,' + I2.Piece + ',%') AND SmallCave = 0)
            -- Check the path by cutting it at the first point of the cave name and looking for the cave name in the second part
)
SELECT COUNT(1) AS Part2
FROM cte_Caves
WHERE Piece = 'end'

-- 136767 for Part2 is correct
-- Runtime is ~4 minutes

--1046
DROP TABLE ##Paths

