USE Test_WME

SET NOCOUNT ON

/*

..#.#
.#.##
##...
.#.#.
###..

00101
01011
11000
01010
11100

*/


CREATE TABLE ##Eris (ID INT IDENTITY(1,1), x INT, y INT, z INT, val INT/*, bioVal AS POWER(2, y + 5*x)*/, UNIQUE(x,y,z))


INSERT ##Eris (x, y, z, val) VALUES (0, 0, 0, 0)
INSERT ##Eris (x, y, z, val) VALUES (0, 1, 0, 0)
INSERT ##Eris (x, y, z, val) VALUES (0, 2, 0, 1)
INSERT ##Eris (x, y, z, val) VALUES (0, 3, 0, 0)
INSERT ##Eris (x, y, z, val) VALUES (0, 4, 0, 1)
                                           
INSERT ##Eris (x, y, z, val) VALUES (1, 0, 0, 0)
INSERT ##Eris (x, y, z, val) VALUES (1, 1, 0, 1)
INSERT ##Eris (x, y, z, val) VALUES (1, 2, 0, 0)
INSERT ##Eris (x, y, z, val) VALUES (1, 3, 0, 1)
INSERT ##Eris (x, y, z, val) VALUES (1, 4, 0, 1)
                                           
INSERT ##Eris (x, y, z, val) VALUES (2, 0, 0, 1)
INSERT ##Eris (x, y, z, val) VALUES (2, 1, 0, 1)
--INSERT ##Eris (x, y, z, val) VALUES (2, 2, 0, 0)
INSERT ##Eris (x, y, z, val) VALUES (2, 3, 0, 0)
INSERT ##Eris (x, y, z, val) VALUES (2, 4, 0, 0)
                                           
INSERT ##Eris (x, y, z, val) VALUES (3, 0, 0, 0)
INSERT ##Eris (x, y, z, val) VALUES (3, 1, 0, 1)
INSERT ##Eris (x, y, z, val) VALUES (3, 2, 0, 0)
INSERT ##Eris (x, y, z, val) VALUES (3, 3, 0, 1)
INSERT ##Eris (x, y, z, val) VALUES (3, 4, 0, 0)
                                           
INSERT ##Eris (x, y, z, val) VALUES (4, 0, 0, 1)
INSERT ##Eris (x, y, z, val) VALUES (4, 1, 0, 1)
INSERT ##Eris (x, y, z, val) VALUES (4, 2, 0, 1)
INSERT ##Eris (x, y, z, val) VALUES (4, 3, 0, 0)
INSERT ##Eris (x, y, z, val) VALUES (4, 4, 0, 0)

/* Example part 2
INSERT ##Eris (x, y, z, val) VALUES (0, 0, 0, 0)
INSERT ##Eris (x, y, z, val) VALUES (0, 1, 0, 0)
INSERT ##Eris (x, y, z, val) VALUES (0, 2, 0, 0)
INSERT ##Eris (x, y, z, val) VALUES (0, 3, 0, 0)
INSERT ##Eris (x, y, z, val) VALUES (0, 4, 0, 1)
                                           
INSERT ##Eris (x, y, z, val) VALUES (1, 0, 0, 1)
INSERT ##Eris (x, y, z, val) VALUES (1, 1, 0, 0)
INSERT ##Eris (x, y, z, val) VALUES (1, 2, 0, 0)
INSERT ##Eris (x, y, z, val) VALUES (1, 3, 0, 1)
INSERT ##Eris (x, y, z, val) VALUES (1, 4, 0, 0)
                                           
INSERT ##Eris (x, y, z, val) VALUES (2, 0, 0, 1)
INSERT ##Eris (x, y, z, val) VALUES (2, 1, 0, 0)
--INSERT ##Eris (x, y, z, val) VALUES (2, 2, 0, 0)
INSERT ##Eris (x, y, z, val) VALUES (2, 3, 0, 1)
INSERT ##Eris (x, y, z, val) VALUES (2, 4, 0, 1)
                                           
INSERT ##Eris (x, y, z, val) VALUES (3, 0, 0, 0)
INSERT ##Eris (x, y, z, val) VALUES (3, 1, 0, 0)
INSERT ##Eris (x, y, z, val) VALUES (3, 2, 0, 1)
INSERT ##Eris (x, y, z, val) VALUES (3, 3, 0, 0)
INSERT ##Eris (x, y, z, val) VALUES (3, 4, 0, 0)
                                           
INSERT ##Eris (x, y, z, val) VALUES (4, 0, 0, 1)
INSERT ##Eris (x, y, z, val) VALUES (4, 1, 0, 0)
INSERT ##Eris (x, y, z, val) VALUES (4, 2, 0, 0)
INSERT ##Eris (x, y, z, val) VALUES (4, 3, 0, 0)
INSERT ##Eris (x, y, z, val) VALUES (4, 4, 0, 0)
*/


CREATE TABLE ##Level (x INT, y INT)

INSERT ##Level (x,y)
SELECT TOP 25
       (ROW_NUMBER() OVER (ORDER BY (SELECT 0)) - 1) % 5 AS x
,      (ROW_NUMBER() OVER (ORDER BY (SELECT 0)) - 1) / 5 AS y
FROM sys.messages

DELETE FROM ##Level WHERE x = 2 AND y = 2

--SELECT * FROM ##Eris

--CREATE TABLE ##Biodiversity (ID INT IDENTITY(1,1), BioValTot INT)

--DECLARE @BioValTot INT = 0

--SELECT @BioValTot = SUM(BioVal) FROM ##Eris WHERE val = 1
--INSERT ##Biodiversity (BioValTot) VALUES (@BioValTot)

