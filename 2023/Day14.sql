USE Test_WME

SET NOCOUNT ON

DECLARE @year VARCHAR(4) = '2023'
DECLARE @day VARCHAR(2)  = '14'

EXEC dbo.GetInput @year = @year, @day = @day
EXEC dbo.ParseInput @year = @year, @day = @day 

--SELECT TOP 10 * FROM ##Input
--SELECT TOP 10 * FROM ##InputInts
--SELECT TOP 10 * FROM ##InputNumbered
--SELECT TOP 10 * FROM ##InputSplit
--SELECT TOP 10 * FROM ##InputSplitCust
  
CREATE UNIQUE INDEX IX_InputGrid_UQ ON ##InputGrid(RowNr,ColNr)

DECLARE @Count INT = 1

-- Tilt the grid one way (to the north)
WHILE @Count > 0
BEGIN
    
    -- Mark every space that is empty and directly north of a rock
    UPDATE I1
    SET I1.Val = 'X'
    FROM ##InputGrid I1
    INNER JOIN ##InputGrid I2 ON I1.RowNr = I2.RowNr - 1 AND I1.ColNr = I2.ColNr
    WHERE I1.Val = '.' AND I2.Val = 'O'

    -- Empty every space that has a rock and an empty space directly north of it
    UPDATE I1
    SET I1.Val = '.'
    FROM ##InputGrid I1
    INNER JOIN ##InputGrid I2 ON I1.RowNr = I2.RowNr + 1 AND I1.ColNr = I2.ColNr
    WHERE I1.Val = 'O' AND I2.Val = 'X'

    -- Change the earlier mark to a rock
    UPDATE I1
    SET I1.Val = 'O'
    FROM ##InputGrid I1
    WHERE I1.Val = 'X' 

    SET @Count = @@ROWCOUNT
END

DECLARE @MaxRowNr INT
SELECT @MaxRowNr = MAX(RowNr) FROM ##InputGrid
SELECT SUM(@MaxRowNr - RowNr + 1) AS Part1 FROM ##InputGrid WHERE Val = 'O'

-- We expect some kind of repetion in the results so prepare to store the result after each cycle
CREATE TABLE ##Result (ID INT IDENTITY, Result INT)

-- Move grid
-- First north, then west, then south, then east

DECLARE @Cycle INT = 0
DECLARE @NrOfBoulders INT

WHILE @Cycle < 200
BEGIN
    
    SET @Count = 1

    -- Tilt the grid to the north
    WHILE @Count > 0
    BEGIN
    
        UPDATE I1
        SET I1.Val = 'X'
        FROM ##InputGrid I1
        INNER JOIN ##InputGrid I2 ON I1.RowNr = I2.RowNr - 1 AND I1.ColNr = I2.ColNr
        WHERE I1.Val = '.' AND I2.Val = 'O'

        UPDATE I1
        SET I1.Val = '.'
        FROM ##InputGrid I1
        INNER JOIN ##InputGrid I2 ON I1.RowNr = I2.RowNr + 1 AND I1.ColNr = I2.ColNr
        WHERE I1.Val = 'O' AND I2.Val = 'X'

        UPDATE I1
        SET I1.Val = 'O'
        FROM ##InputGrid I1
        WHERE I1.Val = 'X' 

        SET @Count = @@ROWCOUNT
    END

    SET @Count = 1

    -- Tilt the grid to the west
    WHILE @Count > 0
    BEGIN
    
        UPDATE I1
        SET I1.Val = 'X'
        FROM ##InputGrid I1
        INNER JOIN ##InputGrid I2 ON I1.RowNr = I2.RowNr AND I1.ColNr = I2.ColNr - 1
        WHERE I1.Val = '.' AND I2.Val = 'O'

        UPDATE I1
        SET I1.Val = '.'
        FROM ##InputGrid I1
        INNER JOIN ##InputGrid I2 ON I1.RowNr = I2.RowNr AND I1.ColNr = I2.ColNr + 1
        WHERE I1.Val = 'O' AND I2.Val = 'X'

        UPDATE I1
        SET I1.Val = 'O'
        FROM ##InputGrid I1
        WHERE I1.Val = 'X' 

        SET @Count = @@ROWCOUNT
    END

    SET @Count = 1

    -- Tilt the grid to the south
    WHILE @Count > 0
    BEGIN
    
        UPDATE I1
        SET I1.Val = 'X'
        FROM ##InputGrid I1
        INNER JOIN ##InputGrid I2 ON I1.RowNr = I2.RowNr + 1 AND I1.ColNr = I2.ColNr
        WHERE I1.Val = '.' AND I2.Val = 'O'

        UPDATE I1
        SET I1.Val = '.'
        FROM ##InputGrid I1
        INNER JOIN ##InputGrid I2 ON I1.RowNr = I2.RowNr - 1 AND I1.ColNr = I2.ColNr
        WHERE I1.Val = 'O' AND I2.Val = 'X'

        UPDATE I1
        SET I1.Val = 'O'
        FROM ##InputGrid I1
        WHERE I1.Val = 'X' 

        SET @Count = @@ROWCOUNT
    END

    SET @Count = 1

    -- Tilt the grid to the east
    WHILE @Count > 0
    BEGIN
    
        UPDATE I1
        SET I1.Val = 'X'
        FROM ##InputGrid I1
        INNER JOIN ##InputGrid I2 ON I1.RowNr = I2.RowNr AND I1.ColNr = I2.ColNr + 1
        WHERE I1.Val = '.' AND I2.Val = 'O'

        UPDATE I1
        SET I1.Val = '.'
        FROM ##InputGrid I1
        INNER JOIN ##InputGrid I2 ON I1.RowNr = I2.RowNr AND I1.ColNr = I2.ColNr - 1
        WHERE I1.Val = 'O' AND I2.Val = 'X'

        UPDATE I1
        SET I1.Val = 'O'
        FROM ##InputGrid I1
        WHERE I1.Val = 'X' 

        SET @Count = @@ROWCOUNT
    END

    -- Store the result as if this was the end 
    INSERT ##Result (Result)
    SELECT SUM(@MaxRowNr - RowNr + 1) FROM ##InputGrid WHERE Val = 'O'

    SET @Cycle = @Cycle + 1

END

/*
-- Let's check if the solution starts repeating...

SELECT R2.ID - R1.ID, *
FROM ##Result R1
INNER JOIN ##Result R2 ON R1.Result = R2.Result AND R1.ID < R2.ID
ORDER BY R1.ID

-- Ah, yes, from iteration 153 and onward. The solutions repeat with a frequency of 26 solutions

*/

DECLARE @Target BIGINT = 1000000000 
DECLARE @Frequency INT = 26
DECLARE @Threshold INT = 153
DECLARE @SolutionID INT 

-- Reduce the target to the minimum value (= 12) then add the frequency enough times to increase the value to be above the threshold.
-- So solution ID = 168
SELECT @SolutionID = @Target % @Frequency + CEILING(1.0 * @Threshold / @Frequency) * @Frequency

SELECT Result AS Part2 FROM ##Result WHERE ID = @SolutionID
