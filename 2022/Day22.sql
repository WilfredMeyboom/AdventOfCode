USE Test_WME

SET NOCOUNT ON

DECLARE @year VARCHAR(4) = '2022'
DECLARE @day VARCHAR(2)  = '22'

EXEC dbo.GetInput @year = @year, @day = @day
EXEC dbo.ParseInput @year = @year, @day = @day 

--SELECT TOP 10 * FROM ##Input
--SELECT TOP 10 * FROM ##InputInts
--SELECT TOP 10 * FROM ##InputNumbered
--SELECT TOP 1000 * FROM ##InputGrid
--SELECT TOP 10 * FROM ##InputSplit
--SELECT TOP 10 * FROM ##InputSplitCust
  


CREATE TABLE ##Grid (ID INT IDENTITY(1,1), RowNr INT, ColNr INT, Val CHAR, Visited INT)
CREATE UNIQUE INDEX uq_Grid ON ##Grid (RowNr, ColNr)

INSERT ##Grid
(
    RowNr,
    ColNr,
    Val,
    Visited
)
SELECT RowNr + 1, ColNr + 1, Val, 0
FROM ##InputGrid
WHERE Val IN ('.','#')

DECLARE @MoveStr VARCHAR(MAX)

SELECT @MoveStr = Line
FROM ##InputNumbered
WHERE TRY_CAST(LEFT(Line,1) AS INT) IS NOT NULL

DECLARE @RowPos INT
DECLARE @ColPos INT
DECLARE @Facing INT = 0

SELECT @RowPos = MIN(RowNr) FROM ##Grid G
SELECT @ColPos = MIN(ColNr) FROM ##Grid G WHERE RowNr = @RowPos

DECLARE @Dist INT
DECLARE @Turn CHAR
DECLARE @NextRowPos INT = @RowPos
DECLARE @NextColPos INT = @ColPos

