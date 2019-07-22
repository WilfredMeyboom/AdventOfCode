use Test_WME

CREATE TABLE Input (Nr NVARCHAR(MAX));

BULK INSERT Input
FROM 'D:\temp\AdventOfCode\input3.txt'
WITH (ROWTERMINATOR = '0x0A');

CREATE TABLE #Areas (AreaId INT, x INT, y INT, width INT, height INT, xw INT, yh INT, OriginalText NVARCHAR(100))

INSERT INTO #Areas 
SELECT 
  CAST(REPLACE(SUBSTRING(Nr, 0, CHARINDEX('@', Nr)), '#','') AS INT) AS AreaId
, CAST(SUBSTRING(Nr, CHARINDEX('@', Nr) + 1, CHARINDEX(',', Nr) - CHARINDEX('@', Nr) - 1) AS INT) AS x
, CAST(SUBSTRING(Nr, CHARINDEX(',', Nr) + 1, CHARINDEX(':', Nr) - CHARINDEX(',', Nr) - 1) AS INT) AS y
, CAST(SUBSTRING(Nr, CHARINDEX(':', Nr) + 1, CHARINDEX('x', Nr) - CHARINDEX(':', Nr) - 1) AS INT) AS width
, CAST(SUBSTRING(Nr, CHARINDEX('x', Nr) + 1, LEN(Nr) - CHARINDEX('x', Nr)) AS INT) AS height

, CAST(SUBSTRING(Nr, CHARINDEX('@', Nr) + 1, CHARINDEX(',', Nr) - CHARINDEX('@', Nr) - 1) AS INT) +
  CAST(SUBSTRING(Nr, CHARINDEX(':', Nr) + 1, CHARINDEX('x', Nr) - CHARINDEX(':', Nr) - 1) AS INT) AS xw
, CAST(SUBSTRING(Nr, CHARINDEX(',', Nr) + 1, CHARINDEX(':', Nr) - CHARINDEX(',', Nr) - 1) AS INT) +
  CAST(SUBSTRING(Nr, CHARINDEX('x', Nr) + 1, LEN(Nr) - CHARINDEX('x', Nr)) AS INT) AS yh

, Nr AS OriginalText
FROM Input



--SELECT MAX(xw) FROM #Areas
--SELECT MAX(yh) FROM #Areas

SELECT * FROM #Areas

ALTER TABLE #Areas ADD Rect GEOMETRY

UPDATE #Areas 
SET Rect = GEOMETRY::STPolyFromText(
           'POLYGON((' + CAST( x AS VARCHAR(5)) + ' ' + CAST( y AS VARCHAR(5)) + ', ' + 
                         CAST(xw AS VARCHAR(5)) + ' ' + CAST( y AS VARCHAR(5)) + ', ' + 
                         CAST(xw AS VARCHAR(5)) + ' ' + CAST(yh AS VARCHAR(5)) + ', ' + 
                         CAST( x AS VARCHAR(5)) + ' ' + CAST(yh AS VARCHAR(5)) + ', ' + 
                         CAST( x AS VARCHAR(5)) + ' ' + CAST( y AS VARCHAR(5)) + '))'
                          ,0)


DECLARE @StartingFabric GEOMETRY = GEOMETRY::STPolyFromText('POLYGON((0 0,0 1000, 1000 1000, 1000 0, 0 0))',0)
DECLARE @Overlap GEOMETRY

DECLARE ReductionCursor CURSOR FOR
SELECT A1.Rect.STIntersection(A2.Rect) AS OverlappingArea
FROM #Areas A1
INNER JOIN #Areas A2 ON A1.AreaId <> A2.AreaId
WHERE A1.Rect.STIntersects(A2.Rect) = 1

OPEN ReductionCursor

FETCH NEXT FROM ReductionCursor INTO @Overlap

WHILE @@FETCH_STATUS = 0
BEGIN

    SELECT @StartingFabric = @StartingFabric.STDifference(@Overlap)

    FETCH NEXT FROM ReductionCursor INTO @Overlap
END

SELECT @StartingFabric.STArea() --898804

SELECT 1000*1000-898804
--101196

SELECT AreaId
FROM #Areas
EXCEPT
SELECT A1.AreaId
FROM #Areas A1
INNER JOIN #Areas A2 ON A1.AreaId <> A2.AreaId
WHERE A1.Rect.STIntersects(A2.Rect) = 1

--DROP TABLE #Areas
--DROP TABLE Input


