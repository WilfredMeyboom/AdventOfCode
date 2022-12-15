USE Test_WME

SET NOCOUNT ON

DECLARE @year VARCHAR(4) = '2022'
DECLARE @day VARCHAR(2)  = '13'

EXEC dbo.GetInput @year = @year, @day = @day
EXEC dbo.ParseInput @year = @year, @day = @day 

--SELECT TOP 10 * FROM ##Input
--SELECT TOP 10 * FROM ##InputInts
--SELECT TOP 10 * FROM ##InputNumbered
--SELECT TOP 10 * FROM ##InputGrid
--SELECT TOP 10 * FROM ##InputSplit
--SELECT TOP 10 * FROM ##InputSplitCust
  

DECLARE @Counter INT = 0
DECLARE @NrOfLists INT
DECLARE @Line1 VARCHAR(MAX)
DECLARE @Line2 VARCHAR(MAX)
DECLARE @Result INT
DECLARE @Debug INT = 0
DECLARE @Results TABLE (PairNr INT, Result INT)

SELECT @NrOfLists = COUNT(1) / 2 FROM ##InputNumbered WHERE Line IS NOT NULL
--SET @NrOfLists = 1


WHILE @Counter <= @NrOfLists
BEGIN

    SELECT @Line1 = Line FROM ##InputNumbered WHERE Ind = @Counter*3 + 1
    SELECT @Line2 = Line FROM ##InputNumbered WHERE Ind = @Counter*3 + 2
    SET @Result = NULL

    PRINT '-------------------------PairNumber: ' + CAST(@Counter + 1 AS VARCHAR(6))

    EXEC dbo.AoCCompare2 @Line1 
                       , @Line2 
                       , @Debug
                       , @Result OUTPUT

    INSERT @Results (PairNr, Result)
    SELECT @Counter + 1, @Result

    SET @Counter = @Counter + 1
END

SELECT * FROM @Results R 
SELECT * FROM @Results R WHERE Result NOT IN (0,1)
SELECT SUM(PairNr) FROM @Results R WHERE Result = 1

--4734 is correct for part1

DECLARE @Switched INT = 1
DECLARE @Iteration INT = 0
--DECLARE @Debug INT = 0
--DECLARE @Counter INT
--DECLARE @Line1 VARCHAR(MAX)
--DECLARE @Line2 VARCHAR(MAX)
--DECLARE @Result INT 

CREATE TABLE ##OrderResults (ID INT IDENTITY, Line VARCHAR(MAX))
INSERT ##OrderResults (Line)
SELECT Line 
FROM ##InputNumbered WHERE Line IS NOT NULL 
UNION SELECT '[[2]]' UNION SELECT '[[6]]'

SET @Debug = 0

--SELECT * FROM ##OrderResults

