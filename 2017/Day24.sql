USE Test_WME

SET NOCOUNT ON

CREATE TABLE ##Input (Line NVARCHAR(MAX));

BULK INSERT ##Input
FROM 'D:\Wilfred\AdventOfCode\2017\input24.txt'
WITH (ROWTERMINATOR = '0x0A');


CREATE TABLE ##Pieces (ID INT IDENTITY(1,1), LeftSide INT, RightSide INT)

INSERT ##Pieces (LeftSide, RightSide)
SELECT LEFT(Line, CHARINDEX('/', Line) - 1)
,      SUBSTRING(Line, CHARINDEX('/', Line) + 1, LEN(Line))
FROM ##Input


CREATE TABLE ##Bridges (ID INT IDENTITY(1,1), Bridge VARCHAR(MAX), Strength INT)

;WITH cte_Bridges AS (
    SELECT RightSide 
    ,      CAST((CAST(ID AS VARCHAR(3)) + '|') AS VARCHAR(MAX)) AS Bridge
    ,      LeftSide + RightSide AS Strength
    FROM ##Pieces 
    WHERE LeftSide = 0
    UNION ALL
    SELECT CASE WHEN B.RightSide = P.LeftSide THEN P.RightSide
                                              ELSE P.LeftSide
                                              END AS RightSide
    ,      CAST((Bridge + CAST(ID AS VARCHAR(3)) + '|') AS VARCHAR(MAX)) AS Bridge
    ,      Strength + P.LeftSide + P.RightSide AS Strength
    FROM cte_Bridges B
    INNER JOIN ##Pieces P ON (B.RightSide = P.LeftSide OR B.RightSide = P.RightSide)
                         AND B.Bridge NOT LIKE '%|' + CAST(P.ID AS VARCHAR(2))+ '|%'
                         AND P.LeftSide <> 0
)
INSERT ##Bridges (Bridge, Strength)
SELECT Bridge, Strength FROM cte_Bridges

SELECT TOP(1) * FROM ##Bridges ORDER BY Strength DESC

-- 2006 is correct :) 
/*

DROP TABLE ##Bridges
DROP TABLE ##Pieces
DROP TABLE ##Input


*/


SELECT MAX(LEN(Bridge)) FROM ##Bridges
SELECT * FROM ##Bridges WHERE LEN(Bridge) = 98 ORDER BY Strength DESC

--1994 is correct :)