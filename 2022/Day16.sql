USE Test_WME

DECLARE @year VARCHAR(4) = '2022'
DECLARE @day VARCHAR(2)  = '16'

EXEC dbo.GetInput @year = @year, @day = @day
EXEC dbo.ParseInput @year = @year, @day = @day, @SplitCustom = ', =;' 

--SELECT TOP 10 * FROM ##Input
--SELECT TOP 10 * FROM ##InputInts
--SELECT TOP 1000 * FROM ##InputNumbered
--SELECT TOP 10 * FROM ##InputGrid
--SELECT TOP 10 * FROM ##InputSplit
--SELECT TOP 100 * FROM ##InputSplitCust
  
CREATE TABLE ##InputData (ID INT IDENTITY(1,1), RowNr INT, Valve VARCHAR(2), FlowRate INT, ToValve1 VARCHAR(2), ToValve2 VARCHAR(2), ToValve3 VARCHAR(2), ToValve4 VARCHAR(2), ToValve5 VARCHAR(2))

INSERT ##InputData
(
    RowNr,
    Valve,
    FlowRate,
    ToValve1,
    ToValve2,
    ToValve3,
    ToValve4,
    ToValve5
)
SELECT * FROM (
    SELECT RowNr, PieceNr, Piece FROM ##InputSplitCust WHERE PieceNr IN (2,6,11,12,13,14,15)
) T
PIVOT (
    MAX(Piece) FOR PieceNr IN ([2],[6],[11],[12],[13],[14],[15])
) T

--SELECT * FROM ##InputData ID WHERE ID.FlowRate > 0 ORDER BY ID.FlowRate DESC

CREATE TABLE ##WeighedGraph (ID INT IDENTITY(1,1), StartValve VARCHAR(2), EndValve VARCHAR(2), StartFlowRate INT, EndFlowRate INT, ShortestDistance INT)

;WITH cte_Path AS (
    SELECT ID.Valve AS StartValve
    ,      ID.Valve AS EndValve
    ,      ID.FlowRate AS StartFlowRate
    ,      0 AS EndFlowRate
    ,      0 AS Dist
    ,      CAST(ID.Valve + '|' AS VARCHAR(MAX)) AS ValvePath
    FROM ##InputData ID
    WHERE valve = 'AA' OR ID.FlowRate > 0

    UNION ALL

    SELECT c.StartValve
    ,      ID.Valve
    ,      c.StartFlowRate
    ,      ID.FlowRate
    ,      c.Dist + 1
    ,      CAST(c.ValvePath + ID.Valve + '|' AS VARCHAR(MAX))
    FROM cte_Path c
    INNER JOIN ##InputData ID ON ID.ToValve1 = c.EndValve OR ID.ToValve2 = c.EndValve OR ID.ToValve3 = c.EndValve OR ID.ToValve4 = c.EndValve OR ID.ToValve5 = c.EndValve
    WHERE c.ValvePath NOT LIKE '%' + ID.Valve + '%'
)
INSERT ##WeighedGraph
(
    StartValve,
    EndValve,
    StartFlowRate,
    EndFlowRate,
    ShortestDistance
)
SELECT c.StartValve, c.EndValve, c.StartFlowRate, c.EndFlowRate, MIN(Dist) AS ShortestDistance
FROM cte_Path c
WHERE c.Dist > 0 AND c.EndFlowRate > 0
GROUP BY c.StartValve,
         c.EndValve,
         c.StartFlowRate,
         c.EndFlowRate
ORDER BY c.StartValve, c.EndValve


CREATE TABLE ##OnePersonResults (ID INT IDENTITY(1,1), TimeElapsed INT, CurrentFlow INT, PressureReleased INT, ValvePath VARCHAR(MAX), TotalPressureReleased INT)

