USE Test_WME

SET NOCOUNT ON

DECLARE @year VARCHAR(4) = '2023'
DECLARE @day VARCHAR(2)  = '13'

EXEC dbo.GetInput @year = @year, @day = @day
EXEC dbo.ParseInput @year = @year, @day = @day 

--SELECT TOP 10 * FROM ##Input
--SELECT TOP 10 * FROM ##InputInts
--SELECT TOP 10 * FROM ##InputNumbered
--SELECT TOP 10 * FROM ##InputSplit
--SELECT TOP 10 * FROM ##InputSplitCust

INSERT ##InputGrid (RowNr, ColNr, Val)
SELECT MAX(RowNr) + 1, 0, NULL FROM ##InputGrid
  
CREATE TABLE ##Maps (ID INT IDENTITY(1,1), MapNr INT, RowNr INT, ColNr INT, Val CHAR)

;WITH cte_Rows2Map AS (
    SELECT ROW_NUMBER() OVER (ORDER BY RowNr) AS MapNr
    ,      ISNULL(LAG(RowNr) OVER (ORDER BY RowNr) + 1, 0) AS StartRowNr
    ,      RowNr AS EndRowNr
    FROM ##InputGrid
    WHERE Val IS NULL
)
INSERT ##Maps (MapNr, RowNr, ColNr, Val)
SELECT c.MapNr, I.RowNr - c.StartRowNr, I.ColNr, I.Val
FROM ##InputGrid I
INNER JOIN cte_Rows2Map c ON I.RowNr BETWEEN c.StartRowNr AND c.EndRowNr
WHERE I.Val IS NOT NULL
ORDER BY MapNr, RowNr, ColNr


CREATE TABLE ##MirrorLines (ID INT IDENTITY(1,1), MapNr INT, RowNr INT, ColNr INT, RowSize INT, ColSize INT)

;WITH cte_MirrorOverRow AS (
    SELECT M1.MapNr, M1.RowNr, COUNT(1) AS NrOfMatchingVals
    FROM ##Maps M1
    INNER JOIN ##Maps M2 ON M1.MapNr = M2.MapNr 
                        AND M1.RowNr = M2.RowNr - 1 
                        AND M1.ColNr = M2.ColNr
                        AND M1.Val = M2.Val
    GROUP BY M1.MapNr, M1.RowNr
), cte_MirrorOverCol AS (
    SELECT M1.MapNr, M1.ColNr, COUNT(1) AS NrOfMatchingVals
    FROM ##Maps M1
    INNER JOIN ##Maps M2 ON M1.MapNr = M2.MapNr 
                        AND M1.RowNr = M2.RowNr
                        AND M1.ColNr = M2.ColNr - 1
                        AND M1.Val = M2.Val
    GROUP BY M1.MapNr, M1.ColNr
), cte_Mapsize AS (
    SELECT MapNr, MAX(RowNr) - MIN(RowNr) + 1 AS RowSize, MAX(ColNr) - MIN(ColNr) + 1 AS ColSize
    FROM ##Maps
    GROUP BY MapNr
)
INSERT ##MirrorLines (MapNr, RowNr, ColNr, RowSize, ColSize)
SELECT cM.MapNr, CMOR.RowNr, CMOC.ColNr, cM.RowSize, cM.ColSize 
FROM cte_Mapsize cM
LEFT JOIN cte_MirrorOverRow CMOR ON cM.MapNr = CMOR.MapNr AND CMOR.NrOfMatchingVals = cM.ColSize
LEFT JOIN cte_MirrorOverCol CMOC ON cM.MapNr = CMOC.MapNr AND CMOC.NrOfMatchingVals = cM.RowSize
ORDER BY cM.MapNr

SELECT *
INTO ##MirrorLines2
FROM ##MirrorLines

DECLARE @Level INT = 1

