use Test_WME

SET NOCOUNT ON

CREATE TABLE ##Input (Line NVARCHAR(MAX));

BULK INSERT ##Input
FROM 'D:\Wilfred\AdventOfCode\2016\input09.txt'
WITH (ROWTERMINATOR = '0x0A');

--DELETE FROM ##Input
--INSERT ##Input (Line) Values ('(25x3)(3x3)ABC(2x3)XY(5x2)PQRSTX(18x9)(3x2)TWO(5x7)SEVEN')
--INSERT ##Input (Line) Values ('(27x12)(20x12)(13x14)(7x10)(1x12)A')
--INSERT ##Input (Line) Values ('X(8x2)(3x3)ABCY')

CREATE TABLE ##Letters (ID INT IDENTITY(1,1), Nr INT, Letter CHAR(1))

;WITH cte_Letters AS (
    SELECT 1 AS Nr
    ,      LEFT(Line, 1) AS Letter
    ,      SUBSTRING(Line, 2, LEN(Line)) AS Remainder
    FROM ##Input
    UNION ALL
    SELECT Nr + 1
    ,      LEFT(Remainder, 1) 
    ,      SUBSTRING(Remainder, 2, LEN(Remainder)) 
    FROM cte_Letters
    WHERE LEN(Remainder) > 0
)
INSERT ##Letters (Nr, Letter)
SELECT Nr, Letter FROM cte_Letters OPTION (MAXRECURSION 30000)

DECLARE @Letter CHAR(1) = ''
DECLARE @InCompression INT = 0
DECLARE @CreatingSubstring INT = 0 
DECLARE @Substring VARCHAR(MAX)=''
DECLARE @Length INT = 0
DECLARE @Quantity INT = 0
DECLARE @ResultString VARCHAR(MAX)=''
DECLARE @Counter INT = 0

DECLARE LetterCursor CURSOR FOR
SELECT Letter FROM ##Letters ORDER BY Nr

OPEN LetterCursor

FETCH NEXT FROM LetterCursor INTO @Letter

WHILE @@FETCH_STATUS = 0
BEGIN

    --IF @InCompression = 0 PRINT @Letter

    IF (@Letter = '(' AND @InCompression = 0 AND @CreatingSubstring = 0) BEGIN SET @InCompression = 1; SET @Length = 0; SET @Quantity = 0; SET @Substring = '' END
    ELSE 
    IF (@Letter = ')' AND @InCompression = 1 AND @CreatingSubstring = 0) BEGIN SET @Quantity = CAST(@Substring AS INT); SET @Substring = ''; SET @CreatingSubstring = 1 END
    ELSE 
    IF (@Letter = 'x' AND @InCompression = 1 AND @CreatingSubstring = 0) BEGIN SET @Length = CAST(@Substring AS INT); SET @Substring = '' END
    ELSE 
    IF @InCompression = 1 OR @CreatingSubstring = 1 SET @Substring = @Substring + @Letter
    ELSE 
    IF @InCompression = 0
    BEGIN
        SET @ResultString = @ResultString + @Letter

        PRINT 'Regular letter added: ' + @Letter
    END

    IF @InCompression = 1 AND LEN(@Substring) = @Length AND @CreatingSubstring = 1
    BEGIN
        
        --PRINT @Substring        
        --PRINT @Quantity
        --PRINT @Length

        SET @Counter = 0

        WHILE @Counter < @Quantity
        BEGIN
            
            SET @ResultString = @ResultString + @Substring

            SET @Counter = @Counter + 1

        END

        SET @Substring = ''
        SET @CreatingSubstring = 0
        SET @InCompression = 0       
        
    END

    --PRINT @ResultString

    FETCH NEXT FROM LetterCursor INTO @Letter
END


CLOSE LetterCursor
DEALLOCATE LetterCursor

--SELECT LEN(Line), Line FROM ##Input
--SELECT LEN(@ResultString), @ResultString
--SELECT @ResultString 

--SELECT *, LEN(Line) FROM ##Input

--112830 is correct for part 1


--X(8x2)(3x3)ABCY
--SELECT LEN('XABCABCABCABCABCABCY')


CREATE TABLE ##Markers (ID INT IDENTITY(1,1), StartPos INT, EndPos INT, Length INT, Quantity INT, Level INT, Size BIGINT, ParentMarkerID INT)

SET @Counter = 1
SET @InCompression = 0
SET @Length = 0
SET @Quantity = 0

DECLARE LetterCursor CURSOR FOR
SELECT Letter FROM ##Letters ORDER BY Nr

