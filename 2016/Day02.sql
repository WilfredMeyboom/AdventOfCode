use Test_WME

SET NOCOUNT ON

CREATE TABLE ##Input (Line NVARCHAR(MAX));

BULK INSERT ##Input
FROM 'D:\Wilfred\AdventOfCode\2016\input02.txt'
WITH (ROWTERMINATOR = '0x0A');

SELECT * FROM ##Input

--DELETE FROM ##Input
--INSERT ##Input VALUES ('ULL'),('RRDDD'),('LURDL'),('UUUUD')

CREATE TABLE ##Directions (ID INT IDENTITY(1,1), LineNr INT, InstrNr INT, Direction CHAR(1))

;WITH cte_Directions AS (
    SELECT ROW_NUMBER() OVER (ORDER BY (SELECT 0)) AS LineNr
    ,      1 AS InstrNr
    ,      LEFT(Line, 1) AS Direction
    ,      SUBSTRING(Line, 2, LEN(Line)) AS Remainder
    ,      LEN(Line) AS LineLength
    FROM ##Input
    UNION ALL 
    SELECT LineNr
    ,      InstrNr + 1
    ,      LEFT(Remainder,1)
    ,      SUBSTRING(Remainder, 2, LEN(Remainder)) 
    ,      LineLength
    FROM cte_Directions
    WHERE LEN(Remainder) > 0
    
)
INSERT ##Directions (LineNr, InstrNr, Direction)
SELECT LineNr, InstrNr, Direction FROM cte_Directions OPTION (MAXRECURSION 10000)


--SELECT * FROM ##Directions ORDER BY LineNr, InstrNr

DECLARE @LineNr INT
DECLARE @InstrNr INT
DECLARE @Direction CHAR(1)
DECLARE @PreviousLineNr INT = 1
DECLARE @XPos INT = -2
DECLARE @YPos INT = 0

DECLARE @PrevXPos INT = -2 
DECLARE @PrevYPos INT = 0

DECLARE DirectionCursor CURSOR 
FOR SELECT LineNr, InstrNr, Direction FROM ##Directions ORDER BY LineNr, InstrNr

OPEN DirectionCursor 

FETCH NEXT FROM DirectionCursor INTO @LineNr, @InstrNr, @Direction

WHILE @@FETCH_STATUS = 0 
BEGIN
    
    IF @LineNr <> @PreviousLineNr SELECT @PreviousLineNr, @XPos, @YPos

    SET @PrevXPos = @XPos
    SET @PrevYPos = @YPos

    IF @Direction = 'U' /*AND @YPos > 0*/ SET @Ypos = @YPos - 1
    IF @Direction = 'D' /*AND @YPos < 2*/ SET @Ypos = @YPos + 1
    IF @Direction = 'L' /*AND @XPos > 0*/ SET @Xpos = @XPos - 1
    IF @Direction = 'R' /*AND @XPos < 2*/ SET @Xpos = @XPos + 1

    IF (ABS(@XPos) + ABS(@YPos) > 2)
    BEGIN
        --Moved outside of grid, so move back
        SET @XPos = @PrevXPos 
        SET @YPos = @PrevYPos
    END

    SET @PreviousLineNr = @LineNr

    FETCH NEXT FROM DirectionCursor INTO @LineNr, @InstrNr, @Direction

END

SELECT @PreviousLineNr, @XPos, @YPos

CLOSE DirectionCursor 

DEALLOCATE DirectionCursor 

--32941 is wrong
--74921 is correct for part 1


/*

DROP TABLE ##Directions
DROP TABLE ##Input

*/

--A6B35