WHILE (SELECT COUNT(1) FROM (SELECT MapNr, RowNr, ColNr FROM ##MirrorLines GROUP BY MapNr, RowNr, ColNr) S) > (SELECT MAX(MapNr) FROM ##Maps)
BEGIN

--DECLARE @Level INT = 2

    UPDATE ##MirrorLines
    SET ColNr = NULL
    WHERE ID IN (
        SELECT ML.ID
        FROM ##MirrorLines ML
        INNER JOIN ##Maps M1 ON ML.MapNr = M1.MapNr
        INNER JOIN ##Maps M2 ON ML.MapNr = M2.MapNr AND ML.ColNr = M1.ColNr + @Level AND ML.ColNr = M2.ColNr - 1 - @Level AND M1.RowNr = M2.RowNr AND M1.Val = M2.Val
        WHERE ML.ColNr IS NOT NULL
        GROUP BY ML.ID, ML.RowSize
        HAVING COUNT(1) < ML.RowSize 
    )


    UPDATE ##MirrorLines
    SET RowNr = NULL
    WHERE ID IN (
        SELECT ML.ID
        FROM ##MirrorLines ML
        INNER JOIN ##Maps M1 ON ML.MapNr = M1.MapNr
        INNER JOIN ##Maps M2 ON ML.MapNr = M2.MapNr AND ML.RowNr = M1.RowNr + @Level AND ML.RowNr = M2.RowNr - 1 - @Level AND M1.ColNr = M2.ColNr AND M1.Val = M2.Val
        WHERE ML.RowNr IS NOT NULL
        GROUP BY ML.ID, ML.ColSize
        HAVING COUNT(1) < ML.ColSize
    )

    DELETE FROM ##MirrorLines
    WHERE RowNr IS NULL AND ColNr IS NULL

    PRINT @Level
    SET @Level = @Level + 1
        
END

DELETE FROM ML 
FROM ##MirrorLines ML
INNER JOIN ##MirrorLines ML2 ON ML.ID > ML2.ID AND ML.MapNr = ML2.MapNr

SELECT SUM(ISNULL(RowNr+1,0)*100 + ISNULL(ColNr+1,0))
FROM ##MirrorLines

--SELECT * FROM ##MirrorLines2
--SELECT * FROM ##MirrorLines


/*
Er zijn 3 groepen:
- maps waar maar 1 regel voor is -> daar zit de smudge dus tegen de mirror lijn aan
- maps waar precies 2 regels voor zijn of waar een row en een col voor zijn -> daar is de regel die in deel afgevallen is, degene die wij nu willen hebben
- maps waar 3 regels of 2 regels en een row & col combi voor zijn -> hier moeten we uit 2 regels de beste gaan kiezen
*/

ALTER TABLE ##MirrorLines2 ADD Category INT

UPDATE M
SET Category = 3
FROM ##MirrorLines2 M
INNER JOIN ##MirrorLines2 M2 ON M.ID <> M2.ID AND M.MapNr = M2.MapNr
WHERE M.RowNr IS NOT NULL AND M2.ColNr IS NOT NULL

UPDATE M
SET Category = 3
FROM ##MirrorLines2 M
WHERE MapNr IN (SELECT MapNr FROM ##MirrorLines2 GROUP BY MapNr HAVING COUNT(1) > 2)

UPDATE M
SET Category = 2
FROM ##MirrorLines2 M WHERE RowNr IS NOT NULL AND ColNr IS NOT NULL

UPDATE M
SET Category = 2
FROM ##MirrorLines2 M
WHERE MapNr IN (SELECT MapNr FROM ##MirrorLines2 GROUP BY MapNr HAVING COUNT(1) = 2)
                             
UPDATE M
SET Category = 1
FROM ##MirrorLines2 M
WHERE Category IS NULL

UPDATE M2
SET M2.RowNr = CASE WHEN M.RowNr IS NOT NULL THEN NULL ELSE M2.RowNr END
,   M2.ColNr = CASE WHEN M.ColNr IS NOT NULL THEN NULL ELSE M2.ColNr END
,   Category = 0
FROM ##MirrorLines2 M2
INNER JOIN ##MirrorLines M ON M.MapNr = M2.MapNr AND (M.RowNr = M2.RowNr OR M.ColNr = M2.ColNr)
WHERE M2.Category = 2

DELETE FROM ##MirrorLines2 WHERE RowNr IS NULL AND ColNr IS NULL

UPDATE ##MirrorLines2 SET Category = 0 WHERE Category = 2

;WITH cte_MirrorOverRow AS (
    SELECT M1.MapNr, M1.RowNr, COUNT(1) AS NrOfMatchingVals
    FROM ##Maps M1
    INNER JOIN ##Maps M2 ON M1.MapNr = M2.MapNr 
                        AND M1.RowNr = M2.RowNr - 1 
                        AND M1.ColNr = M2.ColNr
                        AND M1.Val = M2.Val
    GROUP BY M1.MapNr, M1.RowNr
), cte_MirrorOverCol AS (
    SELECT M1.MapNr, M1.ColNr, COUNT(1) AS NrOfMatchingVals
    FROM ##Maps M1
    INNER JOIN ##Maps M2 ON M1.MapNr = M2.MapNr 
                        AND M1.RowNr = M2.RowNr
                        AND M1.ColNr = M2.ColNr - 1
                        AND M1.Val = M2.Val
    GROUP BY M1.MapNr, M1.ColNr
), cte_Mapsize AS (
    SELECT MapNr, MAX(RowNr) - MIN(RowNr) + 1 AS RowSize, MAX(ColNr) - MIN(ColNr) + 1 AS ColSize
    FROM ##Maps
    GROUP BY MapNr
)
SELECT cM.MapNr, CMOR.RowNr, CMOC.ColNr, cM.RowSize, cM.ColSize
INTO ##MirrorLines3
FROM cte_Mapsize cM
LEFT JOIN cte_MirrorOverRow CMOR ON cM.MapNr = CMOR.MapNr AND CMOR.NrOfMatchingVals = cM.ColSize - 1
LEFT JOIN cte_MirrorOverCol CMOC ON cM.MapNr = CMOC.MapNr AND CMOC.NrOfMatchingVals = cM.RowSize - 1
WHERE cM.MapNr IN (SELECT MapNr FROM ##MirrorLines2 WHERE Category = 1)
ORDER BY cM.MapNr


UPDATE M2
SET RowNr = M3.RowNr
,   ColNr= M3.ColNr
,   Category = 0
FROM ##MirrorLines2 M2
INNER JOIN ##MirrorLines3 M3 ON M2.MapNr = M3.MapNr
WHERE M2.MapNr IN (SELECT MapNr FROM ##MirrorLines3 GROUP BY MapNr HAVING COUNT(1) = 1)

DELETE FROM ##MirrorLines3 WHERE MapNr IN (SELECT MapNr FROM ##MirrorLines3 GROUP BY MapNr HAVING COUNT(1) = 1)

ALTER TABLE ##MirrorLines3 ADD ID INT IDENTITY(1,1)

--DECLARE @Level INT
SET @Level = 1

WHILE (SELECT COUNT(1) FROM (SELECT MapNr, RowNr, ColNr FROM ##MirrorLines3 GROUP BY MapNr, RowNr, ColNr) S) > (SELECT COUNT(1) FROM ##MirrorLines2 WHERE Category = 1)
BEGIN

--DECLARE @Level INT = 2

    UPDATE ##MirrorLines3
    SET ColNr = NULL
    WHERE ID IN (
        SELECT ML.ID
        FROM ##MirrorLines3 ML
        INNER JOIN ##Maps M1 ON ML.MapNr = M1.MapNr
        INNER JOIN ##Maps M2 ON ML.MapNr = M2.MapNr AND ML.ColNr = M1.ColNr + @Level AND ML.ColNr = M2.ColNr - 1 - @Level AND M1.RowNr = M2.RowNr AND M1.Val = M2.Val
        WHERE ML.ColNr IS NOT NULL
        GROUP BY ML.ID, ML.RowSize
        HAVING COUNT(1) < ML.RowSize 
    )


    UPDATE ##MirrorLines3
    SET RowNr = NULL
    WHERE ID IN (
        SELECT ML.ID
        FROM ##MirrorLines3 ML
        INNER JOIN ##Maps M1 ON ML.MapNr = M1.MapNr
        INNER JOIN ##Maps M2 ON ML.MapNr = M2.MapNr AND ML.RowNr = M1.RowNr + @Level AND ML.RowNr = M2.RowNr - 1 - @Level AND M1.ColNr = M2.ColNr AND M1.Val = M2.Val
        WHERE ML.RowNr IS NOT NULL
        GROUP BY ML.ID, ML.ColSize
        HAVING COUNT(1) < ML.ColSize
    )

    DELETE FROM ##MirrorLines3
    WHERE RowNr IS NULL AND ColNr IS NULL

    PRINT @Level
    SET @Level = @Level + 1
        
END

UPDATE M2
SET RowNr = M3.RowNr
,   ColNr= M3.ColNr
,   Category = 0
FROM ##MirrorLines2 M2
INNER JOIN ##MirrorLines3 M3 ON M2.MapNr = M3.MapNr
WHERE M2.MapNr IN (SELECT MapNr FROM ##MirrorLines3 GROUP BY MapNr)


--DECLARE @Level INT = 2
SET @Level = 3

    UPDATE ##MirrorLines2
    SET ColNr = NULL
    WHERE ID IN (
        SELECT ML.ID
        FROM ##MirrorLines2 ML
        INNER JOIN ##Maps M1 ON ML.MapNr = M1.MapNr
        INNER JOIN ##Maps M2 ON ML.MapNr = M2.MapNr AND ML.ColNr = M1.ColNr + @Level AND ML.ColNr = M2.ColNr - 1 - @Level AND M1.RowNr = M2.RowNr AND M1.Val = M2.Val
        WHERE ML.ColNr IS NOT NULL AND ML.Category <> 0
        GROUP BY ML.ID, ML.RowSize
        HAVING COUNT(1) < ML.RowSize - 1
    )


    UPDATE ##MirrorLines2
    SET RowNr = NULL
    WHERE ID IN (
        SELECT ML.ID
        FROM ##MirrorLines2 ML
        INNER JOIN ##Maps M1 ON ML.MapNr = M1.MapNr
        INNER JOIN ##Maps M2 ON ML.MapNr = M2.MapNr AND ML.RowNr = M1.RowNr + @Level AND ML.RowNr = M2.RowNr - 1 - @Level AND M1.ColNr = M2.ColNr AND M1.Val = M2.Val
        WHERE ML.RowNr IS NOT NULL AND ML.Category <> 0
        GROUP BY ML.ID, ML.ColSize
        HAVING COUNT(1) < ML.ColSize - 1
    )

    DELETE FROM ##MirrorLines2
    WHERE RowNr IS NULL AND ColNr IS NULL

    PRINT @Level
    SET @Level = @Level + 1

    
SELECT * FROM ##MirrorLines2 WHERE Category <>0
-- 
DELETE FROM ##MirrorLines2 WHERE ID IN (15, 26, 36, 39)


SELECT SUM(ISNULL(RowNr+1,0)*100 + ISNULL(ColNr+1,0))
FROM ##MirrorLines2

-- 30385 is too high

/*

DROP TABLE ##Maps
DROP TABLE ##MirrorLines
DROP TABLE ##MirrorLines2
DROP TABLE ##MirrorLines3

*/