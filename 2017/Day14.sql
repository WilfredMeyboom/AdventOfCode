USE Test_WME

SET NOCOUNT ON

-- Puzzle input: jzgqcdpd
-- Example input: flqrgnkx
DECLARE @PuzzleInput VARCHAR(10) = 'jzgqcdpd'

DECLARE @ListSize INT = 256 

CREATE TABLE ##StringOfNrs (ID INT IDENTITY(1,1), Pos INT, Nr INT)

CREATE TABLE ##Input (ID INT IDENTITY(1,1), RowNr INT, Inputstring VARCHAR(50))

INSERT ##Input (RowNr, Inputstring)
SELECT TOP(128) ROW_NUMBER() OVER (ORDER BY (SELECT 0)) - 1
,      @PuzzleInput + '-' + CAST((ROW_NUMBER() OVER (ORDER BY (SELECT 0)) - 1) AS VARCHAR(3)) FROM sys.messages

DECLARE @Skipsize INT = 0
DECLARE @PinchSize INT
DECLARE @CurrentPos INT = 0
DECLARE @BeginPinch INT
DECLARE @EndPinch INT
DECLARE @Helper INT
DECLARE @PinchCounter INT 

DECLARE @X INT = 0
DECLARE @Y INT = 0
DECLARE @RowNr INT = 0
DECLARE @Res INT

CREATE TABLE ##Results (ID INT IDENTITY(1,1), RowNr INT, Byte INT, Res INT)


CREATE TABLE ##Input2 (ID INT IDENTITY(1,1), PinchSize INT)

DECLARE @InputString VARCHAR(255) --------


DECLARE InputCursor CURSOR 
FOR SELECT RowNr, Inputstring FROM ##Input

OPEN InputCursor

FETCH NEXT FROM InputCursor INTO @RowNr, @InputString

