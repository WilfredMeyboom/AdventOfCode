USE Test_WME

SET NOCOUNT ON

CREATE TABLE ##Input (Line NVARCHAR(MAX));

BULK INSERT ##Input
FROM 'D:\Wilfred\AdventOfCode\2017\input13.txt'
WITH (ROWTERMINATOR = '0x0A');


CREATE TABLE ##FireWall (ID INT IDENTITY, Layer INT, Depth INT, ScannerPos INT, ScannerDirection INT)

INSERT ##FireWall (Layer, Depth, ScannerPos, ScannerDirection)
SELECT LEFT(Line, CHARINDEX(':', Line) -1)
,      SUBSTRING(Line, CHARINDEX(':', Line) +1, LEN(Line))
,      0
,      1
FROM ##Input

--SELECT * FROM ##FireWall

DECLARE @StartingPos INT = -14799
DECLARE @Pos INT = -1
DECLARE @MaxLayer INT = 0
DECLARE @Severity INT = 0
DECLARE @Caught BIT = 1

SELECT @MaxLayer = Max(Layer) FROM ##FireWall


WHILE @Caught = 1
BEGIN
    
    SET @Pos = @StartingPos
    SET @Caught = 0

    UPDATE ##FireWall
    SET ScannerPos = 0
    ,   ScannerDirection = 1

    WHILE @Pos <= @MaxLayer AND @Caught = 0
    BEGIN

        SET @Pos = @Pos + 1

        IF EXISTS (SELECT 1 FROM ##FireWall WHERE @Pos = Layer AND ScannerPos = 0) 
        BEGIN

            PRINT 'CAUGHT at layer ' + CAST(@Pos AS VARCHAR(3)) + ' with Starting position ' + CAST(@StartingPos AS VARCHAR(10))

            --SELECT @Severity = @Severity + Layer * Depth FROM ##FireWall WHERE Layer = @Pos

            SET @Caught = 1
        END

        UPDATE F
        SET F.ScannerPos = F.ScannerPos + F.ScannerDirection
        ,   F.ScannerDirection = F.ScannerDirection * CASE WHEN F.ScannerPos + F.ScannerDirection = F.Depth - 1 OR F.ScannerPos + F.ScannerDirection = 0 THEN -1 ELSE 1 END
        FROM ##FireWall F

    END

    IF @Caught = 1 SET @StartingPos = @StartingPos - 8
    IF (@StartingPos -1) % 12 = 0 SET @StartingPos = @StartingPos - 8
    IF (@StartingPos -1) % 3 = 0 SET @StartingPos = @StartingPos - 8

END

--SELECT @Severity--, @Pos

SELECT @StartingPos, @Pos, @Caught, @MaxLayer, @Severity
SELECT -1 - @StartingPos

/*

DROP TABLE ##FireWall
DROP TABLE ##Input

*/

--Part 1 3514 Too high
--Part 1 1728 Correct
--Part 2 10000 Too low
--Part 2 100000 Too low
--Part 2 300000 Too low

--Als alternatief, als ik nou een giga tabel maak met daarin alle scannerpos op een bepaalde tijd
--Vervolgens kan ik die gebruiken om allemaal invalide starttijden te bepalen

DECLARE @Timer BIGINT = 0

CREATE TABLE ScannerPositions (ID BIGINT IDENTITY(1,1), Timer BIGINT, Layer INT, ScannerPos INT)

WHILE @Timer < 10000000
BEGIN

    INSERT ScannerPositions(Timer, Layer, ScannerPos)
    SELECT @Timer, Layer, ScannerPos
    FROM ##FireWall

    UPDATE F
    SET F.ScannerPos = F.ScannerPos + F.ScannerDirection
    ,   F.ScannerDirection = F.ScannerDirection * CASE WHEN F.ScannerPos + F.ScannerDirection = F.Depth - 1 OR F.ScannerPos + F.ScannerDirection = 0 THEN -1 ELSE 1 END
    FROM ##FireWall F
    
    SET @Timer = @Timer + 1
END


SELECT COUNT(*) FROM ScannerPositions

--DROP TABLE ScannerPositions
--DROP TABLE Results

SELECT DISTINCT Timer - Layer AS InvalidTime
INTO Results
FROM ScannerPositions WHERE ScannerPos = 0


ALTER TABLE Results ADD OneUp INT

UPDATE Results
SET OneUp = InvalidTime + 1

SELECT *
FROM Results R
LEFT JOIN Results R1 ON R.InvalidTime = R1.OneUp
WHERE R1.InvalidTime IS NULL
AND R.InvalidTime > 0

/*
3946839	3946840	NULL	NULL
5388279	5388280	NULL	NULL
6829719	6829720	NULL	NULL
8271159	8271160	NULL	NULL
9712599	9712600	NULL	NULL
9999991	9999992	NULL	NULL

*/

SELECT * FROM ScannerPositions WHERE Timer = 3946840
SELECT * FROM ScannerPositions WHERE Timer - Layer = 3946838 --> CORRECT!

DROP TABLE ##FireWall
DROP TABLE ScannerPositions
DROP TABLE Results
DROP TABLE ##Input