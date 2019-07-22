USE Test_WME

DECLARE @Depth INT = 510 --4845
DECLARE @TargetX INT = 10 --6
DECLARE @TargetY INT = 10 --770
DECLARE @SizeX INT = 15 --1000
DECLARE @SizeY INT = 15 --1000


DECLARE @AlongYAxis INT = 16807
DECLARE @AlongXAxis INT = 48271

DECLARE @ModuloCorrection INT = 20183

CREATE TABLE ##Grid (ID INT IDENTITY(1,1), X INT, Y INT, GeologicalIndex INT, ErosionLevel INT, TerrainType INT, TimeToReach INT, LastTool INT)

CREATE INDEX UQ_XY ON ##Grid (X, Y)

;WITH cte_X AS ( 
    SELECT TOP (@SizeX+1) ROW_NUMBER() OVER (ORDER BY (SELECT 0)) - 1 AS X FROM sys.messages
), cte_Y AS (
    SELECT TOP (@SizeY+1) ROW_NUMBER() OVER (ORDER BY (SELECT 0)) - 1 AS Y FROM sys.messages
)
INSERT ##Grid (X, Y, GeologicalIndex, ErosionLevel, TerrainType)
SELECT X
,      Y
,      CASE WHEN (X = 0 AND Y = 0) OR (X = @TargetX AND Y = @TargetY) THEN 0
            WHEN Y = 0 THEN @AlongYAxis * X
            WHEN X = 0 THEN @AlongXAxis * Y
            ELSE -1 END AS GeologicalIndex
,      CASE WHEN (X = 0 AND Y = 0) OR (X = @TargetX AND Y = @TargetY) THEN 0
            WHEN Y = 0 THEN (@AlongYAxis * X + @Depth) % @ModuloCorrection
            WHEN X = 0 THEN (@AlongXAxis * Y + @Depth) % @ModuloCorrection
            ELSE -1 END AS ErosionLevel
,      CASE WHEN (X = 0 AND Y = 0) OR (X = @TargetX AND Y = @TargetY) THEN 0
            WHEN Y = 0 THEN (@AlongYAxis * X + @Depth) % @ModuloCorrection % 3
            WHEN X = 0 THEN (@AlongXAxis * Y + @Depth) % @ModuloCorrection % 3
            ELSE -1 END AS TerrainType
FROM cte_X
CROSS APPLY cte_Y