WHILE LEN(@MoveStr) > 0
BEGIN

    -- Determine next move
    IF CHARINDEX('L', @MoveStr) > 0 AND CHARINDEX('R', @MoveStr) > 0
    BEGIN
        IF CHARINDEX('L', @MoveStr) < CHARINDEX('R', @MoveStr) 
        BEGIN
            SET @Dist = LEFT(@MoveStr, CHARINDEX('L', @MoveStr) - 1)
            SET @Turn = 'L'
            SET @MoveStr = SUBSTRING(@MoveStr, CHARINDEX('L', @MoveStr) + 1, LEN(@MoveStr))
        END
        ELSE
        BEGIN
            SET @Dist = LEFT(@MoveStr, CHARINDEX('R', @MoveStr) - 1)
            SET @Turn = 'R'
            SET @MoveStr = SUBSTRING(@MoveStr, CHARINDEX('R', @MoveStr) + 1, LEN(@MoveStr))    
        END
    END
    ELSE
    BEGIN
        -- In the leftover string there are no L's or no R's left
        IF CHARINDEX('L', @MoveStr) > 0
        BEGIN 
            SET @Dist = LEFT(@MoveStr, CHARINDEX('L', @MoveStr) - 1)
            SET @Turn = 'L'
            SET @MoveStr = SUBSTRING(@MoveStr, CHARINDEX('L', @MoveStr) + 1, LEN(@MoveStr))
        END
        ELSE IF CHARINDEX('R', @MoveStr) > 0
        BEGIN
            SET @Dist = LEFT(@MoveStr, CHARINDEX('R', @MoveStr) - 1)
            SET @Turn = 'R'
            SET @MoveStr = SUBSTRING(@MoveStr, CHARINDEX('R', @MoveStr) + 1, LEN(@MoveStr))    
        END
        ELSE
        BEGIN
            SET @Dist = @MoveStr
            SET @Turn = ''
            SET @MoveStr = ''
        END
    END

    WHILE @Dist > 0
    BEGIN
        
        IF @Facing = 0 BEGIN SET @NextColPos = @ColPos + 1 SET @NextRowPos = @RowPos END
        IF @Facing = 1 BEGIN SET @NextRowPos = @RowPos + 1 SET @NextColPos = @ColPos END
        IF @Facing = 2 BEGIN SET @NextColPos = @ColPos - 1 SET @NextRowPos = @RowPos END
        IF @Facing = 3 BEGIN SET @NextRowPos = @RowPos - 1 SET @NextColPos = @ColPos END

        IF NOT EXISTS (SELECT 1 FROM ##Grid G WHERE RowNr = @NextRowPos AND ColNr = @NextColPos)
        BEGIN
            -- Wrap around
            IF @Facing = 0 SELECT @NextColPos = MIN(ColNr) FROM ##Grid WHERE RowNr = @NextRowPos
            IF @Facing = 1 SELECT @NextRowPos = MIN(RowNr) FROM ##Grid WHERE ColNr = @NextColPos
            IF @Facing = 2 SELECT @NextColPos = MAX(ColNr) FROM ##Grid WHERE RowNr = @NextRowPos
            IF @Facing = 3 SELECT @NextRowPos = MAX(RowNr) FROM ##Grid WHERE ColNr = @NextColPos
        END

        IF (SELECT Val FROM ##Grid G WHERE RowNr = @NextRowPos AND ColNr = @NextColPos) = '#'
        BEGIN
            -- Ran into a wall
            SET @Dist = 0
        END
        ELSE
        BEGIN
            -- Move
            SET @RowPos = @NextRowPos
            SET @ColPos = @NextColPos
            SET @Dist = @Dist - 1
            
        END
        
    END

        -- Movement done, let's turn
        IF @Turn <> '' SET @Facing = CASE WHEN @Turn = 'R' THEN (@Facing + 1) % 4 ELSE (@Facing + 3) % 4 END

END

SELECT 1000*@RowPos + 4*@ColPos + @Facing AS Part1

CREATE TABLE ##Conversion (ID INT, Edg VARCHAR(2), 
                           FromStartRow INT, FromEndRow INT, FromStartCol INT, FromEndCol INT,
                           ToStartRow INT, ToEndRow INT, ToStartCol INT, ToEndCol INT,
                           FromFacing INT, ToFacing INT, InverseDir INT)

INSERT ##Conversion
(
    ID,
    Edg,
    FromStartRow,
    FromEndRow,
    FromStartCol,
    FromEndCol,
    FromFacing
)
SELECT 1 AS Nr, 'AB' AS Edg, 1 AS StartRow, 1 AS EndRow, 51 AS StartCol, 100 AS EndCol, 3 AS Facing  UNION
SELECT 2 AS Nr, 'BC' AS Edg, 1, 1, 101, 150, 3 UNION
SELECT 3 AS Nr, 'AD' AS Edg, 1, 50, 51, 51, 2 UNION
SELECT 4 AS Nr, 'DF' AS Edg, 51, 100, 51, 51, 2 UNION
SELECT 5 AS Nr, 'CH' AS Edg, 1, 50, 150, 150, 0 UNION
SELECT 6 AS Nr, 'EH' AS Edg, 50, 50, 101, 150, 1 UNION
SELECT 7 AS Nr, 'EH' AS Edg, 51, 100, 100, 100, 0 UNION
SELECT 8 AS Nr, 'CH' AS Edg, 101, 150, 100, 100, 0 UNION
SELECT 9 AS Nr, 'CG' AS Edg, 150, 150, 51, 100, 1 UNION
SELECT 10 AS Nr, 'CG' AS Edg, 151, 200, 50, 50, 0 UNION
SELECT 11 AS Nr, 'BC' AS Edg, 200, 200, 1, 50, 1 UNION
SELECT 12 AS Nr, 'AD' AS Edg, 101, 150, 1, 1, 2 UNION
SELECT 13 AS Nr, 'AB' AS Edg, 151, 200, 1, 1, 2 UNION
SELECT 14 AS Nr, 'DF' AS Edg, 101, 101, 1, 50, 3 

UPDATE C
SET  ToStartRow = C2.FromStartRow
,    ToEndRow =   C2.FromEndRow
,    ToStartCol = C2.FromStartCol
,    ToEndCol =   C2.FromEndCol
,    ToFacing =   (C2.FromFacing + 2) % 4
,    InverseDir = CASE WHEN C2.Edg IN ('AD','CH') THEN 1 ELSE 0 END
FROM ##Conversion C
INNER JOIN ##Conversion C2 ON C2.Edg = C.Edg AND C2.ID <> C.ID

SELECT @MoveStr = Line
FROM ##InputNumbered
WHERE TRY_CAST(LEFT(Line,1) AS INT) IS NOT NULL

SET @Facing = 0

SELECT @RowPos = MIN(RowNr) FROM ##Grid G
SELECT @ColPos = MIN(ColNr) FROM ##Grid G WHERE RowNr = @RowPos

SET @NextRowPos = @RowPos
SET @NextColPos = @ColPos

DECLARE @PrevFacing INT

PRINT 'Start of Part 2'

WHILE LEN(@MoveStr) > 0
BEGIN

    -- Determine next move
    IF CHARINDEX('L', @MoveStr) > 0 AND CHARINDEX('R', @MoveStr) > 0
    BEGIN
        IF CHARINDEX('L', @MoveStr) < CHARINDEX('R', @MoveStr) 
        BEGIN
            SET @Dist = LEFT(@MoveStr, CHARINDEX('L', @MoveStr) - 1)
            SET @Turn = 'L'
            SET @MoveStr = SUBSTRING(@MoveStr, CHARINDEX('L', @MoveStr) + 1, LEN(@MoveStr))
        END
        ELSE
        BEGIN
            SET @Dist = LEFT(@MoveStr, CHARINDEX('R', @MoveStr) - 1)
            SET @Turn = 'R'
            SET @MoveStr = SUBSTRING(@MoveStr, CHARINDEX('R', @MoveStr) + 1, LEN(@MoveStr))    
        END
    END
    ELSE
    BEGIN
        -- In the leftover string there are no L's or no R's left
        IF CHARINDEX('L', @MoveStr) > 0
        BEGIN 
            SET @Dist = LEFT(@MoveStr, CHARINDEX('L', @MoveStr) - 1)
            SET @Turn = 'L'
            SET @MoveStr = SUBSTRING(@MoveStr, CHARINDEX('L', @MoveStr) + 1, LEN(@MoveStr))
        END
        ELSE IF CHARINDEX('R', @MoveStr) > 0
        BEGIN
            SET @Dist = LEFT(@MoveStr, CHARINDEX('R', @MoveStr) - 1)
            SET @Turn = 'R'
            SET @MoveStr = SUBSTRING(@MoveStr, CHARINDEX('R', @MoveStr) + 1, LEN(@MoveStr))    
        END
        ELSE
        BEGIN
            SET @Dist = @MoveStr
            SET @Turn = ''
            SET @MoveStr = ''
        END
    END

    PRINT 'Dist: ' + CAST(@Dist AS VARCHAR(5)) + ', Turn: ' + @Turn

    WHILE @Dist > 0
    BEGIN
        
        IF @Facing = 0 BEGIN SET @NextColPos = @ColPos + 1 SET @NextRowPos = @RowPos END
        IF @Facing = 1 BEGIN SET @NextRowPos = @RowPos + 1 SET @NextColPos = @ColPos END
        IF @Facing = 2 BEGIN SET @NextColPos = @ColPos - 1 SET @NextRowPos = @RowPos END
        IF @Facing = 3 BEGIN SET @NextRowPos = @RowPos - 1 SET @NextColPos = @ColPos END

        SET @PrevFacing = @Facing

        IF NOT EXISTS (SELECT 1 FROM ##Grid G WHERE RowNr = @NextRowPos AND ColNr = @NextColPos)
        BEGIN

            -- Move to another side of the cube
            SELECT @NextRowPos = CASE WHEN C.ToStartRow = C.ToEndRow THEN C.ToStartRow ELSE 
                                        CASE WHEN C.InverseDir = 0 THEN CASE WHEN C.FromStartRow = C.FromEndRow THEN @ColPos - C.FromStartCol ELSE @RowPos - C.FromStartRow END + C.ToStartRow 
                                                                   ELSE C.ToEndRow - CASE WHEN C.FromStartRow = C.FromEndRow THEN @ColPos - C.FromStartCol ELSE @RowPos - C.FromStartRow END  
                                        END
                                 END
            ,      @NextColPos = CASE WHEN C.ToStartCol = C.ToEndCol THEN C.ToStartCol ELSE  
                                    CASE WHEN C.InverseDir = 0 THEN CASE WHEN C.FromStartRow = C.FromEndRow THEN @ColPos - C.FromStartCol ELSE @RowPos - C.FromStartRow END + C.ToStartCol 
                                                               ELSE C.ToEndCol - CASE WHEN C.FromStartRow = C.FromEndRow THEN @ColPos - C.FromStartCol ELSE @RowPos - C.FromStartRow END  
                                    END
                                 END
            ,      @Facing = C.ToFacing
            FROM ##Conversion C 
            WHERE @RowPos BETWEEN C.FromStartRow AND C.FromEndRow 
              AND @ColPos BETWEEN C.FromStartCol AND C.FromEndCol 
              AND C.FromFacing = @Facing

        END

        IF (SELECT Val FROM ##Grid G WHERE RowNr = @NextRowPos AND ColNr = @NextColPos) = '#'
        BEGIN
            -- Ran into a wall
            SET @Dist = 0
            SET @Facing = @PrevFacing

        END
        ELSE
        BEGIN
            -- Move
            SET @RowPos = @NextRowPos
            SET @ColPos = @NextColPos
            SET @Dist = @Dist - 1
            
        END

    END

        -- Movement done, let's turn
        IF @Turn <> '' SET @Facing = CASE WHEN @Turn = 'R' THEN (@Facing + 1) % 4 ELSE (@Facing + 3) % 4 END

END

SELECT 1000*@RowPos + 4*@ColPos + @Facing AS Part2


DROP TABLE ##Grid
DROP TABLE ##Conversion
