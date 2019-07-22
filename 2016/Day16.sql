USE Test_WME

DECLARE @Input VARCHAR(MAX) = '10111100110001111'
DECLARE @TargetSize INT = 35651584 -- <- Second disc | First disc -> 272

--SET @Input = '10000'
--SET @TargetSize = 20

DECLARE @Output VARCHAR(MAX)

CREATE TABLE ##Data (ID INT IDENTITY(1,1), DiscData VARCHAR(MAX))

WHILE (SELECT LEN(@Input)) < @TargetSize
BEGIN

    SELECT @Output = REVERSE(@Input)

    SELECT @Output = REPLACE(@Output, '0', '2')
    SELECT @Output = REPLACE(@Output, '1', '0')
    SELECT @Output = REPLACE(@Output, '2', '1')

    SET @Input = @Input + '0' + @Output

--    PRINT 'Input: ' + CAST(LEN(@Input) AS VARCHAR(15))

    INSERT ##Data(DiscData) VALUES (@Input)

END

SELECT @Input = SUBSTRING(@Input, 1, @TargetSize)

--PRINT @Input

ALTER TABLE ##Data ADD Checksum VARCHAR(MAX)


DECLARE @Checksum VARCHAR(MAX)
SET @Checksum = @Input

WHILE (SELECT LEN(@Checksum)) % 2 = 0
BEGIN
    
    ;WITH cte_CheckSum AS (
        SELECT CAST(CASE WHEN LEFT(@CheckSum, 2) IN ('00', '11') THEN '1' ELSE '0' END AS VARCHAR(MAX)) AS  CS
        ,      SUBSTRING(@CheckSum, 3, LEN(@CheckSum)) AS Remainder
        UNION ALL
        SELECT CAST(CS AS VARCHAR(MAX)) + CASE WHEN LEFT(Remainder, 2) IN ('00', '11') THEN '1' ELSE '0' END AS CS
        ,      SUBSTRING(Remainder, 3, LEN(Remainder)) AS Remainder
        FROM cte_CheckSum
        WHERE LEN(Remainder) > 0
    )
    SELECT @Checksum = CS
    FROM cte_CheckSum 
    WHERE LEN(Remainder) = 0
    OPTION (MAXRECURSION 20000)

    PRINT 'Checksum: ' + CAST(LEN(@Checksum) AS VARCHAR(15))

END

PRINT @CheckSum


--11100110111101110 Correct for part 1

--10001101010000101 Correct for part 2 (The checksum starts repeating for after the second step