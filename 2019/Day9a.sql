use Test_WME
GO

SET NOCOUNT ON

DECLARE @ProgramFile VARCHAR(250) = 'C:\Source\AdventOfCode\2019\input9.txt'

CREATE TABLE ##Pointers (OpCodeCompNr BIGINT, Pointer BIGINT, RelativeBase BIGINT)

DECLARE @Output BIGINT = 0

INSERT ##Pointers (OpCodeCompNr, Pointer, RelativeBase) VALUES (0, 0, 0)


WHILE @Output <> 99
BEGIN
--    EXEC IntCodeComp @ProgramFile, 0, 1 /*input*/, @Output OUTPUT -- For part 1
    EXEC IntCodeComp @ProgramFile, 0, 2 /*input*/, @Output OUTPUT -- For part 2

PRINT '-------------------------------------->' + CAST(@Output AS VARCHAR(50))

END

--SELECT * FROM Opcodes
--SELECT * FROM ##Pointers

DROP TABLE Opcodes
DROP TABLE ##Pointers

-- 3063082071 is correct for part 1

/*

Hier komt de uiteindelijke Opcodecomp te staan

*/