
--SELECT LEFT(sys.fn_sqlvarbasetostr(HASHBYTES('MD5', 'abc5278568')), 7)


DECLARE @RoomID VARCHAR(10) = 'ojvtpuvg'
DECLARE @Counter BIGINT = 0


CREATE TABLE ##Hashes (ID INT IDENTITY(1,1), Counter BIGINT, Hash VARCHAR(50))

--1469591
--1925351

SET @Counter = 1469591
INSERT ##Hashes (Counter, Hash) VALUES (@Counter, sys.fn_sqlvarbasetostr(HASHBYTES('MD5', @RoomID + CAST(@Counter AS VARCHAR(15)))))
SET @Counter = 1925351
-- This counter will work but it will be added through the regular process
--INSERT ##Hashes (Counter, Hash) VALUES (@Counter, sys.fn_sqlvarbasetostr(HASHBYTES('MD5', @RoomID + CAST(@Counter AS VARCHAR(15)))))


WHILE (SELECT COUNT(DISTINCT SUBSTRING(Hash, 8, 1)) FROM ##Hashes WHERE SUBSTRING(Hash, 8, 1) IN ('0','1','2','3','4','5','6','7')) < 8
BEGIN

    IF (SELECT LEFT(sys.fn_sqlvarbasetostr(HASHBYTES('MD5', @RoomID + CAST(@Counter AS VARCHAR(15)))), 7)) = '0x00000'
    BEGIN
        PRINT 'Correct hash found at ' + CAST(GETDATE() AS VARCHAR(20)) + ' with counter at ' + CAST(@Counter AS VARCHAR(15))
       
        INSERT ##Hashes (Counter, Hash) VALUES (@Counter, sys.fn_sqlvarbasetostr(HASHBYTES('MD5', @RoomID + CAST(@Counter AS VARCHAR(15)))))

    END

    SET @Counter = @Counter + 1
END

SELECT *, SUBSTRING(Hash, 8, 1), SUBSTRING(Hash, 9, 1) FROM ##Hashes ORDER BY SUBSTRING(Hash, 8, 1), Counter


--DROP TABLE ##Hashes

--4543c154 is correct for part 1


--1050cbbd is correct for part 2
