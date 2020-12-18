use Test_WME

SET NOCOUNT ON

CREATE TABLE ##Input (Line NVARCHAR(MAX));

BULK INSERT ##Input
FROM 'C:\Source\AdventOfCode\2020\input18.txt'
WITH (ROWTERMINATOR = '0x0A');

CREATE TABLE ##Homework (ID INT IDENTITY(1,1), Line VARCHAR(200), PosS INT, PosE INT)

INSERT ##Homework (Line)
SELECT Line FROM ##Input

DECLARE @Done INT = 0
DECLARE @DoPart2 INT = 1


WHILE @Done <> 1
BEGIN

    ;WITH cte_ClosingBracket AS (
        SELECT ID
        ,      CHARINDEX(')', Line) + 1 AS PosE
        ,      LEFT(Line, CHARINDEX(')', Line)) AS PartLine
        FROM ##Homework
    ), cte_Brackets AS (
        SELECT ID
        ,      LEN(PartLine) - CHARINDEX('(', REVERSE(PartLine)) + 1 AS PosS
        ,      PosE
        FROM cte_ClosingBracket
    )
    UPDATE H
    SET PosS = B.PosS
    ,   PosE = B.PosE   
    FROM ##Homework H
    INNER JOIN cte_Brackets B ON H.ID = B.ID

--    ,      CASE WHEN B.PosE > 0 THEN SUBSTRING(H.Line, B.PosS, B.PosE - B.PosS) ELSE '' END AS Bracket


    IF @DoPart2 = 0 
        UPDATE H
        SET Line = LEFT(Line, PosS - 1) + CAST(dbo.AoC_Calculate(SUBSTRING(Line, PosS + 1, PosE - PosS - 2)) AS VARCHAR(20)) + SUBSTRING(Line, PosE, LEN(Line))
        FROM ##Homework H
        WHERE PosE > 1
    ELSE
        UPDATE H
        SET Line = LEFT(Line, PosS - 1) + CAST(dbo.AoC_CalculatePrioPlus(SUBSTRING(Line, PosS + 1, PosE - PosS - 2)) AS VARCHAR(20)) + SUBSTRING(Line, PosE, LEN(Line))
        FROM ##Homework H
        WHERE PosE > 1


    IF NOT EXISTS(SELECT 1 FROM ##Homework WHERE PosE > 1) SET @Done = 1

END

SELECT dbo.AoC_Calculate(Line), * FROM ##Homework
SELECT SUM(dbo.AoC_Calculate(Line)) FROM ##Homework

-- 654686398176 is correct for part 1

SELECT dbo.AoC_CalculatePrioPlus(Line), * FROM ##Homework
SELECT SUM(dbo.AoC_CalculatePrioPlus(Line)) FROM ##Homework

-- 8952864356993 is correct for part 2

/*

DROP TABLE ##Homework
DROP TABLE ##Input

*/



/*

CREATE OR ALTER FUNCTION dbo.AoC_Calculate(@Input VARCHAR(100))
RETURNS BIGINT
AS
BEGIN
    
    DECLARE @Output BIGINT

    SET @Input = LTRIM(@Input + ' ')

    DECLARE @Operator CHAR

    WHILE LEN(@Input) > 0
    BEGIN

        IF @Output IS NULL 
            SET @Output = CAST(LEFT(@Input, CHARINDEX(' ', @Input)) AS BIGINT)
        ELSE
            IF LEFT(@Input, CHARINDEX(' ', @Input)) IN ('+' ,'*') 
                SET @Operator = LEFT(@Input, CHARINDEX(' ', @Input))
            ELSE
                IF @Operator = '+' SET @Output = @Output + CAST(LEFT(@Input, CHARINDEX(' ', @Input)) AS BIGINT)
                ELSE SET @Output = @Output * CAST(LEFT(@Input, CHARINDEX(' ', @Input)) AS BIGINT)
        
        IF CHARINDEX(' ', @Input) > 0
            SET @Input = LTRIM(SUBSTRING(@Input, CHARINDEX(' ', @Input), LEN(@Input)))
        ELSE SET @Input = ''

    END

    RETURN @Output

END



CREATE OR ALTER FUNCTION dbo.AoC_CalculatePrioPlus(@Input VARCHAR(100))
RETURNS BIGINT
AS
BEGIN
    
    SET @Input = LTRIM(@Input + ' ')


    WHILE CHARINDEX('+', @Input) > 0
    BEGIN
        
        ;WITH cte_Posses AS (
            SELECT CASE WHEN CHARINDEX(' ', REVERSE(LEFT(@Input, CHARINDEX('+', @Input) - 2))) > 0 
                        THEN CHARINDEX('+', @Input) - CHARINDEX(' ', REVERSE(LEFT(@Input, CHARINDEX('+', @Input) - 2))) 
                        ELSE 1 END AS PosS
            ,      CHARINDEX('+', @Input) + CHARINDEX(' ', SUBSTRING(@Input, CHARINDEX('+', @Input) + 2, LEN(@Input))) AS PosE
        )
        SELECT @Input = LEFT(@Input, PosS - 1) + CAST(dbo.AoC_Calculate(SUBSTRING(@Input, PosS, PosE - PosS + 1)) AS VARCHAR(20)) + SUBSTRING(@Input, PosE + 1, LEN(@Input))
        FROM cte_Posses

    END


    IF CHARINDEX('*', @Input) > 0 RETURN dbo.AoC_Calculate(@Input)
    ELSE RETURN CAST(@Input AS BIGINT)

    --Dummy statement
    RETURN NULL

END


*/


