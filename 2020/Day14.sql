USE Test_WME

SET NOCOUNT ON

CREATE TABLE ##Input (Line NVARCHAR(MAX));

BULK INSERT ##Input
FROM 'C:\Source\AdventOfCode\2020\input14.txt'
WITH (ROWTERMINATOR = '0x0A');

CREATE TABLE ##Instr (ID INT IDENTITY(1,1), InstrTyp VARCHAR(10), Mask VARCHAR(36), Mem BIGINT, Val BIGINT)

INSERT ##Instr (InstrTyp, Mask, Mem, Val)
SELECT CASE WHEN LEFT(Line, 4) = 'mask' THEN 'Mask' ELSE 'Mem' END AS InstrTyp
,      CASE WHEN LEFT(Line, 4) = 'mask' THEN TRIM(SUBSTRING(Line, CHARINDEX('=', Line) + 1, LEN(Line))) END AS Mask
,      CASE WHEN LEFT(Line, 3) = 'mem' THEN SUBSTRING(Line,  CHARINDEX('[', Line) + 1, CHARINDEX(']', Line) - CHARINDEX('[', Line) - 1) END AS Mem
,      CASE WHEN LEFT(Line, 3) = 'mem' THEN SUBSTRING(Line,  CHARINDEX('=', Line) + 1, LEN(Line)) END AS Val
FROM ##Input


DECLARE @DoPart1 INT = 0

IF @DoPart1 = 1
BEGIN

CREATE TABLE ##Result (ID INT, Mem INT, NewVal BIGINT)

DECLARE @MaxID INT
SELECT @MaxID = MAX(ID) FROM ##Instr


;WITH cte_Masks AS (
    SELECT ID, ISNULL(LEAD(ID) OVER (ORDER BY ID), @MaxID + 1) AS NextID, Mask
    FROM ##Instr
    WHERE InstrTyp = 'Mask'
    GROUP BY ID, Mask
), cte_MemBits AS (
    SELECT I.ID, Mem, Val
    , RIGHT('000000000000000000000000000000000000' + CAST(dbo.ConvertToBase(Val, 2) AS VARCHAR(36)), 36) BitVal
    , cM.Mask
    FROM ##Instr I
    INNER JOIN cte_Masks cM ON I.ID BETWEEN cM.ID AND cM.NextID
    WHERE InstrTyp = 'Mem'
    --ORDER BY Mem, I.ID
),  cte_Masked AS (
    SELECT ID, Mem, Val
    , CAST(CASE WHEN RIGHT(Mask, 1) = 'X' THEN RIGHT(BitVal,1) ELSE RIGHT(Mask, 1) END AS VARCHAR(36)) AS Result
    , SUBSTRING(BitVal, 1, LEN(BitVal) - 1) AS RestBitVal
    , SUBSTRING(Mask, 1, LEN(Mask) - 1) AS RestMask
    FROM cte_MemBits

    UNION ALL

    SELECT ID, Mem, Val
    , CAST(CASE WHEN RIGHT(RestMask, 1) = 'X' THEN RIGHT(RestBitVal,1) ELSE RIGHT(RestMask, 1) END  + Result AS VARCHAR(36)) AS Result
    , SUBSTRING(RestBitVal, 1, LEN(RestBitVal) - 1) AS RestBitVal
    , SUBSTRING(RestMask, 1, LEN(RestMask) - 1) AS RestMask
    FROM cte_Masked
    WHERE LEN(RestBitVal) > 1
)
INSERT ##Result(ID, Mem, NewVal)
SELECT ID, Mem, dbo.BinaryToDecimal(CASE WHEN RestMask = 'X' THEN RestBitVal ELSE RestMask END + Result)
--,* ,CASE WHEN RestMask = 'X' THEN RestBitVal ELSE RestMask END + Result
FROM cte_Masked
WHERE LEN(Result) = 35
ORDER BY 1


;WITH cte_OnlyLatest AS (
    SELECT MAX(ID) AS ID, Mem FROM ##Result GROUP BY Mem
)
SELECT SUM(NewVal)
FROM ##Result T1
INNER JOIN cte_OnlyLatest T2 ON T1.ID = T2.ID

-- 12571858860023 is too low for part 1
-- 17028179706934 is correct for part 1

END

ELSE --DoPart1

BEGIN


CREATE TABLE ##Result2 (ID INT, Mem INT, NewMem BIGINT, Val BIGINT)

