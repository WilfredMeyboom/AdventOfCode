use Test_WME

SET NOCOUNT ON

CREATE TABLE ##Input (Line NVARCHAR(MAX));

BULK INSERT ##Input
FROM 'D:\Wilfred\AdventOfCode\2016\input21.txt'
WITH (ROWTERMINATOR = '0x0A');

--SELECT * FROM ##Input

CREATE TABLE ##Instructions (ID INT IDENTITY(1,1), InstrNr INT, Instruction VARCHAR(25), FirstVar CHAR, SecondVar CHAR)

INSERT ##Instructions (InstrNr, Instruction, FirstVar, SecondVar)
SELECT ROW_NUMBER() OVER (ORDER BY (SELECT 0))
,      LEFT(Line, CHARINDEX(' ', Line, CHARINDEX(' ', Line) + 1))
,      SUBSTRING(Line, CHARINDEX(' ', Line, CHARINDEX(' ', Line) + 1) + 1, 1)
,      RIGHT(Line, 1)
FROM ##Input


/*
    
    swap position X with position Y means that the letters at indexes X and Y (counting from 0) should be swapped.
    swap letter X with letter Y means that the letters X and Y should be swapped (regardless of where they appear in the string).
    rotate left/right X steps means that the whole string should be rotated; for example, one right rotation would turn abcd into dabc.
    rotate based on position of letter X means that the whole string should be rotated to the right based on the index of letter X (counting from 0) as determined before this instruction does any rotations. 
        Once the index is determined, rotate the string to the right one time, plus a number of times equal to that index, plus one additional time if the index was at least 4.
    reverse positions X through Y means that the span of letters at indexes X through Y (including the letters at X and Y) should be reversed in order.
    move position X to position Y means that the letter which is at index X should be removed from the string, then inserted such that it ends up at index Y.

*/


DECLARE @Password VARCHAR(8) = 'abcdefgh'
DECLARE @OldPassword VARCHAR(8) = 'abcdefgh'
DECLARE @Counter INT = 1
DECLARE @Instr VARCHAR(20)
DECLARE @FirstVar CHAR
DECLARE @SecondVar CHAR
DECLARE @Help CHAR
DECLARE @FirstInt INT
DECLARE @SecondInt INT

SELECT * FROM ##Instructions ORDER BY InstrNr

-- /* Part 2

CREATE TABLE ##PassWords (ID INT IDENTITY(1,1), PasswordUnscrambled CHAR(8), PasswordScrambled CHAR(8))

;WITH cte_Letters AS (
    SELECT 'a' AS Letter UNION SELECT 'b' UNION SELECT 'c' UNION SELECT 'd' UNION SELECT 'e' UNION SELECT 'f' UNION SELECT 'g' UNION SELECT 'h' 
)
INSERT ##PassWords (PasswordUnscrambled)
SELECT L1.Letter + L2.Letter + L3.Letter + L4.Letter + L5.Letter + L6.Letter + L7.Letter + L8.Letter
FROM cte_Letters L1
INNER JOIN cte_Letters L2 ON L1.Letter <> L2.Letter
INNER JOIN cte_Letters L3 ON L1.Letter <> L3.Letter AND L2.Letter <> L3.Letter
INNER JOIN cte_Letters L4 ON L1.Letter <> L4.Letter AND L2.Letter <> L4.Letter AND L3.Letter <> L4.Letter
INNER JOIN cte_Letters L5 ON L1.Letter <> L5.Letter AND L2.Letter <> L5.Letter AND L3.Letter <> L5.Letter AND L4.Letter <> L5.Letter
INNER JOIN cte_Letters L6 ON L1.Letter <> L6.Letter AND L2.Letter <> L6.Letter AND L3.Letter <> L6.Letter AND L4.Letter <> L6.Letter AND L5.Letter <> L6.Letter
INNER JOIN cte_Letters L7 ON L1.Letter <> L7.Letter AND L2.Letter <> L7.Letter AND L3.Letter <> L7.Letter AND L4.Letter <> L7.Letter AND L5.Letter <> L7.Letter AND L6.Letter <> L7.Letter
INNER JOIN cte_Letters L8 ON L1.Letter <> L8.Letter AND L2.Letter <> L8.Letter AND L3.Letter <> L8.Letter AND L4.Letter <> L8.Letter AND L5.Letter <> L8.Letter AND L6.Letter <> L8.Letter AND L7.Letter <> L8.Letter

DECLARE @ID INT 

DECLARE PasswordCursor CURSOR FOR
SELECT ID, PasswordUnscrambled
FROM ##PassWords

OPEN PasswordCursor

FETCH NEXT FROM PasswordCursor INTO @ID, @Password

WHILE @@FETCH_STATUS = 0
BEGIN
-- */

