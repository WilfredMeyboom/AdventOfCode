USE Test_WME

SET NOCOUNT ON

DECLARE @year VARCHAR(4) = '2022'
DECLARE @day VARCHAR(2)  = '14'

EXEC dbo.GetInput @year = @year, @day = @day
EXEC dbo.ParseInput @year = @year, @day = @day, @SplitCustom = '->'

--SELECT TOP 10 * FROM ##Input
--SELECT TOP 10 * FROM ##InputInts
--SELECT TOP 10 * FROM ##InputNumbered
--SELECT TOP 10 * FROM ##InputGrid
--SELECT TOP 10 * FROM ##InputSplit
--SELECT * FROM ##InputSplitCust
  
DECLARE @Points TABLE (ID INT IDENTITY(1,1), RowNr INT, PieceNr INT, X INT, Y INT)

INSERT @Points (RowNr, PieceNr, X, Y)
SELECT RowNr
,      PieceNr
,      CAST(SUBSTRING(Piece,CHARINDEX(',', Piece)+1, LEN(Piece)) AS INT) AS x
,      CAST(LEFT(Piece,CHARINDEX(',', Piece)-1) AS INT) AS y FROM ##InputSplitCust


DECLARE @MaxX INT
DECLARE @MinY INT
DECLARE @MaxY INT

--SELECT * FROM @Points
SELECT @MaxX = MAX(X) + 1, @MinY = MIN(Y) - 1, @MaxY = MAX(Y) + 1 FROM @Points

-- Create a big enough floor
SET @MinY = 500 - @MaxX
SET @MaxY = 500 + @MaxX

--PRINT @MaxX
--PRINT @MinY
--PRINT @MaxY

CREATE TABLE ##Grid (ID INT IDENTITY(1,1), X INT, Y INT, Val INT)
CREATE INDEX uqGrid ON ##Grid (X,Y)

;WITH cte_x AS (
    SELECT TOP (@MaxX) ROW_NUMBER() OVER (ORDER BY (SELECT 0)) AS X FROM sys.messages
), cte_y AS (
    SELECT TOP (@MaxY-@MinY + 1) ROW_NUMBER() OVER (ORDER BY (SELECT 0)) + @MinY - 1 AS Y FROM sys.messages
)
INSERT ##Grid (X, Y, Val)
SELECT X, Y, 0 -- Use 0 as empty space
FROM cte_x
CROSS APPLY cte_y


--SELECT COUNT(1) FROM ##Grid

DECLARE @RowNr INT = 0
DECLARE @LastRowNr INT = 0
DECLARE @X INT
DECLARE @PrevX INT
DECLARE @Y INT
DECLARE @PrevY INT


DECLARE LineCursor CURSOR FAST_FORWARD FOR SELECT RowNr, X, Y FROM @Points

OPEN LineCursor

FETCH NEXT FROM LineCursor INTO @RowNr, @X, @Y

WHILE @@FETCH_STATUS = 0
BEGIN
    
    IF @RowNr <> @LastRowNr
    BEGIN
        SET @LastRowNr = @RowNr
        SET @PrevX = @X
        SET @PrevY = @Y
    END
    ELSE
    BEGIN
        UPDATE ##Grid
        SET Val = 1 -- Use 1 as a wall
        WHERE (x BETWEEN @PrevX AND @X OR x BETWEEN @X AND @PrevX)
          AND (y BETWEEN @PrevY AND @Y OR y BETWEEN @Y AND @PrevY)

        SET @PrevX = @X
        SET @PrevY = @Y

    END

    FETCH NEXT FROM LineCursor INTO @RowNr, @X, @Y
END

CLOSE LineCursor
DEALLOCATE LineCursor

--SELECT * FROM ##Grid ORDER BY y,x

DECLARE @SandOffScreen INT = 0
DECLARE @Left INT
DECLARE @Middle INT
DECLARE @Right INT
DECLARE @SandStoppedMoving INT = 0

WHILE @SandOffScreen = 0
BEGIN
    
    --Initiate sand particle
    SET @X = 0
    SET @Y = 500
    SET @SandStoppedMoving = 0

    WHILE @SandStoppedMoving = 0 
    BEGIN

        SELECT @Left = Val FROM ##Grid WHERE x = @X + 1 AND y = @Y - 1
        SELECT @Middle = Val FROM ##Grid WHERE x = @X + 1 AND y = @Y
        SELECT @Right = Val FROM ##Grid WHERE x = @X + 1 AND y = @Y + 1

        IF @Middle = 0
        BEGIN
            SET @X = @X + 1
        END
        ELSE IF @Left = 0
        BEGIN
            SET @X = @X + 1
            SET @Y = @Y - 1
        END
        ELSE IF @Right = 0
        BEGIN
            SET @X = @X + 1
            SET @Y = @Y + 1
        END
        ELSE 
        BEGIN --Sand could not move
            UPDATE ##Grid 
            SET Val = 2 -- Use 2 as other sand
            WHERE x = @X AND y = @Y

            SET @SandStoppedMoving = 1
        END

        IF @X = @MaxX
        BEGIN
            SET @SandStoppedMoving = 1
            SET @SandOffScreen = 1
        END

        --PRINT CAST(@X AS VARCHAR(5)) + ' ' + CAST(@Y AS VARCHAR(5))
    END

END

SELECT COUNT(1) FROM ##Grid WHERE Val = 2

DECLARE @SandBlocked INT = 0

WHILE @SandBlocked = 0
BEGIN
    
    --Initiate sand particle
    SET @X = 0
    SET @Y = 500
    SET @SandStoppedMoving = 0

    WHILE @SandStoppedMoving = 0 
    BEGIN

        SELECT @Left = Val FROM ##Grid WHERE x = @X + 1 AND y = @Y - 1
        SELECT @Middle = Val FROM ##Grid WHERE x = @X + 1 AND y = @Y
        SELECT @Right = Val FROM ##Grid WHERE x = @X + 1 AND y = @Y + 1

        IF @Middle = 0
        BEGIN
            SET @X = @X + 1
        END
        ELSE IF @Left = 0
        BEGIN
            SET @X = @X + 1
            SET @Y = @Y - 1
        END
        ELSE IF @Right = 0
        BEGIN
            SET @X = @X + 1
            SET @Y = @Y + 1
        END
        ELSE 
        BEGIN --Sand could not move
            UPDATE ##Grid 
            SET Val = 2 -- Use 2 as other sand
            WHERE x = @X AND y = @Y

            SET @SandStoppedMoving = 1

            IF @X = 0 SET @SandBlocked = 1
        END

        IF @X = @MaxX
        BEGIN
            UPDATE ##Grid 
            SET Val = 2 -- Use 2 as other sand
            WHERE x = @X AND y = @Y

            SET @SandStoppedMoving = 1
        END

        --PRINT CAST(@X AS VARCHAR(5)) + ' ' + CAST(@Y AS VARCHAR(5))
    END

END

SELECT COUNT(1) FROM ##Grid WHERE Val = 2

/*
    DROP TABLE ##Grid

    27935 too low
    27936 is correct
*/