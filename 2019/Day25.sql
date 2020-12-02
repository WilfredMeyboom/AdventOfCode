USE Test_WME
GO

SET NOCOUNT ON

DECLARE @ProgramFile VARCHAR(250) = 'C:\Source\AdventOfCode\2019\input25.txt'

CREATE TABLE ##Pointers (OpCodeCompNr BIGINT, Pointer BIGINT, RelativeBase BIGINT, Ticks BIGINT)
--CREATE TABLE ##Logging (Opcodecomp VARCHAR(10), Pointer VARCHAR(10), ParamInstr VARCHAR(10), Instr VARCHAR(10), [1stNr] VARCHAR(10), [2ndNr] VARCHAR(10), [3rdNr] VARCHAR(10), ParamMode1 VARCHAR(500), ParamMode2 VARCHAR(500), ParamMode3 VARCHAR(500), RelativeBase VARCHAR(10))



INSERT ##Pointers (OpCodeCompNr, Pointer, RelativeBase, Ticks) VALUES (0, 0, 0, 0)

CREATE TABLE ##Result (Res VARCHAR(MAX))
INSERT ##Result (Res) VALUES ('')

-- PROCEDURE [dbo].[IntCodeComp] (@ProgramFile VARCHAR(250)
--                                , @OpCodeCompNr INT
--                                , @Input BIGINT
--                                , @Output BIGINT OUTPUT)

------------------- IntComp loaded

DECLARE @Input VARCHAR(MAX) 
SET @Input = 'south|south|south|take fixed point|south|take festive hat|west|west|take jam|south|take easter egg|north|east|east|north|west|take asterisk|east|north|west|north|'
SET @Input = @Input + 'north|take tambourine|south|south|east|north|west|south|take antenna|north|west|west|take space heater|west|west|inv||'
DECLARE @Index INT = 1
DECLARE @InputChar INT = 115
DECLARE @Output BIGINT = 0

--SELECT SUBSTRING(@Input, @Index, @Index)

WHILE @Output <> -99999 OR @Index <= LEN(@Input)
BEGIN

    EXEC [dbo].[IntCodeComp]  @ProgramFile 
                            , 0 --@OpCodeCompNr INT
                            , @InputChar --@Input BIGINT
                            , @Output OUTPUT

    UPDATE ##Result SET Res = Res + ISNULL(CHAR(@Output), '')

    IF @Output = -99999
    BEGIN
        SET @Index = @Index + 1
        SET @InputChar = ASCII(SUBSTRING(@Input, @Index, @Index))
        IF @InputChar = 124 SET @InputChar = 10 --Change a pipeline to an Enter

        --PRINT @InputChar
    END


END

DECLARE @Result VARCHAR(MAX)
SELECT @Result = Res FROM ##Result
PRINT @Result
--PRINT 'Index: ' + CAST(@Index AS VARCHAR(10))

--DROP TABLE OpCodes
--DROP TABLE ##Pointers
--DROP TABLE ##Result

SELECT *
INTO Pointers
FROM ##Pointers

SELECT * FROM Pointers
/*
   
                                                             [Hull Breach]
                                                                  |
[Security Checkpoint]-[Storage]-[Observatory]----[Hallway]---[Engineering]
                                     |              |             |
                               [Holodeck] [Gift Wrapping Center]  |
                                                                  |
                                                [Sickbay]         |
                                                    |             |
                                     [Warp Drive Maintenance]     |
                                                    |             |
                                               [Science Lab]---[Arcade]
                                                                  |
                                                 [Kitchen]---[Crew Quarters]
                                                                  |
                                     [Corridor]-[Navigation]-[Passages]-[Hot Chocolate Fountain]
                                         |
                                     [Stables ]
             
- asterisk
- antenna
- easter egg
- space heater
- jam
- tambourine
- festive hat
- fixed point

--A loud, robotic voice says "Alert! Droids on this ship are lighter than the detected value!" and you are ejected back to the checkpoint.

*/

SELECT *
INTO ##Pointers
FROM Pointers

CREATE TABLE ##Bin (OnOff INT)

INSERT ##Bin VALUES (0),(1)

CREATE TABLE ##Instructions (ID INT IDENTITY(1,1), InstrStart VARCHAR(MAX), InstrStop VARCHAR(MAX))