WHILE @Counter <= (SELECT MAX(InstrNr) FROM ##Instructions)
BEGIN
    
    SET @OldPassword = @Password

    SELECT @Instr = Instruction
    ,      @FirstVar = FirstVar
    ,      @SecondVar = SecondVar
    FROM ##Instructions
    WHERE @Counter = InstrNr

    IF @Instr = 'swap position'
    BEGIN
        
        -- Switch values if the first is bigger than the last
        IF CAST(@FirstVar AS INT) > CAST(@SecondVar AS INT)
        BEGIN
            SET @Help = @FirstVar
            SET @FirstVar = @SecondVar
            SET @SecondVar = @Help
        END

        SET @FirstInt = CAST(@FirstVar AS INT) + 1
        SET @SecondInt = CAST(@SecondVar AS INT) + 1

        -- Swap two letters based on position
        SET @Password = LEFT(@Password, @FirstInt - 1) + SUBSTRING(@Password, @SecondInt, 1) + SUBSTRING(@Password, @FirstInt + 1, @SecondInt - @FirstInt - 1) + SUBSTRING(@Password, @FirstInt, 1) + SUBSTRING(@Password, @SecondInt + 1, LEN(@Password))

    END

    IF @Instr = 'swap letter'
    BEGIN

        SET @Help = '*'

        SET @Password = REPLACE(@Password, @FirstVar, @Help)
        SET @Password = REPLACE(@Password, @SecondVar, @FirstVar)
        SET @Password = REPLACE(@Password, @Help, @SecondVar)

    END

    IF @Instr = 'rotate based'
    BEGIN
      
        SET @FirstInt = CHARINDEX(@SecondVar, @Password)
        IF @FirstInt >= 5 SET @FirstInt = @FirstInt + 1
        SET @FirstVar = @FirstInt % LEN(@Password)

        SET @Instr = 'rotate right*'
        -- Let the other instruction fix it

        --SELECT 'Push to other instruction', @FirstVar, @SecondVar, @FirstInt, @SecondInt
    END

    IF @Instr = 'rotate left' OR @Instr LIKE 'rotate right%' 
    BEGIN
        
        SET @FirstInt = CAST(@FirstVar AS INT)
        IF @Instr LIKE 'rotate right%' SET @FirstInt = LEN(@Password) - @FirstInt

        SET @Password = RIGHT(@Password, LEN(@Password) - @FirstInt) + LEFT(@Password, @FirstInt)

    END

    IF @Instr = 'move position'
    BEGIN
        
        SET @FirstInt = CAST(@FirstVar AS INT) + 1
        SET @SecondInt = CAST(@SecondVar AS INT) + 1

        SET @Help = SUBSTRING(@Password, @FirstInt, 1)
        SET @Password = REPLACE(@Password, @Help, '')
        SET @Password = LEFT(@Password, @SecondInt - 1) + @Help + SUBSTRING(@Password, @SecondInt, LEN(@Password))

    END

    IF @Instr = 'reverse positions'
    BEGIN

        SET @FirstInt = CAST(@FirstVar AS INT) + 1
        SET @SecondInt = CAST(@SecondVar AS INT) + 1
        
        --SELECT LEFT(@Password, @FirstInt -1) , REVERSE(SUBSTRING(@Password, @FirstInt, @SecondInt - @FirstInt)) , SUBSTRING(@Password, @SecondInt, LEN(@Password))
        SET @Password = LEFT(@Password, @FirstInt -1) + REVERSE(SUBSTRING(@Password, @FirstInt, @SecondInt - @FirstInt + 1)) + SUBSTRING(@Password, @SecondInt + 1, LEN(@Password))

    END

    --SELECT @Counter, @Instr, @FirstVar, @SecondVar, @OldPassword, @Password
    --PRINT @OldPassword + ' ; ' + @Password + ' ; ' + CAST(@Counter AS VARCHAR(5)) + ' ; ' + @Instr + ' ; ' + @FirstVar + ' ; ' + @SecondVar

    SET @Counter = @Counter + 1

END

--SELECT @Password
UPDATE ##PassWords SET PasswordScrambled = @Password WHERE ID = @ID

SET @Counter = 1

FETCH NEXT FROM PasswordCursor INTO @ID, @Password

END

CLOSE PasswordCursor

DEALLOCATE PasswordCursor


--ahcgdfeb is incorrect
--ahcgbfed is incorrect
--fdhbcgea is correct for part 1 :)


SELECT * FROM ##PassWords WHERE PasswordScrambled = 'fbgdceah'

-- egfbcadh is correct for part 2

/*
DROP TABLE ##Passwords

DROP TABLE ##Instructions
DROP TABLE ##Input
*/


