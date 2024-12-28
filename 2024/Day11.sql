USE Test_WME

SET NOCOUNT ON

DECLARE @year VARCHAR(4) = '2024'
DECLARE @day VARCHAR(2)  = '11'

EXEC dbo.GetInput @year = @year, @day = @day
EXEC dbo.ParseInput @year = @year, @day = @day 

--SELECT TOP 10 * FROM ##Input
--SELECT TOP 10 * FROM ##InputInts
--SELECT TOP 10 * FROM ##InputNumbered
--SELECT TOP 10 * FROM ##InputGrid
--SELECT TOP 10 * FROM ##InputSplit
--SELECT TOP 10 * FROM ##InputSplitCust

--SELECT * FROM ##InputSplit

/*
CREATE TABLE ##Loop (ID INT IDENTITY(0,1), Piece BIGINT, Status CHAR)

INSERT ##Loop (Piece)
SELECT Piece FROM ##InputSplit

DECLARE @NrOfPieces INT

--SELECT * FROM ##Loop

DECLARE @I INT = 0

WHILE @I < 25
BEGIN

    UPDATE ##Loop
    SET Status = CASE WHEN LEN(CAST(Piece AS VARCHAR(50))) % 2 = 0 THEN 'S'
                      WHEN Piece = 0 THEN '0'
                      ELSE 'Y'
                      END

    UPDATE ##Loop
    SET Piece = CASE WHEN Status = '0' THEN 1 ELSE Piece * 2024 END
    WHERE Status IN ('0', 'Y')

    INSERT ##Loop (Piece)
    SELECT RIGHT(Piece, LEN(Piece) / 2)
    FROM ##Loop
    WHERE Status = 'S'

    UPDATE ##Loop
    SET Piece = LEFT(Piece, LEN(Piece) / 2)
    WHERE Status = 'S'

    --SELECT @NrOfPieces = COUNT(1) FROM ##Loop
    --PRINT 'Iteration: ' + CAST(@I AS VARCHAR(2)) + ' at ' + CAST(GETDATE() AS VARCHAR(50)) + ' with ' + CAST(@NrOfPieces AS VARCHAR(10)) + ' stones'

    SET @I = @I + 1
END

SELECT COUNT(1) AS Part1 FROM ##Loop

*/

CREATE TABLE ##Loop25 (ID INT IDENTITY(1,1), Piece BIGINT, Cnt BIGINT, Status CHAR)
CREATE TABLE ##TempLoop25 (ID INT IDENTITY(1,1), Piece BIGINT, Cnt BIGINT)


INSERT ##Loop25 (Piece, Cnt) 
SELECT Piece, COUNT(1)
FROM ##InputSplit
GROUP BY Piece
ORDER BY Piece
--SELECT Piece, COUNT(1)
--FROM ##Loop
--GROUP BY Piece
--ORDER BY Piece

DECLARE @J INT = 0

--SELECT * FROM ##Loop25

WHILE @J < 75
BEGIN

    UPDATE ##Loop25
    SET Status = CASE WHEN LEN(CAST(Piece AS VARCHAR(50))) % 2 = 0 THEN 'S'
                      WHEN Piece = 0 THEN '0'
                      ELSE 'Y'
                      END

    INSERT ##TempLoop25 (Piece, Cnt)
    SELECT LEFT(Piece, LEN(Piece) / 2), Cnt
    FROM ##Loop25
    WHERE Status = 'S'
    UNION ALL
    SELECT RIGHT(Piece, LEN(Piece) / 2), Cnt
    FROM ##Loop25
    WHERE Status = 'S'
    
    INSERT ##TempLoop25 (Piece, Cnt)
    SELECT 1, Cnt
    FROM ##Loop25
    WHERE Status = '0'

    INSERT ##TempLoop25 (Piece, Cnt)
    SELECT Piece * 2024, Cnt
    FROM ##Loop25
    WHERE Status = 'Y'

    DELETE FROM ##Loop25

    INSERT ##Loop25 (Piece, Cnt)
    SELECT Piece, SUM(Cnt)
    FROM ##TempLoop25
    GROUP BY Piece

    DELETE FROM ##TempLoop25

    IF @J = 25 SELECT SUM(Cnt) AS Part1 FROM ##Loop25 

    SET @J = @J + 1

--    SELECT * FROM ##Loop25
END

SELECT SUM(Cnt) AS Part2 
FROM ##Loop25 

--165704753602551 Too low


/*

DROP TABLE ##Loop
DROP TABLE ##Loop25
DROP TABLE ##TempLoop25

*/

