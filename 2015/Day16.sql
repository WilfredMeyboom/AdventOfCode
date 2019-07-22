use Test_WME

SET NOCOUNT ON

CREATE TABLE ##Input (Line NVARCHAR(MAX));

BULK INSERT ##Input
FROM 'D:\Wilfred\AdventOfCode\2015\input16.txt'
WITH (ROWTERMINATOR = '0x0A');

--SELECT * FROM ##Input

CREATE TABLE ##AuntProperties (ID INT IDENTITY(1,1), SueNr INT, Prop VARCHAR(20), Value INT)

;WITH cte_Scrubbed AS (
    SELECT REPLACE(LEFT(Line, CHARINDEX(':', Line) -1), 'Sue ', '') AS SueNr
    ,      SUBSTRING(Line,  CHARINDEX(':', Line) + 1, LEN(Line)) AS Remainder
    FROM ##Input 
), cte_Split AS (
    SELECT SueNr
    ,      LEFT(Remainder, CHARINDEX(',', Remainder) - 1) AS Prop
    FROM cte_Scrubbed
    UNION ALL
    SELECT SueNr
    ,      LEFT(SUBSTRING(Remainder, CHARINDEX(',', Remainder) + 1, LEN(Remainder)), CHARINDEX(',', SUBSTRING(Remainder, CHARINDEX(',', Remainder) + 1, LEN(Remainder))) - 1) AS Prop
    FROM cte_Scrubbed
    UNION ALL
    SELECT SueNr
    ,      SUBSTRING(SUBSTRING(Remainder, CHARINDEX(',', Remainder) + 1, LEN(Remainder)), CHARINDEX(',', SUBSTRING(Remainder, CHARINDEX(',', Remainder) + 1, LEN(Remainder))) + 1, LEN(Remainder)) AS Prop2
    FROM cte_Scrubbed
)
INSERT ##AuntProperties (SueNr, Prop, Value)
SELECT CAST(SueNr AS INT) AS SueNr
,      LTRIM(RTRIM(LEFT(Prop, CHARINDEX(':', Prop) - 1))) AS Prop
,      CAST(SUBSTRING(Prop, CHARINDEX(':', Prop) + 1, LEN(Prop)) AS INT) AS Value
FROM cte_Split
ORDER BY SueNr


SELECT * FROM ##AuntProperties

/*

children: 3
cats: 7
samoyeds: 2
pomeranians: 3
akitas: 0
vizslas: 0
goldfish: 5
trees: 3
cars: 2
perfumes: 1

*/

CREATE TABLE ##KnownProps (ID INT IDENTITY(1,1), Prop VARCHAR(20), Value INT)

INSERT ##KnownProps (Prop, Value) VALUES
('children', 3),
('cats', 7),
('samoyeds', 2),
('pomeranians', 3),
('akitas', 0),
('vizslas', 0),
('goldfish', 5),
('trees', 3),
('cars', 2),
('perfumes', 1)



SELECT DISTINCT SueNr
FROM ##AuntProperties AP
EXCEPT
SELECT DISTINCT SueNr
FROM ##AuntProperties AP
INNER JOIN ##KnownProps KP ON AP.Prop = KP.Prop
WHERE AP.Value <> KP.Value


SELECT * FROM ##AuntProperties WHERE SueNr = 373

--373 is correct for part 1

SELECT DISTINCT SueNr
FROM ##AuntProperties AP

EXCEPT

SELECT DISTINCT SueNr
FROM ##AuntProperties AP
INNER JOIN ##KnownProps KP ON AP.Prop = KP.Prop
WHERE AP.Prop IN ('cats', 'trees') AND AP.Value < KP.Value

EXCEPT

SELECT DISTINCT SueNr
FROM ##AuntProperties AP
INNER JOIN ##KnownProps KP ON AP.Prop = KP.Prop
WHERE AP.Prop IN ('pomeranians', 'goldfish') AND AP.Value > KP.Value

EXCEPT

SELECT DISTINCT SueNr
FROM ##AuntProperties AP
INNER JOIN ##KnownProps KP ON AP.Prop = KP.Prop
WHERE AP.Prop NOT IN ('cats', 'trees', 'pomeranians', 'goldfish') AND AP.Value <> KP.Value

--260 is correct for part 2

/*
the cats and trees readings indicates that there are greater than that many 
the pomeranians and goldfish readings indicate that there are fewer than that many 
*/


/* 

DROP TABLE ##Input

*/

