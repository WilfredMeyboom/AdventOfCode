USE Test_WME

/*
Disc #1 has 13 positions; at time=0, it is at position 1.
Disc #2 has 19 positions; at time=0, it is at position 10.
Disc #3 has 3 positions; at time=0, it is at position 2.
Disc #4 has 7 positions; at time=0, it is at position 1.
Disc #5 has 5 positions; at time=0, it is at position 3.
Disc #6 has 17 positions; at time=0, it is at position 5.
*/

CREATE TABLE ##Positions (ID INT IDENTITY(1,1), Time INT, Disc INT, Size INT, Position INT)
INSERT ##Positions (Time, Disc, Size, Position) VALUES (0,1,13,1), (0,2,19,10), (0,3,3,2), (0,4,7,1), (0,5,5,3), (0,6,17,5)


CREATE UNIQUE INDEX UX_Position ON ##Positions (Time, Disc)

DECLARE @Time INT = 0

DECLARE @TimeSlotFound BIT = 0


WHILE @TimeSlotFound = 0
BEGIN
    
    INSERT ##Positions(Time, Disc, Size, Position)
    SELECT Time + 1, Disc, Size, (Position + 1) % Size
    FROM ##Positions
    WHERE Time = @Time

    IF EXISTS (
               SELECT * 
               FROM ##Positions D1
               INNER JOIN ##Positions D2 ON D2.Disc = 2 AND D2.Position = 0 AND D1.Time = D2.Time + 1
               INNER JOIN ##Positions D3 ON D3.Disc = 3 AND D3.Position = 0 AND D2.Time = D3.Time + 1
               INNER JOIN ##Positions D4 ON D4.Disc = 4 AND D4.Position = 0 AND D3.Time = D4.Time + 1
               INNER JOIN ##Positions D5 ON D5.Disc = 5 AND D5.Position = 0 AND D4.Time = D5.Time + 1
               INNER JOIN ##Positions D6 ON D6.Disc = 6 AND D6.Position = 0 AND D5.Time = D6.Time + 1
               WHERE D1.Disc = 1 AND D1.Position = 0
              ) SET @TimeSlotFound = 1

    SET @Time = @Time + 1

END

-- Na 2,5 uur hebben we 3 meetpunten. Dit is genoeg om te extrapoleren:
-- 376777 is goed voor deel 1

-- Part 2: start is hetzelfde als in deel 1 maar met 1 extra disc (11 positions, staat op 0 op t=0


--SELECT TOP 30 * FROM ##Positions WHERE Disc = 1 AND Position = 0 ORDER BY Time
--SELECT TOP 30 * FROM ##Positions WHERE Disc = 2 AND Position = 0 ORDER BY Time
--SELECT TOP 10 * 
--FROM ##Positions D1
--INNER JOIN ##Positions D2 ON D2.Disc = 2 AND D2.Position = 0 AND D1.Time = D2.Time + 1
--WHERE D1.Disc = 1 AND D1.Position = 0
--ORDER BY D1.Time


--Loop met disc 2: T = 9, 28, 47
--Check of andere discs aligned zijn
-- Van groot naar klein: 6, 1, 7, 4, 5, 3

DECLARE @TimeSlotFound BIT = 0
DECLARE @T INT = 9
SET @TimeSlotFound = 0

WHILE @TimeSlotFound = 0
BEGIN

/*
Disc #1 has 13 positions; at time=0, it is at position 1.
Disc #2 has 19 positions; at time=0, it is at position 10.
Disc #3 has 3 positions; at time=0, it is at position 2.
Disc #4 has 7 positions; at time=0, it is at position 1.
Disc #5 has 5 positions; at time=0, it is at position 3.
Disc #6 has 17 positions; at time=0, it is at position 5.
Disc #7 has 11 positions; at time=0, it is at position 0


Disc #1 has 5 positions; at time=0, it is at position 4.
Disc #2 has 2 positions; at time=0, it is at position 1.
*/

    IF (@T - 1 + 1) % 13 = 0 -- 1
        IF (@T + 1 + 2) %  3 = 0 -- 3
            IF (@T + 2 + 1) %  7 = 0 -- 4
                IF (@T + 3 + 3) %  5 = 0 -- 5
                    IF (@T + 4 + 5) % 17 = 0 -- 6
                        IF (@T + 5    ) % 11 = 0 -- 7
                            SET @TimeSlotFound = 1 

    SET @T = @T + 19

END

SET @T = @T - 19 -- Correct for last increment
SET @T = @T - 2  -- Correct for time stamp of second disc
PRINT @T


--3903937 is correct for part 2

/*

DROP TABLE ##Positions

*/


