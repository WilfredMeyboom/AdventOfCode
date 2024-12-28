USE Test_WME

SET NOCOUNT ON

DECLARE @year VARCHAR(4) = '2024'
DECLARE @day VARCHAR(2)  = '15'

EXEC dbo.GetInput @year = @year, @day = @day
EXEC dbo.ParseInput @year = @year, @day = @day 

--SELECT TOP 10 * FROM ##Input
--SELECT TOP 10 * FROM ##InputInts
--SELECT TOP 10 * FROM ##InputNumbered
--SELECT TOP 10 * FROM ##InputGrid
--SELECT TOP 10 * FROM ##InputSplit
--SELECT TOP 10 * FROM ##InputSplitCust

-- Determine at which point the input needs to be split
DECLARE @SplitRow INT
SELECT @SplitRow = RowNr FROM ##InputGrid WHERE Val IS NULL

PRINT 'Splitrow is at ' + CAST(@SplitRow AS VARCHAR(10))

-- Extract the grid from the input
CREATE TABLE ##Grid (ID INT IDENTITY(1,1), RowNr INT, ColNr INT, Val CHAR(1))
INSERT ##Grid (RowNr, ColNr, Val)
SELECT RowNr, ColNr, Val FROM ##InputGrid WHERE RowNr < @SplitRow ORDER BY RowNr, ColNr 
CREATE UNIQUE INDEX IX_Grid ON ##Grid(RowNr, ColNr)

-- Extract the instructions from the input
CREATE TABLE ##Instr (ID INT IDENTITY(1,1), InstrNr INT, Val CHAR(1))
INSERT ##Instr (InstrNr, Val)
SELECT ROW_NUMBER() OVER (ORDER BY RowNr, ColNr), Val FROM ##InputGrid WHERE RowNr > @SplitRow ORDER BY RowNr, ColNr

CREATE TABLE ##Boxes (ID INT IDENTITY(1,1), RowNr INT , ColNr INT, Val CHAR(1))

DECLARE @RowNr INT
DECLARE @ColNr INT
DECLARE @DeltaRowNr INT
DECLARE @DeltaColNr INT
DECLARE @NextPosToMoveTo CHAR(1)

-- Get the starting position of the robot
SELECT @ColNr = ColNr, @RowNr = RowNr FROM ##Grid WHERE Val = '@'

-- Remove the robot from the grid
UPDATE ##Grid 
SET Val = '.'
WHERE Val = '@'

--Retrieve the first instruction
DECLARE @InstrNr INT = 1
DECLARE @Instr CHAR 

SELECT @Instr = Val FROM ##Instr WHERE InstrNr = @InstrNr

DECLARE @MaxCnt INT = 0
SELECT @MaxCnt = COUNT(1) FROM ##Instr

DECLARE @DoPart1 INT = 0

