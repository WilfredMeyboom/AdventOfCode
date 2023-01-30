SET NOCOUNT ON

DECLARE @RoomID VARCHAR(10) = 'ojvtpuvg'
DECLARE @Counter BIGINT = 0


CREATE TABLE ##Hashes (ID INT IDENTITY(1,1), Cnter BIGINT, Hash VARCHAR(50), Pos CHAR)

WHILE (SELECT COUNT(DISTINCT Pos) FROM ##Hashes WHERE Pos BETWEEN '0' AND '7') < 8
BEGIN

    IF (SELECT CAST(CAST(HASHBYTES('MD5', @RoomID + CAST(@Counter AS VARCHAR(15))) AS VARBINARY(4)) AS INT)) BETWEEN 0 AND 4095
    BEGIN
       
        INSERT ##Hashes (Cnter, Hash) VALUES (@Counter, sys.fn_sqlvarbasetostr(HASHBYTES('MD5', @RoomID + CAST(@Counter AS VARCHAR(15)))))
        UPDATE ##Hashes SET Pos = SUBSTRING(Hash, 8, 1) WHERE Pos IS NULL

    END

    SET @Counter = @Counter + 1
END

SELECT [0] + [1] + [2] + [3] + [4] + [5] + [6] + [7] AS Part1
FROM (
    SELECT TOP 8 ROW_NUMBER() OVER (ORDER BY (SELECT 0)) - 1 AS SeqNr
    ,      SUBSTRING(Hash, 8, 1) AS Val
    FROM ##Hashes 
) T
PIVOT (
    MAX(Val) FOR SeqNr IN ([0], [1], [2], [3], [4], [5], [6], [7])
) PVT



SELECT [0] + [1] + [2] + [3] + [4] + [5] + [6] + [7] AS Part2
FROM (
    SELECT SUBSTRING(Hash, 8, 1) AS SeqNr
    ,      FIRST_VALUE(SUBSTRING(Hash, 9, 1)) OVER (PARTITION BY SUBSTRING(Hash, 8, 1) ORDER BY Cnter) AS Val
    FROM ##Hashes 
    WHERE SUBSTRING(Hash, 8, 1) BETWEEN '0' AND '7'
) T
PIVOT (
    MAX(Val) FOR SeqNr IN ([0], [1], [2], [3], [4], [5], [6], [7])
) PVT

DROP TABLE ##Hashes

--Runtime 00:15:35
