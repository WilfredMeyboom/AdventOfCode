USE Test_WME

SET NOCOUNT ON

DECLARE @year VARCHAR(4) = '2021'
DECLARE @day VARCHAR(2)  = '9'

EXEC dbo.GetInput @year = @year, @day = @day
EXEC dbo.ParseInput @year = @year, @day = @day 

SELECT TOP 10 * FROM ##InputNumbered
SELECT TOP 10 * FROM ##InputGrid
SELECT TOP 10 * FROM ##InputInts
SELECT TOP 10 * FROM ##InputSplit
SELECT TOP 10 * FROM ##InputSplitCust


