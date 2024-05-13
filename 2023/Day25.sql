USE Test_WME

SET NOCOUNT ON

DECLARE @year VARCHAR(4) = '2023'
DECLARE @day VARCHAR(2)  = '25'

EXEC dbo.GetInput @year = @year, @day = @day
EXEC dbo.ParseInput @year = @year, @day = @day 

--SELECT TOP 10 * FROM ##Input
--SELECT TOP 10 * FROM ##InputInts
--SELECT TOP 10 * FROM ##InputNumbered
--SELECT TOP 10 * FROM ##InputGrid
--SELECT TOP 10 * FROM ##InputSplitCust

CREATE TABLE ##Edges (ID INT IDENTITY(1,1), Node1 CHAR(3), Node2 CHAR(3))
CREATE TABLE ##Nodes (ID INT IDENTITY(1,1), NodeName CHAR(3), IsInGroup INT)

INSERT ##Edges
(
    Node1,
    Node2
)
SELECT I1.Piece, I2.Piece
FROM ##InputSplit I1
INNER JOIN ##InputSplit I2 ON I1.RowNr = I2.RowNr AND I1.PieceNr < I2.PieceNr
WHERE I1.PieceNr = 1
GROUP BY I1.Piece, I2.Piece 

INSERT ##Edges
(
    Node1,
    Node2
)
SELECT Node2, Node1 FROM ##Edges E

INSERT ##Nodes
(
    NodeName,
    IsInGroup
)
SELECT DISTINCT Node1, 0 FROM ##Edges E

UPDATE N
SET N.IsInGroup = 1
FROM ##Nodes N
--WHERE N.ID = (SELECT MIN(ID) AS ID FROM ##Nodes)
WHERE N.ID = (SELECT MAX(ID) AS ID FROM ##Nodes)

DECLARE @Count INT = 4
DECLARE @NodeToAbsorb CHAR(3)

WHILE @Count > 3
BEGIN

    SELECT TOP 1 @NodeToAbsorb = N2.NodeName, @Count = COUNT(1)
    FROM ##Nodes N
    INNER JOIN ##Edges E ON N.NodeName = E.Node1
    INNER JOIN ##Nodes N2 ON N2.NodeName = E.Node2 AND N2.IsInGroup = 0
    WHERE N.IsInGroup = 1
    GROUP BY N2.NodeName
    ORDER BY 2 DESC

    UPDATE ##Nodes
    SET IsInGroup = 1
    WHERE NodeName = @NodeToAbsorb

    SELECT @Count =  COUNT(1)
    FROM ##Nodes N
    INNER JOIN ##Edges E ON N.NodeName = E.Node1
    INNER JOIN ##Nodes N2 ON N2.NodeName = E.Node2 AND N2.IsInGroup = 0
    WHERE N.IsInGroup = 1

END

;WITH cte_Size AS (
    SELECT N.IsInGroup, COUNT(1) AS Size
    FROM ##Nodes N
    GROUP BY N.IsInGroup
)
SELECT TOP 1 c1.Size * c2.Size AS Part1
FROM cte_Size c1
INNER JOIN cte_Size c2 ON c2.IsInGroup <> c1.IsInGroup

/*

DROP TABLE ##Edges
DROP TABLE ##Nodes

*/