OPEN LetterCursor

FETCH NEXT FROM LetterCursor INTO @Letter

WHILE @@FETCH_STATUS = 0
BEGIN

    IF (@Letter = '(') 
        BEGIN 
            SET @InCompression = @Counter; 
            SET @Length = 0; 
            SET @Quantity = 0; 
            SET @Substring = '' 

        END
    ELSE 
    IF (@Letter = ')') 
        BEGIN 
            SET @Quantity = CAST(@Substring AS INT); 

            INSERT ##Markers (StartPos, EndPos, Length, Quantity, Level) VALUES (@InCompression, @Counter, @Length, @Quantity, 0)

            SET @Substring = '';        
            SET @InCompression = 0
        END
    ELSE 
    IF (@Letter = 'x' AND @InCompression > 0) 
        BEGIN 
          
            SET @Length = CAST(@Substring AS INT); 
            SET @Substring = '' 
        END
    ELSE 
    IF @InCompression > 0 SET @Substring = @Substring + @Letter



    SET @Counter = @Counter + 1

    FETCH NEXT FROM LetterCursor INTO @Letter
END


CLOSE LetterCursor
DEALLOCATE LetterCursor

--SELECT Line FROM ##Input
--SELECT MAX(Level) FROM ##Markers




SELECT COUNT(1) FROM ##Markers
WHILE (SELECT @@ROWCOUNT) > 0
BEGIN 
    UPDATE MDown 
    SET MDown.Level = MTop.Level + 1
    , MDown.ParentMarkerID = MTop.ID
    FROM ##Markers MDown 
    INNER JOIN ##Markers MTop ON MDown.StartPos BETWEEN MTop.EndPos AND MTop.EndPos + MTop.Length
                             AND MTop.ID <> MDown.ID 
                             AND MTop.Level = MDown.Level
END

/*
--SELECT COUNT(1) FROM ##Markers WHERE Level = 6

--UPDATE ##Markers
--SET Size = Length * Quantity
--WHERE Level = 6 

--SET @Counter = 5

--WHILE @Counter >= 0 
--BEGIN 

--    ;WITH cte_Calc AS (
--        SELECT MTop.ID, SUM(MTop.Quantity * MDown.Size /*+ MDown.Size - MTop.Length*/) AS Size
--        FROM ##Markers MTop
--        INNER JOIN ##Markers MDown ON MDown.StartPos BETWEEN MTop.EndPos AND MTop.EndPos + MTop.Length
--        WHERE MTop.Level = @Counter
--        GROUP BY MTop.ID
--    )
--    UPDATE M
--    SET M.Size = cC.Size
--    FROM ##Markers M
--    INNER JOIN cte_Calc cC ON M.ID = cC.ID

--    SET @Counter = @Counter - 1

--END

--SELECT * FROM ##Markers

--SELECT SUM(Size) FROM ##Markers WHERE Level = 0

--19532297555 is too high for part 2

/*

XABCABCABCABCABCABCY --20

(27x12)(20x12)(13x14)(7x10)(1x12)A
(27x12)(20x12)(13x14)(7x10)AAAAAAAAAAAA
(27x12)(20x12)(13x14)
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA --72

(27x12)(20x12)(13x14)(7x10)(1x12)A

(20x12)(13x14)(7x10)(1x12)A(20x12)(13x14)(7x10)(1x12)A(20x12)(13x14)(7x10)(1x12)A(20x12)(13x14)(7x10)(1x12)A(20x12)(13x14)(7x10)(1x12)A(20x12)(13x14)(7x10)(1x12)A(20x12)(13x14)(7x10)(1x12)A(20x12)(13x14)(7x10)(1x12)A(20x12)(13x14)(7x10)(1x12)A(20x12)(13x14)(7x10)(1x12)A(20x12)(13x14)(7x10)(1x12)A(20x12)(13x14)(7x10)(1x12)A

(13x14)(7x10)(1x12)A(13x14)(7x10)(1x12)A(13x14)(7x10)(1x12)A(13x14)(7x10)(1x12)A(13x14)(7x10)(1x12)A(13x14)(7x10)(1x12)A(13x14)(7x10)(1x12)A(13x14)(7x10)(1x12)A(13x14)(7x10)(1x12)A(13x14)(7x10)(1x12)A(13x14)(7x10)(1x12)A(13x14)(7x10)(1x12)A
En dat dus 12x

(7x10)(1x12)A(7x10)(1x12)A(7x10)(1x12)A(7x10)(1x12)A(7x10)(1x12)A(7x10)(1x12)A(7x10)(1x12)A(7x10)(1x12)A(7x10)(1x12)A(7x10)(1x12)A(7x10)(1x12)A(7x10)(1x12)A(7x10)(1x12)A
En dat dan weer 14x (x12 van de vorige)

(1x12)A
Dit 10x (x13x12)

AAAAAA AAAAAA
Lengte 12

SELECT 12*10*14*12*12


X(8x2)(3x3)ABCY
X(3x3)ABC(3x3)ABCY
XABCABCABCABCABCABCY

X(8x2)(3x3)ABCY
X(8x2)ABCABCABCY
XABCABCABABCABCABCY

Dus de compressie is NIET interchangable



*/

