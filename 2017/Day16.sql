USE Test_WME

SET NOCOUNT ON

DECLARE @NrOfDancers INT = 16   -- 5

CREATE TABLE ##Input (Line NVARCHAR(MAX));

BULK INSERT ##Input
FROM 'D:\Wilfred\AdventOfCode\2017\input16.txt'
WITH (ROWTERMINATOR = '0x0A');

--DELETE FROM ##Input
--INSERT ##Input VALUES ('s1,x3/4,pe/b')

CREATE TABLE ##Instructions (ID INT IDENTITY(1,1), Nr INT, Instr VARCHAR(10), InstrType CHAR(1), Input1 VARCHAR(5), Input2 VARCHAR(5))

;WITH cte_Instruction AS (
    SELECT 1 AS Nr
    ,      LEFT(Line, CHARINDEX(',', Line) - 1) AS Instr
    ,      SUBSTRING(Line, CHARINDEX(',', Line) + 1, LEN(Line)) + ',' AS Remainder
    FROM ##Input
    UNION ALL
    SELECT Nr + 1
    ,      LEFT(Remainder, CHARINDEX(',', Remainder) - 1) AS Instr
    ,      SUBSTRING(Remainder, CHARINDEX(',', Remainder) + 1, LEN(Remainder)) AS Remainder
    FROM cte_Instruction
    WHERE LEN(Remainder) > 0
)
INSERT ##Instructions (Nr, Instr)
SELECT Nr, Instr FROM cte_Instruction OPTION (MAXRECURSION 20000)

UPDATE I
SET I.InstrType = LEFT(I.Instr, 1)
,   I.Input1 = CASE WHEN LEFT(I.Instr, 1) = 's' THEN SUBSTRING(I.Instr, 2, LEN(I.Instr))
                                                ELSE SUBSTRING(I.Instr, 2, CHARINDEX('/', I.Instr) - 2)
                                                END
,   I.Input2 = CASE WHEN LEFT(I.Instr, 1) <> 's' THEN SUBSTRING(I.Instr, CHARINDEX('/', I.Instr) + 1, LEN(I.Instr)) END
FROM ##Instructions I

--SELECT * FROM ##Instructions


CREATE TABLE ##Dancers (ID INT IDENTITY(1,1), Position INT, Letter CHAR(1))

INSERT ##Dancers (Position, Letter) SELECT TOP (@NrOfDancers) ROW_NUMBER() OVER (ORDER BY (SELECT 0)) -1, LOWER(CHAR(ROW_NUMBER() OVER (ORDER BY (SELECT 0)) + 64)) FROM sys.messages

--SELECT * FROM ##Dancers

CREATE TABLE Results (ID INT IDENTITY(1,1), Iteration INT, Res VARCHAR(20))

DECLARE @InstrType CHAR(1)
DECLARE @Input1 VARCHAR(5)
DECLARE @Input2 VARCHAR(5)
DECLARE @Helper VARCHAR(5)

DECLARE @Counter INT = 0


WHILE @Counter < 10000
BEGIN

    SET @Counter = @Counter + 1

    DECLARE DanceCursor CURSOR FOR 
    SELECT InstrType, Input1, Input2
    FROM ##Instructions

    OPEN DanceCursor

    FETCH NEXT FROM DanceCursor INTO @InstrType, @Input1, @Input2

    WHILE @@FETCH_STATUS = 0 
    BEGIN

        --Spin, written sX, makes X programs move from the end to the front, but maintain their order otherwise. (For example, s3 on abcde produces cdeab).
        IF @InstrType = 's'
        BEGIN
            UPDATE D
            SET D.Position = (D.Position + @Input1) % @NrOfDancers
            FROM ##Dancers D
        END

         --Exchange, written xA/B, makes the programs at positions A and B swap places.
        IF @InstrType = 'x'
        BEGIN
            SELECT @Helper = Letter
            FROM ##Dancers
            WHERE Position = @Input1

            UPDATE D 
            SET D.Letter = D2.Letter
            FROM ##Dancers D
            CROSS APPLY ##Dancers D2 
            WHERE D2.Position = @Input2 AND D.Position = @Input1

            UPDATE D 
            SET D.Letter = @Helper
            FROM ##Dancers D
            WHERE D.Position = @Input2
        END

        --Partner, written pA/B, makes the programs named A and B swap places.
        IF @InstrType = 'p'
        BEGIN

    --SELECT * FROM ##Dancers ORDER BY Position
    --SELECT @InstrType, @Input1, @Input2, @Helper

            SELECT @Helper = Position
            FROM ##Dancers
            WHERE Letter = @Input2

    --SELECT @Helper

            UPDATE D 
            SET D.Letter = @Input2
            FROM ##Dancers D
            WHERE D.Letter = @Input1

    --SELECT * FROM ##Dancers

            UPDATE D 
            SET D.Letter = @Input1
            FROM ##Dancers D
            WHERE D.Position = @Helper

    --SELECT * FROM ##Dancers ORDER BY Position
    --SELECT @InstrType, @Input1, @Input2, @Helper

        END

        FETCH NEXT FROM DanceCursor INTO @InstrType, @Input1, @Input2

    END 

    CLOSE DanceCursor
    DEALLOCATE DanceCursor

    --SELECT * FROM ##Dancers ORDER BY Position
    --SELECT * FROM ##Instructions

    ;WITH cte_String AS (
        SELECT CAST(Letter AS VARCHAR(20)) AS String
        ,      Position
        FROM ##Dancers
        WHERE Position = 0
        UNION ALL
        SELECT CAST(String + CAST(Letter AS VARCHAR(20)) AS VARCHAR(20))
        ,      D.Position
        FROM cte_String S
        INNER JOIN ##Dancers D ON S.Position = D.Position - 1
    )
    INSERT Results (Iteration, Res)
    SELECT @Counter, String
    FROM cte_String
    WHERE Position = (SELECT COUNT(1) - 1 FROM ##Dancers)

END





/*



DROP TABLE ##Instructions
DROP TABLE ##Dancers
DROP TABLE ##Input



*/

--olgejankfhbmpidc --> Correct Part 1


SELECT TOP (100) * FROM Results R1 INNER JOIN Results R2 ON R1.Res = R2.Res AND R1.ID < R2.ID 

--Na 60 iteraties zijn we terug bij af


SELECT 1000000000 % 60
SELECT * FROM Results WHERE Iteration = 40
-- gfabehpdojkcimnl