IF @DoPart1 > 0
BEGIN

    WHILE @InstrNr <  @MaxCnt
    BEGIN

        -- In what direction wants the robot to move?
        SET @DeltaColNr = 0
        SET @DeltaRowNr = 0

        IF @Instr = '^' SET @DeltaRowNr = -1
        IF @Instr = 'v' SET @DeltaRowNr = 1
        IF @Instr = '<' SET @DeltaColNr = -1
        IF @Instr = '>' SET @DeltaColNr = 1

        -- What is at that position (empty, wall or box)
        SELECT @NextPosToMoveTo = Val FROM ##Grid WHERE RowNr = @RowNr + @DeltaRowNr AND ColNr = @ColNr + @DeltaColNr

        -- Debug info
        --SELECT @InstrNr AS Iter, @RowNr AS R, @ColNr AS C, *, @Instr AS I, @NextPosToMoveTo AS NPos FROM ##Grid

        IF @NextPosToMoveTo = 'O'
        BEGIN

             INSERT ##Boxes (RowNr, ColNr) 
             VALUES (@RowNr + @DeltaRowNr, @ColNr + @DeltaColNr)

             WHILE @NextPosToMoveTo = 'O'
             BEGIN

                SELECT @NextPosToMoveTo = Val 
                FROM ##Grid G
                INNER JOIN ##Boxes B ON G.RowNr = B.RowNr + @DeltaRowNr AND G.ColNr = B.ColNr + @DeltaColNr
                WHERE B.ID = (SELECT MAX(ID) FROM ##Boxes)

                IF @NextPosToMoveTo = 'O'
                    INSERT ##Boxes (RowNr, ColNr)
                    SELECT B.RowNr + @DeltaRowNr, B.ColNr + @DeltaColNr
                    FROM ##Boxes B
                    WHERE B.ID = (SELECT MAX(ID) FROM ##Boxes)

             END

        END

        IF @NextPosToMoveTo = '.'
        BEGIN
            SET @ColNr = @ColNr + @DeltaColNr
            SET @RowNr = @RowNr + @DeltaRowNr

            IF EXISTS(SELECT 1 FROM ##Boxes)
            BEGIN

                UPDATE G
                SET Val = '.'
                FROM ##Grid G
                INNER JOIN ##Boxes B ON G.RowNr = B.RowNr AND G.ColNr = B.ColNr
                WHERE B.ID = (SELECT MIN(ID) FROM ##Boxes)

                UPDATE G
                SET Val = 'O'
                FROM ##Grid G
                INNER JOIN ##Boxes B ON G.RowNr = B.RowNr + @DeltaRowNr AND G.ColNr = B.ColNr + @DeltaColNr
                WHERE B.ID = (SELECT MAX(ID) FROM ##Boxes)

                DELETE FROM ##Boxes

            END


        END

        IF @NextPosToMoveTo = '#' DELETE FROM ##Boxes

        SET @InstrNr = @InstrNr + 1
        SELECT @Instr = Val FROM ##Instr WHERE InstrNr = @InstrNr

        IF @InstrNr % 100 = 0 PRINT 'Iteration: ' + CAST(@InstrNr AS VARCHAR(10)) + ' at: ' + CAST(GETDATE() AS VARCHAR(50))

    END

    SELECT SUM(RowNr * 100 + ColNr) AS Part1 FROM ##Grid WHERE Val = 'O'

--SELECT * FROM ##Grid 
END --End of Part 1


CREATE TABLE ##Grid2 (ID INT IDENTITY(1,1), RowNr INT, ColNr INT, Val CHAR(1))

INSERT ##Grid2 (RowNr, ColNr, Val)
SELECT RowNr
,      CASE WHEN Dbl.S = 'L' THEN ColNr*2 
                             ELSE ColNr*2+1 
       END
,      CASE WHEN Dbl.S = 'L' AND Val = 'O' THEN '[' 
            WHEN Dbl.S = 'R' AND Val = 'O' THEN ']' 
            WHEN Dbl.S = 'R' AND Val = '@' THEN '.'
            ELSE Val END
FROM ##InputGrid 
CROSS APPLY (SELECT 'L' AS S UNION SELECT 'R' AS S) Dbl --Double the grid in size in the length
WHERE RowNr < @SplitRow 
ORDER BY RowNr, ColNr 

CREATE UNIQUE INDEX IX_Grid ON ##Grid2(RowNr, ColNr)

-- Get the starting position of the robot
SELECT @ColNr = ColNr, @RowNr = RowNr FROM ##Grid2 WHERE Val = '@'

-- Remove the robot from the grid
UPDATE ##Grid2 
SET Val = '.'
WHERE Val = '@'

DECLARE @AllBoxesPrepared INT = 0

--SET @MaxCnt = 200

WHILE @InstrNr <  @MaxCnt
BEGIN

    -- In what direction wants the robot to move?
    SET @DeltaColNr = 0
    SET @DeltaRowNr = 0

    IF @Instr = '^' SET @DeltaRowNr = -1
    IF @Instr = 'v' SET @DeltaRowNr = 1
    IF @Instr = '<' SET @DeltaColNr = -1
    IF @Instr = '>' SET @DeltaColNr = 1

    -- What is at that position (empty, wall or box)
    SELECT @NextPosToMoveTo = Val FROM ##Grid2 WHERE RowNr = @RowNr + @DeltaRowNr AND ColNr = @ColNr + @DeltaColNr

    -- Debug info
    --IF @NextPosToMoveTo IN ('[',']') AND @InstrNr > 175
    --    SELECT @InstrNr AS Iter, @RowNr AS R, @ColNr AS C, *, @Instr AS I, @NextPosToMoveTo AS NPos FROM ##Grid2 ORDER BY RowNr, ColNr

    IF @NextPosToMoveTo IN ('[', ']')
    BEGIN

            INSERT ##Boxes (RowNr, ColNr, Val) 
            VALUES (@RowNr + @DeltaRowNr, @ColNr + @DeltaColNr, @NextPosToMoveTo)

            -- Add the other half of the box
            IF @NextPosToMoveTo = '['
                INSERT ##Boxes (RowNr, ColNr, Val) 
                VALUES (@RowNr + @DeltaRowNr, @ColNr + @DeltaColNr + 1,']')
            IF @NextPosToMoveTo = ']'
                INSERT ##Boxes (RowNr, ColNr, Val) 
                VALUES (@RowNr + @DeltaRowNr, @ColNr + @DeltaColNr - 1,'[')
            
            SET @AllBoxesPrepared = 0

            WHILE @AllBoxesPrepared = 0
            BEGIN

                IF @Instr IN ('<','>')
                BEGIN
                    SELECT @NextPosToMoveTo = G.Val 
                    FROM ##Grid2 G
                    INNER JOIN ##Boxes B ON G.RowNr = B.RowNr + @DeltaRowNr AND G.ColNr = B.ColNr + @DeltaColNr
                    WHERE B.ID = (SELECT MAX(ID) FROM ##Boxes)
                    
                    IF @NextPosToMoveTo IN ('[',']')
                    BEGIN
                        INSERT ##Boxes (RowNr, ColNr, Val)
                        SELECT B.RowNr + @DeltaRowNr, B.ColNr + @DeltaColNr, @NextPosToMoveTo
                        FROM ##Boxes B
                        WHERE B.ID = (SELECT MAX(ID) FROM ##Boxes)

                    IF @NextPosToMoveTo = '['
                        INSERT ##Boxes (RowNr, ColNr, Val) 
                        SELECT B.RowNr + @DeltaRowNr, B.ColNr + @DeltaColNr, ']'
                        FROM ##Boxes B
                        WHERE B.ID = (SELECT MAX(ID) FROM ##Boxes)
                    IF @NextPosToMoveTo = ']'
                        INSERT ##Boxes (RowNr, ColNr, Val) 
                        SELECT B.RowNr + @DeltaRowNr, B.ColNr + @DeltaColNr, '['
                        FROM ##Boxes B
                        WHERE B.ID = (SELECT MAX(ID) FROM ##Boxes)
                    END

                    IF @NextPosToMoveTo IN ('.', '#') SET @AllBoxesPrepared = 1
                   
                END --ENDIF < > 
            
                IF @Instr IN ('^','v')
                BEGIN
                -- Let's do complex box analyzing

                    INSERT ##Boxes (RowNr, ColNr, Val)
                    SELECT G.RowNr, G.ColNr, G.Val
                    FROM ##Boxes B
                    INNER JOIN ##Grid2 G ON B.RowNr + @DeltaRowNr = G.RowNr AND B.ColNr + @DeltaColNr = G.ColNr
                    LEFT JOIN ##Boxes B2 ON B2.RowNr = G.RowNr AND B2.ColNr = G.ColNr
                    WHERE B2.ID IS NULL -- Don't look at boxes twice

                    IF EXISTS (SELECT 1 FROM ##Boxes WHERE Val = '#') 
                    BEGIN
                        SET @NextPosToMoveTo = '#'
                        SET @AllBoxesPrepared = 1
                    END
                    ELSE
                    BEGIN
                        --Missing box halves
                        INSERT ##Boxes (RowNr, ColNr, Val)
                        SELECT B.RowNr
                        ,      B.ColNr + CASE WHEN B.Val = '[' THEN 1 ELSE -1 END AS ColNr
                        ,      CASE WHEN B.Val = '[' THEN ']' ELSE '[' END AS Val
                        FROM ##Boxes B 
                        LEFT JOIN ##Boxes B2 ON (B.Val = '[' AND B2.Val = ']' AND B.RowNr = B2.RowNr AND B.ColNr = B2.ColNr - 1)
                                             OR (B.Val = ']' AND B2.Val = '[' AND B.RowNr = B2.RowNr AND B.ColNr = B2.ColNr + 1)
                        WHERE B2.ID IS NULL AND B.Val IN ('[',']')

                        --If we have a line with only dots, that's the free space and we can move
                        IF EXISTS (SELECT 1 FROM ##Boxes WHERE RowNr NOT IN (SELECT RowNr FROM ##Boxes WHERE Val = '[' GROUP BY RowNr))
                        BEGIN                            
                            SET @NextPosToMoveTo = '.'
                            SET @AllBoxesPrepared = 1
                        END
                        ELSE
                            DELETE FROM ##Boxes WHERE Val = '.'

                    END -- ENDIF blocked boxes
                END -- ENDIF ^ v
            END -- END While Boxes prepared
    END

    IF @NextPosToMoveTo = '.'
    BEGIN
        SET @ColNr = @ColNr + @DeltaColNr
        SET @RowNr = @RowNr + @DeltaRowNr

        IF EXISTS(SELECT 1 FROM ##Boxes)
        BEGIN

            UPDATE G
            SET Val = '.'
            FROM ##Grid2 G
            INNER JOIN ##Boxes B ON G.RowNr = B.RowNr AND G.ColNr = B.ColNr

            UPDATE G
            SET Val = B.Val
            FROM ##Grid2 G
            INNER JOIN ##Boxes B ON G.RowNr = B.RowNr + @DeltaRowNr AND G.ColNr = B.ColNr + @DeltaColNr
            WHERE B.Val IN ('[', ']')

            DELETE FROM ##Boxes

        END


    END

    IF @NextPosToMoveTo = '#' DELETE FROM ##Boxes

    SET @InstrNr = @InstrNr + 1
    SELECT @Instr = Val FROM ##Instr WHERE InstrNr = @InstrNr

    IF @InstrNr % 100 = 0 
        PRINT 'Iteration: ' + CAST(@InstrNr AS VARCHAR(10)) + ' at: ' + CAST(GETDATE() AS VARCHAR(50))

END

SELECT SUM(RowNr * 100 + ColNr) AS Part2 FROM ##Grid2 WHERE Val = '['


/*


DROP TABLE ##Boxes
DROP TABLE ##Grid
DROP TABLE ##Grid2
DROP TABLE ##Instr



*/


