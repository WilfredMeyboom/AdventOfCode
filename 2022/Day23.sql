USE Test_WME

SET NOCOUNT ON

DECLARE @year VARCHAR(4) = '2022'
DECLARE @day VARCHAR(2)  = '23'

EXEC dbo.GetInput @year = @year, @day = @day
EXEC dbo.ParseInput @year = @year, @day = @day 

--SELECT TOP 10 * FROM ##Input
--SELECT TOP 10 * FROM ##InputInts
--SELECT TOP 10 * FROM ##InputNumbered
--SELECT TOP 1000 * FROM ##InputGrid
--SELECT TOP 10 * FROM ##InputSplit
--SELECT TOP 10 * FROM ##InputSplitCust
  

CREATE TABLE ##Elves (ID INT IDENTITY(1,1), x INT, y INT, lastDir CHAR, nextDir CHAR, xNew INT, yNew INT, canMove INT, elvesNorth INT, elvesWest INT, elvesSouth INT, elvesEast INT)
CREATE UNIQUE INDEX uq_elves ON ##Elves (x,y)

INSERT ##Elves
(
    x,
    y,
    lastDir
)
SELECT RowNr, ColNr, 'W'
FROM ##InputGrid
WHERE Val = '#'


DECLARE @Counter INT = 0
DECLARE @NrOfElves INT
SELECT @NrOfElves = COUNT(1) FROM ##Elves E

DECLARE @Directions TABLE (PrevDir CHAR, NextDir1 CHAR, NextDir2 CHAR, NextDir3 CHAR)
INSERT @Directions (PrevDir, NextDir1, NextDir2, NextDir3)
SELECT 'E','N','S','W' UNION SELECT 'N','S','W','E' UNION SELECT 'S','W','E','N' UNION SELECT 'W','E','N','S'

--SELECT 'Init' AS [Round], *, GETDATE() AS DT FROM ##Elves E