;WITH cte_Flow AS (
    SELECT DISTINCT WG.StartValve AS CurrentValve
    ,      0 AS TimeElapsed
    ,      0 AS CurrentFlow
    ,      0 AS PressureReleased
    ,      CAST(WG.StartValve + '|' AS VARCHAR(MAX)) AS ValvePath
    FROM ##WeighedGraph WG
    WHERE WG.StartValve = 'AA'

    UNION ALL

    SELECT WG.EndValve
    ,      c.TimeElapsed + WG.ShortestDistance + 1 -- 1 minute for opening the valve
    ,      c.CurrentFlow + WG.EndFlowRate 
    ,      c.PressureReleased + c.CurrentFlow * (WG.ShortestDistance + 1) -- 1 minute for opening the valve
    ,      CAST(c.ValvePath + WG.EndValve + '|' AS VARCHAR(MAX))
    FROM cte_Flow c
    INNER JOIN ##WeighedGraph WG ON c.CurrentValve = WG.StartValve
    WHERE c.TimeElapsed + WG.ShortestDistance + 1 <= 30 AND c.ValvePath NOT LIKE '%' + WG.EndValve + '%'
)
INSERT ##OnePersonResults
(
    TimeElapsed,
    CurrentFlow,
    PressureReleased,
    ValvePath,
    TotalPressureReleased
)
SELECT c.TimeElapsed, c.CurrentFlow, c.PressureReleased, c.ValvePath, c.PressureReleased + (30 - c.TimeElapsed) * c.CurrentFlow
FROM cte_Flow c

SELECT TOP 1 TotalPressureReleased AS Part1 FROM ##OnePersonResults OPR ORDER BY OPR.TotalPressureReleased DESC

;WITH cte_PerValve AS (
    SELECT ID, OPR.TimeElapsed, OPR.CurrentFlow, OPR.PressureReleased
    ,      CASE WHEN OPR.ValvePath LIKE '%CN%' THEN 1 ELSE 0 END CN
    ,      CASE WHEN OPR.ValvePath LIKE '%DT%' THEN 1 ELSE 0 END DT
    ,      CASE WHEN OPR.ValvePath LIKE '%GG%' THEN 1 ELSE 0 END GG
    ,      CASE WHEN OPR.ValvePath LIKE '%HR%' THEN 1 ELSE 0 END HR
    ,      CASE WHEN OPR.ValvePath LIKE '%JQ%' THEN 1 ELSE 0 END JQ
    ,      CASE WHEN OPR.ValvePath LIKE '%KV%' THEN 1 ELSE 0 END KV
    ,      CASE WHEN OPR.ValvePath LIKE '%LI%' THEN 1 ELSE 0 END LI
    ,      CASE WHEN OPR.ValvePath LIKE '%NS%' THEN 1 ELSE 0 END NS
    ,      CASE WHEN OPR.ValvePath LIKE '%QF%' THEN 1 ELSE 0 END QF
    ,      CASE WHEN OPR.ValvePath LIKE '%RI%' THEN 1 ELSE 0 END RI
    ,      CASE WHEN OPR.ValvePath LIKE '%RP%' THEN 1 ELSE 0 END RP
    ,      CASE WHEN OPR.ValvePath LIKE '%SU%' THEN 1 ELSE 0 END SU
    ,      CASE WHEN OPR.ValvePath LIKE '%UH%' THEN 1 ELSE 0 END UH
    ,      CASE WHEN OPR.ValvePath LIKE '%VT%' THEN 1 ELSE 0 END VT
    ,      CASE WHEN OPR.ValvePath LIKE '%YA%' THEN 1 ELSE 0 END YA
    FROM ##OnePersonResults OPR
    WHERE TimeElapsed < 27 AND CurrentFlow >= 197-115
)
SELECT TOP (1) V1.PressureReleased + (26 - V1.TimeElapsed) * V1.CurrentFlow + V2.PressureReleased + (26 - V2.TimeElapsed) * V2.CurrentFlow AS Part2
FROM cte_PerValve V1
INNER JOIN cte_PerValve V2 ON V1.CN + V2.CN < 2
                          AND V1.DT + V2.DT < 2
                          AND V1.GG + V2.GG < 2
                          AND V1.HR + V2.HR < 2
                          AND V1.JQ + V2.JQ < 2
                          AND V1.KV + V2.KV < 2
                          AND V1.LI + V2.LI < 2
                          AND V1.NS + V2.NS < 2
                          AND V1.QF + V2.QF < 2
                          AND V1.RI + V2.RI < 2
                          AND V1.RP + V2.RP < 2
                          AND V1.SU + V2.SU < 2
                          AND V1.UH + V2.UH < 2
                          AND V1.VT + V2.VT < 2
                          AND V1.YA + V2.YA < 2
ORDER BY 1 DESC

-- 2223 is correct for part2

DROP TABLE ##InputData
DROP TABLE ##WeighedGraph
DROP TABLE ##OnePersonResults

