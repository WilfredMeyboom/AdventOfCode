USE Test_WME

SET NOCOUNT ON

/*
Rudolph can fly 22 km/s for  8 seconds, but then must rest for 165 seconds.
Cupid   can fly 8  km/s for 17 seconds, but then must rest for 114 seconds.
Prancer can fly 18 km/s for  6 seconds, but then must rest for 103 seconds.
Donner  can fly 25 km/s for  6 seconds, but then must rest for 145 seconds.
Dasher  can fly 11 km/s for 12 seconds, but then must rest for 125 seconds.
Comet   can fly 21 km/s for  6 seconds, but then must rest for 121 seconds.
Blitzen can fly 18 km/s for  3 seconds, but then must rest for 50  seconds.
Vixen   can fly 20 km/s for  4 seconds, but then must rest for 75  seconds.
Dancer  can fly 7  km/s for 20 seconds, but then must rest for 119 seconds.
*/

CREATE TABLE ##Deer (ID INT IDENTITY(1,1), Name VARCHAR(15), Speed INT, Duration INT, RestTime INT)

INSERT ##Deer (Name, Speed, Duration, RestTime) VALUES
('Rudolph', 22,  8, 165),
('Cupid  ', 8 , 17, 114),
('Prancer', 18,  6, 103),
('Donner ', 25,  6, 145),
('Dasher ', 11, 12, 125),
('Comet  ', 21,  6, 121),
('Blitzen', 18,  3, 50 ),
('Vixen  ', 20,  4, 75 ),
('Dancer ', 7 , 20, 119)


--INSERT ##Deer (Name, Speed, Duration, RestTime) VALUES
--('Comet_Exp', 14, 10, 127), ('Dancer_Exp', 16, 11, 162)


SELECT * FROM ##Deer

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


SELECT * FROM ##Race ORDER BY Distance

--2696 is correct for part 1

SELECT DeerID, COUNT(1)
FROM ##Leaderboard
GROUP BY DeerID
ORDER BY 2

--1084 is correct for part 2

DROP TABLE ##Deer
DROP TABLE ##Race
