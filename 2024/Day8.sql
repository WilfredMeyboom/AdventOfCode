USE Test_WME

SET NOCOUNT ON

DECLARE @year VARCHAR(4) = '2024'
DECLARE @day VARCHAR(2)  = '8'

EXEC dbo.GetInput @year = @year, @day = @day
EXEC dbo.ParseInput @year = @year, @day = @day 

--SELECT TOP 10 * FROM ##Input
--SELECT TOP 10 * FROM ##InputInts
--SELECT TOP 10 * FROM ##InputNumbered
--SELECT TOP 10 * FROM ##InputGrid
--SELECT TOP 10 * FROM ##InputSplit
--SELECT TOP 10 * FROM ##InputSplitCust

;WITH cte_AntiNodes AS (
    SELECT I2.RowNr + (I2.RowNr - I1.RowNr) AS NewRowNr, I2.ColNr + (I2.ColNr - I1.ColNr) AS NewColNr
    FROM ##InputGrid I1
    INNER JOIN ##InputGrid I2 ON I1.Val COLLATE SQL_Latin1_General_CP1_CS_AS = I2.Val COLLATE SQL_Latin1_General_CP1_CS_AS AND I1.Ind <> I2.Ind
    WHERE I1.Val <> '.'
)
SELECT COUNT(DISTINCT CONCAT(cA.NewColNr, '|', cA.NewRowNr)) AS Part1
FROM cte_AntiNodes cA
LEFT JOIN ##InputGrid IG ON cA.NewColNr = IG.ColNr AND cA.NewRowNr = IG.RowNr
WHERE IG.Ind IS NOT NULL


--SELECT MIN(RowNR), MAX(RowNr), MIN(ColNr), MAX(ColNr) FROM ##InputGrid

;WITH cte_AntiNodes AS (
    SELECT I2.RowNr + Fac.tor * (I2.RowNr - I1.RowNr) AS NewRowNr, I2.ColNr + Fac.tor * (I2.ColNr - I1.ColNr) AS NewColNr
    FROM ##InputGrid I1
    INNER JOIN ##InputGrid I2 ON I1.Val COLLATE SQL_Latin1_General_CP1_CS_AS = I2.Val COLLATE SQL_Latin1_General_CP1_CS_AS AND I1.Ind <> I2.Ind
    CROSS APPLY (SELECT TOP 51 ROW_NUMBER() OVER (ORDER BY (SELECT 0)) - 1 AS tor FROM sys.messages) Fac
    WHERE I1.Val <> '.'
)
SELECT COUNT(DISTINCT CONCAT(cA.NewColNr, '|', cA.NewRowNr)) AS Part1
FROM cte_AntiNodes cA
LEFT JOIN ##InputGrid IG ON cA.NewColNr = IG.ColNr AND cA.NewRowNr = IG.RowNr
WHERE IG.Ind IS NOT NULL

--1042 is too low
