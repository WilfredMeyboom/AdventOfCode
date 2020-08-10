use Test_WME

SET NOCOUNT ON

CREATE TABLE ##Input (Line NVARCHAR(MAX));

BULK INSERT ##Input
--FROM 'C:\Source\AdventOfCode\2018\input20_example.txt'
FROM 'C:\Source\AdventOfCode\2018\input20.txt'
WITH (ROWTERMINATOR = '0x0A');

--SELECT * FROM ##Input

--Lumber Collection Area
CREATE TABLE ##Grid (ID INT IDENTITY(1,1), X INT, Y INT, North INT DEFAULT(0), West INT DEFAULT(0), South INT DEFAULT(0), East INT DEFAULT(0), Dist INT)

INSERT ##Grid (X, Y, Dist) VALUES (0,0,0)

DECLARE @XPos INT = 0
DECLARE @YPos INT = 0

DECLARE @Ind INT = 2
DECLARE @Val CHAR
DECLARE @LenInput INT

SELECT @LenInput = LEN(Line) FROM ##Input

CREATE TABLE ##SavePoints (ID INT IDENTITY(1,1), X INT, Y INT)

WHILE @Ind < @LenInput
BEGIN

    SELECT @Val = SUBSTRING(Line, @Ind, 1) FROM ##Input

    -- Store this location
    IF @Val = '(' INSERT ##SavePoints(X, Y) SELECT @XPos, @YPos

    -- Jump back to the last stored location and remove it from the list
    IF @Val = ')'
    BEGIN
        SELECT TOP 1 @XPos = X, @YPos = Y FROM ##SavePoints ORDER BY ID DESC
        DELETE FROM ##SavePoints WHERE ID = (SELECT TOP 1 ID FROM ##SavePoints ORDER BY ID DESC)
    END

    -- Jump back to the last stored location
    IF @Val = '|'
    BEGIN
        SELECT TOP 1 @XPos = X, @YPos = Y FROM ##SavePoints ORDER BY ID DESC
    END

    --Change wall to door in the room we're exiting
    IF @Val = 'N' UPDATE ##Grid SET North = 1 WHERE X = @XPos AND Y = @YPos
    IF @Val = 'W' UPDATE ##Grid SET West = 1 WHERE X = @XPos AND Y = @YPos
    IF @Val = 'S' UPDATE ##Grid SET South = 1 WHERE X = @XPos AND Y = @YPos
    IF @Val = 'E' UPDATE ##Grid SET East = 1 WHERE X = @XPos AND Y = @YPos

    --Move to the new room
    IF @Val = 'N' SET @YPos = @YPos - 1
    IF @Val = 'W' SET @XPos = @XPos - 1
    IF @Val = 'S' SET @YPos = @YPos + 1
    IF @Val = 'E' SET @XPos = @XPos + 1

    --Check if our new location is a known room in the grid
    IF NOT EXISTS (SELECT 1 FROM ##Grid WHERE X = @XPos AND Y = @YPos)
        INSERT ##Grid (X, Y) SELECT @XPos, @YPos

    --Change wall to door in the room we're entering
    IF @Val = 'S' UPDATE ##Grid SET North = 1 WHERE X = @XPos AND Y = @YPos
    IF @Val = 'E' UPDATE ##Grid SET West = 1 WHERE X = @XPos AND Y = @YPos
    IF @Val = 'N' UPDATE ##Grid SET South = 1 WHERE X = @XPos AND Y = @YPos
    IF @Val = 'W' UPDATE ##Grid SET East = 1 WHERE X = @XPos AND Y = @YPos

    SET @Ind = @Ind + 1
END

SELECT * FROM ##Grid

-- Draw grid

DECLARE @X INT 
DECLARE @Y INT 
DECLARE @MaxX INT
DECLARE @MaxY INT
DECLARE @MinX INT
DECLARE @MinY INT
DECLARE @Str1 VARCHAR(500)
DECLARE @Str2 VARCHAR(500)
DECLARE @Str3 VARCHAR(500)

SELECT @MinX = MIN(X), @MaxX = MAX(X), @MinY = MIN(Y), @MaxY = MAX(Y) FROM ##Grid

SET @Y = @MinY

WHILE @Y <= @MaxY
BEGIN

    SET @X = @MinX
    SET @Str1 = ''
    SET @Str2 = ''
    SET @Str3 = ''

    WHILE @X <= @MaxX
    BEGIN
        
        SELECT @Str1 = @Str1 + '#' + CASE WHEN North = 1 THEN '-' ELSE '#' END FROM ##Grid WHERE X = @X AND Y = @Y

        SELECT @Str2 = @Str2 + CASE WHEN West = 1 THEN '|' ELSE '#' END + CASE WHEN X = 0 AND Y = 0 THEN 'X' ELSE '∙' END FROM ##Grid WHERE X = @X AND Y = @Y

        SELECT @Str3 = @Str3 + '#' + CASE WHEN South = 1 THEN '-' ELSE '#' END FROM ##Grid WHERE X = @X AND Y = @Y

        SET @X = @X + 1

    END

    PRINT @Str1 + '#'
    PRINT @Str2 + '#'

    SET @Y = @Y + 1
END

PRINT @Str3 + '#'


WHILE EXISTS (SELECT 1 FROM ##Grid WHERE Dist IS NULL)
BEGIN

    ;WITH cte_Max AS (
        SELECT MAX(Dist) AS MaxDist
        FROM ##Grid
    ), cte_ToUpdate As (
    SELECT G2.ID, G.Dist + 1 AS NewDist
    FROM ##Grid G
    INNER JOIN cte_Max cM ON G.Dist = cM.MaxDist
    INNER JOIN ##Grid G2 ON G2.Dist IS NULL
                        AND (  (G.X = G2.X AND G.Y = G2.Y - 1 AND G.South = 1)
                            OR (G.X = G2.X AND G.Y = G2.Y + 1 AND G.North = 1)
                            OR (G.Y = G2.Y AND G.X = G2.X - 1 AND G.East = 1)
                            OR (G.Y = G2.Y AND G.X = G2.X + 1 AND G.West = 1)
                            )
    )
    UPDATE G
    SET Dist = NewDist
    FROM ##Grid G
    INNER JOIN cte_ToUpdate cTU ON G.ID = cTU.ID


END

SELECT MAX(Dist) FROM ##Grid

-- 3568 is correct for part 1

SELECT COUNT(1) FROM ##Grid WHERE Dist >= 1000

-- 8475 is correct for part 2


/*

DROP TABLE ##Input
DROP TABLE ##Grid
DROP TABLE ##SavePoints

*/