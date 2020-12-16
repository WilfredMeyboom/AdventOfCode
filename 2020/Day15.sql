DECLARE @Input VARCHAR(100) = '11,18,0,20,1,7,16'

--SET @Input = '0,3,6'

SET NOCOUNT ON

CREATE TABLE ##Nrs (ID BIGINT IDENTITY, Nr BIGINT)

CREATE INDEX Ind_Nr ON ##Nrs(Nr)

INSERT ##Nrs (Nr)
SELECT value
FROM string_split(@Input,',')

DECLARE @LastNr BIGINT
DECLARE @ListLen BIGINT
DECLARE @NextNr BIGINT

SELECT TOP (1) @ListLen = ID, @LastNr = Nr FROM ##Nrs ORDER BY ID DESC



WHILE @ListLen < 30000000--2020
BEGIN

    IF (SELECT COUNT(1) FROM ##Nrs WHERE Nr = @LastNr) = 1
        SET @NextNr = 0
    ELSE (SELECT @NextNr = @ListLen - MAX(ID) FROM ##Nrs WHERE Nr = @LastNr AND ID <> @ListLen)

    INSERT ##Nrs (Nr) VALUES (@NextNr)

    SET @ListLen = @ListLen + 1

    SET @LastNr = @NextNr

    IF @ListLen % 100000 = 0 PRINT 'Listlen = ' + CAST(@ListLen AS VARCHAR(20)) + ' at ' + CAST(GETDATE() AS VARCHAR(50))
END

SELECT TOP 10 * FROM ##Nrs ORDER BY ID DESC

--639 is correct for part 1

--DROP TABLE ##Nrs

--30.000.000