WHILE EXISTS (SELECT 1 FROM ##Elves E WHERE ISNULL(E.elvesNorth,1) > 0 OR E.elvesWest > 0 OR E.elvesSouth > 0 OR E.elvesEast > 0)
BEGIN

    -- Reset for the next round
    UPDATE E
    SET canMove = NULL
    ,   xNew = NULL
    ,   yNew = NULL
    ,   lastDir = D.NextDir1
    FROM ##Elves E
    INNER JOIN @Directions D ON E.lastDir = D.PrevDir

    -- How many elves are adjacent to each elf
    ;WITH cte_elfCount AS (
        SELECT E.ID, E.x, E.y
        ,      SUM(CASE WHEN EAd.ID IS NOT NULL AND E.x - EAd.x = 1 THEN 1 ELSE 0 END) AS elvesNorth
        ,      SUM(CASE WHEN EAd.ID IS NOT NULL AND EAd.x - E.x = 1 THEN 1 ELSE 0 END) AS elvesSouth
        ,      SUM(CASE WHEN EAd.ID IS NOT NULL AND E.y - EAd.y = 1 THEN 1 ELSE 0 END) AS elvesWest
        ,      SUM(CASE WHEN EAd.ID IS NOT NULL AND EAd.y - E.y = 1 THEN 1 ELSE 0 END) AS elvesEast
        FROM ##Elves E
        LEFT JOIN ##Elves EAd ON EAd.ID <> E.ID
                             AND ABS(E.x - EAd.x) <= 1
                             AND ABS(E.y - EAd.y) <= 1
        GROUP BY E.ID, E.x, E.y
    )
    UPDATE E
    SET E.elvesNorth = c.elvesNorth
    ,   E.elvesSouth = c.elvesSouth
    ,   E.elvesWest = c.elvesWest
    ,   E.elvesEast = c.elvesEast
    FROM ##Elves E
    INNER JOIN cte_elfCount c ON c.ID = E.ID

    -- Fully free elves and fully enclosed elves don't move
    UPDATE ##Elves
    SET canMove = 0
    WHERE (elvesNorth = 0 AND elvesWest = 0 AND elvesSouth = 0 AND elvesEast = 0)
       OR (elvesNorth > 0 AND elvesWest > 0 AND elvesSouth > 0 AND elvesEast > 0)

    -- Which direction want the elf to move
    UPDATE E
    SET E.nextDir = CASE WHEN D.NextDir1 = 'N' AND E.elvesNorth = 0 THEN 'N'
                         WHEN D.NextDir1 = 'S' AND E.elvesSouth = 0 THEN 'S'
                         WHEN D.NextDir1 = 'W' AND E.elvesWest = 0 THEN 'W'
                         WHEN D.NextDir1 = 'E' AND E.elvesEast = 0 THEN 'E'
                         ELSE CASE WHEN D.NextDir2 = 'N' AND E.elvesNorth = 0 THEN 'N'
                                   WHEN D.NextDir2 = 'S' AND E.elvesSouth = 0 THEN 'S'
                                   WHEN D.NextDir2 = 'W' AND E.elvesWest = 0 THEN 'W'
                                   WHEN D.NextDir2 = 'E' AND E.elvesEast = 0 THEN 'E'
                                   ELSE CASE WHEN D.NextDir3 = 'N' AND E.elvesNorth = 0 THEN 'N'
                                             WHEN D.NextDir3 = 'S' AND E.elvesSouth = 0 THEN 'S'
                                             WHEN D.NextDir3 = 'W' AND E.elvesWest = 0 THEN 'W'
                                             WHEN D.NextDir3 = 'E' AND E.elvesEast = 0 THEN 'E'
                                             ELSE CASE WHEN D.PrevDir = 'N' AND E.elvesNorth = 0 THEN 'N'
                                                       WHEN D.PrevDir = 'S' AND E.elvesSouth = 0 THEN 'S'
                                                       WHEN D.PrevDir = 'W' AND E.elvesWest = 0 THEN 'W'
                                                       WHEN D.PrevDir = 'E' AND E.elvesEast = 0 THEN 'E'
                                                  END
                                        END
                              END
                    END
    , E.canMove = 1
    FROM ##Elves E
    INNER JOIN @Directions D ON E.lastDir = D.PrevDir
    WHERE E.canMove IS NULL

    -- Check if there are any problems
    IF EXISTS (SELECT 1 FROM ##Elves E WHERE E.canMove IS NULL OR (E.canMove = 1 AND E.nextDir IS NULL)) SELECT 'Problem', * FROM ##Elves E

    -- Where does the elf want to move
    UPDATE E
    SET E.xNew = CASE WHEN E.nextDir = 'N' THEN E.x - 1
                      WHEN E.nextDir = 'S' THEN E.x + 1
                      ELSE E.x END
    ,   E.yNew = CASE WHEN E.nextDir = 'W' THEN E.y - 1
                      WHEN E.nextDir = 'E' THEN E.y + 1
                      ELSE E.y END
    FROM ##Elves E 
    WHERE canMove = 1

    -- Do multiple elves want to move in the same space? If yes, stop the movement
    UPDATE E
    SET E.canMove = 0 
    FROM ##Elves E
    INNER JOIN ##Elves E2 ON E.ID <> E2.ID AND E.xNew = E2.xNew AND E.yNew = E2.yNew
    WHERE E.canMove = 1

    -- And finally move
    UPDATE ##Elves
    SET x = xNew
    ,   y = yNew
    WHERE canMove = 1

    --SELECT @Counter AS [Round], *, GETDATE() AS DT FROM ##Elves E

    SET @Counter = @Counter + 1

    IF @Counter = 10 SELECT (MAX(x) - MIN(x) + 1) * (MAX(y) - MIN(y) + 1) - @NrOfElves AS Part1 FROM ##Elves E
END

SELECT @Counter AS Part2


DROP TABLE ##Elves

-- Runtime: 00:11:50

