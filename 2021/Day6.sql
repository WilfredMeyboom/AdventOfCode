USE Test_WME

SET NOCOUNT ON

DECLARE @year VARCHAR(4) = '2021'
DECLARE @day VARCHAR(2)  = '6'

EXEC dbo.GetInput @year = @year, @day = @day
EXEC dbo.ParseInput @year = @year, @day = @day 

SELECT TOP 10 * FROM ##InputNumbered
SELECT TOP 10 * FROM ##InputGrid
SELECT TOP 10 * FROM ##InputInts
SELECT TOP 10 * FROM ##InputSplit

CREATE TABLE ##FishCount (FishDays INT , FishCount BIGINT)


CREATE TABLE ##AggregateFish (Piece INT, Cnt BIGINT)

INSERT ##AggregateFish(Piece,Cnt)
SELECT Piece, COUNT(1) AS Cnt
FROM ##InputSplit GROUP BY Piece
UNION
SELECT 0,0
UNION
SELECT 6,0
UNION
SELECT 7,0
UNION
SELECT 8,0

--SELECT * FROM ##AggregateFish AF ORDER BY Piece

DECLARE @Days INT = 1
DECLARE @NewFish BIGINT = 0
WHILE @Days <= 256
BEGIN

    SELECT @NewFish = Cnt FROM ##AggregateFish AF WHERE Piece = 0

    UPDATE AF1
    SET AF1.Cnt = AF2.Cnt
    FROM ##AggregateFish AF1
    INNER JOIN ##AggregateFish AF2 ON AF1.Piece = AF2.Piece - 1

    UPDATE ##AggregateFish
    SET Cnt = CAST(Cnt + @NewFish AS BIGINT)
    WHERE Piece = 6

    UPDATE ##AggregateFish
    SET Cnt = @NewFish
    WHERE Piece = 8

    INSERT ##FishCount (FishDays, FishCount) SELECT @Days, SUM(Cnt) FROM ##AggregateFish AF

    SET @Days = @Days + 1
END

SELECT *, 'Part1' FROM ##FishCount FC WHERE FC.FishDays = 80
SELECT *, 'Part2' FROM ##FishCount FC WHERE FC.FishDays = 256

DROP TABLE ##FishCount
DROP TABLE ##AggregateFish