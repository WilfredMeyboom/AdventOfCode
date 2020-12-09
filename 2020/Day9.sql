USE Test_WME

SET NOCOUNT ON

CREATE TABLE ##Input (Line NVARCHAR(MAX));

BULK INSERT ##Input
FROM 'C:\Source\AdventOfCode\2020\input9.txt'
WITH (ROWTERMINATOR = '0x0A');

SELECT * FROM ##Input

DECLARE @Preamble INT = 25

;WITH cte_NumberedInput AS (
    SELECT ROW_NUMBER() OVER (ORDER BY (SELECT 0)) AS ID, CAST(Line AS BIGINT) AS Line FROM ##Input
), cte_Top25Cross AS (
    SELECT T1.ID AS FirstID, T2.ID AS SecondID, T1.Line AS FirstNr, T2.line AS SecondNr, T1.Line + T2.Line AS ValidNr
    FROM cte_NumberedInput T1
    INNER JOIN cte_NumberedInput T2 ON T1.ID BETWEEN T2.ID + 1 AND T2.ID + 24
)
SELECT * 
FROM cte_NumberedInput c1
LEFT JOIN cte_Top25Cross c2 ON c1.Line = c2.ValidNr
WHERE c1.ID > @Preamble
AND ValidNr IS NULL
ORDER BY ID

--8755618 is too low for part 1
--23278925 is correct for part 1

;WITH cte_NumberedInput AS (
    SELECT ROW_NUMBER() OVER (ORDER BY (SELECT 0)) AS ID, CAST(Line AS BIGINT) AS Line FROM ##Input
)
SELECT *
INTO ##NrInput
FROM cte_NumberedInput

DECLARE @Target BIGINT = 23278925

DECLARE @TargetFound INT = 0
DECLARE @WindowSize INT = 1
DECLARE @NrsAdded INT = 0
DECLARE @Index INT = 1
DECLARE @CurrentValue BIGINT

WHILE @TargetFound = 0
BEGIN
    
    SET @WindowSize = @WindowSize + 1
    SET @NrsAdded = 1
    SET @Index = 1
    SELECT @CurrentValue = Line FROM ##NrInput WHERE ID = 1

    PRINT 'Trying windowsize: ' + CAST(@WindowSize AS VARCHAR(5)) + ' at ' + CAST(GETDATE() AS VARCHAR(50))

    WHILE @TargetFound = 0 AND @Index < (SELECT COUNT(1) FROM ##NrInput)
    BEGIN
        
        SET @Index = @Index + 1
        SELECT @CurrentValue = @CurrentValue + Line FROM ##NrInput WHERE ID = @Index

        IF @WindowSize > @NrsAdded
        BEGIN
            SET @NrsAdded = @NrsAdded + 1
        END
        ELSE
        BEGIN
            SELECT @CurrentValue = @CurrentValue - Line FROM ##NrInput WHERE ID = @Index - @WindowSize
        END

        IF @CurrentValue = @Target SET @TargetFound = 1 
    END

END

PRINT 'Index (end): ' + CAST(@Index AS VARCHAR(5))
PRINT 'Windowsize: ' + CAST(@WindowSize AS VARCHAR(5))

SELECT Line
FROM ##NrInput
--WHERE ID = @Index OR ID = @Index - @WindowSize + 1
WHERE ID BETWEEN 401 AND 417
ORDER BY Line

SELECT 865846 + 
3145218--2969567 is too low
--2342370
SELECT SUM(Line)
FROM ##NrInput
WHERE ID BETWEEN 401 AND 417
DECLARE @Target BIGINT = 23278925


/*
DROP TABLE ##Input
*/

