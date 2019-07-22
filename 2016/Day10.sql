use Test_WME

SET NOCOUNT ON

CREATE TABLE ##Input (Line NVARCHAR(MAX));

BULK INSERT ##Input
FROM 'D:\Wilfred\AdventOfCode\2016\input10.txt'
WITH (ROWTERMINATOR = '0x0A');

CREATE TABLE ##Bots (ID INT IDENTITY(1,1), BotNr INT, FirstValue INT, SecondValue INT, HighToBotNr INT, LowToBotNr INT)

UPDATE ##Input
SET Line = REPLACE(Line, 'gives low to output 0', 'gives low to output 100')

;WITH cte_Scrubbed AS (
    SELECT REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(Line, ' and high to bot ', '|'), ' gives low to bot ', '_'), 'bot ', ''), ' gives low to output ', '_-'), ' and high to output ', '|-') AS ScrubbedLine
    FROM ##Input
    WHERE LEN(Line) > 30
)
INSERT ##Bots (BotNr, LowToBotNr, HighToBotNr)
SELECT LEFT(ScrubbedLine, CHARINDEX('_', ScrubbedLine) - 1) AS BotNr
,      SUBSTRING(ScrubbedLine, CHARINDEX('_', ScrubbedLine) + 1, CHARINDEX('|', ScrubbedLine) - CHARINDEX('_', ScrubbedLine) - 1) AS LowToBotNr
,      SUBSTRING(ScrubbedLine, CHARINDEX('|', ScrubbedLine) + 1, LEN(ScrubbedLine)) AS HighToBotNr
FROM cte_Scrubbed

;WITH cte_Start AS (
    SELECT SUBSTRING(Line, 7, CHARINDEX(' goes to bot ', Line) - 7) AS Value
    ,      SUBSTRING(Line, CHARINDEX(' goes to bot ', Line) + 13, LEN(Line)) AS Bot
    FROM ##Input WHERE LEN(Line) < 30
)
UPDATE B
SET B.FirstValue = cS.Value
,   B.SecondValue = cS2.Value
FROM ##Bots B
INNER JOIN cte_Start cS ON B.BotNr = cS.Bot
LEFT JOIN cte_Start cS2 ON B.BotNr = cS2.Bot AND cS.Value <> cS2.Value


DECLARE @Counter INT = 0

WHILE EXISTS(SELECT 1 FROM ##Bots WHERE FirstValue IS NULL OR SecondValue IS NULL) AND @Counter < 500
BEGIN

    ;WITH cte_BotValues AS (
        SELECT B.HighToBotNr AS BotNr
        ,      CASE WHEN B.FirstValue > B.SecondValue THEN B.FirstValue ELSE B.SecondValue END AS Value
        FROM ##Bots B
        WHERE B.FirstValue IS NOT NULL AND B.SecondValue IS NOT NULL
        UNION 
        SELECT B.LowToBotNr
        ,      CASE WHEN B.FirstValue < B.SecondValue THEN B.FirstValue ELSE B.SecondValue END AS Value
        FROM ##Bots B
        WHERE B.FirstValue IS NOT NULL AND B.SecondValue IS NOT NULL
        UNION
        SELECT BotNr
        ,      FirstValue
        FROM ##Bots 
        WHERE FirstValue IS NOT NULL
        UNION
        SELECT BotNr
        ,      SecondValue
        FROM ##Bots 
        WHERE SecondValue IS NOT NULL
    ), cte_Numbered AS (
        SELECT ROW_NUMBER() OVER (Partition BY BotNr ORDER BY Value) AS Nr
        ,      BotNr
        ,      Value
        FROM cte_BotValues
    )
    UPDATE B
    SET B.FirstValue = V1.Value
    ,   B.SecondValue = V2.Value
    FROM ##Bots B
    LEFT JOIN cte_Numbered V1 ON B.BotNr = V1.BotNr AND V1.Nr = 1
    LEFT JOIN cte_Numbered V2 ON B.BotNr = V2.BotNr AND V2.Nr = 2
    
    SET @Counter = @Counter + 1

    PRINT 'Rows updated: ' + CAST(@@ROWCOUNT AS VARCHAR(10))

END


SELECT * FROM ##Bots WHERE FirstValue + SecondValue = (61+17) 
-- 47 is correct for part 1

SELECT * FROM ##Bots WHERE LowToBotNr BETWEEN -2 AND 0 OR LowToBotNr = -100

/*

DROP TABLE ##Bots
DROP TABLE ##Input

*/

SELECT * FROM ##Input ORDER BY 1

--> Output 0 = 2
--> Output 1 = 41
--> Output 2 = 61

SELECT 2* 31 * 43
--5002 is too high
--2666 is correct for part 2

