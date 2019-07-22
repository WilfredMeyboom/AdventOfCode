use Test_WME

SET NOCOUNT ON

CREATE TABLE ##Input (Line NVARCHAR(MAX));

BULK INSERT ##Input
FROM 'D:\Wilfred\AdventOfCode\2016\input22.txt'
WITH (ROWTERMINATOR = '0x0A');

DELETE TOP(2) FROM ##Input

CREATE TABLE ##Grid (ID INT IDENTITY(1,1), X INT, Y INT, Size INT, Used INT)

;WITH cte_Grid AS (
    SELECT LEFT(REPLACE(Line, '/dev/grid/node-x',''), CHARINDEX('-y', REPLACE(Line, '/dev/grid/node-x','')) - 1) AS X
    ,      SUBSTRING(REPLACE(Line, '/dev/grid/node-x',''), CHARINDEX('-y', REPLACE(Line, '/dev/grid/node-x','')) + 2, CHARINDEX(' ', REPLACE(Line, '/dev/grid/node-x','')) - CHARINDEX('-y', REPLACE(Line, '/dev/grid/node-x',''))) AS Y
    ,      SUBSTRING(REPLACE(Line, '/dev/grid/node-x',''), CHARINDEX(' ', REPLACE(Line, '/dev/grid/node-x','')), CHARINDEX('T', REPLACE(Line, '/dev/grid/node-x','')) - CHARINDEX(' ', REPLACE(Line, '/dev/grid/node-x',''))) AS Size
    ,      REPLACE(SUBSTRING(REPLACE(Line, '/dev/grid/node-x',''), CHARINDEX('T', REPLACE(Line, '/dev/grid/node-x','')) + 1, 6), 'T', '') AS Available
    FROM ##Input
)
INSERT ##Grid (X, Y, Size, Used)
SELECT CAST(X AS INT)
,      CAST(Y AS INT)
,      CAST(Size AS INT)
,      CAST(Available AS INT)
FROM cte_Grid


SELECT X, Y FROM ##Grid WHERE NOT (X = 27 AND Y = 14)
EXCEPT
SELECT G1.X, G1.Y--, *
-- COUNT(1) 
FROM ##Grid G1
INNER JOIN ##Grid G2 ON G1.ID <> G2.ID AND G1.Used < G2.Size - G2.Used
                    --AND G1.Y = G2.Y AND ABS(G1.X - G2.X) = 1
WHERE G1.Used > 0

--763016 Too high for part 1
--1734 Too high for part 1
--860 is correct for part 1


/*
For Part II
Random thoughts:

Van de 875 velden zijn er 860 die naar 1 andere kunnen.
Of te wel, het is niet mogelijk om data bij elkaar te kiepen
Er is 1 leeg veld waar je mee kan werken
Er zijn 14 velden die muurvast zitten
Dit zijn:
X    Y
21	11
22	11
23	11
24	11
25	11
26	11
27	11
28	11
29	11
30	11
31	11
32	11
33	11
34	11

En het lege veld ligt op 27, 14 dus een beetje schuin onder deze muur

A) Dus het lege veld moet naar 20,11
B) Dan naar 33,0
C) En dan kunnen 0,34 er omheen gaan cyclen

A) 10 stappen 
B) 24 stappen
C) Elke stap naar links van de target data kost 5 stappen
Dus van 34 naar 1 kost 33*5 = 165
En dan nog 1 stap om naar 0,0 te komen

SELECT 10 + 24 + 33*5 + 1

218 is too high
200 is correct for part 2

*/


/*

DROP TABLE ##Grid
DROP TABLE ##Input

*/


