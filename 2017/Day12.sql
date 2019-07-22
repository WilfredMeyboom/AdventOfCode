USE Test_WME

CREATE TABLE ##Input (Line NVARCHAR(MAX));

BULK INSERT ##Input
FROM 'D:\Wilfred\AdventOfCode\2017\input12.txt'
WITH (ROWTERMINATOR = '0x0A');


CREATE TABLE ##Pipes (ID INT IDENTITY(1,1), ProgramID INT, ToProgID INT)

;WITH cte_Pipes AS (
    SELECT LEFT(Line, CHARINDEX('<->', Line) - 1) AS ProgramID
    ,      SUBSTRING(Line + ',', CHARINDEX('<->', Line) + 4, CHARINDEX(',', Line + ',') - CHARINDEX('<->', Line) - 4) AS ToProgrID
    ,      SUBSTRING(Line, CHARINDEX(',', Line + ',') + 1, LEN(Line)) + ',' AS Remainder
    FROM ##Input
    UNION ALL
    SELECT ProgramID
    ,      LEFT(Remainder, CHARINDEX(',', Remainder) - 1)
    ,      SUBSTRING(Remainder, CHARINDEX(',', Remainder) + 1, LEN(Remainder))
    FROM cte_Pipes
    WHERE LEN(Remainder) > 1
)
INSERT ##Pipes (ProgramID, ToProgID)
SELECT ProgramID, ToProgrID FROM cte_Pipes



SELECT * FROM ##Pipes ORDER BY ProgramID

CREATE TABLE ##Groups (ID INT IDENTITY(1,1), ProgramID INT, StartProgram INT)

ALTER TABLE ##Pipes ALTER COLUMN ProgramID INT NOT NULL
--ALTER TABLE ##Pipes ADD CONSTRAINT PK_Pipes PRIMARY KEY (ProgramID)

DECLARE @StartProgram INT = 0
DECLARE @OrphanedProgramsLeft INT = 1

WHILE @OrphanedProgramsLeft > 0
BEGIN

    INSERT ##Groups (ProgramID, StartProgram) VALUES (@StartProgram, @StartProgram)

    WHILE @@ROWCOUNT > 0
    BEGIN

        INSERT ##Groups
        SELECT DISTINCT ToProgID, @StartProgram
        FROM ##Groups G
        INNER JOIN ##Pipes P ON G.ProgramID = P.ProgramID
        LEFT JOIN ##Groups G2 ON G2.ProgramID = P.ToProgID
        WHERE G2.ID IS NULL
    END

    SELECT @OrphanedProgramsLeft = COUNT(1)
    FROM ##Pipes P 
    LEFT JOIN ##Groups G ON P.ProgramID = G.ProgramID
    WHERE G.ID IS NULL

    SELECT TOP(1) @StartProgram = P.ProgramID
    FROM ##Pipes P 
    LEFT JOIN ##Groups G ON P.ProgramID = G.ProgramID
    WHERE G.ID IS NULL
END

SELECT DISTINCT StartProgram FROM ##Groups

DROP TABLE ##Groups
DROP TABLE ##Pipes
DROP TABLE ##Input
