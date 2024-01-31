USE Test_WME

SET NOCOUNT ON

DECLARE @year VARCHAR(4) = '2023'
DECLARE @day VARCHAR(2)  = '23'

EXEC dbo.GetInput @year = @year, @day = @day
EXEC dbo.ParseInput @year = @year, @day = @day 

--SELECT TOP 10 * FROM ##Input
--SELECT TOP 10 * FROM ##InputInts
--SELECT TOP 10 * FROM ##InputNumbered
--
--SELECT TOP 10 * FROM ##InputSplit
--SELECT TOP 10 * FROM ##InputSplitCust
  
DELETE FROM ##InputGrid WHERE Val = '#'

UPDATE ##InputGrid SET Val = 'v' WHERE RowNr = 0 AND Val = '.'

UPDATE IG
SET Val = 'v'
FROM ##InputGrid IG
WHERE Val = '.' AND RowNr = (SELECT MAX(RowNr) AS MaxRowNr FROM ##InputGrid)

CREATE UNIQUE INDEX IX_InputGrid_UQ ON ##InputGrid (RowNr, ColNr)

CREATE TABLE ##Nodes (ID INT IDENTITY(1,1), NodeNr INT, RowNr INT, ColNr INT, Val CHAR)

INSERT ##Nodes
(
    NodeNr,
    RowNr,
    ColNr,
    Val
)
SELECT ROW_NUMBER() OVER (ORDER BY RowNr, ColNr), RowNr, ColNr, Val FROM ##InputGrid WHERE Val NOT IN ('.','#')

CREATE TABLE ##Edges (ID INT IDENTITY(1,1), FromNodeID INT, ToNodeID INT, Dist INT, StartDir CHAR, EndDir CHAR)

CREATE TABLE ##TempRoutes (ID INT IDENTITY(1,1), StartNode INT, StartDir CHAR, CurrentRow INT, CurrentCol INT, Dist INT, Dir CHAR)

;WITH cte_Dirs AS (
    SELECT 'v' AS Chr, 'N' AS Dir UNION
    SELECT 'v' AS Chr, 'S' AS Dir UNION
    SELECT '^' AS Chr, 'N' AS Dir UNION
    SELECT '^' AS Chr, 'S' AS Dir UNION
    SELECT '<' AS Chr, 'W' AS Dir UNION
    SELECT '<' AS Chr, 'E' AS Dir UNION
    SELECT '>' AS Chr, 'W' AS Dir UNION
    SELECT '>' AS Chr, 'E' AS Dir 
)
INSERT ##TempRoutes(StartNode, StartDir, CurrentRow, CurrentCol, Dist, Dir)
SELECT ID, Dir, N.RowNr, N.ColNr, 0, c.Dir
FROM ##Nodes N
INNER JOIN cte_Dirs c ON N.Val = c.Chr

DECLARE @Count INT = 1

WHILE @Count > 0
BEGIN

    UPDATE TR
    SET TR.CurrentRow = IG.RowNr
    ,   TR.CurrentCol = IG.ColNr
    ,   TR.Dist = Dist + 1
    ,   TR.Dir =  CASE WHEN TR.CurrentRow = IG.RowNr + 1 THEN 'N'
                       WHEN TR.CurrentRow = IG.RowNr - 1 THEN 'S'
                       WHEN TR.CurrentCol = IG.ColNr + 1 THEN 'W'
                       WHEN TR.CurrentCol = IG.ColNr - 1 THEN 'E'
                  END
    FROM ##TempRoutes TR
    INNER JOIN ##InputGrid IG ON (TR.CurrentRow = IG.RowNr + 1 AND TR.CurrentCol = IG.ColNr AND Dir <> 'S')
                              OR (TR.CurrentRow = IG.RowNr - 1 AND TR.CurrentCol = IG.ColNr AND Dir <> 'N')
                              OR (TR.CurrentRow = IG.RowNr AND TR.CurrentCol = IG.ColNr + 1 AND Dir <> 'E')
                              OR (TR.CurrentRow = IG.RowNr AND TR.CurrentCol = IG.ColNr - 1 AND Dir <> 'W')
    WHERE IG.Val = '.'

    SET @Count = @@ROWCOUNT
    
END

INSERT ##Edges
(
    FromNodeID,
    ToNodeID,
    Dist,v
    StartDir,
    EndDir
)
SELECT StartNode AS FromNodeID
,      n.ID AS ToNodeID
,      Dist + 1
,      StartDir
,      CASE WHEN TR.CurrentRow = IG.RowNr + 1 THEN 'N'
            WHEN TR.CurrentRow = IG.RowNr - 1 THEN 'S'
            WHEN TR.CurrentCol = IG.ColNr + 1 THEN 'W'
            WHEN TR.CurrentCol = IG.ColNr - 1 THEN 'E'
       END
FROM ##TempRoutes TR
INNER JOIN ##InputGrid IG ON (TR.CurrentRow = IG.RowNr + 1 AND TR.CurrentCol = IG.ColNr AND Dir <> 'S')
                          OR (TR.CurrentRow = IG.RowNr - 1 AND TR.CurrentCol = IG.ColNr AND Dir <> 'N')
                          OR (TR.CurrentRow = IG.RowNr AND TR.CurrentCol = IG.ColNr + 1 AND Dir <> 'E')
                          OR (TR.CurrentRow = IG.RowNr AND TR.CurrentCol = IG.ColNr - 1 AND Dir <> 'W')
INNER JOIN ##Nodes N ON N.RowNr = IG.RowNr AND N.ColNr = IG.ColNr

;WITH cte_Routes AS (
    SELECT ToNodeID AS CurrentNodeID
    ,      EndDir AS CurrentDir
    ,      Dist
    ,      CAST(CAST(E.FromNodeID AS VARCHAR(3)) + '|' + CAST(E.ToNodeID AS VARCHAR(3)) + '|' AS VARCHAR(MAX)) AS Hist
    FROM ##Edges E
    INNER JOIN ##Nodes N ON N.ID = E.FromNodeID
    WHERE N.RowNr = 0

    UNION ALL

    SELECT E.ToNodeID
    ,      E.EndDir
    ,      c.Dist + E.Dist
    ,      CAST(c.Hist + CAST(E.ToNodeID AS VARCHAR(3)) + '|' AS VARCHAR(MAX))
    FROM cte_Routes c
    INNER JOIN ##Edges E ON c.CurrentNodeID = E.FromNodeID AND c.CurrentDir = E.StartDir
    WHERE Hist NOT LIKE '%' + CAST(E.ToNodeID AS VARCHAR(3)) + '%'
)
SELECT * 
FROM cte_Routes c
INNER JOIN ##Nodes N ON c.CurrentNodeID = N.ID
WHERE N.RowNr = (SELECT MAX(RowNr) AS MaxRowNr FROM ##InputGrid) 
ORDER BY Dist DESC


--6298 too low
--6302 is correct

/*

DROP TABLE ##TempRoutes
DROP TABLE ##Nodes
DROP TABLE ##Edges

*/