INSERT ##Instructions (InstrStart)
SELECT  
  CASE WHEN B1.OnOff = 0 THEN 'drop asterisk|'
ELSE '' END + CASE WHEN B2.OnOff = 0 THEN 'drop antenna|'
ELSE '' END + CASE WHEN B3.OnOff = 0 THEN 'drop easter egg|'
ELSE '' END + CASE WHEN B4.OnOff = 0 THEN 'drop space heater|'
ELSE '' END + CASE WHEN B5.OnOff = 0 THEN 'drop jam|'
ELSE '' END + CASE WHEN B6.OnOff = 0 THEN 'drop tambourine|'
ELSE '' END + CASE WHEN B7.OnOff = 0 THEN 'drop festive hat|'
ELSE '' END + CASE WHEN B8.OnOff = 0 THEN 'drop fixed point|'
ELSE '' END FROM ##Bin B1
CROSS APPLY ##Bin B2
CROSS APPLY ##Bin B3
CROSS APPLY ##Bin B4
CROSS APPLY ##Bin B5
CROSS APPLY ##Bin B6
CROSS APPLY ##Bin B7
CROSS APPLY ##Bin B8

UPDATE ##Instructions
SET InstrStop = REPLACE(InstrStart, 'drop', 'take')

--SELECT * FROM ##Instructions

DECLARE @SecurityPassed INT = 0
DECLARE @Ind INT = 0
DECLARE @InputStart VARCHAR(MAX)
DECLARE @InputStop VARCHAR(MAX)
DECLARE @InputChr INT = 100
DECLARE @Outp BIGINT = 0
DECLARE @CharIndex INT = 1

CREATE TABLE ##TempResult (Res VARCHAR(MAX))
INSERT ##TempResult (Res) VALUES ('')

WHILE @SecurityPassed = 0
BEGIN

    SET @Ind = @Ind + 1

    SELECT @InputStart = InstrStart + 'west|'
    ,      @InputStop = InstrStop
    FROM ##Instructions
    WHERE ID = @Ind

    WHILE @Outp <> -99999 OR @CharIndex <= LEN(@InputStart)
    BEGIN

        EXEC [dbo].[IntCodeComp]  '' 
                                , 0 --@OpCodeCompNr INT
                                , @InputChr --@Input BIGINT
                                , @Outp OUTPUT

        UPDATE ##TempResult SET Res = Res + ISNULL(CHAR(@Outp), '')

        IF @Outp = -99999
        BEGIN
            SET @CharIndex = @CharIndex + 1
            SET @InputChr = ASCII(SUBSTRING(@InputStart, @CharIndex, @CharIndex))
            IF @InputChr = 124 SET @InputChr = 10 --Change a pipeline to an Enter

            --PRINT @InputChar
        END
    END

    IF EXISTS (SELECT 1 FROM ##TempResult WHERE Res LIKE '%' + 'and you are ejected back to the checkpoint' + '%')
    BEGIN
        UPDATE ##TempResult SET Res = ''
        SET @CharIndex = 1
        SET @InputChr = 116
    END
    ELSE
    BEGIN
        SET @SecurityPassed = 1
        SET @CharIndex = 1
        SET @InputChr = 105
        SET @InputStop = 'inv|'
    END

    WHILE @Outp <> -99999 OR @CharIndex <= LEN(@InputStop)
    BEGIN

        EXEC [dbo].[IntCodeComp]  '' 
                                , 0 --@OpCodeCompNr INT
                                , @InputChr --@Input BIGINT
                                , @Outp OUTPUT

        UPDATE ##TempResult SET Res = Res + ISNULL(CHAR(@Outp), '')

        IF @Outp = -99999
        BEGIN
            SET @CharIndex = @CharIndex + 1
            SET @InputChr = ASCII(SUBSTRING(@InputStop, @CharIndex, @CharIndex))
            IF @InputChr = 124 SET @InputChr = 10 --Change a pipeline to an Enter

            --PRINT @InputChar
        END
    END

END

PRINT @Ind
DECLARE @Result2 VARCHAR(MAX)
SELECT @Result2 = Res FROM ##Result
PRINT @Result2