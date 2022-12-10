USE Test_WME

DECLARE @year VARCHAR(4) = '2022'
DECLARE @day VARCHAR(2)  = '9'

EXEC dbo.GetInput @year = @year, @day = @day
EXEC dbo.ParseInput @year = @year, @day = @day 

--SELECT TOP 10 * FROM ##Input
--SELECT TOP 10 * FROM ##InputInts
--SELECT TOP 10 * FROM ##InputNumbered
--SELECT TOP 10 * FROM ##InputGrid
--SELECT TOP 10 * FROM ##InputSplit
--SELECT TOP 10 * FROM ##InputSplitCust
  

DECLARE @Dir VARCHAR(1)
DECLARE @Amount INT
DECLARE @Counter INT
DECLARE @HeadX INT = 0
DECLARE @HeadY INT = 0
DECLARE @TailX INT = 0
DECLARE @TailY INT = 0


CREATE TABLE ##Tail(ID INT IDENTITY(1,1), x INT, y INT)

DECLARE moveCursor CURSOR FAST_FORWARD READ_ONLY FOR SELECT LEFT(Line,1), CAST(SUBSTRING(Line,3,LEN(Line)) AS INT) FROM ##InputNumbered ORDER BY Ind

OPEN moveCursor

FETCH NEXT FROM moveCursor INTO @Dir, @Amount

WHILE @@FETCH_STATUS = 0
BEGIN
    
    SET @Counter = 0 

    WHILE @Counter < @Amount
    BEGIN
        
        IF @Dir = 'U' SET @HeadY = @HeadY + 1
        IF @Dir = 'D' SET @HeadY = @HeadY - 1
        IF @Dir = 'L' SET @HeadX = @HeadX - 1
        IF @Dir = 'R' SET @HeadX = @HeadX + 1

        IF ABS(@HeadX - @TailX) > 1 
        BEGIN
        PRINT'x'
            SET @TailX = @TailX + CASE WHEN @HeadX > @TailX THEN 1 ELSE -1 END
            SET @TailY = @HeadY
        END
        IF ABS(@HeadY - @TailY) > 1 
        BEGIN
            SET @TailX = @HeadX
            SET @TailY = @TailY + CASE WHEN @HeadY > @TailY THEN 1 ELSE -1 END
        END

        INSERT ##Tail
        (
            x,
            y
        )
        SELECT @TailX, @TailY

        SET @Counter = @Counter + 1

        --PRINT @HeadX
        --PRINT @HeadY
        --PRINT @TailX
        --PRINT @TailY

    END



    FETCH NEXT FROM moveCursor INTO @Dir, @Amount
END

CLOSE moveCursor
DEALLOCATE moveCursor


SELECT DISTINCT x,y FROM ##Tail T
--SELECT * FROM ##Tail


DROP TABLE ##Tail



CREATE TABLE ##Tail9(ID INT IDENTITY(1,1), x INT, y INT)

CREATE TABLE ##Rope(ID INT IDENTITY(1,1), PartNr INT , x INT, y INT)

INSERT ##Rope
(
    PartNr,
    x,
    y
)
SELECT TOP 10 ROW_NUMBER() OVER( ORDER BY (SELECT 0)) -1 ,0,0 FROM sys.messages M

DECLARE moveCursor CURSOR FAST_FORWARD READ_ONLY FOR SELECT LEFT(Line,1), CAST(SUBSTRING(Line,3,LEN(Line)) AS INT) FROM ##InputNumbered ORDER BY Ind

OPEN moveCursor

FETCH NEXT FROM moveCursor INTO @Dir, @Amount

WHILE @@FETCH_STATUS = 0
BEGIN
    
    SET @Counter = 0 

    WHILE @Counter < @Amount
    BEGIN
        
        IF @Dir = 'U' UPDATE ##Rope SET Y = Y + 1 WHERE Partnr = 0
        IF @Dir = 'D' UPDATE ##Rope SET Y = Y - 1 WHERE Partnr = 0
        IF @Dir = 'L' UPDATE ##Rope SET X = X - 1 WHERE Partnr = 0
        IF @Dir = 'R' UPDATE ##Rope SET X = X + 1 WHERE Partnr = 0


        WHILE EXISTS(SELECT 1 FROM ##Rope R INNER JOIN ##Rope R2 ON R2.PartNr = R.PartNr + 1 AND ABS(R2.x - R.x) > 1 OR ABS(R2.y - R.y) > 1)
        BEGIN
            
            UPDATE R
            SET R.x = R.x + CASE WHEN r2.x > r.x THEN 1 ELSE -1 END
            ,   R.y = R2.y
            FROM ##Rope R
            INNER JOIN ##Rope R2 ON R2.PartNr = R.PartNr - 1
            WHERE ABS(R.x - R2.x) > 1 

            UPDATE R
            SET R.x = R.x 
            ,   R.y = R.y + CASE WHEN r2.y > r.y THEN 1 ELSE -1 END
            FROM ##Rope R
            INNER JOIN ##Rope R2 ON R2.PartNr = R.PartNr - 1
            WHERE ABS(R.y - R2.y) > 1 

        END

        INSERT ##Tail9
        (
            x,
            y
        )
        SELECT x,y FROM ##Rope R WHERE r.PartNr = 9

        SET @Counter = @Counter + 1

        --SELECT * FROM ##Rope R
    END



    FETCH NEXT FROM moveCursor INTO @Dir, @Amount
END

CLOSE moveCursor
DEALLOCATE moveCursor

SELECT DISTINCT x,y FROM ##Tail9 T


DROP TABLE ##Tail9
DROP TABLE ##Rope