
use Test_WME

CREATE TABLE #Input (Name NVARCHAR(MAX));

BULK INSERT #Input
FROM 'D:\Wilfred\AdventOfCode\2017\input8.txt'
WITH (ROWTERMINATOR = '0x0A');


CREATE TABLE #Instructions (ID INT IDENTITY(1,1) PRIMARY KEY, Register VARCHAR(5), IncDec INT, Amount INT, IfRegister VARCHAR(5), IfCondition VARCHAR(5), IfValue INT)

;WITH cte_Scrubbed AS (
    SELECT Name
    ,      SUBSTRING(Name, PATINDEX('%inc%', Name) + PATINDEX('%dec%', Name) + 4, LEN(Name)) AS SecondPart
    ,      SUBSTRING(Name, PATINDEX('%if%', Name) + 3, LEN(Name)) AS ThirdPart
    FROM #Input
)
INSERT #Instructions (Register, IncDec, Amount, IfRegister, IfCondition, IfValue)
SELECT 
       LEFT(Name, CHARINDEX(' ', Name)) AS Register
,      CASE WHEN PATINDEX('%inc%', Name) > 0 THEN 1 ELSE -1 END AS IncDec
,      LEFT(SecondPart, CHARINDEX(' ', SecondPart)) AS Amount
,      LEFT(ThirdPart, CHARINDEX(' ', ThirdPart)) AS IfRegister
,      LTRIM(RTRIM(SUBSTRING(ThirdPart, CHARINDEX(' ', ThirdPart) + 1, 2))) AS IfCondition
,      LTRIM(RTRIM(SUBSTRING(ThirdPart, PATINDEX('%'+SUBSTRING(ThirdPart, CHARINDEX(' ', ThirdPart) + 1, 2)+'%', ThirdPart) + 2, LEN(ThirdPart)))) AS IfValue
FROM cte_Scrubbed


CREATE TABLE #Registers (ID INT IDENTITY(1, 1), Name VARCHAR(5), Value INT DEFAULT(0))

INSERT #Registers (Name)
SELECT DISTINCT Register
FROM #Instructions
UNION
SELECT DISTINCT IfRegister
FROM #Instructions

DECLARE @Register VARCHAR(5)
DECLARE @IncDec INT
DECLARE @Amount INT
DECLARE @IfRegister VARCHAR(5)
DECLARE @IfCondition VARCHAR(5)
DECLARE @IfValue INT
DECLARE @Diff INT = 0
DECLARE @HighestMax INT = 0
DECLARE @Max INT = 0

DECLARE InstructionCursor CURSOR FOR
SELECT Register, IncDec, Amount, IfRegister, IfCondition, IfValue FROM #Instructions
ORDER BY ID

OPEN InstructionCursor 

FETCH NEXT FROM InstructionCursor INTO @Register, @IncDec, @Amount, @IfRegister, @IfCondition, @IfValue 

WHILE (@@FETCH_STATUS = 0)
BEGIN

    SELECT @Diff = Value - @IfValue FROM #Registers WHERE Name = @IfRegister

    IF ((@IfCondition = '>'  AND @Diff >  0) OR
        (@IfCondition = '>=' AND @Diff >= 0) OR
        (@IfCondition = '<'  AND @Diff <  0) OR
        (@IfCondition = '<=' AND @Diff <= 0) OR
        (@IfCondition = '==' AND @Diff = 0) OR
        (@IfCondition = '!=' AND @Diff <> 0))
    BEGIN
        UPDATE #Registers
        SET Value = Value + @IncDec * @Amount
        WHERE Name = @Register
    END

    SELECT @Max = MAX(Value) FROM #Registers

    IF (@Max > @HighestMax) SET @HighestMax = @Max

    FETCH NEXT FROM InstructionCursor INTO @Register, @IncDec, @Amount, @IfRegister, @IfCondition, @IfValue 

END 


CLOSE InstructionCursor 
DEALLOCATE InstructionCursor 

SELECT * FROM #Registers ORDER BY Value DESC
SELECT @HighestMax

DROP TABLE #Registers
DROP TABLE #Instructions
DROP TABLE #Input