use Test_WME

SET NOCOUNT ON

CREATE TABLE ##Input23 (Name NVARCHAR(MAX));

BULK INSERT ##Input23
FROM 'D:\Wilfred\AdventOfCode\input23.txt'
WITH (ROWTERMINATOR = '0x0A');

CREATE TABLE ##Nanobots (ID INT IDENTITY(1,1), X BIGINT, Y BIGINT, Z BIGINT, R BIGINT)

;WITH cte_YZ AS (
    SELECT Name
    ,      SUBSTRING(Name, CHARINDEX(',', Name) + 1, CHARINDEX('r', Name) - CHARINDEX(',', Name) - 4) AS YZ
    ,      SUBSTRING(Name, CHARINDEX('r', Name), LEN(Name)) AS R
    FROM ##Input23
)
INSERT ##Nanobots (X, Y, Z, R)
SELECT SUBSTRING(Name, CHARINDEX('<', Name) + 1, CHARINDEX(',', Name) - CHARINDEX('<', Name) - 1) AS X
,      LEFT(YZ, CHARINDEX(',', YZ) - 1) AS Y
,      SUBSTRING(YZ, CHARINDEX(',', YZ) + 1, LEN(YZ)) AS Z
,      REPLACE(R, 'r=', '') AS R
FROM cte_YZ



SELECT * FROM ##Nanobots ORDER BY R DESC

SELECT N.ID, COUNT(1) AS InRangeBots
FROM ##Nanobots N
INNER JOIN ##Nanobots N2 ON ABS(N.X - N2.X) + ABS (N.Y - N2.Y) + ABS(N.Z - N2.Z) <= N.R
WHERE N.ID = 92
GROUP BY N.ID

SELECT MAX(X) - MIN(X), MAX(Y) - MIN(Y), MAX(Z) - MIN(Z) FROM ##Nanobots

SELECT N.ID, COUNT(1) AS InRangeBots
FROM ##Nanobots N
INNER JOIN ##Nanobots N2 ON ABS(N.X - N2.X) + ABS (N.Y - N2.Y) + ABS(N.Z - N2.Z) <= N.R
GROUP BY N.ID
ORDER BY 2

SELECT *, ABS(N.X - N2.X) + ABS (N.Y - N2.Y) + ABS(N.Z - N2.Z) - N.R
FROM ##Nanobots N
INNER JOIN ##Nanobots N2 ON ABS(N.X - N2.X) + ABS (N.Y - N2.Y) + ABS(N.Z - N2.Z) < N.R
WHERE N.ID = 543
ORDER BY 11

/*


DROP TABLE ##Input23



*/
--277.726.382	212.195.888	335.899.160

SELECT MAX(X) - MIN(X), MAX(Y) - MIN(Y), MAX(Z) - MIN(Z) 
FROM ##Nanobots
WHERE ID NOT IN (
    SELECT N.ID
    FROM ##Nanobots N
    INNER JOIN ##Nanobots N2 ON ABS(N.X - N2.X) + ABS (N.Y - N2.Y) + ABS(N.Z - N2.Z) <= N.R
    GROUP BY N.ID
    HAVING COUNT(1) = 1 -- Altijd in range van zichzelf
)


----------------------------------------------------------------270.567.838	178.303.720	200.708.950


CREATE TABLE Grid (ID INT IDENTITY(1,1), X BIGINT, Y BIGINT, Z BIGINT)

CREATE UNIQUE INDEX Ind_Grid ON Grid (X,Y,Z)

TRUNCATE TABLE Grid

DECLARE @StepSize BIGINT = 1
DECLARE @MinX BIGINT
DECLARE @MinY BIGINT
DECLARE @MinZ BIGINT
DECLARE @MaxX BIGINT
DECLARE @MaxY BIGINT
DECLARE @MaxZ BIGINT

--SELECT @MaxX = MAX(X), @MinX = MIN(X), @MaxY = MAX(Y), @MinY = MIN(Y), @MaxZ = MAX(Z), @MinZ = MIN(Z) FROM ##Nanobots
--WHERE ID NOT IN (
--    SELECT N.ID
--    FROM ##Nanobots N
--    INNER JOIN ##Nanobots N2 ON ABS(N.X - N2.X) + ABS (N.Y - N2.Y) + ABS(N.Z - N2.Z) <= N.R
--    GROUP BY N.ID
--    HAVING COUNT(1) = 1 -- Altijd in range van zichzelf
--)


