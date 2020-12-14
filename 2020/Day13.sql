DECLARE @StartTime BIGINT = 1011416
DECLARE @Input VARCHAR(MAX) = '41,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,37,x,x,x,x,x,911,x,x,x,x,x,x,x,x,x,x,x,x,13,17,x,x,x,x,x,x,x,x,23,x,x,x,x,x,29,x,827,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,19'

--SET @Input = '17,x,13,19' --Example 1
--SET @Input = '67,7,59,61' --Example 2

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

CREATE TABLE ##Factors (ID INT IDENTITY(1,1), BusID INT, Interval INT, Factor INT) 

;WITH cte_Input AS (
    SELECT ROW_NUMBER() OVER (ORDER BY (SELECT 0)) - 1 AS Interval
    ,      value AS BusID
    FROM string_split(@Input, ',')
)
INSERT ##Factors (BusID, Interval)
SELECT BusID, Interval
FROM cte_Input
WHERE BusiD <> 'x'


DECLARE @Counter INT = 1
DECLARE @Factor INT
DECLARE @FirstBus INT
SELECT @FirstBus = BusID FROM ##Factors WHERE ID = 1
DECLARE @TotalFactor BIGINT = 1

WHILE @Counter <= (SELECT COUNT(1) FROM ##Factors) 
BEGIN

    SET @Factor = 1

    WHILE (SELECT (BusID * @Factor - Interval) % @FirstBus FROM ##Factors WHERE ID = @Counter) <> 0
        SET @Factor = @Factor + 1

    UPDATE ##Factors
    SET Factor = @Factor
    WHERE ID = @Counter

    SET @TotalFactor = @TotalFactor * @Factor

    SET @Counter = @Counter + 1
END


SELECT * FROM ##Factors

SELECT CAST(827 AS BIGINT) * 23 * 13 * 19 * 41 * 37 * 17 * 29 * 911 
-- 3200966845281517 Step interval; our answer lies below this number

--DROP TABLE ##Factors

/*
*/
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
