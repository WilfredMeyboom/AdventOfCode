USE Test_WME

SET NOCOUNT ON

DECLARE @year VARCHAR(4) = '2024'
DECLARE @day VARCHAR(2)  = '13'

EXEC dbo.GetInput @year = @year, @day = @day
EXEC dbo.ParseInput @year = @year, @day = @day, @SplitCustom = '+ =,'

--SELECT TOP 10 * FROM ##Input
--SELECT TOP 10 * FROM ##InputInts
--SELECT TOP 10 * FROM ##InputNumbered
--SELECT TOP 10 * FROM ##InputGrid
--SELECT TOP 10 * FROM ##InputSplit
--SELECT TOP 10 * FROM ##InputSplitCust


CREATE TABLE ##XY (ID INT IDENTITY(1,1), MachineNr INT, Button CHAR, X INT, Y INT)

INSERT ##XY (MachineNr, Button, X, Y)
SELECT NTILE(4) OVER (ORDER BY (SELECT 0)), CASE WHEN I1.RowNr % 2 = 0 THEN 'B' ELSE 'A' END, RIGHT(I1.Piece, 2) AS X, RIGHT(I2.Piece, 2) AS Y
FROM ##InputSplit I1
INNER JOIN ##InputSplit I2 ON I1.RowNr = I2.RowNr AND I2.PieceNr = 4 AND I2.RowNr % 4 IN (1,2)
WHERE I1.PieceNr = 3 AND I1.RowNr % 4 IN (1,2)

CREATE TABLE ##Targets (ID INT IDENTITY, MachineNr INT, X BIGINT, Y BIGINT)

INSERT ##Targets (MachineNr, X, Y)
SELECT NTILE(320) OVER (ORDER BY (SELECT 0)), REPLACE(I1.Piece,'x=','') AS X, REPLACE(I2.Piece, 'y=','') AS Y
FROM ##InputSplit I1
INNER JOIN ##InputSplit I2 ON I1.RowNr = I2.RowNr AND I2.PieceNr = 3 AND I2.RowNr % 4 = 3
WHERE I1.PieceNr = 2 AND I1.RowNr % 4 = 3

--SELECT * FROM ##XY

;WITH cte_Nrs AS (
    SELECT TOP 100 ROW_NUMBER() OVER (ORDER BY (SELECT 0)) AS RN FROM sys.messages
), cte_Calc AS (
SELECT M1.MachineNr, 3*A.RN + B.RN AS TokenCost
--, M1.X * A.RN + M2.X * B.RN, M1.Y * A.RN + M2.Y * B.RN, *
FROM ##XY M1
INNER JOIN ##XY M2 ON M1.MachineNr = M2.MachineNr AND M1.Button < M2.Button
CROSS APPLY cte_Nrs A
CROSS APPLY cte_Nrs B
INNER JOIN ##Targets T ON M1.MachineNr = T.MachineNr
WHERE T.X = M1.X * A.RN + M2.X * B.RN AND T.Y = M1.Y * A.RN + M2.Y * B.RN
--ORDER BY M1.MachineNr
)
SELECT SUM(TokenCost) AS Part1
FROM cte_Calc




UPDATE ##Targets
SET X = X + 10000000000000
,   Y = Y + 10000000000000
            

CREATE TABLE ##LaLa (ID INT IDENTITY(1,1), MachineNr INT, AX FLOAT, BX FLOAT, TX FLOAT, AY FLOAT, [BY] FLOAT, TY FLOAT)

INSERT ##LaLa (MachineNr, AX, BX, TX, AY, [BY], TY)
SELECT T.MachineNr, T1.X AS AX, T2.X AS BX, T.X AS TX, T1.Y AS AY, T2.Y AS [BY], T.Y AS TY
FROM ##XY T1
INNER JOIN ##XY T2 ON T1.MachineNr = T2.MachineNr AND T1.Button < T2.Button
INNER JOIN ##Targets T ON T.MachineNr = T1.MachineNr

SELECT *
INTO ##LaLaBackup
FROM ##LaLa

--SELECT *, CAST(AX AS DECIMAL(38,0)),BX / CAST(AX AS DECIMAL(38,0)), TX / CAST(AX AS DECIMAL(38,0)) FROM ##Lala
UPDATE ##LaLa
SET AX = AX / AX 
,   BX = BX / AX 
,   TX = TX / AX 

--SELECT CAST(AY AS DECIMAL(38,9)) * CAST([BX] AS DECIMAL(38,9)) FROM ##Lala

UPDATE ##LaLa
SET AY = AY - AY * AX
,  [BY] = [BY] - AY * BX
,   TY = TY - AY * TX

--SELECT *, CAST([BY] AS DECIMAL(38,12)) FROM ##Lala ORDER BY [BY]
--SELECT * FROM ##LalaBackup WHERE ID = 6332
--SELECT * FROM ##Lala
DELETE FROM ##Lala WHERE [BY] = 0

UPDATE ##LaLa
SET AY = AY    / [BY]
,  [BY] = [BY] / [BY]
,   TY = TY    / [BY]

--SELECT * FROM ##Lala
UPDATE ##LaLa
SET AX = AX - BX * AY
,   BX = BX - BX * [BY]
,   TX = TX - BX * TY

SELECT 
LB.TX
, ROUND(L.TX,0) * LB.AX + ROUND(L.TY,0) * LB.BX
, LB.TY
, ROUND(L.TX,0) * LB.AY + ROUND(L.TY,0) * LB.[BY]
,  CASE WHEN ROUND(L.TX,0) * LB.AX + ROUND(L.TY,0) * LB.BX = LB.TX
  AND ROUND(L.TX,0) * LB.AY + ROUND(L.TY,0) * LB.[BY] = LB.TY THEN 'J' ELSE 'N' END
--SUM(ROUND(L.TX,0) * 3 + ROUND(L.TY,0))
FROM ##LaLa L
INNER JOIN ##LaLaBackup LB ON L.MachineNr = LB.MachineNr
WHERE ROUND(L.TX,0) * LB.AX + ROUND(L.TY,0) * LB.BX = LB.TX
  AND ROUND(L.TX,0) * LB.AY + ROUND(L.TY,0) * LB.[BY] = LB.TY

--13758108904596 too low
--14940927033247 too low
--78101482023732
--360308747890659 too high

;WITH cte_Ints AS (
SELECT CAST(ROUND(LB.AX,0) AS INT) AX
, CAST(ROUND(LB.BX,0) AS INT) BX
, CAST(ROUND(LB.AY,0) AS INT) AY
, CAST(ROUND(LB.[BY],0) AS INT) [BY]
, CAST(ROUND(L.TX,0) AS BIGINT) [TX]
, CAST(ROUND(L.TY,0) AS BIGINT) [TY]
, CAST(ROUND(LB.TX,0) AS BIGINT) [TTX]
, CAST(ROUND(LB.TY,0) AS BIGINT) [TTY]
FROM ##lala L
INNER JOIN ##LaLaBackup LB ON L.MachineNr = LB.MachineNr
)
SELECT --AX * TX + BX * TY, TTX, AY * TX + [BY] * TY, TTY--,
SUM(3*TX + TY)
FROM cte_Ints 
WHERE  AX * TX + BX * TY - TTX = 0 AND AY * TX + [BY] * TY - TTY = 0


/*

DROP TABLE ##XY
DROP TABLE ##Targets
DROP TABLE ##LaLa
DROP TABLE ##LaLaBackup

*/