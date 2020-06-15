use Test_WME

SET NOCOUNT ON

CREATE TABLE #Input (Nr NVARCHAR(MAX));

BULK INSERT #Input
FROM 'C:\Source\AdventOfCode\2019\input14.txt'
WITH (ROWTERMINATOR = '0x0A');

UPDATE #Input SET Nr = LEFT(Nr, LEN(Nr)-1)

CREATE TABLE ##Conversions (ID BIGINT IDENTITY(1,1), ConvNr BIGINT, IsNeededAmount BIGINT, IsNeededChem VARCHAR(10), IsCreatedAmount BIGINT, IsCreatedChem VARCHAR(10))

;WITH cte_Conversions AS (
    SELECT ROW_NUMBER() OVER (ORDER BY (SELECT 0)) AS ConvNr
    ,      LTRIM(RTRIM(SUBSTRING(Nr, CHARINDEX('=>', Nr) + 3, LEN(Nr)))) AS IsCreated
    ,      CASE WHEN Nr LIKE '%,%' THEN LTRIM(RTRIM(SUBSTRING(Nr, 1, CHARINDEX(',', Nr) - 1))) 
                                   ELSE LTRIM(RTRIM(SUBSTRING(Nr, 1, CHARINDEX('=>', Nr) - 1))) END AS IsNeeded
    ,      CASE WHEN Nr LIKE '%,%' THEN SUBSTRING(Nr, CHARINDEX(',', Nr) + 1, CHARINDEX('=>', Nr) - CHARINDEX(',', Nr) - 1) 
                                   ELSE '' END AS IsAlsoNeeded
    FROM #Input
    UNION ALL
    SELECT ConvNr
    ,      IsCreated
    ,      CASE WHEN IsAlsoNeeded LIKE '%,%' THEN LTRIM(RTRIM(SUBSTRING(IsAlsoNeeded, 1, CHARINDEX(',', IsAlsoNeeded) - 1)))
                                         ELSE LTRIM(RTRIM(IsAlsoNeeded)) END AS IsNeeded
    ,      CASE WHEN IsAlsoNeeded LIKE '%,%' THEN SUBSTRING(IsAlsoNeeded, CHARINDEX(',', IsAlsoNeeded) + 1, LEN(IsAlsoNeeded))
                                         ELSE '' END AS IsAlsoNeeded
    FROM cte_Conversions
    WHERE LEN(IsAlsoNeeded) > 0
)
INSERT ##Conversions (ConvNr, IsNeededAmount, IsNeededChem, IsCreatedAmount, IsCreatedChem)
SELECT ConvNr
,      SUBSTRING(IsNeeded, 1, CHARINDEX(' ', IsNeeded) - 1) AS IsNeededAmount
,      SUBSTRING(IsNeeded, CHARINDEX(' ', IsNeeded) + 1, LEN(IsNeeded)) AS IsNeededChem
,      SUBSTRING(IsCreated, 1, CHARINDEX(' ', IsCreated) - 1) AS IsCreatedAmount
,      SUBSTRING(IsCreated, CHARINDEX(' ', IsCreated) + 1, LEN(IsCreated)) AS IsCreatedChem
FROM cte_Conversions
ORDER BY 1


DROP TABLE #Input

--SELECT * FROM ##Conversions

CREATE TABLE ##RequiredChems (ID BIGINT IDENTITY(1,1), ReqAmount BIGINT, ReqChem VARCHAR(10))
CREATE TABLE ##RequiredChemsTemp (ID BIGINT IDENTITY(1,1), ReqAmount BIGINT, ReqChem VARCHAR(10))
CREATE TABLE ##LeftOverChems (ID BIGINT IDENTITY(1,1), LOAmount BIGINT, LOChem VARCHAR(10))

--INSERT ##RequiredChems (ReqAmount, ReqChem) VALUES (1, 'FUEL') -- Input for part 1
INSERT ##RequiredChems (ReqAmount, ReqChem) VALUES (998536, 'FUEL') --Trail and error input for part 2  ->  999999548174
--INSERT ##RequiredChems (ReqAmount, ReqChem) VALUES (998537, 'FUEL') --Trail and error input for part 2  ->  1000001872527

