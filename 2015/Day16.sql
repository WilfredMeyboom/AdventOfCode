USE Test_WME

SET NOCOUNT ON

DECLARE @year VARCHAR(4) = '2015'
DECLARE @day VARCHAR(2)  = '16'

EXEC dbo.GetInput @year = @year, @day = @day
EXEC dbo.ParseInput @year = @year, @day = @day

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


/*
--The relevant aunt

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


-- Get a list of all aunts that have a property that doesn't match with the expectation
;WITH cte_AuntProps AS (
    SELECT DISTINCT SueNr
    FROM ##AuntProperties AP
    INNER JOIN ##KnownProps KP ON AP.Prop = KP.Prop
    WHERE AP.Value <> KP.Value
)
SELECT DISTINCT AP.SueNr AS Part1
FROM ##AuntProperties AP
LEFT JOIN cte_AuntProps c ON AP.SueNr = c.SueNr
WHERE c.SueNr IS NULL

--Same difference, we just needed to extend the WHERE in the cte a bit
;WITH cte_AuntProps AS (
    SELECT DISTINCT SueNr
    FROM ##AuntProperties AP
    INNER JOIN ##KnownProps KP ON AP.Prop = KP.Prop
    WHERE (AP.Prop IN ('cats', 'trees') AND AP.Value <= KP.Value)
       OR (AP.Prop IN ('pomeranians', 'goldfish') AND AP.Value >= KP.Value)
       OR (AP.Prop NOT IN ('cats', 'trees', 'pomeranians', 'goldfish') AND AP.Value <> KP.Value)

)
SELECT DISTINCT AP.SueNr AS Part2
FROM ##AuntProperties AP
LEFT JOIN cte_AuntProps c ON AP.SueNr = c.SueNr
WHERE c.SueNr IS NULL

DROP TABLE ##AuntProperties
DROP TABLE ##KnownProps