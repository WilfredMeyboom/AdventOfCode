SET NOCOUNT ON

CREATE TABLE ##GeneratorNumbers (ID INT IDENTITY(1,1), Timer BIGINT, GenA BIGINT, GenB BIGINT, Judge BIT)

--Generator A starts with 277
--Generator B starts with 349

INSERT ##GeneratorNumbers (Timer, GenA, GenB, Judge) VALUES (0, 277, 349, 0)

DECLARE @GenA BIGINT = 277
DECLARE @GenB BIGINT = 349
DECLARE @FactorA INT = 16807
DECLARE @FactorB INT = 48271
DECLARE @Divider BIGINT = 2147483647

DECLARE @Counter INT = 0

WHILE @Counter <= 40000000
BEGIN

    SET @Counter = @Counter + 1
    
    SET @GenA = (@GenA * @FactorA) % @Divider
    SET @GenB = (@GenB * @FactorB) % @Divider

    INSERT ##GeneratorNumbers (Timer, GenA, GenB, Judge) SELECT @Counter, @GenA, @GenB, CASE WHEN (@GenA & 65535) = (@GenB & 65535) THEN 1 ELSE 0 END

    IF (@Counter % 10000) = 0 PRINT 'Round: ' + CAST(@Counter AS VARCHAR(8)) + ' at time: ' + CAST(GETDATE() AS VARCHAR(50))

END


SELECT COUNT(1) FROM ##GeneratorNumbers WHERE Judge = 1
-- 592 Correct 

/*
To get a significant sample, the judge would like to consider 40 million pairs. (In the example above, the judge would eventually find a total of 588 pairs that match in their lowest 16 bits.)
After 40 million pairs, what is the judge's final count?
*/


--DROP TABLE ##GeneratorNumbers

SELECT COUNT(1) FROM ##GeneratorNumbers WHERE GenA % 4 = 0
--10 001 631
SELECT COUNT(1) FROM ##GeneratorNumbers WHERE GenB % 8 = 0
--4997699

SELECT TOP 10 * FROM ##GeneratorNumbers ORDER BY ID Desc


--DECLARE @GenB BIGINT = 349
--DECLARE @FactorA INT = 16807
--DECLARE @FactorB INT = 48271
--DECLARE @Divider BIGINT = 2147483647

--DECLARE @Counter INT = 0


SET @GenB = 900145984

SET @Counter = 2

--Generate extra records for B
WHILE @Counter <= 3000
BEGIN
    
    SET @GenB = (@GenB * @FactorB) % @Divider

    INSERT ##GeneratorNumbers (Timer, GenB) SELECT @Counter + 40000001, @GenB WHERE @GenB % 8 = 0

    IF (@GenB % 8) = 0 SET @Counter = @Counter + 1

END


;WITH cte_A AS (
    SELECT TOP 5000000
           ROW_NUMBER() OVER (ORDER BY ID) AS RowNr
    ,      GenA
    FROM ##GeneratorNumbers WHERE GenA % 4 = 0
), cte_B AS (
    SELECT TOP 5000000
           ROW_NUMBER() OVER (ORDER BY ID) AS RowNr
    ,      GenB
    FROM ##GeneratorNumbers WHERE GenB % 8 = 0
)
SELECT SUM(CASE WHEN (A.GenA & 65535) = (B.GenB & 65535) THEN 1 ELSE 0 END)
FROM cte_A A
INNER JOIN cte_B B ON A.RowNr = B.RowNr

--320 

