USE Test_WME

DECLARE @year VARCHAR(4) = '2022'
DECLARE @day VARCHAR(2)  = '2'

EXEC dbo.GetInput @year = @year, @day = @day
EXEC dbo.ParseInput @year = @year, @day = @day 

--SELECT TOP 10 * FROM ##Input
--SELECT TOP 10 * FROM ##InputInts
--SELECT TOP 10 * FROM ##InputNumbered
--SELECT TOP 10 * FROM ##InputGrid
--SELECT TOP 10 * FROM ##InputSplit
--SELECT TOP 10 * FROM ##InputSplitCust
  
--a rock, b paper, c scissors
--x rock, y paper, z scissors

DECLARE @Scores TABLE (ID INT IDENTITY, Line VARCHAR(10), Score INT, Score2 INT)

INSERT @Scores
(
    Line,
    Score,
    Score2
)
SELECT 'A X', 4, 3 UNION   --1 + 3 | 3 + 0
SELECT 'A Y', 8, 4 UNION   --2 + 6 | 1 + 3
SELECT 'A Z', 3, 8 UNION   --3 + 0 | 2 + 6
SELECT 'B X', 1, 1 UNION   --1 + 0 | 1 + 0
SELECT 'B Y', 5, 5 UNION   --2 + 3 | 2 + 3
SELECT 'B Z', 9, 9 UNION   --3 + 6 | 3 + 6
SELECT 'C X', 7, 2 UNION   --1 + 6 | 2 + 0
SELECT 'C Y', 2, 6 UNION   --2 + 0 | 3 + 3
SELECT 'C Z', 6, 7         --3 + 3 | 1 + 6


SELECT SUM(Score) AS Part1, SUM(Score2) AS Part2
FROM ##Input I
left JOIN @Scores S ON i.line = s.Line