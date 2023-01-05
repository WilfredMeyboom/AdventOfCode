USE Test_WME

SET NOCOUNT ON

DECLARE @year VARCHAR(4) = '2015'
DECLARE @day VARCHAR(2)  = '17'

EXEC dbo.GetInput @year = @year, @day = @day
EXEC dbo.ParseInput @year = @year, @day = @day

CREATE TABLE ##Buckets (ID INT IDENTITY(1,1), UsedBuckets VARCHAR(250), Volume INT, Counter INT)

;WITH cte_Buckets AS (
    SELECT CAST('|' + CAST(Ind AS VARCHAR(10)) + '|' AS VARCHAR(MAX)) AS UsedBuckets
    ,      Val AS Volume
    ,      1 AS Counter
    ,      Ind AS LastInd
    ,      Val AS LastVal
    FROM ##InputInts

    UNION ALL

    SELECT CAST(B.UsedBuckets + CAST(I.Ind AS VARCHAR(10)) + '|' AS VARCHAR(MAX))
    ,      I.Val + B.Volume
    ,      Counter + 1
    ,      I.Ind
    ,      I.Val
    FROM cte_Buckets B
    INNER JOIN ##InputInts I ON B.LastVal > I.Val OR B.LastVal = I.Val AND B.LastInd > I.Ind
    WHERE B.Volume <= 150
)
INSERT ##Buckets (UsedBuckets, Volume, Counter)
SELECT UsedBuckets, Volume, Counter
FROM cte_Buckets
WHERE Volume = 150


SELECT COUNT(1) AS Part1 FROM ##Buckets

;WITH cte_Min AS (
    SELECT MIN(Counter) AS MinCount FROM ##Buckets
)
SELECT COUNT(1) AS Part2
FROM ##Buckets B
INNER JOIN cte_Min M ON B.Counter = M.MinCount


DROP TABLE ##Buckets