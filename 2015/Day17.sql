use Test_WME

SET NOCOUNT ON

CREATE TABLE ##Input (Line NVARCHAR(MAX));

BULK INSERT ##Input
FROM 'D:\Wilfred\AdventOfCode\2015\input17.txt'
WITH (ROWTERMINATOR = '0x0A');

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
SELECT COUNT(1)
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
