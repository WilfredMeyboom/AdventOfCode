USE Test_WME

/*
Disc #1 has 13 positions; at time=0, it is at position 1.
Disc #2 has 19 positions; at time=0, it is at position 10.
Disc #3 has 3 positions; at time=0, it is at position 2.
Disc #4 has 7 positions; at time=0, it is at position 1.
Disc #5 has 5 positions; at time=0, it is at position 3.
Disc #6 has 17 positions; at time=0, it is at position 5.

Part 2:
Disc #7 has 11 positions; at time=0, it is at position 0
*/


DECLARE @TimeSlotFound BIT = 0
DECLARE @T INT = 9 -- We'll be looping with the biggest disc (#2), it is in the right position if we start at T = 9
SET @TimeSlotFound = 0

WHILE @TimeSlotFound = 0
BEGIN

    IF (@T - 1 + 1) % 13 = 0                      -- Disc #1 Check, would it fall through with this starting time, ignoring all other discs
        IF (@T + 1 + 2) %  3 = 0                  -- Disc #3 Check, would it fall through with this starting time, ignoring all other discs
            IF (@T + 2 + 1) %  7 = 0              -- Disc #4 Check, would it fall through with this starting time, ignoring all other discs
                IF (@T + 3 + 3) %  5 = 0          -- Disc #5 Check, would it fall through with this starting time, ignoring all other discs
                    IF (@T + 4 + 5) % 17 = 0      -- Disc #6 Check, would it fall through with this starting time, ignoring all other discs
                        SET @TimeSlotFound = 1 

    IF @TimeSlotFound = 0 SET @T = @T + 19

END

SET @T = @T - 2  -- Correct for time stamp of second disc
SELECT @T AS Part1


SET @T = 9
SET @TimeSlotFound = 0

WHILE @TimeSlotFound = 0
BEGIN

    IF (@T - 1 + 1) % 13 = 0                     -- Disc #1 Check, would it fall through with this starting time, ignoring all other discs
        IF (@T + 1 + 2) %  3 = 0                 -- Disc #3 Check, would it fall through with this starting time, ignoring all other discs
            IF (@T + 2 + 1) %  7 = 0             -- Disc #4 Check, would it fall through with this starting time, ignoring all other discs
                IF (@T + 3 + 3) %  5 = 0         -- Disc #5 Check, would it fall through with this starting time, ignoring all other discs
                    IF (@T + 4 + 5) % 17 = 0     -- Disc #6 Check, would it fall through with this starting time, ignoring all other discs
                        IF (@T + 5    ) % 11 = 0 -- Disc #7 Check, would it fall through with this starting time, ignoring all other discs
                            SET @TimeSlotFound = 1 

    IF @TimeSlotFound = 0 SET @T = @T + 19

END

SET @T = @T - 2  -- Correct for time stamp of second disc
SELECT @T AS Part2