--;WITH cte_BracketClose AS (
--    SELECT ROW_NUMBER() OVER (ORDER BY Nr) AS RN
--    ,      Nr
--    ,      Letter 
--    FROM ##Letters 
--    WHERE Letter = ')'
--), cte_BracketOpen AS (
--    SELECT ROW_NUMBER() OVER (ORDER BY Nr) AS RN
--    ,      Nr
--    ,      Letter 
--    FROM ##Letters 
--    WHERE Letter = '('
--)
--SELECT BC.Nr + 1, BO.Nr - BC.Nr - 1
--FROM cte_BracketClose BC
--INNER JOIN cte_BracketOpen BO ON BC.RN = BO.RN - 1

--SELECT * FROM ##Input

CREATE TABLE Solution (ID INT IDENTITY, Line VARCHAR(MAX))
CREATE TABLE SolutionPart (ID INT IDENTITY, Line VARCHAR(MAX))

ALTER TABLE Test_WME.dbo.SolutionPart ADD CONSTRAINT PK_SolutionPart PRIMARY KEY (ID)

INSERT SolutionPart (Line)
SELECT SUBSTRING(Line, StartPos, EndPos + Length - StartPos + 1)
FROM ##Input 
CROSS APPLY ##Markers
WHERE Level = 0

SET @Counter = 0
PRINT CAST(GETDATE() AS VARCHAR(15)) + ' Counter: ' + CAST(@Counter AS VARCHAR(10))

WHILE (SELECT COUNT(1) FROM SolutionPart) > 0 
BEGIN

    SELECT @Substring = SUBSTRING(Line, CHARINDEX(')', Line) + 1, LEN(Line))
    ,      @Length    = SUBSTRING(Line, 2, CHARINDEX('x', Line) - 2)
    ,      @Quantity  = SUBSTRING(Line, CHARINDEX('x', Line) + 1, CHARINDEX(')', Line) - CHARINDEX('x', Line) - 1)
    FROM SolutionPart
    WHERE ID = (SELECT MIN(ID) AS MinID FROM SolutionPart)

--    PRINT @Substring + ' ' + CAST(@Length AS VARCHAR(5)) + ' ' + CAST(@Quantity AS VARCHAR(5))

    DELETE FROM SolutionPart WHERE ID = (SELECT MIN(ID) AS MinID FROM SolutionPart)

    IF (SELECT CHARINDEX('(', @Substring)) = 1
    BEGIN
        

        INSERT SolutionPart
        SELECT TOP(@Quantity) SUBSTRING(@Substring, 1, @Length)
        FROM sys.messages

--        PRINT 'went to solution part with id ' + CAST(@@IDENTITY AS VARCHAR(8))

        IF @Length < LEN(@Substring)
        BEGIN
            
            SET @Substring = SUBSTRING(@Substring, @Length + 1, LEN(@SubString))

            IF (SELECT CHARINDEX('(', @Substring)) > 0
                INSERT SolutionPart SELECT @Substring
            ELSE 
                INSERT Solution SELECT SUBSTRING(@Substring, @Length + 1, LEN(@SubString))

--            PRINT 'and tail was added: ' + @Substring + ' with id ' + CAST(@@IDENTITY AS VARCHAR(5))
        END
    END
    ELSE IF (SELECT CHARINDEX('(', @Substring)) > 0
    BEGIN

        --Het stuk dat we krijgen bevat een haakje maar start daar niet mee

        IF (SELECT CHARINDEX('(', @Substring)) <= @Length
            PRINT 'Heel onhandig: ' + @Substring
        ELSE 
        BEGIN
            
--            PRINT 'Onhandig: ' + @Substring
            
            INSERT Solution
            SELECT TOP(@Quantity) SUBSTRING(@Substring, 1, @Length)
            FROM sys.messages

