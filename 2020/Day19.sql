use Test_WME

SET NOCOUNT ON

CREATE TABLE ##Input (Line NVARCHAR(MAX));

BULK INSERT ##Input
FROM 'C:\Source\AdventOfCode\2020\input19.txt'
WITH (ROWTERMINATOR = '0x0A');

CREATE TABLE ##Data (ID INT IDENTITY(1,1), Line VARCHAR(200))

INSERT ##Data (Line)
SELECT Line FROM ##Input WHERE LEFT(Line,1) IN ('a','b')

CREATE TABLE ##Rules (ID INT IDENTITY(1,1), RuleNr INT, Pattern VARCHAR(200))

INSERT ##Rules (RuleNr, Pattern)
SELECT LEFT(Line, CHARINDEX(':', Line) - 1) AS RuleNr
,      SUBSTRING(Line, CHARINDEX(':', Line) + 1, LEN(Line)) + ' ' AS Pattern
FROM ##Input
WHERE Line IS NOT NULL AND LEFT(Line,1) NOT IN ('a','b')

UPDATE ##Rules
SET Pattern = TRIM(REPLACE(Pattern, N'"', ''))
WHERE Pattern LIKE N'%"%' 

INSERT ##Rules (RuleNr, Pattern)
SELECT RuleNr, SUBSTRING(Pattern, CHARINDEX('|', Pattern) + 1, LEN(Pattern))
FROM ##Rules 
WHERE Pattern LIKE '%|%'

UPDATE R
SET Pattern = LEFT(Pattern, CHARINDEX('|', Pattern) - 1)
FROM ##Rules R
WHERE Pattern LIKE '%|%'


DECLARE @DoPart2 INT = 1

CREATE TABLE ##TempRules (ID INT IDENTITY(1,1), OriginalID INT, RuleNr INT, Pattern VARCHAR(200))

IF @DoPart2 = 0
BEGIN

DECLARE @UnfinishedRules INT = 100

WHILE @UnfinishedRules > 0
BEGIN

    ;WITH cte_IncompletedRules AS (
        SELECT DISTINCT RuleNr
        FROM ##Rules
        WHERE Pattern LIKE '%0%'
           OR Pattern LIKE '%1%'
           OR Pattern LIKE '%2%'
           OR Pattern LIKE '%3%'
           OR Pattern LIKE '%4%'
           OR Pattern LIKE '%5%'
           OR Pattern LIKE '%6%'
           OR Pattern LIKE '%7%'
           OR Pattern LIKE '%8%'
           OR Pattern LIKE '%9%'    
    ), cte_CompletedRules AS (
        SELECT R.RuleNr, Pattern
        FROM ##Rules R
        LEFT JOIN cte_IncompletedRules cIR ON R.RuleNr = cIR.RuleNr
        WHERE Pattern NOT LIKE '%0%'
          AND Pattern NOT LIKE '%1%'
          AND Pattern NOT LIKE '%2%'
          AND Pattern NOT LIKE '%3%'
          AND Pattern NOT LIKE '%4%'
          AND Pattern NOT LIKE '%5%'
          AND Pattern NOT LIKE '%6%'
          AND Pattern NOT LIKE '%7%'
          AND Pattern NOT LIKE '%8%'
          AND Pattern NOT LIKE '%9%'
          AND cIR.RuleNr IS NULL
    )
    INSERT ##TempRules (OriginalID, RuleNr, Pattern)
    SELECT R.ID, R.RuleNr, REPLACE(R.Pattern, ' ' + CAST(cCR.RuleNr AS VARCHAR(3)) + ' ', ' ' + cCR.Pattern + ' ')
    FROM ##Rules R
    INNER JOIN cte_CompletedRules cCR ON R.Pattern LIKE '% ' + CAST(cCR.RuleNr AS VARCHAR(3)) + ' %'
    
    DELETE FROM ##Rules WHERE ID IN (SELECT DISTINCT OriginalID FROM ##TempRules)
    INSERT ##Rules (RuleNr, Pattern) SELECT DISTINCT RuleNr, Pattern FROM ##TempRules
    DELETE FROM ##TempRules

    --Clean pattern
    UPDATE R
    SET Pattern = TRIM(REPLACE(Pattern, ' ', ''))
    FROM ##Rules R
    WHERE Pattern NOT LIKE '%0%'
      AND Pattern NOT LIKE '%1%'
      AND Pattern NOT LIKE '%2%'
      AND Pattern NOT LIKE '%3%'
      AND Pattern NOT LIKE '%4%'
      AND Pattern NOT LIKE '%5%'
      AND Pattern NOT LIKE '%6%'
      AND Pattern NOT LIKE '%7%'
      AND Pattern NOT LIKE '%8%'
      AND Pattern NOT LIKE '%9%'

    SELECT @UnfinishedRules = COUNT(1)
    FROM ##Rules
    WHERE Pattern LIKE '%0%'
       OR Pattern LIKE '%1%'
       OR Pattern LIKE '%2%'
       OR Pattern LIKE '%3%'
       OR Pattern LIKE '%4%'
       OR Pattern LIKE '%5%'
       OR Pattern LIKE '%6%'
       OR Pattern LIKE '%7%'
       OR Pattern LIKE '%8%'
       OR Pattern LIKE '%9%'

      PRINT 'Iteration done, unfinished rules left: ' + CAST(@UnfinishedRules AS VARCHAR(6)) + ' at ' + CAST(GETDATE() AS VARCHAR(50))