WHILE (SELECT COUNT(1) FROM ##Grid WHERE TerrainType = -1) > 0
BEGIN

    UPDATE G
    SET    GeologicalIndex = G_X.ErosionLevel * G_Y.ErosionLevel
    ,      ErosionLevel    = (G_X.ErosionLevel * G_Y.ErosionLevel + @Depth) % @ModuloCorrection
    ,      TerrainType     = ((G_X.ErosionLevel * G_Y.ErosionLevel + @Depth) % @ModuloCorrection) % 3
    FROM ##Grid G
    INNER JOIN ##Grid G_X ON G.Y = G_X.Y AND G.X = G_X.X + 1 AND G_X.TerrainType <> -1
    INNER JOIN ##Grid G_Y ON G.X = G_Y.X AND G.Y = G_Y.Y + 1 AND G_Y.TerrainType <> -1
    WHERE G.TerrainType = -1

END


SELECT SUM(TerrainType) FROM ##Grid WHERE X <= @TargetX AND Y <= @TargetY



/*


DROP TABLE ##Grid


*/



--DECLARE @X INT = 0
--DECLARE @Y INT = 0
--DECLARE @MaxX INT 
--DECLARE @Str VARCHAR(MAX) = ''
--SELECT @MaxX = MAX(X) FROM ##Grid

--WHILE @Y <= (SELECT MAX(Y) FROM ##Grid)
--BEGIN

--    SELECT @X = MIN(X) FROM ##Grid
--    SET @Str = ''

--    WHILE @X <= @MaxX
--    BEGIN
        
----        SELECT @Str = @Str + CAST(ISNULL(TerrainType,' ') AS CHAR(1)) FROM ##Grid WHERE X = @X AND Y = @Y
----        SELECT @Str = @Str + CASE WHEN TerrainType < 2 THEN 'X' ELSE '.' END FROM ##Grid WHERE X = @X AND Y = @Y --Rocky and wet
--        SELECT @Str = @Str + CASE WHEN TerrainType IN (0,2) THEN 'X' ELSE '.' END FROM ##Grid WHERE X = @X AND Y = @Y --Rocky and narrow
----        SELECT @Str = @Str + CASE WHEN TerrainType > 0 THEN 'X' ELSE '.' END FROM ##Grid WHERE X = @X AND Y = @Y --Narrow and wet

--        SET @X = @X + 1

--    END

--    PRINT @Str

--    SET @Y = @Y + 1

--END 

--5400 Correcte antwoord voor deel 1


--Het Grid van 1000 x 1000 is goed en handig maar opbouwen kost meer dan 90 minuten


-- Begin een lijst met 0,0 op t = 0
-- Zet vakjes 0,0 in het grid op 0 (qua tijd)

-- Start loop

    -- Kijk naar welke vakjes je kan lopen en welke tool je daarvoor vast pakt

    -- Ken aan deze vakjes de tijd toe als die lager is dan wat er nu staat of als die nog geen tijd heeft
    -- Voeg deze vakjes toe aan je lijst
    -- Verwijder je de oude vakjes uit de lijst

    -- Sta je op vakje 6,770 vertel dan de tijd en welke tool je vast hebt

-- End loop als vakje 10, 800 (en 6, 770) hebt gehad (arbitrair maar ik weet niks beters)



--SELECT *
--INTO Grid
--FROM ##Grid

--ALTER TABLE Grid ALTER COLUMN X INT NOT NULL
--ALTER TABLE Grid ALTER COLUMN Y INT NOT NULL
--ALTER TABLE Grid ADD CONSTRAINT PK_Grid PRIMARY KEY (X, Y)

--ALTER TABLE ##Grid ADD LastTool INT

-- Type: Rocky (C/T) - Narrow (T/N) - Wet (C/N)
-- Tool: Torch (R/N) - Climbing Gear (R/W) - Neither (W/N)
-- Start 0, 0, T
-- End 6,770, T

-- Neither = 0 | Torch = 1 | Climbing Gear = 2
-- Rocky = 0 | Wet = 1 | Narrow = 2

SET NOCOUNT ON

CREATE TABLE ##CurrentSpaces (ID INT IDENTITY(1,1), X INT, Y INT, Tool INT, TimeInMin INT, TerrainType INT)

INSERT ##CurrentSpaces (X, Y, Tool, TimeInMin, TerrainType) VALUES (0, 0, 1, 0, 0)

CREATE TABLE ##AvailableSpaces (ID INT IDENTITY(1,1), X INT, Y INT, Tool INT, TimeInMin INT, TerrainType INT)

DECLARE @Counter INT = 0
DECLARE @GridSpacesFilled INT = 1
DECLARE @GridSize INT
DECLARE @RowsToProcess INT = 1

SELECT @GridSize = COUNT(1) FROM Grid

WHILE (@Counter < 5000 AND @RowsToProcess > 0)
BEGIN

    DELETE FROM ##AvailableSpaces
    
    INSERT ##AvailableSpaces (X, Y, Tool, TimeInMin, TerrainType)
    SELECT CS.X + Sub.dX, CS.Y + Sub.dY, CS.Tool, CS.TimeInMin + 1, CS.TerrainType
    FROM ##CurrentSpaces CS
    CROSS APPLY (
        SELECT 1 AS dX, 0 AS dY UNION
        SELECT -1, 0 UNION 
        SELECT 0, 1 UNION
        SELECT 0, -1
        ) Sub
    WHERE CS.X + Sub.dX >= 0 AND CS.Y + Sub.dY >= 0
    
    UPDATE A
    SET A.Tool = CASE WHEN A.TerrainType = 0 AND Tool = 1 AND G.TerrainType = 1 THEN 2
                      WHEN A.TerrainType = 0 AND Tool = 2 AND G.TerrainType = 2 THEN 1
                      WHEN A.TerrainType = 1 AND Tool = 2 AND G.TerrainType = 2 THEN 0
                      WHEN A.TerrainType = 1 AND Tool = 0 AND G.TerrainType = 0 THEN 2
                      WHEN A.TerrainType = 2 AND Tool = 1 AND G.TerrainType = 1 THEN 0
                      WHEN A.TerrainType = 2 AND Tool = 0 AND G.TerrainType = 0 THEN 1
                      ELSE A.Tool END                                        
    ,   A.TimeInMin = A.TimeInMin + CASE WHEN Tool = 0 AND G.TerrainType = 0
                                           OR Tool = 1 AND G.TerrainType = 1
                                           OR Tool = 2 AND G.TerrainType = 2
                                        THEN 7 ELSE 0 END
    ,   A.TerrainType = G.TerrainType
    FROM ##AvailableSpaces A
    INNER JOIN Grid G ON G.X = A.X AND G.Y = A.Y

    ;WITH cte_Shortest AS (
        SELECT X
        ,      Y
        ,      MIN(TimeInMin) AS MinTimeInMin
        FROM ##AvailableSpaces
        GROUP BY X, Y
    )
    UPDATE G
    SET G.TimeToReach = A.TimeInMin
    ,   G.LastTool = A.Tool
    FROM Grid G
    INNER JOIN ##AvailableSpaces A ON G.X = A.X AND G.Y = A.Y AND (G.TimeToReach IS NULL OR G.TimeToReach > A.TimeInMin)
    INNER JOIN cte_Shortest S ON S.X = G.X AND S.Y = G.Y AND A.TimeInMin = S.MinTimeInMin

    DELETE FROM ##CurrentSpaces

    INSERT ##CurrentSpaces (X, Y, Tool, TimeInMin, TerrainType)
    SELECT DISTINCT 
           A.X
    ,      A.Y
    ,      A.Tool
    ,      A.TimeInMin
    ,      A.TerrainType
    FROM ##AvailableSpaces A
    INNER JOIN Grid G ON A.X = G.X AND A.Y = G.Y
    WHERE G.TimeToReach = A.TimeInMin
      AND A.TimeInMin = (SELECT MIN (ASub.TimeInMin) FROM ##AvailableSpaces ASub WHERE ASub.X = A.X AND ASub.Y = A.Y)

    SELECT @RowsToProcess = @@ROWCOUNT

    IF @Counter % 10 = 0 
    BEGIN
        SELECT @GridSpacesFilled = COUNT(1) FROM Grid WHERE TimeToReach IS NOT NULL

        PRINT 'End of round ' + CAST(@Counter AS VARCHAR(10)) + ' at time ' + CAST(GETDATE() AS VARCHAR(30)) + '. Grid has ' + CAST(@GridSpacesFilled AS VARCHAR(15)) + ' spaces filled'

    END 

    SET @Counter = @Counter + 1

END


/*


		                    Gaat naar		
Komt van	          	     Rocky (0)	          Wet (1)	          Narrow (2)
Rocky (0)	  Torch (1)	     Torch (1)	          *Climbing Gear (2)	Torch (1)
	       Climbing Gear (2)	Climbing Gear (2)	Climbing Gear (2)	*Torch (1)
Wet (1)	  Climbing Gear (2)	Climbing Gear (2)	Climbing Gear (2)	*Neither(0)
	       Neither(0)	     *Climbing Gear (2)	Neither(0)	     Neither(0)
Narrow (2)  Torch (1)	     Torch (1)	          *Neither(0)	     Torch (1)
	       Neither(0)	     *Torch (1)	     Neither(0)	     Neither(0)

DROP TABLE ##CurrentSpaces
DROP TABLE ##AvailableSpaces

UPDATE Grid SET TimeToReach = NULL, LastTool = NULL
UPDATE Grid SET TimeToReach = 0, LastTool = 2 WHERE X = 0 AND Y = 0


*/

--SELECT * FROM Grid WHERE X <= 10 AND Y <= 10

-- 1053 too high
-- Doorrekenen was nu 26:46 min

-- 1036 too low
-- Doorrekenen was nu 26:57 min

--1044 too low (random guess)

-- 1048 is goed?
/*
SELECT (1053 - 1044)/2 + 1044
SELECT 1053-7
SELECT 1053-1
*/