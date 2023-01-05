USE Test_WME

SET NOCOUNT ON

DECLARE @year VARCHAR(4) = '2015'
DECLARE @day VARCHAR(2)  = '19'

EXEC dbo.GetInput @year = @year, @day = @day
EXEC dbo.ParseInput @year = @year, @day = @day

CREATE TABLE ##Instructions (ID INT IDENTITY(1,1), Input VARCHAR(10), Output VARCHAR(20))

INSERT ##Instructions (Input, Output)
SELECT LTRIM(RTRIM(LEFT(Line, CHARINDEX('=>', Line) - 1)))
,      LTRIM(RTRIM(SUBSTRING(Line, CHARINDEX('=>', Line) + 2, LEN(Line))))
FROM ##Input 
WHERE CHARINDEX('=>', Line) > 0

CREATE TABLE ##Molecule (ID INT IDENTITY(1,1), Molecule VARCHAR(MAX), Iteration INT)
INSERT ##Molecule (Molecule, Iteration) SELECT Line, 0 FROM ##Input WHERE CHARINDEX('=>', Line) = 0

DECLARE @LenMolecule INT
SELECT @LenMolecule = LEN(Molecule) FROM ##Molecule

;WITH cte_NrList AS (
-- Get a list numbered from 1 to the string length combined with a 1 or a 2. We'll use this to generate all possible one and two letter elements in the molecule
    SELECT TOP(2*@LenMolecule) ROW_NUMBER() OVER (ORDER BY (SELECT 0)) % (@LenMolecule + 1) AS StartInd, (ROW_NUMBER() OVER (ORDER BY (SELECT 0)) - 1) / @LenMolecule + 1 AS L FROM sys.messages
)
SELECT COUNT(DISTINCT SUBSTRING(M.Molecule, 1, c.StartInd - 1) + I.OutPut + SUBSTRING(M.Molecule, c.StartInd + L, LEN(M.Molecule))) AS Part1
FROM ##Molecule M
CROSS APPLY cte_NrList c
INNER JOIN ##Instructions I ON I.Input = SUBSTRING(M.Molecule, c.StartInd, c.L)
WHERE c.StartInd <> 0 AND ASCII(SUBSTRING(M.Molecule, c.StartInd, 1)) BETWEEN 65 AND 90 -- All elements start with a capital letter



-- We assume that it doesn't matter which elements are replaced by which
-- Other then Rn, Ar and Y which can be switched out easier

UPDATE ##Molecule SET Molecule = REPLACE(Molecule, 'Rn', '(')
UPDATE ##Molecule SET Molecule = REPLACE(Molecule, 'Ar', ')')
UPDATE ##Molecule SET Molecule = REPLACE(Molecule, 'Y', ',')
UPDATE ##Instructions SET Output = REPLACE(Output, 'Rn', '(')
UPDATE ##Instructions SET Output = REPLACE(Output, 'Ar', ')')
UPDATE ##Instructions SET Output = REPLACE(Output, 'Y', ',')

INSERT ##Instructions (Input, Output) VALUES ('C', 'XX')

DECLARE @InputStr VARCHAR(2)
DECLARE ReplaceCursor CURSOR FOR SELECT Input FROM ##Instructions GROUP BY Input ORDER BY LEN(Input) DESC

OPEN ReplaceCursor

FETCH NEXT FROM ReplaceCursor INTO @InputStr

WHILE @@FETCH_STATUS = 0
BEGIN

    UPDATE ##Molecule
    SET Molecule = REPLACE(Molecule, @InputStr, 'X')

    UPDATE ##Instructions
    SET Input = REPLACE(Input, @InputStr, 'X')
    ,   Output = REPLACE(Output, @InputStr, 'X')

    FETCH NEXT FROM ReplaceCursor INTO @InputStr
END

CLOSE ReplaceCursor
DEALLOCATE ReplaceCursor

DECLARE @Iteration INT = 0


WHILE @Iteration < 200 AND NOT EXISTS (SELECT 1 FROM ##Molecule WHERE Molecule = 'X')
BEGIN

    SET @Iteration = @Iteration + 1   

    INSERT ##Molecule (Molecule, Iteration)
    SELECT DISTINCT LEFT(M.Molecule, CHARINDEX(I.Output, M.Molecule) - 1) + I.Input + SUBSTRING(M.Molecule, CHARINDEX(I.Output, M.Molecule) + LEN(I.Output), LEN(M.Molecule)) AS NewMolecule
    ,      @Iteration
    FROM ##Molecule M
    CROSS APPLY ##Instructions I 
    WHERE CHARINDEX(I.Output, M.Molecule) > 0
    
    DELETE FROM ##Molecule 
    WHERE LEN(Molecule) > (SELECT MIN(LEN(Molecule)) FROM ##Molecule) -- Only keep the shortest one

END

SELECT @Iteration AS Part2

DROP TABLE ##Instructions
DROP TABLE ##Molecule



