USE Test_WME

SET NOCOUNT ON

DECLARE @year VARCHAR(4) = '2024'
DECLARE @day VARCHAR(2)  = '10'

EXEC dbo.GetInput @year = @year, @day = @day
EXEC dbo.ParseInput @year = @year, @day = @day 

--SELECT TOP 10 * FROM ##Input
--SELECT TOP 10 * FROM ##InputInts
--SELECT TOP 10 * FROM ##InputNumbered
--SELECT TOP 10 * FROM ##InputGrid
--SELECT TOP 10 * FROM ##InputSplit
--SELECT TOP 10 * FROM ##InputSplitCust

;WITH cte_Trails AS (
    SELECT I0.RowNr R0, I0.ColNr C0, I9.RowNr R9, I9.ColNr C9, COUNT(1) AS Rating
    FROM ##InputGrid I0
    INNER JOIN ##InputGrid I1 ON ((I0.RowNr = I1.RowNr AND ABS(I0.ColNr - I1.ColNr) = 1) OR I0.ColNr = I1.ColNr AND ABS(I0.RowNr - I1.RowNr) = 1) AND I1.Val = 1 
    INNER JOIN ##InputGrid I2 ON ((I1.RowNr = I2.RowNr AND ABS(I1.ColNr - I2.ColNr) = 1) OR I1.ColNr = I2.ColNr AND ABS(I1.RowNr - I2.RowNr) = 1) AND I2.Val = 2 
    INNER JOIN ##InputGrid I3 ON ((I2.RowNr = I3.RowNr AND ABS(I2.ColNr - I3.ColNr) = 1) OR I2.ColNr = I3.ColNr AND ABS(I2.RowNr - I3.RowNr) = 1) AND I3.Val = 3 
    INNER JOIN ##InputGrid I4 ON ((I3.RowNr = I4.RowNr AND ABS(I3.ColNr - I4.ColNr) = 1) OR I3.ColNr = I4.ColNr AND ABS(I3.RowNr - I4.RowNr) = 1) AND I4.Val = 4 
    INNER JOIN ##InputGrid I5 ON ((I4.RowNr = I5.RowNr AND ABS(I4.ColNr - I5.ColNr) = 1) OR I4.ColNr = I5.ColNr AND ABS(I4.RowNr - I5.RowNr) = 1) AND I5.Val = 5 
    INNER JOIN ##InputGrid I6 ON ((I5.RowNr = I6.RowNr AND ABS(I5.ColNr - I6.ColNr) = 1) OR I5.ColNr = I6.ColNr AND ABS(I5.RowNr - I6.RowNr) = 1) AND I6.Val = 6 
    INNER JOIN ##InputGrid I7 ON ((I6.RowNr = I7.RowNr AND ABS(I6.ColNr - I7.ColNr) = 1) OR I6.ColNr = I7.ColNr AND ABS(I6.RowNr - I7.RowNr) = 1) AND I7.Val = 7 
    INNER JOIN ##InputGrid I8 ON ((I7.RowNr = I8.RowNr AND ABS(I7.ColNr - I8.ColNr) = 1) OR I7.ColNr = I8.ColNr AND ABS(I7.RowNr - I8.RowNr) = 1) AND I8.Val = 8 
    INNER JOIN ##InputGrid I9 ON ((I8.RowNr = I9.RowNr AND ABS(I8.ColNr - I9.ColNr) = 1) OR I8.ColNr = I9.ColNr AND ABS(I8.RowNr - I9.RowNr) = 1) AND I9.Val = 9 
    WHERE I0.Val = 0
    GROUP BY I0.RowNr, I0.ColNr, I9.RowNr, I9.ColNr
)
SELECT COUNT(1) AS Part1, SUM(Rating) AS Part2
FROM cte_Trails

--1735 is too high for part 1