SET @MaxX = 24690000
SET @MaxY = 26720001
SET @MaxZ = 19480001
SET @MinX = 24680000
SET @MinY = 26720000
SET @MinZ = 19480000



    SELECT TOP ((@MaxX - @MinX)/@StepSize)
        @MinX / @StepSize + ROW_NUMBER() OVER (ORDER BY (SELECT 0)) AS X
    FROM sys.messages

    SELECT TOP ((@MaxY - @MinY)/@StepSize)
        @MinY / @StepSize + ROW_NUMBER() OVER (ORDER BY (SELECT 0)) AS Y
    FROM sys.messages

    SELECT TOP ((@MaxZ - @MinZ)/@StepSize)
        @MinZ / @StepSize + ROW_NUMBER() OVER (ORDER BY (SELECT 0)) AS Z
    FROM sys.messages


;WITH cte_X AS (
    SELECT TOP ((@MaxX - @MinX)/@StepSize)
        @MinX / @StepSize + ROW_NUMBER() OVER (ORDER BY (SELECT 0)) AS X
    FROM sys.messages
), cte_Y AS (
    SELECT TOP ((@MaxY - @MinY)/@StepSize)
        @MinY / @StepSize + ROW_NUMBER() OVER (ORDER BY (SELECT 0)) AS Y
    FROM sys.messages
), cte_Z AS (
    SELECT TOP ((@MaxZ - @MinZ)/@StepSize)
        @MinZ / @StepSize + ROW_NUMBER() OVER (ORDER BY (SELECT 0)) AS Z
    FROM sys.messages
)
INSERT Grid (X, Y, Z)
SELECT X*@StepSize AS X, Y*@StepSize AS Y, Z*@StepSize AS Z
FROM cte_X
CROSS APPLY cte_Y
CROSS APPLY cte_Z




SELECT TOP (1000000) G.X, G.Y, G.Z, COUNT(1) AS NrOfNanoInRange, G.X+G.Y+G.Z AS ManhattanDist
FROM Grid G
INNER JOIN ##Nanobots N ON ABS(N.X - G.X) + ABS (N.Y - G.Y) + ABS(N.Z - G.Z) <= N.R
GROUP BY G.X, G.Y, G.Z
HAVING COUNT(1) = 873
ORDER BY 5 
--9:47

/*

INSERT Grid (X,Y,Z) VALUES (24700000,26700000,19500000)
INSERT Grid (X,Y,Z) VALUES (24800000,26600000,19500000)
INSERT Grid (X,Y,Z) VALUES (25700000,27500000,17700000)

24700000	26700000	19500000	873
24800000	26600000	19500000	873
25700000	27500000	17700000	873


Eerste gok 70887804 too low --> Dit is vreemd, de enige conclusie die ik hieruit kan trekken is dat er een hoger aantal nanobots mogelijk is dan 873
*/



/*

Wat je kan doen maar waar je nog geen antwoord in ziet:

Je kan elk coordinaat + range van een nanobot converteren naar een kubus op zijn punt aan de hand van 6 hoekpunten.
Volgens mij staan al deze kubussen op een punt, oftewel gedraaid over 45° over alle drie de assen

Je kan die draaiing voor alle hoekpunten ongedaan maken. Dit zijn de conversie matrixen:

1	       0	              0
0	       cos theta	    sin theta
0	       -sin theta	    cos theta
		
cos theta	  0	             -sin theta
0	       1	             0
sin theta	  0	             cos theta
		
cos theta	  sin theta	   0
-sin theta  cos theta	   0
0	       0	             1

Volgens mij kan je dan (relatief makkelijk) de overlappende inhoud tussen twee kubussen bepalen
Theoretisch zou je dit ook moeten kunnen met de ongeroteerde kubussen

Maar hoe kom je dan tot een oplossing

- Neem de maximale ruimte
- Haal hier alle ruimte af die door 2 kubussen gebruikt worden
- Neem de inverse

Dan heb je dus alle ruimte die minimaal door 2 kubussen gebruikt wordt

*/