USE Test_WME

SET NOCOUNT ON

DECLARE @year VARCHAR(4) = '2015'
DECLARE @day VARCHAR(2)  = '17'

EXEC dbo.GetInput @year = @year, @day = @day
EXEC dbo.ParseInput @year = @year, @day = @day


;WITH cte_Buckets AS (
    SELECT CAST('|' + CAST(Ind AS VARCHAR(10)) + '|' AS VARCHAR(MAX)) AS UsedBuckets
    ,      CAST('|' + CAST(Val AS VARCHAR(10)) + '|' AS VARCHAR(MAX)) AS UsedVolumes
    ,      Val AS Volume
    ,      1 AS Counter
    ,      Val AS LastVal
    FROM ##InputInts

    UNION ALL

    SELECT CAST(B.UsedBuckets + CAST(I.Ind AS VARCHAR(10)) + '|' AS VARCHAR(MAX))
    ,      CAST(B.UsedVolumes + CAST(I.Val AS VARCHAR(10)) + '|' AS VARCHAR(MAX))
    ,      I.Val + B.Volume
    ,      Counter + 1
    ,      I.Val
    FROM cte_Buckets B
    INNER JOIN ##InputInts I ON B.LastVal >= I.Val AND B.UsedBuckets NOT LIKE '%|' + CAST(I.Ind AS VARCHAR(10)) + '|%'
    WHERE B.Volume <= 150
)
SELECT UsedVolumes, COUNT(1), Counter
FROM cte_Buckets
WHERE Volume = 150
GROUP BY UsedVolumes, Counter


CREATE TABLE ##Buckets (ID INT IDENTITY(1,1), Size INT)

INSERT ##Buckets (Size)
SELECT CAST(Line AS INT) FROM ##Input ORDER BY 1


SELECT COUNT(1)
FROM ##Buckets B1
INNER JOIN ##Buckets B2 ON B1.ID > B2.ID
INNER JOIN ##Buckets B3 ON B2.ID > B3.ID
INNER JOIN ##Buckets B4 ON B3.ID > B4.ID
WHERE ISNULL(B1.Size, 0)
    + ISNULL(B2.Size, 0)
    + ISNULL(B3.Size, 0)
    + ISNULL(B4.Size, 0)
    = 150
UNION ALL
SELECT COUNT(1)
FROM ##Buckets B1
INNER JOIN ##Buckets B2 ON B1.ID > B2.ID
INNER JOIN ##Buckets B3 ON B2.ID > B3.ID
INNER JOIN ##Buckets B4 ON B3.ID > B4.ID
INNER JOIN ##Buckets B5 ON B4.ID > B5.ID
WHERE ISNULL(B1.Size, 0)
    + ISNULL(B2.Size, 0)
    + ISNULL(B3.Size, 0)
    + ISNULL(B4.Size, 0)
    + ISNULL(B5.Size, 0)
    = 150
UNION ALL
SELECT COUNT(1)
FROM ##Buckets B1
INNER JOIN ##Buckets B2 ON B1.ID > B2.ID
INNER JOIN ##Buckets B3 ON B2.ID > B3.ID
INNER JOIN ##Buckets B4 ON B3.ID > B4.ID
INNER JOIN ##Buckets B5 ON B4.ID > B5.ID
INNER JOIN ##Buckets B6 ON B5.ID > B6.ID
WHERE ISNULL(B1.Size, 0)
    + ISNULL(B2.Size, 0)
    + ISNULL(B3.Size, 0)
    + ISNULL(B4.Size, 0)
    + ISNULL(B5.Size, 0)
    + ISNULL(B6.Size, 0)
    = 150
UNION ALL
SELECT COUNT(1)
FROM ##Buckets B1
INNER JOIN ##Buckets B2 ON B1.ID > B2.ID
INNER JOIN ##Buckets B3 ON B2.ID > B3.ID
INNER JOIN ##Buckets B4 ON B3.ID > B4.ID
INNER JOIN ##Buckets B5 ON B4.ID > B5.ID
INNER JOIN ##Buckets B6 ON B5.ID > B6.ID
INNER JOIN ##Buckets B7 ON B6.ID > B7.ID
WHERE ISNULL(B1.Size, 0)
    + ISNULL(B2.Size, 0)
    + ISNULL(B3.Size, 0)
    + ISNULL(B4.Size, 0)
    + ISNULL(B5.Size, 0)
    + ISNULL(B6.Size, 0)
    + ISNULL(B7.Size, 0)
    = 150
UNION ALL
SELECT *---,COUNT(1)
FROM ##Buckets B1
INNER JOIN ##Buckets B2 ON B1.ID > B2.ID
INNER JOIN ##Buckets B3 ON B2.ID > B3.ID
INNER JOIN ##Buckets B4 ON B3.ID > B4.ID
INNER JOIN ##Buckets B5 ON B4.ID > B5.ID
INNER JOIN ##Buckets B6 ON B5.ID > B6.ID
INNER JOIN ##Buckets B7 ON B6.ID > B7.ID
INNER JOIN ##Buckets B8 ON B7.ID > B8.ID
WHERE ISNULL(B1.Size, 0)
    + ISNULL(B2.Size, 0)
    + ISNULL(B3.Size, 0)
    + ISNULL(B4.Size, 0)
    + ISNULL(B5.Size, 0)
    + ISNULL(B6.Size, 0)
    + ISNULL(B7.Size, 0)
    + ISNULL(B8.Size, 0)
    = 150
UNION ALL
SELECT COUNT(1)
FROM ##Buckets B1
INNER JOIN ##Buckets B2 ON B1.ID > B2.ID
INNER JOIN ##Buckets B3 ON B2.ID > B3.ID
INNER JOIN ##Buckets B4 ON B3.ID > B4.ID
INNER JOIN ##Buckets B5 ON B4.ID > B5.ID
INNER JOIN ##Buckets B6 ON B5.ID > B6.ID
INNER JOIN ##Buckets B7 ON B6.ID > B7.ID
INNER JOIN ##Buckets B8 ON B7.ID > B8.ID
INNER JOIN ##Buckets B9 ON B8.ID > B9.ID
WHERE ISNULL(B1.Size, 0)
    + ISNULL(B2.Size, 0)
    + ISNULL(B3.Size, 0)
    + ISNULL(B4.Size, 0)
    + ISNULL(B5.Size, 0)
    + ISNULL(B6.Size, 0)
    + ISNULL(B7.Size, 0)
    + ISNULL(B8.Size, 0)
    + ISNULL(B9.Size, 0)
    = 150


SELECT 57+231+262+97+7

--654 is correct for part 1
--57 is correct for part 2


/* 

DROP TABLE ##Input

*/
