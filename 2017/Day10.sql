USE Test_WME

SET NOCOUNT ON

DECLARE @ListSize INT = 256 --5

CREATE TABLE ##StringOfNrs (ID INT IDENTITY(1,1), Pos INT, Nr INT)

INSERT ##StringOfNrs(Pos, Nr)
SELECT TOP(@ListSize) ROW_NUMBER() OVER (ORDER BY (SELECT 0)) - 1 , ROW_NUMBER() OVER (ORDER BY (SELECT 0)) - 1 FROM sys.messages


CREATE TABLE ##Input (ID INT IDENTITY(1,1), PinchSize INT)

--Input
--83,0,193,1,254,237,187,40,88,27,2,255,149,29,42,100
INSERT ##Input(PinchSize) SELECT 83 UNION ALL SELECT 0 UNION ALL SELECT 193 UNION ALL SELECT 1 UNION ALL SELECT 254 UNION ALL SELECT 237 UNION ALL SELECT 187 UNION ALL SELECT 40 UNION ALL SELECT 88
                                    UNION ALL SELECT 27 UNION ALL SELECT 2 UNION ALL SELECT 255 UNION ALL SELECT 149 UNION ALL SELECT 29 UNION ALL SELECT 42 UNION ALL SELECT 100

--INSERT ##Input(PinchSize) SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 1 UNION ALL SELECT 5

DECLARE @Skipsize INT = 0
DECLARE @PinchSize INT
DECLARE @CurrentPos INT = 0
DECLARE @BeginPinch INT
DECLARE @EndPinch INT
DECLARE @Helper INT
DECLARE @PinchCounter INT 

--DECLARE PinchCursor CURSOR
--FOR SELECT PinchSize FROM ##Input ORDER BY ID

--OPEN PinchCursor

--FETCH NEXT FROM PinchCursor INTO @PinchSize 

--WHILE @@FETCH_STATUS = 0
--BEGIN
    
--    SET @BeginPinch = @CurrentPos
--    SET @EndPinch = (@CurrentPos + @PinchSize - 1) % @ListSize

--    --PRINT 'Start: ' + CAST(@BeginPinch AS VARCHAR(3)) + ' ' + CAST(@EndPinch AS VARCHAR(3))

--    SET @PinchCounter = 0
    
--    WHILE @PinchSize - @PinchCounter > 1
--    BEGIN
        
--        Set @PinchCounter = @PinchCounter + 2

--        SELECT @Helper = Nr FROM ##StringOfNrs WHERE Pos = @BeginPinch

--        UPDATE S1 
--        SET S1.Nr = S2.Nr
--        FROM ##StringOfNrs S1
--        CROSS APPLY (SELECT Nr FROM ##StringOfNrs WHERE Pos = @EndPinch) S2
--        WHERE S1.Pos = @BeginPinch

--        UPDATE S1 
--        SET S1.Nr = @Helper
--        FROM ##StringOfNrs S1
--        WHERE S1.Pos = @EndPinch

--        SET @BeginPinch = (@BeginPinch + 1) % @ListSize
--        SET @EndPinch = (@EndPinch + @ListSize - 1) % @ListSize

--        --PRINT CAST(@BeginPinch AS VARCHAR(3)) + ' ' + CAST(@EndPinch AS VARCHAR(3))

--    END
    
--    SET @CurrentPos = (@CurrentPos + @PinchSize + @Skipsize) % @ListSize

--    SET @Skipsize = @Skipsize + 1

--    --SELECT * FROM ##StringOfNrs

--    FETCH NEXT FROM PinchCursor INTO @PinchSize 
--END

--CLOSE PinchCursor
--DEALLOCATE PinchCursor


--SELECT *
--FROM ##StringOfNrs
----SELECT @Skipsize

DROP TABLE ##Input
--DROP TABLE ##StringOfNrs


--49062 too high
--6642 too low

--SELECT 92*218
-- 20056 Correct


/*

21034
43012
43012
34210

*/


/*
Part 1 is 1 ronde van Knot Hash algorithm
Input is een string of bytes die omgezet moeten worden middels ASCII
en de komma's tellen mee als chars

83,0,193,1,254,237,187,40,88,27,2,255,149,29,42,100

Voeg deze chars toe aan de string of bytes: 17, 31, 73, 47, 23 (als getallen!)

64x Knot Hash met dezelfde input
maar current position en skip size moeten bewaard worden

Het resultaat is de sparse hash en moet dense hash worden
Per blok van 16 moet je een XOR uitvoeren op elk getal

En dan hou je 16 getallen over
Die je in Hex moet opschrijven

*/

CREATE TABLE ##Input2 (ID INT IDENTITY(1,1), PinchSize INT)

DECLARE @InputString VARCHAR(255) = '83,0,193,1,254,237,187,40,88,27,2,255,149,29,42,100'

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
SELECT --Pos, 
       ASCII(NextChar)
FROM cte_Chars
UNION ALL SELECT /*52,*/ 17 UNION ALL SELECT /*53,*/ 31 UNION ALL SELECT /*54,*/ 73 UNION ALL SELECT /*55,*/ 47 UNION ALL SELECT /*56,*/ 23

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

        --PRINT 'Start: ' + CAST(@BeginPinch AS VARCHAR(3)) + ' ' + CAST(@EndPinch AS VARCHAR(3))

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

            --PRINT CAST(@BeginPinch AS VARCHAR(3)) + ' ' + CAST(@EndPinch AS VARCHAR(3))

        END
    
        SET @CurrentPos = (@CurrentPos + @PinchSize + @Skipsize) % @ListSize

        SET @Skipsize = @Skipsize + 1

        --SELECT * FROM ##StringOfNrs

        FETCH NEXT FROM PinchCursor INTO @PinchSize 
    END

    CLOSE PinchCursor
    DEALLOCATE PinchCursor

    SET @Part2Counter = @Part2Counter + 1

END




/*

DROP TABLE ##StringOfNrs

DROP TABLE ##Input2

DROP TABLLE ##Results
*/

SELECT * FROM ##StringOfNrs

DECLARE @X INT = 0
DECLARE @Y INT = 0
DECLARE @Res INT

CREATE TABLE ##Results (ID INT IDENTITY(1,1), Res INT)

WHILE @X < 16
BEGIN
    
    SET @Y = 0

    SELECT @Res = Nr FROM ##StringOfNrs WHERE Pos = @X * 16 + @Y

    SET @Y = 1

    WHILE @Y < 16
    BEGIN

        SELECT @Res = @Res ^ Nr FROM ##StringOfNrs WHERE Pos = @X * 16 + @Y

        PRINT 'X: ' + CAST(@X AS VARCHAR(2)) + ' Y: ' + CAST(@Y AS VARCHAR(2)) + ' Res: ' + CAST(@Res AS VARCHAR(3)) + ' ' + CAST(GETDATE() AS VARCHAR(50))

        SET @Y = @Y + 1

    END

    INSERT ##Results (Res) SELECT @Res

    SET @X = @X + 1
END


SELECT * FROM ##Results
SELECT CONVERT(VARBINARY(8), Res) FROM ##Results

/*
--> Correct :)
d9a7de4a809c56bf3a9465cb84392c8e
*/