--            PRINT 'went to solution with id ' + CAST(@@IDENTITY AS VARCHAR(8))

            INSERT Solution SELECT SUBSTRING(@Substring, @Length - 1, CHARINDEX('(', @SubString) - @Length - 1)

--            PRINT 'went to solution with id ' + CAST(@@IDENTITY AS VARCHAR(8))

            INSERT SolutionPart SELECT SUBSTRING(@Substring, CHARINDEX('(', @SubString), LEN(@Substring))
            
--            PRINT 'went to solution part with id ' + CAST(@@IDENTITY AS VARCHAR(8))
        END
    END
    ELSE IF (SELECT CHARINDEX('(', @Substring)) = 0
    BEGIN

        INSERT Solution
        SELECT TOP(@Quantity) SUBSTRING(@Substring, 1, @Length)
        FROM sys.messages

--        PRINT 'went to solution with id ' + CAST(@@IDENTITY AS VARCHAR(8))

        IF @Length < LEN(@Substring)
        BEGIN
            
            SET @Substring = SUBSTRING(@Substring, @Length + 1, LEN(@SubString))
            INSERT Solution SELECT SUBSTRING(@Substring, @Length + 1, LEN(@SubString))

--            PRINT 'and tail was added: ' + @Substring

        END

    END

    SET @Counter = @Counter + 1

    IF @Counter % 100 = 0 PRINT CAST(GETDATE() AS VARCHAR(15)) + ' Counter: ' + CAST(@Counter AS VARCHAR(10))
END
*/

/*

DROP TABLE ##Input
DROP TABLE ##Letters

DROP TABLE ##Markers

--DROP TABLE Solution
--DROP TABLE SolutionPart

*/

--SELECT * FROM ##Input


--INSERT ##Input (Line) Values ('(25x3)(3x3)ABC(2x3)XY(5x2)PQRSTX(18x9)(3x2)TWO(5x7)SEVEN')
--INSERT ##Input (Line) Values ('(27x12)(20x12)(13x14)(7x10)(1x12)A')
--INSERT ##Input (Line) Values ('X(8x2)(3x3)ABCY')


--SELECT dbo.DetermineSize('X(8x2)(3x3)ABCY') --> 20 die is goed

--SELECT dbo.DetermineSize('(27x12)(20x12)(13x14)(7x10)(1x12)A') --> 241920 die is ook goed

--SELECT dbo.DetermineSize('(25x3)(3x3)ABC(2x3)XY(5x2)PQRSTX(18x9)(3x2)TWO(5x7)SEVEN') --> 103 :( die is fout

;WITH cte_Sizes AS (
    SELECT dbo.DetermineSize(SUBSTRING(Line, StartPos, EndPos - StartPos + Length + 1)) AS Size
    FROM ##Input
    CROSS APPLY ##Markers
    WHERE Level = 0
)
SELECT SUM(Size) FROM cte_Sizes


--SELECT * FROM ##Input


-->>>> 10931789799 :D :D :D Hij is goed!


/*** De gebruikte functie:


ALTER FUNCTION dbo.DetermineSize (@Str VARCHAR(MAX))
RETURNS BIGINT
AS 

BEGIN

    DECLARE @Substring VARCHAR(MAX)
    DECLARE @Length INT
    DECLARE @Quantity INT

    -- Als er geen haakje meer in staat dan geven we de lengte van de string terug
    IF CHARINDEX('(',@Str) = 0 
    BEGIN
        RETURN LEN(@Str)
    END

    -- Als de string niet start met een haakje dan geven de lengte terug tot aan het haakje plus de lengte van de ongecomprimeerde string
    IF CHARINDEX('(',@Str) > 1
    BEGIN
        
        RETURN LEN(SUBSTRING(@Str, 1, CHARINDEX('(',@Str) -1)) + dbo.DetermineSize(SUBSTRING(@Str, CHARINDEX('(', @Str), LEN(@Str)))

    END

    -- Als we hier komen dan weten we dus dat de string met een marker / haakje begint
    SELECT @Substring = SUBSTRING(@Str, CHARINDEX(')', @Str) + 1, LEN(@Str))
    ,      @Length    = SUBSTRING(@Str, 2, CHARINDEX('x', @Str) - 2)
    ,      @Quantity  = SUBSTRING(@Str, CHARINDEX('x', @Str) + 1, CHARINDEX(')', @Str) - CHARINDEX('x', @Str) - 1)

    RETURN @Quantity * dbo.DetermineSize(SUBSTRING(@Substring, 1, @Length)) + + dbo.DetermineSize(SUBSTRING(@Substring, @Length + 1, LEN(@Substring)))

END


***/