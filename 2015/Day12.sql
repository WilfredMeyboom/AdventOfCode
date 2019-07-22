use Test_WME

SET NOCOUNT ON

CREATE TABLE ##Input (Line NVARCHAR(MAX));

BULK INSERT ##Input
FROM 'D:\Wilfred\AdventOfCode\2015\input12.txt'
WITH (ROWTERMINATOR = '0x0A');

CREATE TABLE ##Chars (ID INT IDENTITY(1,1), Pos INT, Charac CHAR)

;WITH cte_Chars AS (
    SELECT 1 AS Pos
    ,      LEFT(Line, 1) AS Charac
    ,      SUBSTRING(Line, 2, LEN(Line)) AS Remainder
    FROM ##Input
    UNION ALL
    SELECT Pos + 1
    ,      LEFT(Remainder, 1)
    ,      SUBSTRING(Remainder, 2, LEN(Remainder)) 
    FROM cte_Chars
    WHERE LEN(Remainder) > 0
)
INSERT ##Chars (Pos, Charac)
SELECT Pos, Charac
FROM cte_Chars
OPTION (MAXRECURSION 27000)


DECLARE @Char CHAR
DECLARE @Pos INT
DECLARE @PreviousPos INT = 0
DECLARE @Result VARCHAR(10) = ''

CREATE TABLE ##Results (ID INT IDENTITY(1,1), Result INT)

DECLARE CharCursor CURSOR FOR 
SELECT Pos, Charac FROM ##Chars
WHERE Charac IN ('-', '1', '2', '3', '4', '5', '6', '7', '8', '9', '0')

OPEN CharCursor

FETCH NEXT FROM CharCursor INTO @Pos, @Char

WHILE @@FETCH_STATUS = 0
BEGIN

    IF @PreviousPos = @Pos - 1
        SET @Result = @Result + @Char
    ELSE
    BEGIN

        INSERT ##Results (Result) SELECT CAST(@Result AS INT)

        SET @Result = @Char

    END


    SET @PreviousPos = @Pos

    FETCH NEXT FROM CharCursor INTO @Pos, @Char

END

CLOSE CharCursor
DEALLOCATE CharCursor

SELECT SUM(Result) FROM ##Results

--111754 is correct for part 1


/*

DROP TABLE ##Input

*/

CREATE TABLE ##RedPositions (Pos INT)

INSERT ##RedPositions (Pos)
SELECT L1.Pos AS StartRed
FROM ##Chars L1
INNER JOIN ##Chars L2 ON L1.Pos = L2.Pos - 1 AND L2.Charac = 'e'
INNER JOIN ##Chars L3 ON L2.Pos = L3.Pos - 1 AND L3.Charac = 'd'
WHERE L1.Charac = 'r'


SELECT * INTO ##BackupChars FROM ##Chars

CREATE TABLE ##BracketArray (ID INT IDENTITY(1,1), Iteration INT, BracketNr INT, Type CHAR(2), OpenPos INT, ClosePos INT)

DECLARE @Iteration INT = 1

