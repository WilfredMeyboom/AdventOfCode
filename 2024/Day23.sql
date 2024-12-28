USE Test_WME

SET NOCOUNT ON

DECLARE @year VARCHAR(4) = '2024'
DECLARE @day VARCHAR(2)  = '23'

EXEC dbo.GetInput @year = @year, @day = @day
EXEC dbo.ParseInput @year = @year, @day = @day 

--SELECT TOP 10 * FROM ##Input
--SELECT TOP 10 * FROM ##InputInts
--SELECT TOP 10 * FROM ##InputNumbered
--SELECT TOP 10 * FROM ##InputGrid
--SELECT TOP 10 * FROM ##InputSplit
--SELECT TOP 10 * FROM ##InputSplitCust

;WITH cte_Connections AS (
    SELECT CASE WHEN LEFT(Line, 2) < RIGHT(Line,2)
                THEN LEFT(Line, 2) ELSE RIGHT(Line,2) END AS Comp1
    ,      CASE WHEN LEFT(Line, 2) > RIGHT(Line,2)
                THEN LEFT(Line, 2) ELSE RIGHT(Line,2) END AS Comp2
    , Line
    FROM ##InputNumbered
)
SELECT COUNT(1) AS Part1 --c1.Comp1, c1.Comp2, c2.Comp2
FROM cte_Connections c1
INNER JOIN cte_Connections c2 ON c1.Comp1 = c2.Comp1 AND c1.Comp2 < c2.Comp2
INNER JOIN cte_Connections c3 ON c1.Comp2 = c3.Comp1 AND c2.Comp2 = c3.Comp2
WHERE c1.Comp1 LIKE 't%'
   OR c1.Comp2 LIKE 't%'
   OR c2.Comp2 LIKE 't%'
--ORDER BY c1.Comp1, c1.Comp2




CREATE TABLE ##Comps (ID INT IDENTITY(1,1), Comp VARCHAR(2))

INSERT ##Comps (Comp)
SELECT LEFT(Line,2)
FROM ##InputNumbered
UNION
SELECT RIGHT(Line,2)
FROM ##InputNumbered

CREATE TABLE ##Connections (ID INT IDENTITY, Comp1 VARCHAR(2), Comp2 VARCHAR(2))

;WITH cte_Connections AS (
    SELECT CASE WHEN LEFT(Line, 2) < RIGHT(Line,2)
                THEN LEFT(Line, 2) ELSE RIGHT(Line,2) END AS Comp1
    ,      CASE WHEN LEFT(Line, 2) > RIGHT(Line,2)
                THEN LEFT(Line, 2) ELSE RIGHT(Line,2) END AS Comp2
    FROM ##InputNumbered
    UNION
    SELECT CASE WHEN LEFT(Line, 2) > RIGHT(Line,2)
                THEN LEFT(Line, 2) ELSE RIGHT(Line,2) END AS Comp1
    ,      CASE WHEN LEFT(Line, 2) < RIGHT(Line,2)
                THEN LEFT(Line, 2) ELSE RIGHT(Line,2) END AS Comp2
    FROM ##InputNumbered
)
INSERT ##Connections (Comp1, Comp2)
SELECT Comp1, Comp2
FROM cte_Connections c1



CREATE TABLE ##Groups (ID INT IDENTITY(1,1), Comp VARCHAR(2), GroupNr INT)

CREATE TABLE ##TempComps (ID INT IDENTITY(1,1), Comp VARCHAR(2))

DECLARE @GroupNr INT = 1
DECLARE @Comp VARCHAR(2)


WHILE EXISTS (SELECT 1
              FROM ##Connections c1
              INNER JOIN ##Connections c2 ON c1.Comp1 = c2.Comp1 AND c1.Comp2 < c2.Comp2
              INNER JOIN ##Connections c3 ON c1.Comp2 = c3.Comp1 AND c2.Comp2 = c3.Comp2)
BEGIN
    
   

--DECLARE @GroupNr INT = 1
    --Pick a starting triangle
    ;WITH cte_Start AS (
        SELECT TOP(1) c1.Comp1, c1.Comp2, c2.Comp2 AS Comp3
        FROM ##Connections c1
        INNER JOIN ##Connections c2 ON c1.Comp1 = c2.Comp1 AND c1.Comp2 < c2.Comp2
        INNER JOIN ##Connections c3 ON c1.Comp2 = c3.Comp1 AND c2.Comp2 = c3.Comp2
    )
    INSERT ##Groups (Comp, GroupNr)
    SELECT Comp1, @GroupNr
    FROM cte_Start
    UNION
    SELECT Comp2, @GroupNr
    FROM cte_Start
    UNION
    SELECT Comp3, @GroupNr
    FROM cte_Start

    --These comps are assigned to a group
    DELETE FROM ##Comps
    WHERE Comp IN (SELECT Comp FROM ##Groups WHERE GroupNr = @GroupNr)

    --Prep a list for the while loop
    DELETE FROM ##TempComps
    INSERT ##TempComps (Comp) SELECT Comp FROM ##Comps

    --Loop over the remaining comps
    WHILE EXISTS (SELECT 1 FROM ##TempComps)
    BEGIN

        SELECT TOP(1) @Comp = Comp FROM ##TempComps

        --If this comp has a connection to all others in the group, add it to the group
        IF NOT EXISTS (
            SELECT 1
            FROM ##Groups G
            LEFT JOIN ##Connections CN ON G.Comp = CN.Comp1 AND CN.Comp2 = @Comp
            WHERE CN.ID IS NULL AND G.GroupNr = @GroupNr
        )
        INSERT ##Groups (Comp, GroupNr) SELECT @Comp, @GroupNr

        DELETE FROM ##TempComps WHERE Comp = @Comp
    END

    DELETE FROM ##Comps
    WHERE Comp IN (SELECT Comp FROM ##Groups WHERE GroupNr = @GroupNr)

    DELETE FROM ##Connections
    WHERE Comp1 IN (SELECT Comp FROM ##Groups WHERE GroupNr = @GroupNr)
      AND Comp2 IN (SELECT Comp FROM ##Groups WHERE GroupNr = @GroupNr)

    SET @GroupNr = @GroupNr + 1

END

SELECT STRING_AGG(Comp, ',') 
FROM ##Groups G
INNER JOIN (SELECT TOP (1) GroupNr, COUNT(1) AS Size FROM ##Groups GROUP BY GroupNr ORDER BY 2 DESC) Sub ON Sub.GroupNr = G.GroupNr


/*

DROP TABLE ##TempComps
DROP TABLE ##Groups
DROP TABLE ##Connections
DROP TABLE ##Comps

*/