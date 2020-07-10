USE Test_WME
GO

SET NOCOUNT ON

DECLARE @ProgramFile VARCHAR(250) = 'C:\Source\AdventOfCode\2019\input21.txt'

CREATE TABLE ##Pointers (OpCodeCompNr BIGINT, Pointer BIGINT, RelativeBase BIGINT)

DECLARE @Output BIGINT = 0

INSERT ##Pointers (OpCodeCompNr, Pointer, RelativeBase) VALUES (0, 0, 0)

-- PROCEDURE [dbo].[IntCodeComp] (@ProgramFile VARCHAR(250)
--								, @OpCodeCompNr INT
--								, @Input BIGINT
--								, @Output BIGINT OUTPUT)

------------------- IntComp loaded

DECLARE @SkipPart1 INT = 1

CREATE TABLE ##InputText (Command VARCHAR(10))
CREATE TABLE ##Input (ID INT IDENTITY(1,1), Val INT)

IF @SkipPart1 = 0 
BEGIN

-- Solution: !A | (!C & D)
-- If there is a hole on the next tile -> always jump
-- If there is a hole at position 3 and there is ground at position 4 -> also jump

--Program:
-- NOT C J
-- AND D J
-- NOT A T
-- OR T J
-- WALK

INSERT ##Input(Val) VALUES 
(78),(79),(84),(32),(67),(32),(74),(10),(65),(78),(68),(32),(68),(32),(74),(10),(78),(79),(84),(32),(65),(32),(84),(10),(79),(82),(32),(84),(32),(74),(10),(87),(65),(76),(75),(10)

END
ELSE
BEGIN -- Part 2

-- Solution: !A | (D & !(C & B) & (H | E))
-- If there is a hole on the next tile -> always jump
-- If there is ground to land on at D and a hole at E prematurely jump

--Program:
INSERT ##InputText(Command) VALUES 
('OR C J'),
('AND B J'),
('NOT J J'),
('OR H T'),
('OR E T'),
('AND T J'),
('AND D J'),
('NOT A T'),
('OR T J'),
('RUN')

;WITH cte_PerLetter AS (
    SELECT 1 AS PosNr
    ,      ROW_NUMBER() OVER (ORDER BY (SELECT 0)) AS LineNr
    ,      LEFT(Command, 1) AS Letter
    ,      SUBSTRING(Command, 2, LEN(Command)) + CHAR(10) AS Rest
    FROM ##InputText
    UNION ALL
    SELECT PosNr + 1
    ,      LineNr
    ,      LEFT(Rest, 1)
    ,      SUBSTRING(Rest, 2, LEN(Rest)) AS Rest
    FROM cte_PerLetter
    WHERE LEN(Rest) > 0
)
INSERT ##Input(Val) 
SELECT ASCII(Letter)
FROM cte_PerLetter
ORDER BY LineNr, PosNr



END

--SELECT * FROM ##Input

DECLARE @Count INT
SELECT @Count = COUNT(1) FROM ##Input
DECLARE @Index INT = 1
DECLARE @Input INT = -1

WHILE @Index <= @Count AND @Output <> -999999
BEGIN
    
    SELECT @Input = Val FROM ##Input WHERE ID = @Index
    --PRINT @Input
    EXEC IntCodeComp @ProgramFile, 0, @Input, @Output OUTPUT

    IF @Output <> -99999 PRINT @Output

    IF @Output = -99999 SET @Index = @Index + 1

END 

PRINT 'Instructions loaded at ' + CAST(GETDATE() AS VARCHAR(50))

WHILE @Output <> -999999
BEGIN
    EXEC IntCodeComp @ProgramFile, 0, -1 /*Dummy*/, @Output OUTPUT

    IF @Output <> -99999 PRINT @Output

END


--19357335 is correct for part 1
--1140147758 is correct for part 2

/*

DROP TABLE ##InputText
DROP TABLE ##Input
DROP TABLE ##Pointers
DROP TABLE Opcodes

*/

