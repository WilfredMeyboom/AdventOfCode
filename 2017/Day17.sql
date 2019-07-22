SET NOCOUNT ON

DECLARE @NrOfSteps INT = 363

CREATE TABLE ##Spinlock (ID BIGINT IDENTITY(1,1), Position BIGINT, Value BIGINT)

INSERT ##Spinlock (Position, Value) VALUES (0, 0)

DECLARE @Counter BIGINT = 1
DECLARE @CurrentPos BIGINT = 0
DECLARE @ValueAfterZero BIGINT = 0

WHILE @Counter < 50000000 --2018
BEGIN

    SET @CurrentPos = (@CurrentPos + @NrOfSteps) % @Counter

    UPDATE ##Spinlock
    SET Position = Position + 1
    WHERE Position > @CurrentPos

    INSERT ##Spinlock
    SELECT @CurrentPos + 1, @Counter

    SET @CurrentPos = @CurrentPos + 1

    SET @Counter = @Counter + 1

--    SELECT *, @CurrentPos AS CurrentPos FROM ##Spinlock ORDER BY Position

    IF @ValueAfterZero <> (SELECT Value FROM ##Spinlock WHERE Position = 1)
    BEGIN
        
        SELECT @ValueAfterZero = Value FROM ##Spinlock WHERE Position = 1

        PRINT 'Round: ' + CAST(@Counter - 1 AS VARCHAR(10)) + ' at ' + CAST(GETDATE() AS VARCHAR(50)) + ' after zero = ' + CAST(@ValueAfterZero AS VARCHAR(10))
    END
END


--SELECT * FROM ##Spinlock WHERE Value = 2017
--SELECT * FROM ##Spinlock ORDER BY Position


DROP TABLE ##Spinlock


--136 Correct answer for Part 1

--21370 Too low for Part 2
--56592 Too low for Part 2

DECLARE @NrOfSteps INT = 363
DECLARE @Counter BIGINT = 1
DECLARE @CurrentPos BIGINT = 0

WHILE @Counter < 50000000 --2018
BEGIN

    SET @CurrentPos = (@CurrentPos + @NrOfSteps) % @Counter

    SET @CurrentPos = @CurrentPos + 1

    SET @Counter = @Counter + 1

    IF @CurrentPos = 1 PRINT @Counter - 1 

----    SELECT *, @CurrentPos AS CurrentPos FROM ##Spinlock ORDER BY Position

--    IF @ValueAfterZero <> (SELECT Value FROM ##Spinlock WHERE Position = 1)
--    BEGIN
        
--        SELECT @ValueAfterZero = Value FROM ##Spinlock WHERE Position = 1

--        PRINT 'Round: ' + CAST(@Counter - 1 AS VARCHAR(10)) + ' at ' + CAST(GETDATE() AS VARCHAR(50)) + ' after zero = ' + CAST(@ValueAfterZero AS VARCHAR(10))
--    END
END

--1080289 --> Correct for part 2