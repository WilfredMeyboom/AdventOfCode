USE Test_WME

SET NOCOUNT ON

DECLARE @year VARCHAR(4) = '2023'
DECLARE @day VARCHAR(2)  = '5'

EXEC dbo.GetInput @year = @year, @day = @day
EXEC dbo.ParseInput @year = @year, @day = @day 

--SELECT TOP 10 * FROM ##Input
--SELECT TOP 10 * FROM ##InputInts
--SELECT TOP 10 * FROM ##InputNumbered
--SELECT TOP 10 * FROM ##InputGrid
--SELECT TOP 10 * FROM ##InputSplit
--SELECT TOP 10 * FROM ##InputSplitCust
  
CREATE TABLE ##Seeds (ID INT IDENTITY(1,1), Seed BIGINT) 
INSERT ##Seeds (Seed) SELECT Piece FROM ##InputSplit WHERE RowNr = 1 AND PieceNr <> 1

CREATE TABLE ##Seed2Soil (ID INT IDENTITY(1,1), SeedStart BIGINT, SeedEnd BIGINT, SoilStart BIGINT, SoilEnd BIGINT)
INSERT ##Seed2Soil (SeedStart, SeedEnd, SoilStart, SoilEnd) 
SELECT [2] SeedStart, [2] + [3] - 1 AS SeedEnd, [1] SoilStart, [1] + [3] - 1 AS SoilEnd
FROM (
    SELECT RowNr, PieceNr, CAST(Piece AS BIGINT) AS Piece
    FROM ##InputSplit
    WHERE RowNr BETWEEN (SELECT RowNr+1 FROM ##InputSplit WHERE Piece = 'seed-to-soil') AND (SELECT RowNr-2 FROM ##InputSplit WHERE Piece = 'soil-to-fertilizer')
) Sub
PIVOT (
    SUM(Piece)
    FOR PieceNr IN ([1],[2],[3])
    ) pvt

CREATE TABLE ##Soil2Fertilizer (ID INT IDENTITY(1,1), SoilStart BIGINT, SoilEnd BIGINT, FertilizerStart BIGINT, FertilizerEnd BIGINT)
INSERT ##Soil2Fertilizer (SoilStart, SoilEnd, FertilizerStart, FertilizerEnd) 
SELECT [2] SoilStart, [2] + [3] - 1 AS SoilEnd, [1] FertilizerStart, [1] + [3] - 1 AS FertilizerEnd
FROM (
    SELECT RowNr, PieceNr, CAST(Piece AS BIGINT) AS Piece
    FROM ##InputSplit
    WHERE RowNr BETWEEN (SELECT RowNr+1 FROM ##InputSplit WHERE Piece = 'soil-to-fertilizer') AND (SELECT RowNr-2 FROM ##InputSplit WHERE Piece = 'fertilizer-to-water')
) Sub
PIVOT (
    SUM(Piece)
    FOR PieceNr IN ([1],[2],[3])
    ) pvt

CREATE TABLE ##Fertilizer2Water (ID INT IDENTITY(1,1), FertilizerStart BIGINT, FertilizerEnd BIGINT, WaterStart BIGINT, WaterEnd BIGINT)
INSERT ##Fertilizer2Water (FertilizerStart, FertilizerEnd, WaterStart, WaterEnd) 
SELECT [2] FertilizerStart, [2] + [3] - 1 AS FertilizerEnd, [1] WaterStart, [1] + [3] - 1 AS WaterEnd
FROM (
    SELECT RowNr, PieceNr, CAST(Piece AS BIGINT) AS Piece
    FROM ##InputSplit
    WHERE RowNr BETWEEN (SELECT RowNr+1 FROM ##InputSplit WHERE Piece = 'fertilizer-to-water') AND (SELECT RowNr-2 FROM ##InputSplit WHERE Piece = 'water-to-light')
) Sub
PIVOT (
    SUM(Piece)
    FOR PieceNr IN ([1],[2],[3])
    ) pvt

CREATE TABLE ##Water2Light (ID INT IDENTITY(1,1), WaterStart BIGINT, WaterEnd BIGINT, LightStart BIGINT, LightEnd BIGINT)
INSERT ##Water2Light (WaterStart, WaterEnd, LightStart, LightEnd) 
SELECT [2] WaterStart, [2] + [3] - 1 AS WaterEnd, [1] LightStart, [1] + [3] - 1 AS LightEnd
FROM (
    SELECT RowNr, PieceNr, CAST(Piece AS BIGINT) AS Piece
    FROM ##InputSplit
    WHERE RowNr BETWEEN (SELECT RowNr+1 FROM ##InputSplit WHERE Piece = 'water-to-light') AND (SELECT RowNr-2 FROM ##InputSplit WHERE Piece = 'light-to-temperature')
) Sub
PIVOT (
    SUM(Piece)
    FOR PieceNr IN ([1],[2],[3])
    ) pvt

CREATE TABLE ##Light2Temperature (ID INT IDENTITY(1,1), LightStart BIGINT, LightEnd BIGINT, TemperatureStart BIGINT, TemperatureEnd BIGINT)
INSERT ##Light2Temperature (LightStart, LightEnd, TemperatureStart, TemperatureEnd) 
SELECT [2] LightStart, [2] + [3] - 1 AS LightEnd, [1] TemperatureStart, [1] + [3] - 1 AS TemperatureEnd
FROM (
    SELECT RowNr, PieceNr, CAST(Piece AS BIGINT) AS Piece
    FROM ##InputSplit
    WHERE RowNr BETWEEN (SELECT RowNr+1 FROM ##InputSplit WHERE Piece = 'light-to-temperature') AND (SELECT RowNr-2 FROM ##InputSplit WHERE Piece = 'temperature-to-humidity')
) Sub
PIVOT (
    SUM(Piece)
    FOR PieceNr IN ([1],[2],[3])
    ) pvt

CREATE TABLE ##Temperature2Humidity (ID INT IDENTITY(1,1), TemperatureStart BIGINT, TemperatureEnd BIGINT, HumidityStart BIGINT, HumidityEnd BIGINT)
INSERT ##Temperature2Humidity (TemperatureStart, TemperatureEnd, HumidityStart, HumidityEnd) 
SELECT [2] TemperatureStart, [2] + [3] - 1 AS TemperatureEnd, [1] HumidityStart, [1] + [3] - 1 AS HumidityEnd
FROM (
    SELECT RowNr, PieceNr, CAST(Piece AS BIGINT) AS Piece
    FROM ##InputSplit
    WHERE RowNr BETWEEN (SELECT RowNr+1 FROM ##InputSplit WHERE Piece = 'temperature-to-humidity') AND (SELECT RowNr-2 FROM ##InputSplit WHERE Piece = 'humidity-to-location')
) Sub
PIVOT (
    SUM(Piece)
    FOR PieceNr IN ([1],[2],[3])
    ) pvt

CREATE TABLE ##Humidity2Location (ID INT IDENTITY(1,1), HumidityStart BIGINT, HumidityEnd BIGINT, LocationStart BIGINT, LocationEnd BIGINT)
INSERT ##Humidity2Location (HumidityStart, HumidityEnd, LocationStart, LocationEnd) 
SELECT [2] HumidityStart, [2] + [3] - 1 AS HumidityEnd, [1] LocationStart, [1] + [3] - 1 AS LocationEnd
FROM (
    SELECT RowNr, PieceNr, CAST(Piece AS BIGINT) AS Piece
    FROM ##InputSplit
    WHERE RowNr >= (SELECT RowNr+1 FROM ##InputSplit WHERE Piece = 'humidity-to-location')
) Sub
PIVOT (
    SUM(Piece)
    FOR PieceNr IN ([1],[2],[3])
    ) pvt


;WITH cte_Seed2Soil AS (
    SELECT Seed AS OriginalSeed, Seed, ISNULL(Seed - SeedStart + SoilStart, Seed) AS Soil
    FROM ##Seeds S
    LEFT JOIN ##Seed2Soil SS ON S.Seed BETWEEN SS.SeedStart AND SS.SeedEnd
), cte_Soil2Fertilizer AS (
    SELECT OriginalSeed, Soil, ISNULL(Soil - SoilStart + FertilizerStart, Soil) AS Fertilizer
    FROM cte_Seed2Soil cS
    LEFT JOIN ##Soil2Fertilizer SF ON cS.Soil BETWEEN SF.SoilStart AND SF.SoilEnd
), cte_Fertilizer2Water AS (
    SELECT OriginalSeed, Fertilizer, ISNULL(Fertilizer - FertilizerStart + WaterStart, Fertilizer) AS Water
    FROM cte_Soil2Fertilizer cS
    LEFT JOIN ##Fertilizer2Water FW ON cS.Fertilizer BETWEEN FW.FertilizerStart AND FW.FertilizerEnd
), cte_Water2Light AS (
    SELECT OriginalSeed, Water, ISNULL(Water - WaterStart + LightStart, Water) AS Light
    FROM cte_Fertilizer2Water cF
    LEFT JOIN ##Water2Light WL ON cF.Water BETWEEN WL.WaterStart AND WL.WaterEnd
), cte_Light2Temperature AS (
    SELECT OriginalSeed, Light, ISNULL(Light - LightStart + TemperatureStart, Light) AS Temperature
    FROM cte_Water2Light cW
    LEFT JOIN ##Light2Temperature LT ON cW.Light BETWEEN LT.LightStart AND LT.LightEnd
), cte_Temperature2Humidity AS (
    SELECT OriginalSeed, Temperature, ISNULL(Temperature - TemperatureStart + HumidityStart, Temperature) AS Humidity
    FROM cte_Light2Temperature cL
    LEFT JOIN ##Temperature2Humidity TH ON cL.Temperature BETWEEN TH.TemperatureStart AND TH.TemperatureEnd
), cte_Humidity2Location AS (
    SELECT OriginalSeed, Humidity, ISNULL(Humidity - HumidityStart + LocationStart, Humidity) AS Location
    FROM cte_Temperature2Humidity cT
    LEFT JOIN ##Humidity2Location HL ON cT.Humidity BETWEEN HL.HumidityStart AND HL.HumidityEnd
)
SELECT TOP 1 Location AS Part1
FROM cte_Humidity2Location
ORDER BY Location

--Seed -> Soil -> Fertilizer -> Water -> Light -> Temperature -> Humidity -> Location

--Seed -> Soil --------------------------------------------------------------------------------------

CREATE TABLE ##SeedRanges (ID INT IDENTITY(1,1), SeedStart BIGINT, SeedEnd BIGINT, Lvl INT) 
INSERT ##SeedRanges (SeedStart, SeedEnd, Lvl) 
SELECT S1.Seed, S1.Seed + S2.Seed - 1, 0
FROM ##Seeds S1
INNER JOIN ##Seeds S2 ON S1.ID = S2.ID - 1
WHERE S1.ID % 2 = 1
ORDER BY S1.Seed

DECLARE @Counter INT = 1
DECLARE @Lvl INT = 0

WHILE @Counter > 0
BEGIN

    INSERT ##SeedRanges (SeedStart, SeedEnd, Lvl)

    SELECT SR.SeedStart 
    ,      ISNULL(CASE WHEN SR.SeedEnd < SS.SeedEnd THEN SR.SeedEnd ELSE SS.SeedEnd END, MIN(SS_Min.SeedStart)-1) AS SeedEnd
    ,      @Lvl + 1 AS Lvl
    FROM ##SeedRanges SR
    LEFT JOIN ##Seed2Soil SS ON SR.SeedStart BETWEEN SS.SeedStart AND SS.SeedEnd
    LEFT JOIN ##Seed2Soil SS_Min ON SR.SeedStart < SS_Min.SeedStart AND SS.ID IS NULL
    WHERE SR.Lvl = @Lvl
    GROUP BY SR.SeedStart, SR.SeedEnd, SS.SeedEnd

    UNION 

    SELECT ISNULL(CASE WHEN SR.SeedEnd < SS.SeedEnd THEN SR.SeedEnd ELSE SS.SeedEnd END, MIN(SS_Min.SeedStart)-1) + 1 AS SeedStartNext
    ,      SR.SeedEnd AS OriginalEnd
    ,      @Lvl + 1
    FROM ##SeedRanges SR
    LEFT JOIN ##Seed2Soil SS ON SR.SeedStart BETWEEN SS.SeedStart AND SS.SeedEnd
    LEFT JOIN ##Seed2Soil SS_Min ON SR.SeedStart < SS_Min.SeedStart AND SS.ID IS NULL
    WHERE SR.SeedEnd > SS.SeedEnd AND SR.Lvl = @Lvl
    GROUP BY SR.SeedStart, SR.SeedEnd, SS.SeedEnd

    SET @Counter = @@ROWCOUNT

    DELETE SR1
    FROM ##SeedRanges SR1
    INNER JOIN ##SeedRanges SR2 ON SR1.SeedStart = SR2.SeedStart AND SR1.SeedEnd > SR2.SeedEnd AND SR1.Lvl = @Lvl

    DELETE SR1
    FROM ##SeedRanges SR1
    INNER JOIN ##SeedRanges SR2 ON SR1.SeedStart = SR2.SeedStart AND SR1.SeedEnd = SR2.SeedEnd AND SR1.Lvl > SR2.Lvl

    SET @Lvl = @Lvl + 1
    
END


-- Soil -> Fertilizer --------------------------------------------------------------------------------------

CREATE TABLE ##SoilRanges (ID INT IDENTITY(1,1), SoilStart BIGINT, SoilEnd BIGINT, Lvl INT) 

INSERT ##SoilRanges (SoilStart, SoilEnd, Lvl)
SELECT ISNULL(SR.SeedStart - SS.SeedStart + SoilStart, SR.SeedStart) AS SoilStart
,      ISNULL(SR.SeedEnd - SS.SeedStart + SoilStart, SR.SeedEnd) AS SoilEnd
,      0 AS Lvl
FROM ##SeedRanges SR
LEFT JOIN ##Seed2Soil SS ON SR.SeedStart BETWEEN SS.SeedStart AND SS.SeedEnd

SET @Counter = 1
SET @Lvl = 0

WHILE @Counter > 0
BEGIN

-- DECLARE @Counter INT = 1, @Lvl INT = 0

    INSERT ##SoilRanges (SoilStart, SoilEnd, Lvl)

    SELECT SR.SoilStart 
    ,      ISNULL(CASE WHEN SR.SoilEnd < SS.SoilEnd THEN SR.SoilEnd ELSE SS.SoilEnd END, 
                CASE WHEN MIN(SS_Min.SoilStart) < SR.SoilEnd THEN MIN(SS_Min.SoilStart)-1 ELSE SR.SoilEnd END) AS SoilEnd
    ,      @Lvl + 1 AS Lvl
    FROM ##SoilRanges SR
    LEFT JOIN ##Soil2Fertilizer SS ON SR.SoilStart BETWEEN SS.SoilStart AND SS.SoilEnd
    LEFT JOIN ##Soil2Fertilizer SS_Min ON SR.SoilStart < SS_Min.SoilStart AND SS.ID IS NULL
    WHERE SR.Lvl = @Lvl
    GROUP BY SR.SoilStart, SR.SoilEnd, SS.SoilEnd

    UNION 

    SELECT ISNULL(CASE WHEN SR.SoilEnd < SS.SoilEnd THEN SR.SoilEnd ELSE SS.SoilEnd END, MIN(SS_Min.SoilStart)-1) + 1 AS SoilStartNext
    ,      SR.SoilEnd AS OriginalEnd
    ,      @Lvl + 1
    FROM ##SoilRanges SR
    LEFT JOIN ##Soil2Fertilizer SS ON SR.SoilStart BETWEEN SS.SoilStart AND SS.SoilEnd
    LEFT JOIN ##Soil2Fertilizer SS_Min ON SR.SoilStart < SS_Min.SoilStart AND SS.ID IS NULL
    WHERE SR.SoilEnd > SS.SoilEnd AND SR.Lvl = @Lvl
    GROUP BY SR.SoilStart, SR.SoilEnd, SS.SoilEnd

    SET @Counter = @@ROWCOUNT

    DELETE SR1
    FROM ##SoilRanges SR1
    INNER JOIN ##SoilRanges SR2 ON SR1.SoilStart = SR2.SoilStart AND SR1.SoilEnd > SR2.SoilEnd AND SR1.Lvl = @Lvl

    DELETE SR1
    FROM ##SoilRanges SR1
    INNER JOIN ##SoilRanges SR2 ON SR1.SoilStart = SR2.SoilStart AND SR1.SoilEnd = SR2.SoilEnd AND SR1.Lvl > SR2.Lvl

    SET @Lvl = @Lvl + 1
    
END

-- Fertilizer -> Water --------------------------------------------------------------------------------------

CREATE TABLE ##FertilizerRanges (ID INT IDENTITY(1,1), FertilizerStart BIGINT, FertilizerEnd BIGINT, Lvl INT) 

INSERT ##FertilizerRanges (FertilizerStart, FertilizerEnd, Lvl)
SELECT ISNULL(SR.SoilStart - SS.SoilStart + FertilizerStart, SR.SoilStart) AS FertilizerStart
,      ISNULL(SR.SoilEnd - SS.SoilStart + FertilizerStart, SR.SoilEnd) AS FertilizerEnd
,      0 AS Lvl
FROM ##SoilRanges SR
LEFT JOIN ##Soil2Fertilizer SS ON SR.SoilStart BETWEEN SS.SoilStart AND SS.SoilEnd

SET @Counter = 1
SET @Lvl = 0

WHILE @Counter > 0
BEGIN

    INSERT ##FertilizerRanges (FertilizerStart, FertilizerEnd, Lvl)

    SELECT SR.FertilizerStart 
    ,      ISNULL(CASE WHEN SR.FertilizerEnd < SS.FertilizerEnd THEN SR.FertilizerEnd ELSE SS.FertilizerEnd END, 
                CASE WHEN MIN(SS_Min.FertilizerStart) < SR.FertilizerEnd THEN MIN(SS_Min.FertilizerStart)-1 ELSE SR.FertilizerEnd END) AS FertilizerEnd
    ,      @Lvl + 1 AS Lvl
    FROM ##FertilizerRanges SR
    LEFT JOIN ##Fertilizer2Water SS ON SR.FertilizerStart BETWEEN SS.FertilizerStart AND SS.FertilizerEnd
    LEFT JOIN ##Fertilizer2Water SS_Min ON SR.FertilizerStart < SS_Min.FertilizerStart AND SS.ID IS NULL
    WHERE SR.Lvl = @Lvl
    GROUP BY SR.FertilizerStart, SR.FertilizerEnd, SS.FertilizerEnd

    UNION 

    SELECT ISNULL(CASE WHEN SR.FertilizerEnd < SS.FertilizerEnd THEN SR.FertilizerEnd ELSE SS.FertilizerEnd END, MIN(SS_Min.FertilizerStart)-1) + 1 AS FertilizerStartNext
    ,      SR.FertilizerEnd AS OriginalEnd
    ,      @Lvl + 1
    FROM ##FertilizerRanges SR
    LEFT JOIN ##Fertilizer2Water SS ON SR.FertilizerStart BETWEEN SS.FertilizerStart AND SS.FertilizerEnd
    LEFT JOIN ##Fertilizer2Water SS_Min ON SR.FertilizerStart < SS_Min.FertilizerStart AND SS.ID IS NULL
    WHERE SR.FertilizerEnd > SS.FertilizerEnd AND SR.Lvl = @Lvl
    GROUP BY SR.FertilizerStart, SR.FertilizerEnd, SS.FertilizerEnd

    SET @Counter = @@ROWCOUNT

    DELETE SR1
    FROM ##FertilizerRanges SR1
    INNER JOIN ##FertilizerRanges SR2 ON SR1.FertilizerStart = SR2.FertilizerStart AND SR1.FertilizerEnd > SR2.FertilizerEnd AND SR1.Lvl = @Lvl

    DELETE SR1
    FROM ##FertilizerRanges SR1
    INNER JOIN ##FertilizerRanges SR2 ON SR1.FertilizerStart = SR2.FertilizerStart AND SR1.FertilizerEnd = SR2.FertilizerEnd AND SR1.Lvl > SR2.Lvl

    SET @Lvl = @Lvl + 1
    
END

-- Water -> Light --------------------------------------------------------------------------------------

CREATE TABLE ##WaterRanges (ID INT IDENTITY(1,1), WaterStart BIGINT, WaterEnd BIGINT, Lvl INT) 

INSERT ##WaterRanges (WaterStart, WaterEnd, Lvl)
SELECT ISNULL(SR.FertilizerStart - SS.FertilizerStart + WaterStart, SR.FertilizerStart) AS WaterStart
,      ISNULL(SR.FertilizerEnd - SS.FertilizerStart + WaterStart, SR.FertilizerEnd) AS WaterEnd
,      0 AS Lvl
FROM ##FertilizerRanges SR
LEFT JOIN ##Fertilizer2Water SS ON SR.FertilizerStart BETWEEN SS.FertilizerStart AND SS.FertilizerEnd

SET @Counter = 1
SET @Lvl = 0

WHILE @Counter > 0
BEGIN

    INSERT ##WaterRanges (WaterStart, WaterEnd, Lvl)

    SELECT SR.WaterStart 
    ,      ISNULL(CASE WHEN SR.WaterEnd < SS.WaterEnd THEN SR.WaterEnd ELSE SS.WaterEnd END, 
                CASE WHEN MIN(SS_Min.WaterStart) < SR.WaterEnd THEN MIN(SS_Min.WaterStart)-1 ELSE SR.WaterEnd END) AS WaterEnd
    ,      @Lvl + 1 AS Lvl
    FROM ##WaterRanges SR
    LEFT JOIN ##Water2Light SS ON SR.WaterStart BETWEEN SS.WaterStart AND SS.WaterEnd
    LEFT JOIN ##Water2Light SS_Min ON SR.WaterStart < SS_Min.WaterStart AND SS.ID IS NULL
    WHERE SR.Lvl = @Lvl
    GROUP BY SR.WaterStart, SR.WaterEnd, SS.WaterEnd

    UNION 

    SELECT ISNULL(CASE WHEN SR.WaterEnd < SS.WaterEnd THEN SR.WaterEnd ELSE SS.WaterEnd END, MIN(SS_Min.WaterStart)-1) + 1 AS WaterStartNext
    ,      SR.WaterEnd AS OriginalEnd
    ,      @Lvl + 1
    FROM ##WaterRanges SR
    LEFT JOIN ##Water2Light SS ON SR.WaterStart BETWEEN SS.WaterStart AND SS.WaterEnd
    LEFT JOIN ##Water2Light SS_Min ON SR.WaterStart < SS_Min.WaterStart AND SS.ID IS NULL
    WHERE SR.WaterEnd > SS.WaterEnd AND SR.Lvl = @Lvl
    GROUP BY SR.WaterStart, SR.WaterEnd, SS.WaterEnd

    SET @Counter = @@ROWCOUNT

    DELETE SR1
    FROM ##WaterRanges SR1
    INNER JOIN ##WaterRanges SR2 ON SR1.WaterStart = SR2.WaterStart AND SR1.WaterEnd > SR2.WaterEnd AND SR1.Lvl = @Lvl

    DELETE SR1
    FROM ##WaterRanges SR1
    INNER JOIN ##WaterRanges SR2 ON SR1.WaterStart = SR2.WaterStart AND SR1.WaterEnd = SR2.WaterEnd AND SR1.Lvl > SR2.Lvl

    SET @Lvl = @Lvl + 1
    
END

-- Light -> Temperature --------------------------------------------------------------------------------------

CREATE TABLE ##LightRanges (ID INT IDENTITY(1,1), LightStart BIGINT, LightEnd BIGINT, Lvl INT) 

INSERT ##LightRanges (LightStart, LightEnd, Lvl)
SELECT ISNULL(SR.WaterStart - SS.WaterStart + LightStart, SR.WaterStart) AS LightStart
,      ISNULL(SR.WaterEnd - SS.WaterStart + LightStart, SR.WaterEnd) AS LightEnd
,      0 AS Lvl
FROM ##WaterRanges SR
LEFT JOIN ##Water2Light SS ON SR.WaterStart BETWEEN SS.WaterStart AND SS.WaterEnd

SET @Counter = 1
SET @Lvl = 0

WHILE @Counter > 0
BEGIN

    INSERT ##LightRanges (LightStart, LightEnd, Lvl)

    SELECT SR.LightStart 
    ,      ISNULL(CASE WHEN SR.LightEnd < SS.LightEnd THEN SR.LightEnd ELSE SS.LightEnd END, 
                CASE WHEN MIN(SS_Min.LightStart) < SR.LightEnd THEN MIN(SS_Min.LightStart)-1 ELSE SR.LightEnd END) AS LightEnd
    ,      @Lvl + 1 AS Lvl
    FROM ##LightRanges SR
    LEFT JOIN ##Light2Temperature SS ON SR.LightStart BETWEEN SS.LightStart AND SS.LightEnd
    LEFT JOIN ##Light2Temperature SS_Min ON SR.LightStart < SS_Min.LightStart AND SS.ID IS NULL
    WHERE SR.Lvl = @Lvl
    GROUP BY SR.LightStart, SR.LightEnd, SS.LightEnd

    UNION 

    SELECT ISNULL(CASE WHEN SR.LightEnd < SS.LightEnd THEN SR.LightEnd ELSE SS.LightEnd END, MIN(SS_Min.LightStart)-1) + 1 AS LightStartNext
    ,      SR.LightEnd AS OriginalEnd
    ,      @Lvl + 1
    FROM ##LightRanges SR
    LEFT JOIN ##Light2Temperature SS ON SR.LightStart BETWEEN SS.LightStart AND SS.LightEnd
    LEFT JOIN ##Light2Temperature SS_Min ON SR.LightStart < SS_Min.LightStart AND SS.ID IS NULL
    WHERE SR.LightEnd > SS.LightEnd AND SR.Lvl = @Lvl
    GROUP BY SR.LightStart, SR.LightEnd, SS.LightEnd

    SET @Counter = @@ROWCOUNT

    DELETE SR1
    FROM ##LightRanges SR1
    INNER JOIN ##LightRanges SR2 ON SR1.LightStart = SR2.LightStart AND SR1.LightEnd > SR2.LightEnd AND SR1.Lvl = @Lvl

    DELETE SR1
    FROM ##LightRanges SR1
    INNER JOIN ##LightRanges SR2 ON SR1.LightStart = SR2.LightStart AND SR1.LightEnd = SR2.LightEnd AND SR1.Lvl > SR2.Lvl

    SET @Lvl = @Lvl + 1
    
END

-- Temperature -> Humidity --------------------------------------------------------------------------------------

CREATE TABLE ##TemperatureRanges (ID INT IDENTITY(1,1), TemperatureStart BIGINT, TemperatureEnd BIGINT, Lvl INT) 

INSERT ##TemperatureRanges (TemperatureStart, TemperatureEnd, Lvl)
SELECT ISNULL(SR.LightStart - SS.LightStart + TemperatureStart, SR.LightStart) AS TemperatureStart
,      ISNULL(SR.LightEnd - SS.LightStart + TemperatureStart, SR.LightEnd) AS TemperatureEnd
,      0 AS Lvl
FROM ##LightRanges SR
LEFT JOIN ##Light2Temperature SS ON SR.LightStart BETWEEN SS.LightStart AND SS.LightEnd

SET @Counter = 1
SET @Lvl = 0

WHILE @Counter > 0
BEGIN

    INSERT ##TemperatureRanges (TemperatureStart, TemperatureEnd, Lvl)

    SELECT SR.TemperatureStart 
    ,      ISNULL(CASE WHEN SR.TemperatureEnd < SS.TemperatureEnd THEN SR.TemperatureEnd ELSE SS.TemperatureEnd END, 
                CASE WHEN MIN(SS_Min.TemperatureStart) < SR.TemperatureEnd THEN MIN(SS_Min.TemperatureStart)-1 ELSE SR.TemperatureEnd END) AS TemperatureEnd
    ,      @Lvl + 1 AS Lvl
    FROM ##TemperatureRanges SR
    LEFT JOIN ##Temperature2Humidity SS ON SR.TemperatureStart BETWEEN SS.TemperatureStart AND SS.TemperatureEnd
    LEFT JOIN ##Temperature2Humidity SS_Min ON SR.TemperatureStart < SS_Min.TemperatureStart AND SS.ID IS NULL
    WHERE SR.Lvl = @Lvl
    GROUP BY SR.TemperatureStart, SR.TemperatureEnd, SS.TemperatureEnd

    UNION 

    SELECT ISNULL(CASE WHEN SR.TemperatureEnd < SS.TemperatureEnd THEN SR.TemperatureEnd ELSE SS.TemperatureEnd END, MIN(SS_Min.TemperatureStart)-1) + 1 AS TemperatureStartNext
    ,      SR.TemperatureEnd AS OriginalEnd
    ,      @Lvl + 1
    FROM ##TemperatureRanges SR
    LEFT JOIN ##Temperature2Humidity SS ON SR.TemperatureStart BETWEEN SS.TemperatureStart AND SS.TemperatureEnd
    LEFT JOIN ##Temperature2Humidity SS_Min ON SR.TemperatureStart < SS_Min.TemperatureStart AND SS.ID IS NULL
    WHERE SR.TemperatureEnd > SS.TemperatureEnd AND SR.Lvl = @Lvl
    GROUP BY SR.TemperatureStart, SR.TemperatureEnd, SS.TemperatureEnd

    SET @Counter = @@ROWCOUNT

    DELETE SR1
    FROM ##TemperatureRanges SR1
    INNER JOIN ##TemperatureRanges SR2 ON SR1.TemperatureStart = SR2.TemperatureStart AND SR1.TemperatureEnd > SR2.TemperatureEnd AND SR1.Lvl = @Lvl

    DELETE SR1
    FROM ##TemperatureRanges SR1
    INNER JOIN ##TemperatureRanges SR2 ON SR1.TemperatureStart = SR2.TemperatureStart AND SR1.TemperatureEnd = SR2.TemperatureEnd AND SR1.Lvl > SR2.Lvl

    SET @Lvl = @Lvl + 1
    
END


-- Humidity -> Location --------------------------------------------------------------------------------------

CREATE TABLE ##HumidityRanges (ID INT IDENTITY(1,1), HumidityStart BIGINT, HumidityEnd BIGINT, Lvl INT) 

INSERT ##HumidityRanges (HumidityStart, HumidityEnd, Lvl)
SELECT ISNULL(SR.TemperatureStart - SS.TemperatureStart + HumidityStart, SR.TemperatureStart) AS HumidityStart
,      ISNULL(SR.TemperatureEnd - SS.TemperatureStart + HumidityStart, SR.TemperatureEnd) AS HumidityEnd
,      0 AS Lvl
FROM ##TemperatureRanges SR
LEFT JOIN ##Temperature2Humidity SS ON SR.TemperatureStart BETWEEN SS.TemperatureStart AND SS.TemperatureEnd

SET @Counter = 1
SET @Lvl = 0

WHILE @Counter > 0
BEGIN

    INSERT ##HumidityRanges (HumidityStart, HumidityEnd, Lvl)

    SELECT SR.HumidityStart 
    ,      ISNULL(CASE WHEN SR.HumidityEnd < SS.HumidityEnd THEN SR.HumidityEnd ELSE SS.HumidityEnd END, 
                CASE WHEN MIN(SS_Min.HumidityStart) < SR.HumidityEnd THEN MIN(SS_Min.HumidityStart)-1 ELSE SR.HumidityEnd END) AS HumidityEnd
    ,      @Lvl + 1 AS Lvl
    FROM ##HumidityRanges SR
    LEFT JOIN ##Humidity2Location SS ON SR.HumidityStart BETWEEN SS.HumidityStart AND SS.HumidityEnd
    LEFT JOIN ##Humidity2Location SS_Min ON SR.HumidityStart < SS_Min.HumidityStart AND SS.ID IS NULL
    WHERE SR.Lvl = @Lvl
    GROUP BY SR.HumidityStart, SR.HumidityEnd, SS.HumidityEnd

    UNION 

    SELECT ISNULL(CASE WHEN SR.HumidityEnd < SS.HumidityEnd THEN SR.HumidityEnd ELSE SS.HumidityEnd END, MIN(SS_Min.HumidityStart)-1) + 1 AS HumidityStartNext
    ,      SR.HumidityEnd AS OriginalEnd
    ,      @Lvl + 1
    FROM ##HumidityRanges SR
    LEFT JOIN ##Humidity2Location SS ON SR.HumidityStart BETWEEN SS.HumidityStart AND SS.HumidityEnd
    LEFT JOIN ##Humidity2Location SS_Min ON SR.HumidityStart < SS_Min.HumidityStart AND SS.ID IS NULL
    WHERE SR.HumidityEnd > SS.HumidityEnd AND SR.Lvl = @Lvl
    GROUP BY SR.HumidityStart, SR.HumidityEnd, SS.HumidityEnd

    SET @Counter = @@ROWCOUNT

    DELETE SR1
    FROM ##HumidityRanges SR1
    INNER JOIN ##HumidityRanges SR2 ON SR1.HumidityStart = SR2.HumidityStart AND SR1.HumidityEnd > SR2.HumidityEnd AND SR1.Lvl = @Lvl

    DELETE SR1
    FROM ##HumidityRanges SR1
    INNER JOIN ##HumidityRanges SR2 ON SR1.HumidityStart = SR2.HumidityStart AND SR1.HumidityEnd = SR2.HumidityEnd AND SR1.Lvl > SR2.Lvl

    SET @Lvl = @Lvl + 1
    
END



SELECT TOP 1 ISNULL(SR.HumidityStart - SS.HumidityStart + LocationStart, SR.HumidityStart) AS Part2
FROM ##HumidityRanges SR
LEFT JOIN ##Humidity2Location SS ON SR.HumidityStart BETWEEN SS.HumidityStart AND SS.HumidityEnd
ORDER BY ISNULL(SR.HumidityStart - SS.HumidityStart + LocationStart, SR.HumidityStart)

/*

DROP TABLE ##Seeds
DROP TABLE ##Seed2Soil
DROP TABLE ##Soil2Fertilizer
DROP TABLE ##Fertilizer2Water
DROP TABLE ##Water2Light
DROP TABLE ##Light2Temperature
DROP TABLE ##Temperature2Humidity
DROP TABLE ##Humidity2Location
DROP TABLE ##SeedRanges
DROP TABLE ##SoilRanges
DROP TABLE ##FertilizerRanges
DROP TABLE ##WaterRanges
DROP TABLE ##LightRanges
DROP TABLE ##TemperatureRanges
DROP TABLE ##HumidityRanges

*/





