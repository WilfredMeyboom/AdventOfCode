
--use Test_WME

--CREATE TABLE #Input (Name NVARCHAR(MAX));

--BULK INSERT #Input
--FROM 'D:\Wilfred\AdventOfCode\2017\input7.txt'
--WITH (ROWTERMINATOR = '0x0A');

--SELECT * FROM #Input

CREATE TABLE #NamesHierarchy (ID INT IDENTITY(1,1), BottomName NVARCHAR(20), TopName NVARCHAR(20), BottomWeight INT)

;WITH cte_TopTowers AS (
    SELECT LTRIM(RTRIM(SUBSTRING(Name, 1, CHARINDEX(' ',Name)))) AS BottomName
    ,      SUBSTRING(Name, CHARINDEX('(',Name) + 1, CHARINDEX(')',Name) - CHARINDEX('(',Name) - 1) AS BottomWeight
    ,      '' AS Remainder
    FROM #Input
    WHERE CHARINDEX('>', Name) = 0
), cte_Towers AS (
SELECT LTRIM(RTRIM(SUBSTRING(Name, 1, CHARINDEX(' ',Name)))) AS BottomName
,      LTRIM(RTRIM(SUBSTRING(Name, CHARINDEX('(',Name) + 1, CHARINDEX(')',Name) - CHARINDEX('(',Name) - 1))) AS BottomWeight
,      LTRIM(RTRIM(SUBSTRING(Name, CHARINDEX('>', Name) + 1, CHARINDEX(',', Name) - CHARINDEX('>', Name) - 1))) AS TopName

,      SUBSTRING(Name, CHARINDEX(',', Name) + 1, LEN(Name)) + ',' AS Remainder

FROM #Input
WHERE CHARINDEX('>', Name) > 0 
UNION ALL
SELECT BottomName
,      BottomWeight
,      LTRIM(RTRIM(SUBSTRING(Remainder, 1, CHARINDEX(',', Remainder) - 1) ))
,      SUBSTRING(Remainder, CHARINDEX(',', Remainder) + 1, LEN(Remainder))
FROM cte_Towers
WHERE LEN(Remainder) > 0
)
INSERT #NamesHierarchy (BottomName , TopName , BottomWeight)
SELECT BottomName, TopName, BottomWeight --, Remainder
FROM cte_Towers T1
UNION
SELECT BottomName, NULL, BottomWeight
FROM cte_TopTowers
--WHERE BottomName = 'ahxil' OR BottomName = 'vuoipf'



SELECT DISTINCT T2.BottomName, T2.TopName, T1.BottomName, T1.TopName
FROM #NamesHierarchy  T1
LEFT JOIN #NamesHierarchy  T2 ON T1.BottomName = T2.TopName




CREATE TABLE #Weights (ID INT IDENTITY(1,1), NodeName VARCHAR(10), TotalWeight INT)

INSERT #Weights (NodeName)
SELECT DISTINCT BottomName FROM #NamesHierarchy

UPDATE W
SET TotalWeight = BottomWeight
FROM #Weights W
INNER JOIN #NamesHierarchy NH ON W.NodeName = NH.BottomName AND NH.TopName IS NULL



DECLARE @RowCount INT = 1

WHILE (@RowCount > 0)
BEGIN

    ;WITH cte_NotAvailable_Nodes AS (
        SELECT NodeName
        FROM #Weights
        WHERE TotalWeight IS NOT NULL
        UNION
        SELECT W.NodeName
        FROM #Weights W
        INNER JOIN #NamesHierarchy NH ON W.NodeName = NH.BottomName
        INNER JOIN #Weights WT ON NH.TopName = WT.NodeName
        WHERE W.TotalWeight IS NULL AND WT.TotalWeight IS NULL

    ), cte_Available_Nodes AS (
        SELECT W.NodeName
        FROM #Weights W
        EXCEPT
        SELECT cNN.NodeName
        FROM cte_NotAvailable_Nodes cNN
    ), cte_Weights AS (
        SELECT W.ID, NH.BottomWeight + SUM(WT.TotalWeight) AS Weight
        FROM #Weights W
        INNER JOIN cte_Available_Nodes cAN ON W.NodeName = cAN.NodeName
        INNER JOIN #NamesHierarchy NH ON W.NodeName = NH.BottomName
        INNER JOIN #Weights WT ON NH.TopName = WT.NodeName
        GROUP BY W.ID, NH.BottomWeight
    )
    UPDATE W
    SET TotalWeight = Weight
    FROM #Weights W
    INNER JOIN cte_Weights cW ON W.ID = cW.ID

    SET @RowCount = @@ROWCOUNT

END

;WITH cte_1 AS (
SELECT NH.BottomName
,      W.TotalWeight
FROM #NamesHierarchy NH
INNER JOIN #Weights W ON NH.TopName = W.NodeName
GROUP BY NH.BottomName, W.TotalWeight
)
SELECT BottomName
FROM cte_1 AS C1
GROUP BY BottomName
HAVING COUNT(1) > 1

SELECT *
FROM #NamesHierarchy NH
WHERE BottomName IN ('fbtzaic','gejdtfw','gmcrj')
ORDER BY BottomName

SELECT * FROM #Weights WHERE NodeName IN ('dqwfuzn','mdbtyw','nzkxl')

SELECT * FROM #NamesHierarchy WHERE BottomName = 'mdbtyw' --396; should be 5 less -> 391

UPDATE #NamesHierarchy 
SET BottomWeight = 391
WHERE BottomName = 'mdbtyw' 

--DROP TABLE #Weights
--DROP TABLE #NamesHierarchy
--DROP TABLE #Input