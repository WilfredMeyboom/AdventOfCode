USE Test_WME

DECLARE @year VARCHAR(4) = '2022'
DECLARE @day VARCHAR(2)  = '1'

EXEC dbo.GetInput @year = @year, @day = @day
EXEC dbo.ParseInput @year = @year, @day = @day 

SELECT TOP 10 * FROM ##Input
SELECT TOP 10 * FROM ##InputInts
SELECT TOP 10 * FROM ##InputNumbered
SELECT TOP 10 * FROM ##InputGrid
SELECT TOP 10 * FROM ##InputSplit
SELECT TOP 10 * FROM ##InputSplitCust
  



