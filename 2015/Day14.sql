USE Test_WME

SET NOCOUNT ON

DECLARE @year VARCHAR(4) = '2015'
DECLARE @day VARCHAR(2)  = '14'

EXEC dbo.GetInput @year = @year, @day = @day
EXEC dbo.ParseInput @year = @year, @day = @day


CREATE TABLE ##Deer (ID INT IDENTITY(1,1), Name VARCHAR(15), Speed INT, Duration INT, RestTime INT)

INSERT ##Deer (Name, Speed, Duration, RestTime) 
SELECT [1],[4],[7],[14] FROM (
    SELECT RowNr, PieceNr, Piece FROM ##InputSplit WHERE PieceNr IN (1,4,7,14)
) T
PIVOT (
    MAX(Piece) FOR PieceNr IN ([1],[4],[7],[14])
) PVT


CREATE TABLE ##Race(ID INT, Distance INT, IsRunning INT, RunningTime INT, RestingTime INT)

INSERT ##Race (ID, Distance, IsRunning, RunningTime, RestingTime)
SELECT ID, 0, 1, 0, 0
FROM ##Deer

DECLARE @Timer INT = 0

CREATE TABLE ##Leaderboard (ID INT IDENTITY, DeerID INT)

WHILE @Timer < 2503
BEGIN

    UPDATE R
    SET R.Distance = R.Distance + CASE WHEN R.IsRunning = 1 THEN D.Speed ELSE 0 END

    ,   R.IsRunning = CASE WHEN (R.RunningTime >= D.Duration - 1 AND R.IsRunning = 1) THEN 0
                           WHEN (R.RestingTime >= D.RestTime - 1 AND R.IsRunning = 0) THEN 1 
                           ELSE R.IsRunning END
    
    ,   R.RunningTime = CASE WHEN R.IsRunning = 1 THEN R.RunningTime + 1 ELSE 0 END
    ,   R.RestingTime = CASE WHEN R.IsRunning = 0 THEN R.RestingTime + 1 ELSE 0 END
    FROM ##Race R 
    INNER JOIN ##Deer D ON R.ID = D.ID

    ;WITH cte_MaxDist AS (
        SELECT MAX(Distance) AS MaxDist FROM ##Race   
    )
    INSERT ##Leaderboard (DeerID)
    SELECT ID
    FROM ##Race
    WHERE Distance = (SELECT MaxDist FROM cte_MaxDist)



    SET @Timer = @Timer + 1
END


SELECT TOP 1 Distance AS Part1
FROM ##Race 
ORDER BY Distance DESC

--2696 is correct for part 1

SELECT TOP 1 DeerID, COUNT(1) AS Part2
FROM ##Leaderboard
GROUP BY DeerID
ORDER BY 2 DESC

--1084 is correct for part 2

DROP TABLE ##Deer
DROP TABLE ##Race
DROP TABLE ##Leaderboard