DECLARE @MaxID2 INT
SELECT @MaxID2 = MAX(ID) FROM ##Instr

DECLARE @X AS TABLE (Inp CHAR, X CHAR)
INSERT @X VALUES ('X', '0'),('X', '1'), ('0', NULL), ('1', NULL)

;WITH cte_Masks AS (
    SELECT ID, ISNULL(LEAD(ID) OVER (ORDER BY ID), @MaxID2 + 1) AS NextID, Mask
    FROM ##Instr
    WHERE InstrTyp = 'Mask'
    GROUP BY ID, Mask
), cte_MemBits AS (
    SELECT I.ID, Mem, Val
    , RIGHT('000000000000000000000000000000000000' + CAST(dbo.ConvertToBase(Mem, 2) AS VARCHAR(36)), 36) BitMem
    , cM.Mask
    FROM ##Instr I
    INNER JOIN cte_Masks cM ON I.ID BETWEEN cM.ID AND cM.NextID
    WHERE InstrTyp = 'Mem'
    --ORDER BY I.ID
),  cte_Masked AS (
    SELECT ID, Mem, Val
    , CAST(ISNULL(X, CASE WHEN RIGHT(Mask, 1) = '0' THEN RIGHT(BitMem,1) ELSE RIGHT(Mask, 1) END) AS VARCHAR(36)) AS Result
    , SUBSTRING(BitMem, 1, LEN(BitMem) - 1) AS RestBitMem
    , SUBSTRING(Mask, 1, LEN(Mask) - 1) AS RestMask
    FROM cte_MemBits
    INNER JOIN @X X ON RIGHT(Mask, 1) = X.Inp

    UNION ALL

    SELECT ID, Mem, Val
    , CAST(ISNULL(X, CASE WHEN RIGHT(RestMask, 1) = '0' THEN RIGHT(RestBitMem,1) ELSE RIGHT(RestMask, 1) END) + Result AS VARCHAR(36)) AS Result
    , CASE WHEN LEN(RestBitMem) = 1 THEN '' ELSE SUBSTRING(RestBitMem, 1, LEN(RestBitMem) - 1) END AS RestBitMem
    , CASE WHEN LEN(RestMask) = 1 THEN '' ELSE SUBSTRING(RestMask, 1, LEN(RestMask) - 1) END AS RestMask
    FROM cte_Masked cM
    INNER JOIN @X X ON RIGHT(RestMask, 1) = X.Inp
    WHERE LEN(RestBitMem) > 0
)
INSERT ##Result2(ID, Mem, Val, NewMem)
SELECT DISTINCT ID, Mem, Val
--, Result
, dbo.BinaryToDecimal(Result)
FROM cte_Masked
WHERE LEN(Result) = 36
ORDER BY 1


;WITH cte_OnlyLatest AS (
    SELECT MAX(ID) AS ID, NewMem FROM ##Result2 GROUP BY NewMem
)
SELECT SUM(Val)
FROM ##Result2 T1
INNER JOIN cte_OnlyLatest T2 ON T1.ID = T2.ID AND T1.NewMem = T2.NewMem

--3683236147222 is correct for part 2

END

--SELECT * FROM ##Result2
--SELECT * FROM ##Instr

/*

DROP TABLE ##Result2
DROP TABLE ##Result
DROP TABLE ##Instr
DROP TABLE ##Input



    CREATE FUNCTION dbo.ConvertToBase  
    (  
        @value AS BIGINT,  
        @base AS INT  
    ) RETURNS VARCHAR(MAX) AS BEGIN  
      
        -- some variables  
        DECLARE @characters CHAR(36),  
                @result VARCHAR(MAX);  
      
        -- the encoding string and the default result  
        SELECT @characters = '0123456789abcdefghijklmnopqrstuvwxyz',  
               @result = '';  
      
        -- make sure it's something we can encode.  you can't have  
        -- base 1, but if we extended the length of our @character  
        -- string, we could have greater than base 36  
        IF @value < 0 OR @base < 2 OR @base > 36 RETURN NULL;  
      
        -- until the value is completely converted, get the modulus  
        -- of the value and prepend it to the result string.  then  
        -- devide the value by the base and truncate the remainder  
        WHILE @value > 0  
            SELECT @result = SUBSTRING(@characters, @value % @base + 1, 1) + @result,  
                   @value = @value / @base;  
      
        -- return our results  
        RETURN @result;  
      
    END  
*/



