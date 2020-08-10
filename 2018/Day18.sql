use Test_WME

SET NOCOUNT ON

CREATE TABLE ##Input (Name NVARCHAR(MAX));

BULK INSERT ##Input
--FROM 'C:\Source\AdventOfCode\2018\input18_example.txt'
FROM 'C:\Source\AdventOfCode\2018\input18.txt'
WITH (ROWTERMINATOR = '0x0A');

--SELECT * FROM ##Input

--Lumber Collection Area
CREATE TABLE ##LCA (ID INT IDENTITY(1,1), X INT, Y INT, LCASpace CHAR(1))

;WITH cte_LCA AS (
    SELECT LEFT(Name, 1) AS LCASpace
    ,      SUBSTRING(Name, 2, LEN(Name)) AS Remainder
    ,      ROW_NUMBER() OVER (ORDER BY (SELECT 0)) - 1 AS Y
    ,      0 AS X
    FROM ##Input
    UNION ALL
    SELECT LEFT(Remainder, 1)
    ,      SUBSTRING(Remainder, 2, LEN(Remainder))
    ,      Y
    ,      X + 1
    FROM cte_LCA
    WHERE LEN(Remainder) > 0
)
INSERT ##LCA (X, Y, LCASpace)
SELECT X 
,      Y
,      LCASpace
FROM cte_LCA
--OPTION (MAXRECURSION 25000)

CREATE TABLE ##ResourceValues (ID INT IDENTITY(1,1), Minuut INT, ResValue BIGINT)

ALTER TABLE ##LCA ADD CONSTRAINT UQ_XY UNIQUE (X,Y)

--SELECT * FROM ##LCA

DECLARE @Minute INT = 0

WHILE @Minute < 10000
BEGIN
    ;WITH cte_AreaPerSpace AS (
        SELECT LM.X
        ,      LM.Y
        ,      LM.LCASpace
        ,      CASE WHEN LU.LCASpace = '.' THEN 1 ELSE 0 END + CASE WHEN LL.LCASpace = '.' THEN 1 ELSE 0 END + 
               CASE WHEN LD.LCASpace = '.' THEN 1 ELSE 0 END + CASE WHEN LR.LCASpace = '.' THEN 1 ELSE 0 END +
               CASE WHEN LUL.LCASpace = '.' THEN 1 ELSE 0 END + CASE WHEN LUR.LCASpace = '.' THEN 1 ELSE 0 END + 
               CASE WHEN LDL.LCASpace = '.' THEN 1 ELSE 0 END + CASE WHEN LDR.LCASpace = '.' THEN 1 ELSE 0 END 
                AS nrOfOpenSpaces
        ,      CASE WHEN LU.LCASpace = '|' THEN 1 ELSE 0 END + CASE WHEN LL.LCASpace = '|' THEN 1 ELSE 0 END + 
               CASE WHEN LD.LCASpace = '|' THEN 1 ELSE 0 END + CASE WHEN LR.LCASpace = '|' THEN 1 ELSE 0 END +
               CASE WHEN LUL.LCASpace = '|' THEN 1 ELSE 0 END + CASE WHEN LUR.LCASpace = '|' THEN 1 ELSE 0 END + 
               CASE WHEN LDL.LCASpace = '|' THEN 1 ELSE 0 END + CASE WHEN LDR.LCASpace = '|' THEN 1 ELSE 0 END
                AS nrOfTreeSpaces
        ,      CASE WHEN LU.LCASpace = '#' THEN 1 ELSE 0 END + CASE WHEN LL.LCASpace = '#' THEN 1 ELSE 0 END + 
               CASE WHEN LD.LCASpace = '#' THEN 1 ELSE 0 END + CASE WHEN LR.LCASpace = '#' THEN 1 ELSE 0 END +
               CASE WHEN LUL.LCASpace = '#' THEN 1 ELSE 0 END + CASE WHEN LUR.LCASpace = '#' THEN 1 ELSE 0 END + 
               CASE WHEN LDL.LCASpace = '#' THEN 1 ELSE 0 END + CASE WHEN LDR.LCASpace = '#' THEN 1 ELSE 0 END
                AS nrOfYardSpaces
        FROM ##LCA LM
            LEFT JOIN ##LCA LU ON LM.X = LU.X AND LM.Y = LU.Y + 1
            LEFT JOIN ##LCA LD ON LM.X = LD.X AND LM.Y = LD.Y - 1
            LEFT JOIN ##LCA LL ON LM.X = LL.X + 1 AND LM.Y = LL.Y
            LEFT JOIN ##LCA LR ON LM.X = LR.X - 1 AND LM.Y = LR.Y
            LEFT JOIN ##LCA LUL ON LM.X = LUL.X + 1 AND LM.Y = LUL.Y + 1
            LEFT JOIN ##LCA LUR ON LM.X = LUR.X - 1 AND LM.Y = LUR.Y + 1
            LEFT JOIN ##LCA LDL ON LM.X = LDL.X + 1 AND LM.Y = LDL.Y - 1
            LEFT JOIN ##LCA LDR ON LM.X = LDR.X - 1 AND LM.Y = LDR.Y - 1
    )
    UPDATE L
    SET L.LCASpace = CASE WHEN L.LCASpace = '.' AND cA.nrOfTreeSpaces >= 3 THEN '|'
                          WHEN L.LCASpace = '|' AND cA.nrOfYardSpaces >= 3 THEN '#'
                          WHEN L.LCASpace = '#' AND cA.nrOfYardSpaces >= 1 AND cA.nrOfTreeSpaces >= 1 THEN '#'
                          WHEN L.LCASpace = '#' AND (cA.nrOfYardSpaces = 0 OR cA.nrOfTreeSpaces = 0) THEN '.'
                          ELSE L.LCASpace
                          END
    FROM ##LCA L
    INNER JOIN cte_AreaPerSpace cA ON L.X = cA.X AND L.Y = cA.Y

    INSERT ##ResourceValues (Minuut, ResValue)
    SELECT @Minute
    ,      SUM(CASE WHEN LCASpace = '|' THEN 1 ELSE 0 END) * 
           SUM(CASE WHEN LCASpace = '#' THEN 1 ELSE 0 END) 
    FROM ##LCA

    SET @Minute = @Minute + 1
END

SELECT * FROM ##ResourceValues


DECLARE @X INT = 0
DECLARE @Y INT = 0
DECLARE @Str VARCHAR(50)

WHILE @Y < 50
BEGIN

    SET @X = 0
    SET @Str = ''

    WHILE @X < 50
    BEGIN
        
        SELECT @Str = @Str + LCASpace FROM ##LCA WHERE X = @X AND Y = @Y

        SET @X = @X + 1

    END

    PRINT @Str

    SET @Y = @Y + 1
END

-- 549936 is correct for part 1

SELECT TOP 500 *  
FROM ##resourcevalues RV
INNER JOIN ##resourcevalues RV2 ON RV.ResValue = RV2.ResValue AND RV.Minuut < RV2.Minuut

SELECT TOP 500 *, Minuut - LAG(Minuut, 1, 0) OVER (ORDER BY Minuut)  
FROM ##resourcevalues RV
WHERE ResValue = 209420
ORDER BY Minuut

SELECT 1000000000 % 28
--20 but the system stabilezes after minute 450

SELECT * FROM ##ResourceValues WHERE ID = (20 + 28*100)

-- 206304 is correct for part 2


/*

DROP TABLE ##Input
DROP TABLE ##LCA
DROP TABLE ##ResourceValues

*/