END

SELECT * FROM ##Rules ORDER BY RuleNr

SELECT DISTINCT D.ID FROM ##Rules R
INNER JOIN ##Data D ON D.Line = R.Pattern
WHERE RuleNr = 0

SELECT * 
FROM ##Data D
INNER JOIN ##Rules R ON D.Line = R.Pattern
                    AND R.RuleNr = 0
ORDER BY D.ID 

--95 is not correct for part 1
--115 is correct for part 1

--There are 125 lines with exactly 24 characters in the data

END

ELSE --DoPart2

BEGIN

    -- Changes for part 2
    INSERT ##Rules (RuleNr, Pattern) VALUES (8, ' 42 8 ')
    INSERT ##Rules (RuleNr, Pattern) VALUES (11, ' 42 11 31 ')

    --SELECT * FROM ##Rules ORDER BY RuleNr

    DECLARE @AlmostUnfinishedRules INT = 100

WHILE @AlmostUnfinishedRules <> 0
BEGIN

    ;WITH cte_IncompletedRules AS (
        SELECT DISTINCT RuleNr
        FROM ##Rules
        WHERE Pattern LIKE '%0%'
           OR Pattern LIKE '%1%'
           OR Pattern LIKE '%2%'
           OR Pattern LIKE '%3%'
           OR Pattern LIKE '%4%'
           OR Pattern LIKE '%5%'
           OR Pattern LIKE '%6%'
           OR Pattern LIKE '%7%'
           OR Pattern LIKE '%8%'
           OR Pattern LIKE '%9%'    
    ), cte_CompletedRules AS (
        SELECT R.RuleNr, Pattern
        FROM ##Rules R
        LEFT JOIN cte_IncompletedRules cIR ON R.RuleNr = cIR.RuleNr
        WHERE Pattern NOT LIKE '%0%'
          AND Pattern NOT LIKE '%1%'
          AND Pattern NOT LIKE '%2%'
          AND Pattern NOT LIKE '%3%'
          AND Pattern NOT LIKE '%4%'
          AND Pattern NOT LIKE '%5%'
          AND Pattern NOT LIKE '%6%'
          AND Pattern NOT LIKE '%7%'
          AND Pattern NOT LIKE '%8%'
          AND Pattern NOT LIKE '%9%'
          AND cIR.RuleNr IS NULL
    )
    INSERT ##TempRules (OriginalID, RuleNr, Pattern)
    SELECT R.ID, R.RuleNr, REPLACE(R.Pattern, ' ' + CAST(cCR.RuleNr AS VARCHAR(3)) + ' ', ' ' + cCR.Pattern + ' ')
    FROM ##Rules R
    INNER JOIN cte_CompletedRules cCR ON R.Pattern LIKE '% ' + CAST(cCR.RuleNr AS VARCHAR(3)) + ' %'
    
    DELETE FROM ##Rules WHERE ID IN (SELECT DISTINCT OriginalID FROM ##TempRules)
    INSERT ##Rules (RuleNr, Pattern) SELECT DISTINCT RuleNr, Pattern FROM ##TempRules
    DELETE FROM ##TempRules

    --Clean pattern
    UPDATE R
    SET Pattern = TRIM(REPLACE(Pattern, ' ', ''))
    FROM ##Rules R
    WHERE Pattern NOT LIKE '%0%'
      AND Pattern NOT LIKE '%1%'
      AND Pattern NOT LIKE '%2%'
      AND Pattern NOT LIKE '%3%'
      AND Pattern NOT LIKE '%4%'
      AND Pattern NOT LIKE '%5%'
      AND Pattern NOT LIKE '%6%'
      AND Pattern NOT LIKE '%7%'
      AND Pattern NOT LIKE '%8%'
      AND Pattern NOT LIKE '%9%'

    SELECT @AlmostUnfinishedRules = COUNT(1)
    FROM ##Rules
    WHERE (Pattern LIKE '%0%'
       OR Pattern LIKE '%1%'
       OR Pattern LIKE '%2%'
       OR Pattern LIKE '%3%'
       OR Pattern LIKE '%4%'
       OR Pattern LIKE '%5%'
       OR Pattern LIKE '%6%'
       OR Pattern LIKE '%7%'
       OR Pattern LIKE '%8%'
       OR Pattern LIKE '%9%')
       AND RuleNr NOT IN (0, 8, 11)

      PRINT 'Iteration done, unfinished rules left: ' + CAST(@AlmostUnfinishedRules AS VARCHAR(6)) + ' at ' + CAST(GETDATE() AS VARCHAR(50))

