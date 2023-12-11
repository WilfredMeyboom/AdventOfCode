USE Test_WME

SET NOCOUNT ON

DECLARE @year VARCHAR(4) = '2023'
DECLARE @day VARCHAR(2)  = '9'

EXEC dbo.GetInput @year = @year, @day = @day
EXEC dbo.ParseInput @year = @year, @day = @day 

--SELECT TOP 10 * FROM ##Input
--SELECT TOP 10 * FROM ##InputInts
--SELECT TOP 10 * FROM ##InputNumbered
--SELECT TOP 10 * FROM ##InputGrid
--SELECT TOP 10 * FROM ##InputSplitCust
  

CREATE TABLE ##Histories (ID INT IDENTITY(1,1), RowNr INT, PieceNr INT, Val INT, Lvl INT)

-- Store the starting lines (and assign a level 1)
INSERT ##Histories
(
    RowNr,
    PieceNr,
    Val,
    Lvl
)
SELECT RowNr
,      PieceNr
,      CAST(Piece AS INT)
,      1
FROM ##InputSplit


DECLARE @Lvl INT = 1
DECLARE @Count INT = 1

-- Calculate all the next lines 
-- (Don't try to stop when the line is all zeros, since every line is one shorter than the previous one, the calculation will end automatically)
WHILE @Count > 0
BEGIN

    INSERT ##Histories
    (
        RowNr,
        PieceNr,
        Val,
        Lvl
    )
    SELECT H.RowNr, H.PieceNr, H2.Val - H.Val, @Lvl + 1
    FROM ##Histories H
    INNER JOIN ##Histories H2 ON H.RowNr = H2.RowNr AND H.PieceNr = H2.PieceNr - 1 AND H.Lvl = H2.Lvl
    WHERE H.Lvl = @Lvl

    SET @Count = @@ROWCOUNT

    SET @Lvl = @Lvl + 1

END

-- Interestingly the value we need is a sum of all the last values of all the line
-- So if we take the last value on each line and level and add them, we get the answer per line
;WITH cte_LastValues AS (
    SELECT RowNr, Lvl, MAX(PieceNr) AS MaxPieceNr FROM ##Histories H 
    GROUP BY RowNr, Lvl
)
SELECT SUM(Val) AS Part1
FROM cte_LastValues cLV
INNER JOIN ##Histories H ON H.RowNr = cLV.RowNr AND H.Lvl = cLV.Lvl AND H.PieceNr = cLV.MaxPieceNr


-- This also works on the other end but the values should be alternately added and substracted
;WITH cte_LastValues AS (
    SELECT RowNr, Lvl, MIN(PieceNr) AS MaxPieceNr FROM ##Histories H 
    GROUP BY RowNr, Lvl
)
SELECT SUM(CASE WHEN cLV.Lvl % 2  = 1 THEN Val ELSE -1 * Val END) AS Part2
FROM cte_LastValues cLV
INNER JOIN ##Histories H ON H.RowNr = cLV.RowNr AND H.Lvl = cLV.Lvl AND H.PieceNr = cLV.MaxPieceNr

--DROP TABLE ##Histories