DECLARE @LOAmount BIGINT
DECLARE @LOAmountCorr BIGINT
DECLARE @LOChem VARCHAR(10)

WHILE (SELECT COUNT(1) FROM ##RequiredChems WHERE ReqChem <> 'ORE') > 0
BEGIN

-- Find the new required chemicals
    INSERT ##RequiredChemsTemp (ReqAmount, ReqChem)
    SELECT CASE WHEN RC.ReqAmount % C.IsCreatedAmount = 0 THEN RC.ReqAmount / C.IsCreatedAmount 
                                                          ELSE RC.ReqAmount / C.IsCreatedAmount + 1
           END * C.IsNeededAmount AS ReqAmount, IsNeededChem AS ReqChem
    FROM ##RequiredChems RC
    INNER JOIN ##Conversions C ON RC.ReqChem = C.IsCreatedChem
    UNION ALL
    SELECT ReqAmount, ReqChem
    FROM ##RequiredChems
    WHERE ReqChem = 'ORE'

    ;WITH cte_ChemLoeftOver AS (
        SELECT DISTINCT CASE WHEN RC.ReqAmount % C.IsCreatedAmount = 0 THEN RC.ReqAmount / C.IsCreatedAmount 
                                                              ELSE RC.ReqAmount / C.IsCreatedAmount + 1
               END * C.IsCreatedAmount - RC.ReqAmount AS LOAmount, RC.ReqChem AS LOChem
        FROM ##RequiredChems RC
        INNER JOIN ##Conversions C ON RC.ReqChem = C.IsCreatedChem
    )
    INSERT ##LeftOverChems (LOAmount, LOChem)
    SELECT LOAmount, LOChem
    FROM cte_ChemLoeftOver
    WHERE LOAmount > 0

-- Switch out required chemicals
    DELETE FROM ##RequiredChems
    INSERT ##RequiredChems (ReqAmount, ReqChem) SELECT SUM(ReqAmount), ReqChem FROM ##RequiredChemsTemp GROUP BY ReqChem
    DELETE FROM ##RequiredChemsTemp

-- Reduce requird chems with leftover chems
    DECLARE LO_Cursor CURSOR FOR
        SELECT T1.LOAmount, T1.LOChem
        FROM ##LeftOverChems T1
        INNER JOIn ##RequiredChems T2 ON T1.LOChem = T2.ReqChem

    OPEN LO_Cursor

    FETCH NEXT FROM LO_Cursor INTO @LOAmount, @LOChem

    WHILE @@FETCH_STATUS = 0
    BEGIN
    
        --SELECT * FROM ##LeftOverChems
        --SELECT *, @LOAmount, @LOChem FROM ##RequiredChems

        UPDATE ##RequiredChems
        SET ReqAmount = CASE WHEN ReqAmount >= @LOAmount THEN ReqAmount - @LOAmount ELSE 0 END
        ,   @LOAmountCorr = CASE WHEN ReqAmount >= @LOAmount THEN 0 ELSE @LOAmount - ReqAmount END
        WHERE ReqChem = @LOChem

        UPDATE ##LeftOverChems
        SET LOAmount = @LOAmountCorr
        WHERE LOChem = @LOChem

        --SELECT * FROM ##LeftOverChems
        --SELECT *, @LOAmount, @LOChem FROM ##RequiredChems

        FETCH NEXT FROM LO_Cursor INTO @LOAmount, @LOChem
    END

    CLOSE LO_Cursor
    DEALLOCATE LO_Cursor

    DELETE FROM ##LeftOverChems WHERE LOAmount = 0 

--SELECT * FROM ##RequiredChems
--SELECT * FROM ##RequiredChemsTemp
--SELECT * FROM ##LeftOverChems

END

--SELECT * FROM ##RequiredChems

SELECT SUM(ReqAmount) FROM ##RequiredChems
--SELECT * FROM ##Conversions

--202226 is too low
--1882238 is too low
--2486514 is correct for part 1

DROP TABLE ##RequiredChems
DROP TABLE ##RequiredChemsTemp
DROP TABLE ##LeftOverChems

DROP TABLE ##Conversions

-- 461339770182 -  460664
-- 901318582284 -  900000
--1001465098472 - 1000000
--1000000000000 

-- 998536 is correct for part 2