END

--SELECT * FROM ##Rules WHERE RuleNr IN (0, 8, 11, 31, 42)
--SELECT DISTINCT RuleNr, Pattern FROM ##Rules WHERE LEN(Pattern) >= 8

/*
Ran above loop 1 more time manually to reduce rules to letters and combo's of 0, 8 and 11

0 = 8 11
8 = 42 | 42 8
11 = 42 31 | 42 11 31

=>
0 = (42 * x) & 42 & (11 * y) & 31 <=>
0 = (42 * (x+1)) & (11 * y) & 31 <=> -- x + 1 is the same as x since we don't know x, simarily works for y
0 = (42 * x) & (31 * y)
with x >= 2 and y >= 1 -- At least one 42 from 8 and one from 11, and at least one 31 from 11

So as long as the data starts with 42 pattern(s) and ends with 31 pattern(s), it's ok
*/

--SELECT * FROM ##Rules ORDER BY RuleNr
--SELECT * FROM ##Rules WHERE RuleNr = 31
--SELECT * FROM ##Rules WHERE RuleNr = 42

ALTER TABLE ##Data ADD IsValid INT

DECLARE @Counter INT = 1 
DECLARE @MaxID INT 
DECLARE @Data VARCHAR(200)
DECLARE @BlockNr INT
DECLARE @IsValid INT
DECLARE @Switch INT 
DECLARE @BlockLength INT
DECLARE @Count42 INT
DECLARE @Count31 INT

SELECT TOP 1 @BlockLength = LEN(Pattern) FROM ##Rules WHERE RuleNr = 42

SELECT @MaxID = MAX(ID) FROM ##Data

WHILE @Counter <= @MaxID
BEGIN

    SELECT @Data = Line FROM ##Data WHERE ID = @Counter
    SET @IsValid = 1
    SET @BlockNr = 1
    SET @Switch = 0
    SET @Count31 = 0
    SET @Count42 = 0

    WHILE LEN(@Data) > 0 AND @IsValid = 1
    BEGIN

        IF NOT EXISTS(SELECT 1 FROM ##Rules WHERE RuleNr IN (31, 42) AND LEFT(@Data, @BlockLength) = Pattern)
            SET @IsValid = 0 --Unknown part of pattern
        ELSE
            IF @BlockNr IN (1, 2) AND NOT EXISTS (SELECT 1 FROM ##Rules WHERE RuleNr = 42 AND LEFT(@Data, @BlockLength) = Pattern)
                SET @IsValid = 0 --Data needs to start with 2 42 blocks
            ELSE
                IF @Switch = 1 AND NOT EXISTS (SELECT 1 FROM ##Rules WHERE RuleNr = 31 AND LEFT(@Data, @BlockLength) = Pattern)
                    SET @IsValid = 0 -- Data tries to switch back to 42
                ELSE
                    IF NOT EXISTS (SELECT 1 FROM ##Rules WHERE RuleNr = 42 AND LEFT(@Data, @BlockLength) = Pattern)
                    BEGIN
                        SET @Switch = 1 -- Datablock is present in 31 but not in 42 so we've switched to the other block set
                        SET @Count31 = @Count31 + 1
                    END
                    ELSE 
                        SET @Count42 = @Count42 + 1

        SET @BlockNr = @BlockNr + 1
        SET @Data = SUBSTRING(@Data, @BlockLength + 1, LEN(@Data)) -- Cut off the front of the block

    END

    IF @Switch = 0 SET @IsValid = 0 -- The data didn't have a 31 block
    IF @Count31 >= @Count42 SET @IsValid = 0 -- The data should always have more 42 blocks than 31

    PRINT 'ID: ' + CAST(@Counter AS VARCHAR(4)) + ' Is Valid: ' + CAST(@IsValid AS CHAR(1)) + ' Nr of 42: ' + CAST(@Count42 AS VARCHAR(2)) + ' Nr of 31: ' + CAST(@Count31 AS VARCHAR(2)) 

    UPDATE ##Data
    SET IsValid = @IsValid
    WHERE ID = @Counter

    SET @Counter = @Counter + 1

END

SELECT IsValid, COUNT(1) FROM ##Data GROUP BY IsValid

END

SELECT * FROM ##Data

--251 is too high for part 2
--240 is too high for part 2
--237 is correct for part 2

/*

DROP TABLE ##Data
DROP TABLE ##TempRules
DROP TABLE ##Rules
DROP TABLE ##Input

*/



