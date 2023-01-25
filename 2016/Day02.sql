use Test_WME

SET NOCOUNT ON

DECLARE @year VARCHAR(4) = '2016'
DECLARE @day VARCHAR(2)  = '2'

EXEC dbo.GetInput @year = @year, @day = @day
EXEC dbo.ParseInput @year = @year, @day = @day 

--SELECT TOP 10 * FROM ##InputNumbered
--SELECT TOP 10 * FROM ##InputGrid
--SELECT TOP 10 * FROM ##InputInts
--SELECT TOP 10 * FROM ##InputSplit
--SELECT * FROM ##Input


CREATE TABLE ##KeyPad1 (ID INT IDENTITY(1,1), RowNr INT, ColNr INT, Val CHAR)
CREATE TABLE ##KeyPad2 (ID INT IDENTITY(1,1), RowNr INT, ColNr INT, Val CHAR)
INSERT ##KeyPad1 (ColNr, RowNr, Val) VALUES (-1,1,'1'), (0,1,'2'), (1,1,'3'), (-1,0,'4'), (0,0,'5'), (1,0,'6'), (-1,-1,'7'), (0,-1,'8'), (1,-1,'9')
INSERT ##KeyPad2 (ColNr, RowNr, Val) VALUES (0,2,'1'), (-1,1,'2'), (0,1,'3'), (1,1,'4'), (-2,0,'5'), (-1,0,'6'), (0,0,'7'), (1,0,'8'), (2,0,'9'), (-1,-1,'A'), (0,-1,'B'), (1,-1,'C'), (0,-2,'D')

DECLARE @LineNr INT
DECLARE @InstrNr INT
DECLARE @Direction CHAR(1)
DECLARE @PreviousLineNr INT = 0
DECLARE @XPos1 INT = 0
DECLARE @YPos1 INT = 0
DECLARE @XPos2 INT = -2
DECLARE @YPos2 INT = 0

DECLARE @PrevXPos1 INT
DECLARE @PrevYPos1 INT
DECLARE @PrevXPos2 INT
DECLARE @PrevYPos2 INT

DECLARE @Part1 VARCHAR(10) = ''
DECLARE @Part2 VARCHAR(10) = ''

DECLARE DirectionCursor CURSOR 
FOR SELECT RowNr, ColNr, Val FROM ##InputGrid ORDER BY RowNr, ColNr

OPEN DirectionCursor 

FETCH NEXT FROM DirectionCursor INTO @LineNr, @InstrNr, @Direction

WHILE @@FETCH_STATUS = 0 
BEGIN
    
    IF @LineNr <> @PreviousLineNr SELECT @Part1 = @Part1 + Val FROM ##KeyPad1 WHERE @XPos1 = ColNr AND @YPos1 = RowNr
    IF @LineNr <> @PreviousLineNr SELECT @Part2 = @Part2 + Val FROM ##KeyPad2 WHERE @XPos2 = ColNr AND @YPos2 = RowNr

    SET @PrevXPos1 = @XPos1
    SET @PrevYPos1 = @YPos1
    SET @PrevXPos2 = @XPos2
    SET @PrevYPos2 = @YPos2


    IF @Direction = 'U' BEGIN SET @Ypos1 = @YPos1 + 1 SET @Ypos2 = @YPos2 + 1 END
    IF @Direction = 'D' BEGIN SET @Ypos1 = @YPos1 - 1 SET @Ypos2 = @YPos2 - 1 END
    IF @Direction = 'L' BEGIN SET @Xpos1 = @XPos1 - 1 SET @Xpos2 = @XPos2 - 1 END
    IF @Direction = 'R' BEGIN SET @Xpos1 = @XPos1 + 1 SET @Xpos2 = @XPos2 + 1 END

    IF (ABS(@XPos1) > 1 OR ABS(@YPos1) > 1)
    BEGIN
        --Moved outside of grid, so move back
        SET @XPos1 = @PrevXPos1
        SET @YPos1 = @PrevYPos1
    END

    IF (ABS(@XPos2) + ABS(@YPos2) > 2)
    BEGIN
        --Moved outside of grid, so move back
        SET @XPos2 = @PrevXPos2
        SET @YPos2 = @PrevYPos2
    END

    SET @PreviousLineNr = @LineNr

    FETCH NEXT FROM DirectionCursor INTO @LineNr, @InstrNr, @Direction

END

--Don't forget the last digit
SELECT @Part1 = @Part1 + Val FROM ##KeyPad1 WHERE @XPos1 = ColNr AND @YPos1 = RowNr
SELECT @Part2 = @Part2 + Val FROM ##KeyPad2 WHERE @XPos2 = ColNr AND @YPos2 = RowNr

CLOSE DirectionCursor 

DEALLOCATE DirectionCursor 

SELECT @Part1 AS Part1
SELECT @Part2 AS Part2

DROP TABLE ##KeyPad1
DROP TABLE ##KeyPad2




