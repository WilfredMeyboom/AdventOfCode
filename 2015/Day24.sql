USE Test_WME

CREATE TABLE ##Packages (ID INT IDENTITY(1,1), Weight INT)

INSERT ##Packages (Weight) VALUES (1), (3), (5), (11), (13), (17), (19), (23), (29), (31), (37), (41), (43), (47), (53), (59), (67), (71), (73), (79), (83), (89), (97), (101), (103), (107), (109), (113)

DECLARE @TargetWeigth INT 
SELECT @TargetWeigth = SUM(Weight)/3 FROM ##Packages

PRINT @TargetWeigth

;WITH cte_Load AS (
    SELECT Weight
    ,      CAST(CAST(Weight AS VARCHAR(3)) + '|' AS VARCHAR(MAX)) WeightsUsed
    ,      Weight AS LastWeightUsed
    ,      1 AS NrOfWeightsUsed
    ,      CAST(Weight AS DECIMAL(38,0)) AS QuantumEntangelement
    FROM ##Packages
    UNION ALL
    SELECT cL.Weight + P.Weight
    ,      CAST(cL.WeightsUsed + CAST(P.Weight AS VARCHAR(3)) + '|' AS VARCHAR(MAX))
    ,      P.Weight
    ,      cL.NrOfWeightsUsed + 1
    ,      CAST(cL.QuantumEntangelement * CAST(P.Weight AS DECIMAL(38,0)) AS DECIMAL(38,0))
    FROM cte_Load cL
    INNER JOIN ##Packages P ON cL.LastWeightUsed > P.Weight
    WHERE cL.Weight + P.Weight <= @TargetWeigth
)
SELECT TOP 1 QuantumEntangelement AS Part1
FROM cte_Load
WHERE Weight = @TargetWeigth
ORDER BY QuantumEntangelement



SELECT @TargetWeigth = SUM(Weight)/4 FROM ##Packages

;WITH cte_Load AS (
    SELECT Weight
    ,      CAST(CAST(Weight AS VARCHAR(3)) + '|' AS VARCHAR(MAX)) WeightsUsed
    ,      Weight AS LastWeightUsed
    ,      1 AS NrOfWeightsUsed
    ,      CAST(Weight AS DECIMAL(38,0)) AS QuantumEntangelement
    FROM ##Packages
    UNION ALL
    SELECT cL.Weight + P.Weight
    ,      CAST(cL.WeightsUsed + CAST(P.Weight AS VARCHAR(3)) + '|' AS VARCHAR(MAX))
    ,      P.Weight
    ,      cL.NrOfWeightsUsed + 1
    ,      CAST(cL.QuantumEntangelement * CAST(P.Weight AS DECIMAL(38,0)) AS DECIMAL(38,0))
    FROM cte_Load cL
    INNER JOIN ##Packages P ON cL.LastWeightUsed > P.Weight
    WHERE cL.Weight + P.Weight <= @TargetWeigth
)
SELECT TOP 1 QuantumEntangelement AS Part2
FROM cte_Load
WHERE Weight = @TargetWeigth
ORDER BY QuantumEntangelement


-- Runtime 00:09:00

DROP TABLE ##Packages 