WHILE @@FETCH_STATUS = 0
BEGIN

    SET @Skipsize = 0
    SET @CurrentPos = 0

    DELETE FROM ##StringOfNrs

    INSERT ##StringOfNrs(Pos, Nr)
    SELECT TOP(@ListSize) ROW_NUMBER() OVER (ORDER BY (SELECT 0)) - 1 , ROW_NUMBER() OVER (ORDER BY (SELECT 0)) - 1 FROM sys.messages

    DELETE ##Input2

    ;WITH cte_Chars AS (
        SELECT LEFT(@InputString, 1) AS NextChar
        ,      1 AS Pos
        ,      SUBSTRING(@InputString, 2, LEN(@InputString)) AS Remainder  
        UNION ALL
        SELECT LEFT(Remainder, 1)
        ,      Pos + 1
        ,      SUBSTRING(Remainder, 2, LEN(Remainder))
        FROM cte_Chars
        WHERE LEN(Remainder) > 0
    )
    INSERT ##Input2
    SELECT ASCII(NextChar)
    FROM cte_Chars
    UNION ALL SELECT 17 
    UNION ALL SELECT 31 
    UNION ALL SELECT 73 
    UNION ALL SELECT 47 
    UNION ALL SELECT 23

    DECLARE @Part2Counter INT = 0

    WHILE @Part2Counter < 64
    BEGIN

        DECLARE PinchCursor CURSOR
        FOR SELECT PinchSize FROM ##Input2 ORDER BY ID

        OPEN PinchCursor

        FETCH NEXT FROM PinchCursor INTO @PinchSize 

        WHILE @@FETCH_STATUS = 0
        BEGIN
    
            SET @BeginPinch = @CurrentPos
            SET @EndPinch = (@CurrentPos + @PinchSize - 1) % @ListSize

            SET @PinchCounter = 0
    
            WHILE @PinchSize - @PinchCounter > 1
            BEGIN
        
                Set @PinchCounter = @PinchCounter + 2

                SELECT @Helper = Nr FROM ##StringOfNrs WHERE Pos = @BeginPinch

                UPDATE S1 
                SET S1.Nr = S2.Nr
                FROM ##StringOfNrs S1
                CROSS APPLY (SELECT Nr FROM ##StringOfNrs WHERE Pos = @EndPinch) S2
                WHERE S1.Pos = @BeginPinch

                UPDATE S1 
                SET S1.Nr = @Helper
                FROM ##StringOfNrs S1
                WHERE S1.Pos = @EndPinch

                SET @BeginPinch = (@BeginPinch + 1) % @ListSize
                SET @EndPinch = (@EndPinch + @ListSize - 1) % @ListSize

            END
    
            SET @CurrentPos = (@CurrentPos + @PinchSize + @Skipsize) % @ListSize

            SET @Skipsize = @Skipsize + 1

            FETCH NEXT FROM PinchCursor INTO @PinchSize 
        END

        CLOSE PinchCursor
        DEALLOCATE PinchCursor

        SET @Part2Counter = @Part2Counter + 1

    END


    SET @X = 0
    SET @Y = 0
    SET @Res = 0 

    --DELETE FROM ##Results 

    WHILE @X < 16
    BEGIN
    
        SET @Y = 0

        SELECT @Res = Nr FROM ##StringOfNrs WHERE Pos = @X * 16 + @Y

        SET @Y = 1

        WHILE @Y < 16
        BEGIN

            SELECT @Res = @Res ^ Nr FROM ##StringOfNrs WHERE Pos = @X * 16 + @Y

--            PRINT 'Row: ' + CAST(@RowNR AS VARCHAR(3)) + ' X: ' + CAST(@X AS VARCHAR(2)) + ' Y: ' + CAST(@Y AS VARCHAR(2)) + ' Res: ' + CAST(@Res AS VARCHAR(3)) + ' ' + CAST(GETDATE() AS VARCHAR(50))

            SET @Y = @Y + 1

        END

        INSERT ##Results (RowNr, Byte, Res) SELECT @RowNr, @X ,@Res

        SET @X = @X + 1
    END

--    SELECT CONVERT(VARBINARY(8), Res) FROM ##Results

    FETCH NEXT FROM InputCursor INTO @RowNr, @InputString
 
END

PRINT 'Row: ' + CAST(@Rownr AS VARCHAR(3)) + ' is done'

CLOSE InputCursor
DEALLOCATE InputCursor


CREATE TABLE ##Grid (ID INT IDENTITY(1,1), X INT, Y INT, Value INT)



;WITH cte_Bits AS (
    SELECT Byte * 8 AS X
    ,      Rownr AS Y
    ,      LEFT(RIGHT('00000000' + CAST(dbo.DecimalToBinary(Res) AS VARCHAR(8)), 8), 1) AS Bit
    ,      RIGHT('00000000' + CAST(dbo.DecimalToBinary(Res) AS VARCHAR(8)), 7) AS Remainder
    FROM ##Results
    UNION ALL
    SELECT X + 1
    ,      Y
    ,      LEFT(Remainder, 1)
    ,      SUBSTRING(Remainder, 2, LEN(Remainder))
    FROM cte_Bits
    WHERE LEN(Remainder) > 0
)
INSERT ##Grid (X, Y, Value)
SELECT X, Y, Bit
FROM cte_Bits 
OPTION (MAXRECURSION 17000)



SELECT SUM(Value) FROM ##Grid

CREATE TABLE ##Groups (ID INT IDENTITY(1,1), X INT, Y INT, GroupNr INT)

INSERT ##Groups (X, Y, GroupNr)
SELECT X, Y, ROW_NUMBER() OVER (ORDER BY (SELECT 0))
FROM ##Grid
WHERE Value = 1

CREATE UNIQUE INDEX UX_Groups ON ##Groups(X, Y)

WHILE @@ROWCOUNT > 0
BEGIN
    
    UPDATE G
    SET G.GroupNr = G_Adj.GroupNr
    FROM ##Groups G
    INNER JOIN ##Groups G_Adj ON ((ABS(G.X - G_Adj.X) = 1 AND G.Y = G_Adj.Y)
                              OR (ABS(G.Y - G_Adj.Y) = 1 AND G.X = G_Adj.X))
                             AND G.GroupNr > G_Adj.GroupNr
END


SELECT DISTINCT GroupNr FROM ##Groups

/*



DROP TABLE ##Grid
DROP TABLE ##Input
DROP TABLE ##Input2
DROP TABLE ##Results
DROP TABLE ##StringOfNrs





CREATE FUNCTION [dbo].[DecimalToBinary]
(
	@Input bigint
)
RETURNS varchar(255)
AS
BEGIN

	DECLARE @Output varchar(255) = ''

	WHILE @Input > 0 BEGIN

		SET @Output = @Output + CAST((@Input % 2) AS varchar)
		SET @Input = @Input / 2

	END

	RETURN REVERSE(@Output)

END
*/