WHILE @Switched >= 1
BEGIN
    
    PRINT 'Iteratie ' + CAST(@Iteration AS VARCHAR(5)) + ' ' + CAST(GETDATE() AS VARCHAR(100))
    SET @Iteration = @Iteration + 1
    SET @Switched = 0
    SET @Counter = 1

    WHILE @Counter < (SELECT COUNT(1) FROM ##OrderResults)
    BEGIN
           
        SELECT @Line1 = Line FROM ##OrderResults WHERE ID = @Counter 
        SELECT @Line2 = Line FROM ##OrderResults WHERE ID = @Counter + 1

        --PRINT @Counter
        --PRINT @Line1
        --PRINT @Line2

        SET @Result = NULL

        EXEC dbo.AoCCompare2 @Line1 
                           , @Line2 
                           , @Debug
                           , @Result OUTPUT

        --PRINT @Result 

        IF @Result = 0
        BEGIN

            --PRINT 'Switch ' + CAST(@Counter AS VARCHAR(5))
            --PRINT @Line1
            --PRINT @Line2

            UPDATE ##OrderResults SET Line = @Line2 WHERE ID = @Counter 
            UPDATE ##OrderResults SET Line = @Line1 WHERE ID = @Counter + 1
            SET @Switched = @Switched + 1
        END

        SET @Counter = @Counter + 1
    END

    PRINT 'Switches ' + CAST(@Switched AS VARCHAR(6))

END

SELECT * FROM ##OrderResults 
WHERE Line IN ('[[2]]','[[6]]')
ORDER BY ID


--DROP TABLE ##OrderResults
-- Too high SELECT 198 * 253

/*
CREATE OR ALTER PROCEDURE dbo.AoCCompare2 (@Line1 VARCHAR(MAX), @Line2 VARCHAR(MAX), @Debug INT, @InOrder INT OUTPUT) 
AS
BEGIN

    -- 2 situaties:
        --Hij start met een blokhaak
            -- De ander start met een blokhaak --> Voor beide geldt haal het array er uit en recursie
            -- De ander start niet met een blokhaak --> Upgrade de ander naar een array van 1 item
        --Hij start niet met een blokhaak
            -- De ander start met een blokhaak --> Upgrade de ander naar een array van 1 item
            -- De ander start niet met een blokhaak --> Ga per getal vergelijken
                -- Zijn beide lijsten leeg      --> resultaat is NULL ga verder met de rest van de string
                -- Is één van beide lijsten leeg --> Links leeg is goed, rechts leeg is slecht
                -- Vergelijk het eerst volgende element --> Links kleiner is goed, Links groter is slecht
    DECLARE @Pos1 INT = 0 
    DECLARE @Pos2 INT = 0
    DECLARE @NewLine1 VARCHAR(MAX) = ''
    DECLARE @NewLine2 VARCHAR(MAX) = ''
    DECLARE @Level1 INT = 0
    DECLARE @Level2 INT = 0
    DECLARE @Part1 VARCHAR(4)
    DECLARE @Part2 VARCHAR(4)
    
    WHILE @InOrder IS NULL AND (LEN(@Line1) > 0 OR LEN(@Line2) > 0)
    BEGIN
    
        SET @Pos1 = 0
        SET @Pos2 = 0
        SET @NewLine1 = ''
        SET @NewLine2 = ''
        SET @Level1 = 0
        SET @Level2 = 0
        SET @Part1 = ''
        SET @Part2 = ''


        IF LEFT(@Line1,1) = '[' AND Left(@Line2,1) = '['
        BEGIN

            IF @Debug = 1 PRINT '2 Blokhaken'
            IF @Debug = 1 PRINT @Line1
            IF @Debug = 1 PRINT @Line2

            WHILE RIGHT(@NewLine1,1) <> ']' OR @Level1 <> 0
            BEGIN
                SET @Pos1 = @Pos1 + 1
                SET @NewLine1 = @NewLine1 + SUBSTRING(@Line1, @Pos1, 1)
                IF SUBSTRING(@Line1, @Pos1, 1) = '[' SET @Level1 = @Level1 + 1
                IF SUBSTRING(@Line1, @Pos1, 1) = ']' SET @Level1 = @Level1 - 1
            END
            SET @NewLine1 = SUBSTRING(@NewLine1,2,LEN(@NewLine1)-2)

            WHILE RIGHT(@NewLine2,1) <> ']' OR @Level2 <> 0
            BEGIN
                SET @Pos2 = @Pos2 + 1
                SET @NewLine2 = @NewLine2 + SUBSTRING(@Line2, @Pos2, 1)
                IF SUBSTRING(@Line2, @Pos2, 1) = '[' SET @Level2 = @Level2 + 1
                IF SUBSTRING(@Line2, @Pos2, 1) = ']' SET @Level2 = @Level2 - 1
            END
            SET @NewLine2 = SUBSTRING(@NewLine2,2,LEN(@NewLine2)-2)

            EXEC dbo.AoCCompare2 @NewLine1, @NewLine2, @Debug, @InOrder OUTPUT

            SET @Line1 = SUBSTRING(@Line1, @Pos1 + 2, LEN(@Line1))
            SET @Line2 = SUBSTRING(@Line2, @Pos2 + 2, LEN(@Line2))

            IF @Debug = 1 PRINT '2 Blokhaken 2'
            IF @Debug = 1 PRINT @Line1
            IF @Debug = 1 PRINT @Line2
            IF @Debug = 1 PRINT @NewLine1
            IF @Debug = 1 PRINT @NewLine2
        END
        ELSE
        IF LEFT(@Line1,1) = '[' AND Left(@Line2,1) <> '['
        BEGIN

            IF @Debug = 1 PRINT '1 Blokhaak Links'
            IF @Debug = 1 PRINT @Line1
            IF @Debug = 1 PRINT @Line2

            IF LEN(@Line2) = 0
            BEGIN
                SET @InOrder = 0
                IF @Debug = 1 PRINT 'Right list empty'
            END
            ELSE
            BEGIN

                IF CHARINDEX(',', @Line2) > 0 
                    SET @NewLine2 = '[' + LEFT(@Line2, CHARINDEX(',',@Line2) - 1) + ']' + SUBSTRING(@Line2, CHARINDEX(',',@Line2), LEN(@Line2))
                ELSE SET @NewLine2 = '[' + @Line2 + ']'

                EXEC dbo.AoCCompare2 @Line1, @NewLine2, @Debug, @InOrder OUTPUT

                IF CHARINDEX(',',@Line1) > 1 SET @Line1 = SUBSTRING(@Line1, CHARINDEX(',',@Line1) + 1, LEN(@Line1)) ELSE SET @Line1 = ''
                IF CHARINDEX(',',@Line2) > 1 SET @Line2 = SUBSTRING(@Line2, CHARINDEX(',',@Line2) + 1, LEN(@Line2)) ELSE SET @Line2 = ''

                IF @Debug = 1 PRINT @Line1 + 'Na BH L'
                IF @Debug = 1 PRINT @Line2
            END

        END
        ELSE
        IF LEFT(@Line1,1) <> '[' AND Left(@Line2,1) = '['
        BEGIN

            IF @Debug = 1 PRINT '1 Blokhaak Rechts'
            IF @Debug = 1 PRINT @Line1
            IF @Debug = 1 PRINT @Line2

            IF LEN(@Line1) = 0
            BEGIN
                SET @InOrder = 1
                IF @Debug = 1 PRINT 'Left list empty'
            END
            ELSE
            BEGIN

                IF CHARINDEX(',', @Line1) > 0 
                    SET @NewLine1 = '[' + LEFT(@Line1, CHARINDEX(',',@Line1) - 1) + ']' + SUBSTRING(@Line1, CHARINDEX(',',@Line1), LEN(@Line1))
                ELSE SET @NewLine1 = '[' + @Line1 + ']'

                EXEC dbo.AoCCompare2 @NewLine1, @Line2, @Debug, @InOrder OUTPUT

                IF CHARINDEX(',',@Line1) > 1 SET @Line1 = SUBSTRING(@Line1, CHARINDEX(',',@Line1) + 1, LEN(@Line1)) ELSE SET @Line1 = ''
                IF CHARINDEX(',',@Line2) > 1 SET @Line2 = SUBSTRING(@Line2, CHARINDEX(',',@Line2) + 1, LEN(@Line2)) ELSE SET @Line2 = ''

                IF @Debug = 1 PRINT @Line1 + 'Na BH R'
                IF @Debug = 1 PRINT @Line2

            END
        END
        ELSE 
        BEGIN
        
            IF LEN(@Line1) = 0 AND LEN(@Line2) = 0
            BEGIN
                SET @InOrder = NULL
                IF @Debug = 1 PRINT 'Both lists empty'
            END
            ELSE 
            IF LEN(@Line1) = 0
            BEGIN
                SET @InOrder = 1
                IF @Debug = 1 PRINT 'Left list empty'
            END
            ELSE
            IF LEN(@Line2) = 0
            BEGIN
                SET @InOrder = 0
                IF @Debug = 1 PRINT 'Right list empty'
            END
            ELSE
            BEGIN

                IF @Debug = 1 PRINT 'Compare'
                IF @Debug = 1 PRINT @Line1
                IF @Debug = 1 PRINT @Line2
                
                --We're starting with the actual list
                IF CHARINDEX(',',@Line1) > 1 SET @Part1 = SUBSTRING(@Line1, 1, CHARINDEX(',',@Line1) - 1) ELSE SET @Part1 = @Line1
                IF CHARINDEX(',',@Line2) > 1 SET @Part2 = SUBSTRING(@Line2, 1, CHARINDEX(',',@Line2) - 1) ELSE SET @Part2 = @Line2
        
                IF CAST(@Part1 AS INT) > CAST(@Part2 AS INT) SET @InOrder = 0 
                IF CAST(@Part1 AS INT) < CAST(@Part2 AS INT) SET @InOrder = 1

                IF CHARINDEX(',',@Line1) > 1 SET @NewLine1 = SUBSTRING(@Line1, CHARINDEX(',',@Line1) + 1, LEN(@Line1)) ELSE SET @NewLine1 = ''
                IF CHARINDEX(',',@Line2) > 1 SET @NewLine2 = SUBSTRING(@Line2, CHARINDEX(',',@Line2) + 1, LEN(@Line2)) ELSE SET @NewLine2 = ''

                IF @Debug = 1 PRINT 'Compare2'
                IF @Debug = 1 PRINT @NewLine1
                IF @Debug = 1 PRINT @NewLine2
                IF @Debug = 1 PRINT 'InOrder: ' + CAST(@InOrder AS VARCHAR(2))

                IF @InOrder IS NULL EXEC dbo.AoCCompare2 @NewLine1, @NewLine2, @Debug, @InOrder OUTPUT

                SET @Line1 = @NewLine1
                SET @Line2 = @NewLine2
            END

        END
    END
END

*/