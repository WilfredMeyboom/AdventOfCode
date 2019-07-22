use Test_WME

SET NOCOUNT ON

CREATE TABLE ##Input (Line NVARCHAR(MAX));

BULK INSERT ##Input
FROM 'D:\Wilfred\AdventOfCode\2016\input08.txt'
WITH (ROWTERMINATOR = '0x0A');

CREATE TABLE ##Instructions (ID INT IDENTITY(1,1), InstrNr INT, Instr VARCHAR(10), Int1 INT, Int2 INT)

INSERT ##Instructions (InstrNr, Instr, Int1, Int2)
SELECT ROW_NUMBER() OVER (ORDER BY (SELECT 0)) AS InstrNr
,      CASE WHEN Line LIKE '%rect%' THEN 'rect' 
            WHEN Line LIKE '%row%'  THEN 'row' 
            WHEN Line LIKE '%colu%' THEN 'column' END AS Instr
,      CASE WHEN Line LIKE '%rect%' THEN SUBSTRING(Line, 6, CHARINDEX('x', Line) - 6)
            WHEN Line LIKE '%row%'  THEN SUBSTRING(Line, 14, CHARINDEX('by', Line) - 14)
            WHEN Line LIKE '%colu%' THEN SUBSTRING(Line, 17, CHARINDEX('by', Line) - 17)
            END AS Int1
,      CASE WHEN Line LIKE '%rect%' THEN SUBSTRING(Line, CHARINDEX('x', Line) + 1, LEN(Line))
            WHEN Line LIKE '%row%'  THEN SUBSTRING(Line, CHARINDEX('by', Line) + 3, LEN(Line))
            WHEN Line LIKE '%colu%' THEN SUBSTRING(Line, CHARINDEX('by', Line) + 3, LEN(Line))
            END AS Int2
FROM ##Input

CREATE TABLE ##Grid (ID INT IDENTITY(1,1), X INT, Y INT, Pixel INT)

INSERT ##Grid (X, Y, Pixel)
SELECT X, Y, 0 FROM
(SELECT TOP (6) ROW_NUMBER() OVER (ORDER BY (SELECT 0)) - 1 AS Y FROM sys.messages) SubY
CROSS APPLY
(SELECT TOP (50) ROW_NUMBER() OVER (ORDER BY (SELECT 0)) - 1 AS X FROM sys.messages) SubX



--SELECT * FROM ##Instructions
--SELECT * FROM ##Grid

DECLARE @Instr VARCHAR(10)
DECLARE @Int1 INT
DECLARE @Int2 INT

DECLARE InstrCursor CURSOR FOR
SELECT Instr, Int1, Int2 FROM ##Instructions

OPEN InstrCursor

FETCH NEXT FROM InstrCursor INTO @Instr, @Int1, @Int2

WHILE (@@FETCH_STATUS = 0)
BEGIN

    IF @Instr = 'rect'
    BEGIN

        UPDATE ##Grid
        SET Pixel = 1
        WHERE X < @Int1 AND Y < @Int2

    END

    IF @Instr = 'row'
    BEGIN

        UPDATE ##Grid
        SET X = (X + @Int2) % 50
        WHERE Y = @Int1

    END

    IF @Instr = 'column'
    BEGIN

        UPDATE ##Grid
        SET Y = (Y + @Int2) % 6
        WHERE X = @Int1

    END


    FETCH NEXT FROM InstrCursor INTO @Instr, @Int1, @Int2

END

CLOSE InstrCursor
DEALLOCATE InstrCursor

SELECT SUM(Pixel) FROM ##Grid


DECLARE @X INT
DECLARE @Y INT
DECLARE @MinX INT
DECLARE @MaxX INT
DECLARE @MaxY INT
DECLARE @Str NVARCHAR(MAX) = ''

SELECT @X = MIN(X), @Y = MIN(Y), @MaxX = MAX(X), @MaxY = MAX(Y) FROM ##Grid
SET @MinX = @X

WHILE (@Y <= @MaxY)
BEGIN

    SET @Str = ''

    WHILE (@X <= @MaxX)
    BEGIN
    
        SELECT @Str = @Str + CASE WHEN Pixel = 1 THEN '*' ELSE '.' END
        FROM ##Grid G
        WHERE G.X = @X AND G.Y = @Y       

        SET @X = @X + 1

        IF @X % 5 = 0 SET @Str = @Str + '   '

    END

    PRINT @Str

    SET @Y = @Y + 1
    SET @X = @MinX
END





/*

DROP TABLE ##Grid
DROP TABLE ##Instructions
DROP TABLE ##Input

*/

--SELECT * FROM ##Input


--116 is correct for part 1

--UPOJFLBCEZ is correct for part 2


