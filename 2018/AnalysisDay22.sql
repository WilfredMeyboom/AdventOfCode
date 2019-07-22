--SELECT COUNT(1) FROM ##AvailableSpaces
--SELECT COUNT(1) FROM ##CurrentSpaces
--250310



DECLARE @X INT = 0
DECLARE @Y INT = 0
DECLARE @MaxX INT 
DECLARE @MaxY INT 
DECLARE @Str VARCHAR(MAX) = ''
SELECT @MaxX = MAX(X) FROM Grid
SELECT @MaxY = MAX(Y) FROM Grid

--SET @MaxX = 5
--SET @MaxY = 5

WHILE @Y <= @MaxY
BEGIN

    SELECT @X = MIN(X) FROM Grid
    SET @Str = ''

    WHILE @X <= @MaxX
    BEGIN
        
        SELECT @Str = @Str + RIGHT('000' + CAST(TimeToReach AS VARCHAR(5)), 4) + '|' FROM Grid WHERE X = @X AND Y = @Y 
        --SELECT @Str = @Str + CAST(TerrainType AS VARCHAR(5)) + '|' FROM Grid WHERE X = @X AND Y = @Y 
        SET @X = @X + 1

    END

    PRINT @Str

    SET @Y = @Y + 1

END 

-- Type: Rocky (C/T) - Narrow (T/N) - Wet (C/N)
-- Tool: Torch (R/N) - Climbing Gear (R/W) - Neither (W/N)

-- Neither = 0 | Torch = 1 | Climbing Gear = 2
-- Rocky = 0 | Wet = 1 | Narrow = 2

--SELECT * FROM Grid WHERE X = 1000 AND TimeToReach < 1054
--SELECT * FROM Grid WHERE Y = 1000 AND TimeToReach < 1054
--SELECT COUNT(1) FROM Grid


--SELECT * FROM Grid WHERE X IN (997,998,999,1000) AND Y IN (999,1000)

-- Kan je een query schrijven om te controleren dat we echt klaar zijn?
-- Oftewel, twee aangegrenzde vakjes waarbij geldt dat de kleine meer dan 1 verschilt van de grote
-- 

SELECT * 
FROM Grid G1
INNER JOIN Grid G2 ON ((ABS(G1.X - G2.X) = 1 AND G1.Y = G2.Y)
                   OR (ABS(G1.Y - G2.Y) = 1 AND G1.X = G2.X))
                   AND G1.TimeToReach - G2.TimeToReach > 1
                   AND G1.TerrainType = G2.TerrainType
