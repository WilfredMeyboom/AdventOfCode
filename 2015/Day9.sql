USE Test_WME

SET NOCOUNT ON

DECLARE @year VARCHAR(4) = '2015'
DECLARE @day VARCHAR(2)  = '9'

EXEC dbo.GetInput @year = @year, @day = @day
EXEC dbo.ParseInput @year = @year, @day = @day 


CREATE TABLE ##Distances (ID INT IDENTITY(1,1), FromA VARCHAR(15), ToB VARCHAR(15), Dist INT)

INSERT ##Distances (FromA, ToB, Dist)
SELECT LEFT(Line, CHARINDEX(' ', Line))
,      SUBSTRING(Line, CHARINDEX(' to ', Line) + 4, CHARINDEX(' = ', Line) - CHARINDEX(' to ', Line) - 4)
,      CAST(SUBSTRING(Line, CHARINDEX(' = ', Line) + 3, LEN(Line) - CHARINDEX(' = ', Line)) AS INT)
FROM ##Input
UNION
SELECT SUBSTRING(Line, CHARINDEX(' to ', Line) + 4, CHARINDEX(' = ', Line) - CHARINDEX(' to ', Line) - 4)
,      LEFT(Line, CHARINDEX(' ', Line))
,      CAST(SUBSTRING(Line, CHARINDEX(' = ', Line) + 3, LEN(Line) - CHARINDEX(' = ', Line)) AS INT)
FROM ##Input


CREATE TABLE ##Routes (ID INT IDENTITY(1,1), Loc1 VARCHAR(15), Loc2 VARCHAR(15), Loc3 VARCHAR(15), Loc4 VARCHAR(15), Loc5 VARCHAR(15), Loc6 VARCHAR(15), Loc7 VARCHAR(15), Loc8 VARCHAR(15), TotalDist INT)

SELECT 
--       L1.FromA
--,      L2.FromA
--,      L3.FromA
--,      L4.FromA
--,      L5.FromA
--,      L6.FromA
--,      L7.FromA
--,      L7.ToB
      MIN(L1.Dist + L2.Dist + L3.Dist + L4.Dist + L5.Dist + L6.Dist + L7.Dist) AS Part1
,     MAX(L1.Dist + L2.Dist + L3.Dist + L4.Dist + L5.Dist + L6.Dist + L7.Dist) AS Part2
FROM ##Distances L1
INNER JOIN ##Distances L2 ON L1.ToB = L2.FromA AND L1.FromA <> L2.ToB
INNER JOIN ##Distances L3 ON L2.ToB = L3.FromA AND L1.FromA <> L3.ToB AND L2.FromA <> L3.ToB
INNER JOIN ##Distances L4 ON L3.ToB = L4.FromA AND L1.FromA <> L4.ToB AND L2.FromA <> L4.ToB AND L3.FromA <> L4.ToB
INNER JOIN ##Distances L5 ON L4.ToB = L5.FromA AND L1.FromA <> L5.ToB AND L2.FromA <> L5.ToB AND L3.FromA <> L5.ToB AND L4.FromA <> L5.ToB
INNER JOIN ##Distances L6 ON L5.ToB = L6.FromA AND L1.FromA <> L6.ToB AND L2.FromA <> L6.ToB AND L3.FromA <> L6.ToB AND L4.FromA <> L6.ToB AND L5.FromA <> L6.ToB
INNER JOIN ##Distances L7 ON L6.ToB = L7.FromA AND L1.FromA <> L7.ToB AND L2.FromA <> L7.ToB AND L3.FromA <> L7.ToB AND L4.FromA <> L7.ToB AND L5.FromA <> L7.ToB AND L6.FromA <> L7.ToB



--141 is correct for part 1


DROP TABLE ##Distances
DROP TABLE ##Routes



