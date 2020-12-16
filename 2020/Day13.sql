DECLARE @StartTime BIGINT = 1011416
DECLARE @Input VARCHAR(MAX) = '41,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,37,x,x,x,x,x,911,x,x,x,x,x,x,x,x,x,x,x,x,13,17,x,x,x,x,x,x,x,x,23,x,x,x,x,x,29,x,827,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,19'

--SET @Input = '17,x,13,19' --Example 1
--SET @Input = '67,7,59,61' --Example 2
--SET @Input = '67,x,7,59,61' --Example 3
--SET @Input = '67,7,x,59,61' --Example 4
--SET @Input = '1789,37,47,1889' --Example 5
--SET @Input = '3,5,7'

;WITH cte_Input AS (
    SELECT ROW_NUMBER() OVER (ORDER BY (SELECT 0)) AS ID
    ,      value AS BusID
    FROM string_split(@Input, ',')
)
SELECT *
,      (@StartTime / CAST(BusID AS BIGINT) + 1) * BusID - @StartTime AS WaitTime
,      ((@StartTime / CAST(BusID AS BIGINT) + 1) * BusID - @StartTime) * BusID AS Answer
FROM cte_Input
WHERE BusiD <> 'x'
ORDER BY 3

--4135 is correct for part 1

CREATE TABLE ##Buses (ID INT IDENTITY(1,1), BusID INT, Interval INT, IntervalChange INT)

;WITH cte_Input AS (
    SELECT ROW_NUMBER() OVER (ORDER BY (SELECT 0)) - 1 AS Interval
    ,      value AS BusID
    FROM string_split(@Input, ',')
)
INSERT ##Buses (BusID, Interval, IntervalChange)
SELECT BusID, Interval, Interval - LAG(Interval) OVER (ORDER BY (SELECT 0))
FROM cte_Input
WHERE BusiD <> 'x'



SELECT * FROM ##Buses

DECLARE @Counter INT = 2
DECLARE @FirstBus BIGINT
DECLARE @SecondBus BIGINT
DECLARE @Interval BIGINT = 0
DECLARE @Offset BIGINT = 0
DECLARE @X BIGINT
DECLARE @MaxInterval BIGINT

SELECT @FirstBus = BusID FROM ##Buses WHERE ID = 1

--SELECT @FirstBus, @SecondBus, @Interval

WHILE @Counter <= (SELECT COUNT(1) FROM ##Buses)
BEGIN

    SELECT @SecondBus = BusID
    ,      @Interval = IntervalChange
    ,      @MaxInterval = Interval
    FROM ##Buses
    WHERE ID = @Counter

    PRINT 'Next iteration with FirstBus: ' + CAST(@FirstBus AS VARCHAR(10)) + ' and SecondBus: ' + CAST(@SecondBus AS VARCHAR(10))
    PRINT 'with offset: ' + CAST(@Offset AS VARCHAR(20)) + ' and interval: ' + CAST(@Interval AS VARCHAR(10)) + ' (Counter: ' + CAST(@Counter AS VARCHAR(3)) + ')' 
    SET @X = 1

    WHILE (@SecondBus * @X) % @FirstBus <> @Offset + @Interval--)%@FirstBus
    BEGIN
        SET @X = @X + 1
    END
    
    SET @Offset = @X * @SecondBus
    SET @FirstBus = @FirstBus * @SecondBus

    PRINT 'Mod found: ' + CAST(@X AS VARCHAR(10)) + ' which leads to offset ' + CAST(@Offset AS VARCHAR(20)) + ' at ' + CAST(GETDATE() AS VARCHAR(50))

    SET @Counter = @Counter + 1

END

PRINT 'Answer: ' + CAST(@Offset - @MaxInterval AS VARCHAR(20))

DROP TABLE ##Buses

--640856202464541 is correct for part 2
--Above code is too slow but using WolframAlpha.com with the logic of the code worked


--SELECT CAST(827 AS BIGINT) * 23 * 13 * 19 * 41 * 37 * 17 * 29 * 911 
-- 3200966845281517 Step interval; our answer lies below this number

--DROP TABLE ##Factors

/*

--100.000.000.000.000

DECLARE @Timestamp BIGINT = 109769484084 * 911

--SET @Timestamp = 19

DECLARE @TimeFound INT = 0
DECLARE @Counter BIGINT = 1

WHILE @TimeFound = 0
BEGIN

    --IF (@Timestamp -3) % 17 = 0
    --    IF (@Timestamp - 1) % 13 = 0
    --        PRINT @Timestamp - 3

    IF (@Timestamp + 31) % 827 = 0
        IF (@Timestamp) % 41 = 0
            IF (@Timestamp - 6) % 37 = 0
                IF (@Timestamp + 29) % 29 = 0
                    IF (@Timestamp) % 23 = 0
                        IF (@Timestamp + 50) % 19 = 0
                            IF (@Timestamp + 14) % 17 = 0
                                IF (@Timestamp) % 13 = 0
            SET @TimeFound = 1                      

    --SET @Timestamp = @Timestamp + 19
    SET @Timestamp = @Timestamp + 911

    SET @Counter = @Counter + 1
    IF @Counter % 1000 = 0 PRINT CAST(@Counter AS VARCHAR(10)) + ' at ' + CAST(GETDATE() AS VARCHAR(50)) + ' TS: ' + CAST(@Timestamp AS VARCHAR(20))

END

PRINT @Timestamp - 41

--SELECT * 
--,      Interval -41
--FROM ##Factors ORDER BY BusID DESC

--105764770648613 'trial and error' got to this after 3 hours
--100000000000524 start
*/