USE Test_WME

DECLARE @year VARCHAR(4) = '2021'
DECLARE @day VARCHAR(2)  = '3'

EXEC dbo.GetInput @year = @year, @day = @day
EXEC dbo.ParseInput @year = @year, @day = @day 

SELECT TOP 10 * FROM ##InputNumbered
SELECT TOP 10 * FROM ##InputGrid
SELECT TOP 10 * FROM ##InputInts
SELECT TOP 10 * FROM ##InputSplit

;WITH cte_Count AS (
    SELECT ColNr, Val, COUNT(1) AS Cnt 
    FROM ##InputGrid 
    GROUP BY ColNr, Val
), cte_Value AS (
    SELECT DISTINCT CAST(c1.ColNr AS INT) AS ColNr
    ,      CAST(CASE WHEN c1.Cnt > c2.Cnt THEN c1.Val ELSE c2.Val END AS INT) AS Gamma
    ,      CAST(CASE WHEN c1.Cnt < c2.Cnt THEN c1.Val ELSE c2.Val END AS INT) AS Epsilon
    FROM cte_Count c1
    INNER JOIN cte_Count c2 ON c1.ColNr = c2.ColNr AND c1.Val <> c2.Val
), cte_BinValues AS (
    SELECT 'Gamma' AS Rate, CONCAT([0], [1], [2], [3], [4], [5], [6], [7], [8], [9], [10], [11]) AS BinValue
    FROM (
        SELECT ColNr, Gamma FROM cte_Value
        ) AS cV
    PIVOT
    (
        SUM(Gamma)
        FOR ColNr IN ([0], [1], [2], [3], [4], [5], [6], [7], [8], [9], [10], [11])
    ) AS PivotTable1
    UNION
    SELECT 'Epsilon', CONCAT([0], [1], [2], [3], [4], [5], [6], [7], [8], [9], [10], [11])
    FROM (
        SELECT ColNr, Epsilon FROM cte_Value
        ) AS cV
    PIVOT
    (
        SUM(Epsilon)
        FOR ColNr IN ([0], [1], [2], [3], [4], [5], [6], [7], [8], [9], [10], [11])
    ) AS PivotTable2
)
SELECT cVB1.Rate, cVB1.BinValue, dbo.Binary2Decimal(cVB1.BinValue),
       cVB2.Rate, cVB2.BinValue, dbo.Binary2Decimal(cVB2.BinValue),
       dbo.Binary2Decimal(cVB1.BinValue) * dbo.Binary2Decimal(cVB2.BinValue) AS Part1
FROM cte_BinValues cVB1
INNER JOIN cte_BinValues cVB2 ON cVB1.Rate = 'Gamma' AND cVB2.Rate = 'Epsilon'

-- 4103154 is correct for Part1


SELECT *
INTO ##Oxygen
FROM ##Input

SELECT *
INTO ##CO2
FROM ##Input


DECLARE @Index INT = 1
DECLARE @Continu BIT = 1
DECLARE @NextBit INT = 0

WHILE @Continu = 1
BEGIN

    ;WITH cte_Cnt AS (
        SELECT SUBSTRING(Line, @Index, 1) AS Val, COUNT(1) AS Amt
        FROM ##Oxygen
        GROUP BY SUBSTRING(Line, @Index, 1)
    )
    SELECT TOP 1 @NextBit = Val
    FROM cte_Cnt
    ORDER BY Amt DESC, Val DESC -- Prio to 1 if values are equal

    DELETE FROM ##Oxygen
    WHERE SUBSTRING(Line, @Index, 1) <> @NextBit

    SET @Index = @Index + 1

    IF (SELECT COUNT(1) FROM ##Oxygen) = 1 SET @Continu = 0 

END

SET @Continu = 0
SET @Index = 1
SET @Continu = 1

WHILE @Continu = 1
BEGIN

    ;WITH cte_Cnt AS (
        SELECT SUBSTRING(Line, @Index, 1) AS Val, COUNT(1) AS Amt
        FROM ##CO2
        GROUP BY SUBSTRING(Line, @Index, 1)
    )
    SELECT TOP 1 @NextBit = Val
    FROM cte_Cnt
    ORDER BY Amt ASC, Val ASC -- Prio to 1 if values are equal

    DELETE FROM ##CO2
    WHERE SUBSTRING(Line, @Index, 1) <> @NextBit

    SET @Index = @Index + 1

    IF (SELECT COUNT(1) FROM ##CO2) = 1 SET @Continu = 0 

END

SELECT O.Line, dbo.Binary2Decimal(CAST(O.Line AS CHAR(12))) AS OxygenDec, 
       C.Line, dbo.Binary2Decimal(CAST(C.Line AS CHAR(12))) AS CO2Dec, 
       dbo.Binary2Decimal(CAST(O.Line AS CHAR(12))) * dbo.Binary2Decimal(CAST(C.Line AS CHAR(12))) AS Part2
FROM ##Oxygen O
CROSS APPLY ##CO2 C


DROP TABLE ##Oxygen
DROP TABLE ##CO2

--SELECT * FROM ##Oxygen
--SELECT * FROM ##CO2

-- 4245351 is correct for part 2
