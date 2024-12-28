USE Test_WME

SET NOCOUNT ON

DECLARE @year VARCHAR(4) = '2024'
DECLARE @day VARCHAR(2)  = '4'

EXEC dbo.GetInput @year = @year, @day = @day
EXEC dbo.ParseInput @year = @year, @day = @day 

--SELECT TOP 10 * FROM ##Input
--SELECT TOP 10 * FROM ##InputInts
--SELECT TOP 10 * FROM ##InputNumbered
--SELECT TOP 10 * FROM ##InputGrid
--SELECT TOP 10 * FROM ##InputSplit
--SELECT TOP 10 * FROM ##InputSplitCust

SELECT COUNT(1) AS Part1
FROM ##InputGrid I1
INNER JOIN ##InputGrid I2 ON ABS(I1.RowNr - I2.RowNr) <= 1 AND ABS(I1.ColNr - I2.ColNr) <= 1 AND I2.Val = 'M'
INNER JOIN ##InputGrid I3 ON I3.RowNr = I2.RowNr - (I1.RowNr - I2.RowNr) 
                         AND I3.ColNr = I2.ColNr - (I1.ColNr - I2.ColNr)
                         AND I3.Val = 'A'
INNER JOIN ##InputGrid I4 ON I4.RowNr = I3.RowNr - (I1.RowNr - I2.RowNr) 
                         AND I4.ColNr = I3.ColNr - (I1.ColNr - I2.ColNr)
                         AND I4.Val = 'S'
WHERE I1.Val = 'X'


;WITH cte_Branch AS (
    SELECT I1.RowNr AS ARowNr, I1.ColNr AS AColNr, I2.RowNr, I2.ColNr, I2.Val
    FROM ##InputGrid I1
    INNER JOIN ##InputGrid I2 ON ABS(I1.RowNr - I2.RowNr) = 1 AND ABS(I1.ColNr - I2.ColNr) = 1 AND I2.Val IN ('M','S')
    WHERE I1.Val = 'A'
)
    SELECT c1.AColNr, c1.ARowNr, c1.ColNr AS MColNr, c1.RowNr AS MRowNr
    INTO ##OneSide
    FROM cte_Branch c1
    INNER JOIN cte_Branch c2 ON c1.AColNr = c2.AColNr AND c1.ARowNr = c2.ARowNr
                            AND c2.Val = 'S'
                            AND ABS(c1.ColNr - c2.ColNr) = 2 AND ABS(c1.RowNr - c2.RowNr) = 2
    WHERE c1.Val = 'M'

SELECT COUNT(1) / 2 AS Part2
FROM ##OneSide cOS1
INNER JOIN ##OneSide cOS2 ON cOS1.ARowNr = cOS2.ARowNr AND cOS1.AColNr = cOS2.AColNr
                           AND (cOS1.MRowNr <> cOS2.MRowNr OR cOS1.MColNr <> cOS2.MColNr)

DROP TABLE ##OneSide

--4058 too high