WHILE (SELECT COUNT(1) FROM ##Chars) > 0
BEGIN

    ;WITH cte_OpenBracket AS (
        SELECT Pos
        FROM ##Chars
        WHERE Charac = '['
    ), cte_CloseBracket AS (
        SELECT Pos
        FROM ##Chars
        WHERE Charac = ']'
    ), cte_BracketArray AS (
        SELECT OB.Pos AS OpenPos, CB.Pos AS ClosePos
        FROM cte_OpenBracket OB
        INNER JOIN cte_CloseBracket CB ON OB.Pos < CB.Pos
        LEFT JOIN (
            SELECT Pos
            FROM ##Chars
            WHERE Charac IN ('[',']','{','}')
        ) Bracks ON Bracks.Pos BETWEEN OB.Pos + 1 AND CB.Pos - 1
        WHERE Bracks.Pos IS NULL

    ), cte_OpenCurlyBracket AS (
        SELECT Pos
        FROM ##Chars
        WHERE Charac = '{'
    ), cte_CloseCurlyBracket AS (
        SELECT Pos
        FROM ##Chars
        WHERE Charac = '}'
    ), cte_CurlyBracketArray AS (
        SELECT OB.Pos AS OpenPos, CB.Pos AS ClosePos
        FROM cte_OpenCurlyBracket OB
        INNER JOIN cte_CloseCurlyBracket CB ON OB.Pos < CB.Pos
        LEFT JOIN (
            SELECT Pos
            FROM ##Chars
            WHERE Charac IN ('[',']','{','}')
        ) Bracks ON Bracks.Pos BETWEEN OB.Pos + 1 AND CB.Pos - 1
        WHERE Bracks.Pos IS NULL
    )
    INSERT ##BracketArray (Iteration, Type, BracketNr, OpenPos, ClosePos) 
    SELECT @Iteration, '[]', ROW_NUMBER() OVER (ORDER BY (SELECT 0)), OpenPos, ClosePos FROM cte_BracketArray
    UNION 
    SELECT @Iteration, '{}', ROW_NUMBER() OVER (ORDER BY (SELECT 0)), OpenPos, ClosePos FROM cte_CurlyBracketArray


    DELETE FROM C 
    FROM ##Chars C
    INNER JOIN ##BracketArray BA ON Iteration = @Iteration AND C.Pos BETWEEN BA.OpenPos AND BA.ClosePos

    SET @Iteration = @Iteration + 1

END

--SELECT * FROM ##Input

DROP TABLE ##Chars
SELECT * INTO ##Chars FROM ##BackupChars

SELECT * FROM ##Chars
SELECT * FROM ##RedPositions
SELECT * FROM ##BracketArray

;WITH cte_RedInBrackets AS (
    SELECT RP.Pos, MAX(BA.OpenPos) OpenPos
    FROM ##RedPositions RP
    INNER JOIN ##BracketArray BA ON RP.Pos BETWEEN BA.OpenPos AND BA.ClosePos
    GROUP BY RP.Pos
), cte_ToBeDeleted AS (
    SELECT BA.OpenPos, BA.ClosePos
    FROM cte_RedInBrackets cRIB
    INNER JOIN ##BracketArray BA ON cRIB.OpenPos = BA.OpenPos 
    WHERE Type = '{}'
)
DELETE FROM C
FROM ##Chars C
INNER JOIN cte_ToBeDeleted cTBD ON C.Pos BETWEEN cTBD.OpenPos AND cTBD.ClosePos


TRUNCATE TABLE ##Results

DECLARE @Char CHAR
DECLARE @Pos INT
DECLARE @PreviousPos INT = 0
DECLARE @Result VARCHAR(10) = ''


DECLARE CharCursor CURSOR FOR 
SELECT Pos, Charac FROM ##Chars
WHERE Charac IN ('-', '1', '2', '3', '4', '5', '6', '7', '8', '9', '0')

OPEN CharCursor

FETCH NEXT FROM CharCursor INTO @Pos, @Char

WHILE @@FETCH_STATUS = 0
BEGIN

    IF @PreviousPos = @Pos - 1
        SET @Result = @Result + @Char
    ELSE
    BEGIN

        INSERT ##Results (Result) SELECT CAST(@Result AS INT)

        SET @Result = @Char

    END


    SET @PreviousPos = @Pos

    FETCH NEXT FROM CharCursor INTO @Pos, @Char

END

SELECT SUM(Result) FROM ##Results


CLOSE CharCursor
DEALLOCATE CharCursor


--65402 is correct for part 2

DROP TABLE ##BackupChars
DROP TABLE ##BracketArray
DROP TABLE ##Chars
DROP TABLE ##Input
DROP TABLE ##RedPositions
DROP TABLE ##Results