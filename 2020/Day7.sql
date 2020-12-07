use Test_WME

SET NOCOUNT ON

CREATE TABLE ##Input (Line NVARCHAR(MAX));

BULK INSERT ##Input
FROM 'C:\Source\AdventOfCode\2020\input7.txt'
WITH (ROWTERMINATOR = '0x0A');

;WITH cte_Stripped AS (
    SELECT REPLACE(REPLACE(REPLACE(Line, 'bags', ''), 'bag', ''), '.','') LineStripped FROM ##Input
), cte_Bags AS (
    SELECT TRIM(LEFT(LineStripped, CHARINDEX('contain', LineStripped) - 2)) AS OuterBag
    ,      TRIM(SUBSTRING(LineStripped, CHARINDEX('contain', LineStripped) + 8, LEN(LineStripped))) AS InnerBags
    FROM cte_Stripped
), cte_PerBag AS (
    SELECT OuterBag
    ,      TRIM(CASE WHEN InnerBags LIKE '%,%' THEN LEFT(InnerBags, CHARINDEX(',', InnerBags) - 1) ELSE InnerBags END) AS InnerBag
    ,      TRIM(CASE WHEN InnerBags LIKE '%,%' THEN SUBSTRING(InnerBags, CHARINDEX(',', InnerBags) + 1, LEN(InnerBags)) ELSE '' END) AS Rest
    FROM cte_Bags

    UNION ALL

    SELECT OuterBag
    ,      TRIM(CASE WHEN Rest LIKE '%,%' THEN LEFT(Rest, CHARINDEX(',', Rest) - 1) ELSE Rest END) AS InnerBag
    ,      TRIM(CASE WHEN Rest LIKE '%,%' THEN SUBSTRING(Rest, CHARINDEX(',', Rest) + 1, LEN(Rest)) ELSE '' END) AS Rest
    FROM cte_PerBag
    WHERE LEN(Rest) > 0
)
SELECT OuterBag
,      CASE WHEN LEFT(InnerBag, CHARINDEX(' ', InnerBag)) = 'no' THEN 0 ELSE CAST(LEFT(InnerBag, CHARINDEX(' ', InnerBag)) AS INT) END AS InnerBagAmount
,      TRIM(SUBSTRING(InnerBag, CHARINDEX(' ', InnerBag), LEN(InnerBag))) AS InnerBag
--, *
INTO ##BagSituation
FROM cte_PerBag
ORDER BY OuterBag


;WITH cte_BagsInBags AS (
    SELECT InnerBag AS StartBag
    ,      OuterBag
    ,      InnerBag + '|' + OuterBag AS BagPath
    ,      1 AS Lvl
    FROM ##BagSituation
    WHERE InnerBag = 'shiny gold'

    UNION ALL

    SELECT T1.StartBag
    ,      T2.OuterBag
    ,      T1.BagPath + '|' + T2.OuterBag
    ,      Lvl + 1
    FROM cte_BagsInBags T1
    INNER JOIN ##BagSituation T2 ON T1.OuterBag = T2.InnerBag
)
SELECT DISTINCT OuterBag
FROM cte_BagsInBags

--SELECT * FROM ##BagSituation WHERE InnerBag LIKE '%shiny gold%'

-- 25 is incorrect for part 1
-- 1449 is too high for part 1
-- 268 is correct for part 1

;WITH cte_BagsInBags2 AS (
    SELECT OuterBag
    ,      InnerBag
    ,      1 AS Lvl
    ,      InnerBagAmount
    ,      OuterBag + '|' + InnerBag AS BagPath
    FROM ##BagSituation
    WHERE OuterBag = 'shiny gold'

    UNION ALL

    SELECT T1.OuterBag
    ,      T2.InnerBag
    ,      Lvl + 1
    ,      CASE WHEN T2.InnerBagAmount <> 0 THEN T1.InnerBagAmount * T2.InnerBagAmount ELSE T1.InnerBagAmount END
    ,      BagPath + '|' + T2.InnerBag
    FROM cte_BagsInBags2 T1
    INNER JOIN ##BagSituation T2 ON T1.InnerBag = T2.OuterBag
    WHERE T2.InnerBagAmount <> 0
)
SELECT SUM(InnerBagAmount)
--*
FROM cte_BagsInBags2

--20858 is too high for part 2
-- 6587 is too low for part 2
-- 7867 is correct for part 2

/*
DROP TABLE ##BagSituation
DROP TABLE ##Input
*/