DECLARE @Counter INT = 0 

--WHILE (SELECT COUNT(1) FROM ##Biodiversity WHERE BioValTot = @BioValTot) < 2
WHILE @Counter < 200 --10
BEGIN

    ;WITH cte_MaxZ AS
    (
        SELECT MAX(z) AS maxZ
        FROM ##Eris
    ), cte_NewLevelNeeded AS
    (
        SELECT DISTINCT 1 AS dummy
        FROM ##Eris E
        INNER JOIN cte_MaxZ cM ON E.z = cM.maxZ
        WHERE val > 0
    )
    INSERT ##Eris (x, y, z, val)
    SELECT x, y, maxZ + 1, 0
    FROM ##Level
    CROSS APPLY cte_NewLevelNeeded
    CROSS APPlY cte_MaxZ

    ;WITH cte_MinZ AS
    (
        SELECT MIN(z) AS minZ
        FROM ##Eris
    ), cte_NewLevelNeeded AS
    (
        SELECT DISTINCT 1 AS dummy
        FROM ##Eris E
        INNER JOIN cte_MinZ cM ON E.z = cM.minZ
        WHERE val > 0
    )
    INSERT ##Eris (x, y, z, val)
    SELECT x, y, minZ - 1, 0
    FROM ##Level
    CROSS APPLY cte_NewLevelNeeded
    CROSS APPlY cte_MinZ    

-- Maak de join complexer. 2,2 alleen op niveau 0, binnenrand met niveau lager, buitenrand met niveau hoger
    ;WITH cte_Adj AS (
        SELECT EC.ID, SUM(EA.val) AS NrOfAdj
        FROM ##Eris EC
        INNER JOIN ##Eris EA ON (ABS(EC.x - EA.x) = 1 AND EC.y = EA.y AND EC.z = EA.z)  --Alles aangrenzend op hetzelfde
                             OR (ABS(EC.y - EA.y) = 1 AND EC.x = EA.x AND EC.z = EA.z)  --level is goed

                             OR (EC.x = 0 AND EC.z = EA.z - 1 AND EA.x = 1 AND EA.y = 2) -- Rij 0 zit vast aan het vak dat er midden boven zit
                             OR (EC.x = 4 AND EC.z = EA.z - 1 AND EA.x = 3 AND EA.y = 2) -- Rij 4 zit vast aan het vak dat er midden onder zit
                             OR (EC.y = 0 AND EC.z = EA.z - 1 AND EA.x = 2 AND EA.y = 1) -- Kolom 0 zit vast aan het vak dat er midden links zit
                             OR (EC.y = 4 AND EC.z = EA.z - 1 AND EA.x = 2 AND EA.y = 3) -- Kolom 4 zit vast aan het vak dat er midden rechts zit

                             OR (EC.x = 1 AND EC.y = 2 AND EC.z = EA.z + 1 AND EA.x = 0) -- Vakje 1,2 zit aan een hele rij vast
                             OR (EC.x = 3 AND EC.y = 2 AND EC.z = EA.z + 1 AND EA.x = 4) -- Vakje 1,2 zit aan een hele rij vast
                             OR (EC.x = 2 AND EC.y = 1 AND EC.z = EA.z + 1 AND EA.y = 0) -- Vakje 1,2 zit aan een hele rij vast
                             OR (EC.x = 2 AND EC.y = 3 AND EC.z = EA.z + 1 AND EA.y = 4) -- Vakje 1,2 zit aan een hele rij vast
        GROUP BY EC.ID
    )
    UPDATE E
    SET val = CASE WHEN E.val = 1 AND cA.NrOfAdj <> 1 THEN 0
                   WHEN E.val = 0 AND cA.NrOfAdj IN (1,2) THEN 1
                   ELSE E.val END
    FROM ##Eris E
    INNER JOIN cte_Adj cA ON E.ID = cA.ID

    --SELECT @BioValTot = SUM(BioVal) FROM ##Eris WHERE val = 1
    --INSERT ##Biodiversity (BioValTot) VALUES (@BioValTot)

    SET @Counter = @Counter + 1

    IF (@Counter % 10) = 0 PRINT '10 iterations done at ' + CAST(GETDATE() AS VARCHAR(50))
END

/*

DROP TABLE ##Eris
DROP TABLE ##Biodiversity
DROP TABLE ##Level

*/

--18401265 is correct for part 1


/*

DECLARE @x INT = 0
DECLARE @y INT = 0
DECLARE @z INT = 0
DECLARE @zMax INT = 0
DECLARE @Str VARCHAR(5)
DECLARE @Space CHAR
SELECT @z = MIN(z), @zMax = MAX(z) FROM ##Eris

WHILE @z <= @zMax
BEGIN

    PRINT @z
    SET @x = 0
    
    WHILE @x < 5
    BEGIN

        SET @y = 0
        SET @Str = ''

        WHILE @y < 5
        BEGIN

            ;WITH cte_1 AS (
                SELECT CASE WHEN val = 0 THEN '.' ELSE '#' END AS Space
                FROM ##Eris WHERE x = @x AND y = @y AND z = @z
                UNION SELECT '?'
            )
            SELECT TOP 1 @Space = Space FROM cte_1

            SET @Str = @Str + @Space

            SET @y = @y + 1
        END

        PRINT @Str
        SET @x = @x + 1
    END

    PRINT ''

    SET @z = @z + 1
END

*/



SELECT * FROM ##Eris
SELECT SUM(Val) FROM ##Eris

--1144 is too low for part 2
--2255 is too high for part 2
--2184 is too high for part 2