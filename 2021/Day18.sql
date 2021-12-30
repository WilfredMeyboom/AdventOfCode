USE Test_WME

SET NOCOUNT ON

DECLARE @year VARCHAR(4) = '2021'
DECLARE @day VARCHAR(2)  = '18'

IF EXISTS (SELECT * FROM tempdb.sys.tables WHERE name = '##Input') DROP TABLE ##Input
CREATE TABLE ##Input (Line NVARCHAR(MAX) NULL);

IF EXISTS (SELECT * FROM tempdb.sys.tables WHERE name = '##InputNumbered') DROP TABLE ##InputNumbered
CREATE TABLE ##InputNumbered (Ind INT NOT NULL, Line NVARCHAR(MAX) NULL);

IF EXISTS (SELECT * FROM tempdb.sys.tables WHERE name = '##InputGrid') DROP TABLE ##InputGrid
CREATE TABLE ##InputGrid (Ind INT IDENTITY(1,1), RowNr INT, ColNr INT, Val CHAR);

IF EXISTS (SELECT * FROM tempdb.sys.tables WHERE name = '##InputInts') DROP TABLE ##InputInts
CREATE TABLE ##InputInts (Ind INT NOT NULL, Val BIGINT);

IF EXISTS (SELECT * FROM tempdb.sys.tables WHERE name = '##InputSplit') DROP TABLE ##InputSplit
CREATE TABLE ##InputSplit (Ind INT IDENTITY(1,1), RowNr INT, PieceNr INT, Piece VARCHAR(MAX));

IF EXISTS (SELECT * FROM tempdb.sys.tables WHERE name = '##InputSplitCust') DROP TABLE ##InputSplitCust
CREATE TABLE ##InputSplitCust (Ind INT IDENTITY(1,1), RowNr INT, PieceNr INT, Piece VARCHAR(MAX));

EXEC dbo.GetInput @year = @year, @day = @day
EXEC dbo.ParseInput @year = @year, @day = @day, @SplitCustom = '= .,'

DECLARE @SnailFish VARCHAR(MAX) = ''
DECLARE @SnailFishAdd VARCHAR(MAX) = ''
SELECT TOP(1) @SnailFish = Line FROM ##InputNumbered INU WHERE Ind = 1

DECLARE @Index INT = 1
DECLARE @Level INT = 0
DECLARE @FirstNumber INT 
DECLARE @SecondNumber INT 
DECLARE @ThisNumber INT
DECLARE @StartIndexNumber INT 
DECLARE @CheckingForExpl INT

DECLARE snailfishcursor CURSOR FAST_FORWARD READ_ONLY FOR SELECT Line FROM ##InputNumbered INU WHERE Ind > 1 ORDER BY Ind

OPEN snailfishcursor

FETCH NEXT FROM snailfishcursor INTO @SnailFishAdd

WHILE @@FETCH_STATUS = 0
BEGIN
   
    SET @SnailFish = '[' + @SnailFish + ',' + @SnailFishAdd + ']'

    SET @Index = 1
    SET @Level = 0
    SET @CheckingForExpl = 1

    WHILE @Index < LEN(@SnailFish) OR @CheckingForExpl = 1
    BEGIN

        IF SUBSTRING(@SnailFish, @Index, 1) = '[' 
        BEGIN            
            SET @Level = @Level + 1
            SET @Index = @Index + 1
        END
        ELSE IF SUBSTRING(@SnailFish, @Index, 1) = ']' 
        BEGIN
            SET @Level = @Level - 1
            SET @Index = @Index + 1
        END
        ELSE IF SUBSTRING(@SnailFish, @Index, 1) = ','
        BEGIN
            SET @Index = @Index + 1
        END
        ELSE 
        BEGIN
            
            IF (@Level >= 5 
                AND CHARINDEX('[',SUBSTRING(@SnailFish, @Index, CHARINDEX(']', @SnailFish, @Index) - @Index)) = 0)
                AND @CheckingForExpl = 1
            BEGIN

                SET @StartIndexNumber = @Index
                SET @FirstNumber = SUBSTRING(@SnailFish, @Index, 1)

                WHILE TRY_CAST(SUBSTRING(@SnailFish, @Index + 1, 1) AS INT) IS NOT NULL
                BEGIN
                    SET @Index = @Index + 1
                    SET @FirstNumber = 10 * @FirstNumber + SUBSTRING(@SnailFish, @Index, 1)  
                END

                SET @Index = @Index + 2 -- Skip comma

                SET @SecondNumber = SUBSTRING(@SnailFish, @Index, 1)
      
                WHILE TRY_CAST(SUBSTRING(@SnailFish, @Index + 1, 1) AS INT) IS NOT NULL
                BEGIN
                    SET @Index = @Index + 1
                    SET @SecondNumber = 10 * @SecondNumber + SUBSTRING(@SnailFish, @Index, 1)  
                END
       
                WHILE TRY_CAST(SUBSTRING(@SnailFish, @Index + 1, 1) AS INT) IS NULL AND @Index < LEN(@SnailFish)
                BEGIN
                    SET @Index = @Index + 1
                END

                SET @Index = @Index + 1

                SET @ThisNumber = SUBSTRING(@SnailFish, @Index, 1)
       
                WHILE TRY_CAST(SUBSTRING(@SnailFish, @Index + 1, 1) AS INT) IS NOT NULL AND @Index < LEN(@SnailFish)
                BEGIN
                    SET @Index = @Index + 1
                    SET @ThisNumber = 10 * @ThisNumber + SUBSTRING(@SnailFish, @Index, 1)  
                END

                IF @Index < LEN(@SnailFish)
                SET @SnailFish = LEFT(@SnailFish, @StartIndexNumber - 2) + '0' + 
                    SUBSTRING(@SnailFish, @StartIndexNumber + LEN(@FirstNumber) + LEN(@SecondNumber) + 2, @Index - @StartIndexNumber - LEN(@FirstNumber) - LEN(@SecondNumber) - 2 - (LEN(@ThisNumber) - 1)) +
                    CAST(@SecondNumber + @ThisNumber AS VARCHAR(4)) + 
                    SUBSTRING(@SnailFish, @Index + 1, LEN(@SnailFish))
                ELSE
                SET @SnailFish = LEFT(@SnailFish, @StartIndexNumber - 2) + '0' + 
                    SUBSTRING(@SnailFish, @StartIndexNumber + LEN(@FirstNumber) + LEN(@SecondNumber) + 2, @Index - @StartIndexNumber - LEN(@FirstNumber) - LEN(@SecondNumber) - 2) +
                    SUBSTRING(@SnailFish, @Index + 1, LEN(@SnailFish))


                SET @StartIndexNumber = @StartIndexNumber - 1
      
                WHILE TRY_CAST(SUBSTRING(@SnailFish, @StartIndexNumber - 1, 1) AS INT) IS NULL AND @StartIndexNumber > 0
                BEGIN
                    SET @StartIndexNumber = @StartIndexNumber - 1
                END

                SET @StartIndexNumber = @StartIndexNumber - 1

                WHILE TRY_CAST(SUBSTRING(@SnailFish, @StartIndexNumber - 1, 1) AS INT) IS NOT NULL AND @StartIndexNumber > 0
                BEGIN
                    SET @StartIndexNumber = @StartIndexNumber - 1
                END

                IF @StartIndexNumber > 0
                BEGIN
                
                SET @ThisNumber = SUBSTRING(@SnailFish, @StartIndexNumber, 1)

                WHILE TRY_CAST(SUBSTRING(@SnailFish, @StartIndexNumber + 1, 1) AS INT) IS NOT NULL
                BEGIN
                    SET @StartIndexNumber = @StartIndexNumber + 1
                    SET @ThisNumber = 10 * @ThisNumber + SUBSTRING(@SnailFish, @StartIndexNumber, 1)  
                END

                SET @SnailFish = LEFT(@SnailFish, @StartIndexNumber - 1 - LEN(@ThisNumber) + 1) +
                    CAST(@FirstNumber + @ThisNumber AS VARCHAR(4)) + 
                    SUBSTRING(@SnailFish, @StartIndexNumber + 1, LEN(@SnailFish))
                END
          
                SET @Index = 0
                SET @Level = 0

            END
            ELSE
            --Split
            IF TRY_CAST(SUBSTRING(@SnailFish, @Index + 1, 1) AS INT) IS NOT NULL AND @CheckingForExpl = 0
            BEGIN
                SET @StartIndexNumber = @Index
                SET @ThisNumber = SUBSTRING(@SnailFish, @Index, 1)

                WHILE TRY_CAST(SUBSTRING(@SnailFish, @Index + 1, 1) AS INT) IS NOT NULL
                BEGIN
                    SET @Index = @Index + 1
                    SET @ThisNumber = 10 * @ThisNumber + SUBSTRING(@SnailFish, @Index, 1)  
                END

                SET @SnailFish = LEFT(@SnailFish, @StartIndexNumber-1) + 
                                '[' + CAST(FLOOR(@ThisNumber / 2.0) AS VARCHAR(4)) + ',' + CAST(CEILING(@ThisNumber / 2.0) AS VARCHAR(4)) +']' + 
                                SUBSTRING(@SnailFish, @Index + 1, LEN(@SnailFish))

                SET @Index = 0
                SET @Level = 0
                SET @CheckingForExpl = 1

            END
            ELSE
                SET @Index = @Index + 1


            IF @Index >= LEN(@SnailFish) AND @CheckingForExpl = 1 -- Checking for explosions done
            BEGIN
                SET @CheckingForExpl = 0
                SET @Index = 0
                SET @Level = 0
            END

        END

    END

    --PRINT 'Current status of Snailfish: ' + @SnailFish

    FETCH NEXT FROM snailfishcursor INTO @SnailFishAdd
END

CLOSE snailfishcursor
DEALLOCATE snailfishcursor

-- Calculate magnitude
WHILE LEFT(@SnailFish,1) = '['
BEGIN

    ;WITH cte_Numbers AS (
        SELECT 1 AS Ind
        ,      CAST(LEFT(@SnailFish, 1) AS VARCHAR(100)) AS Chr
        ,      SUBSTRING(@SnailFish, 2, LEN(@SnailFish)) AS LeftOver

        UNION ALL

        SELECT Ind + 1
        ,      CAST(CASE WHEN LEFT(LeftOver, 1) IN ('[',']',',') 
                    THEN LEFT(LeftOver, 1)
                    ELSE CASE WHEN CHARINDEX(',', LeftOver + ',') < CHARINDEX(']',LeftOver)
                              THEN SUBSTRING(LeftOver, 1, CHARINDEX(',', LeftOver) - 1)
                              ELSE SUBSTRING(LeftOver, 1, CHARINDEX(']', LeftOver) - 1)
                         END
                    END AS VARCHAR(100)) AS Chr
        ,      CASE WHEN LEFT(LeftOver, 1) IN ('[',']',',') 
                    THEN SUBSTRING(LeftOver, 2, LEN(@SnailFish))
                    ELSE CASE WHEN CHARINDEX(',', LeftOver + ',') < CHARINDEX(']',LeftOver)
                              THEN SUBSTRING(LeftOver, CHARINDEX(',', LeftOver), LEN(@SnailFish))
                              ELSE SUBSTRING(LeftOver, CHARINDEX(']', LeftOver), LEN(@SnailFish))
                         END
                    END
    
        FROM cte_Numbers
        WHERE LEN(LeftOVer) > 0
    ), cte_Magnitudes AS (
        SELECT '[' + cN2.Chr + ',' + cN3.Chr + ']' AS Pair
        ,       3*CAST(cN2.Chr AS INT) + 2*CAST(cn3.Chr AS INT) AS Val
        FROM cte_Numbers cN
        INNER JOIN cte_Numbers cN2 ON cN.Ind = cN2.Ind + 1 AND cN2.Chr NOT IN ('[',']')
        INNER JOIN cte_Numbers cN3 ON cN.Ind = cN3.Ind - 1 AND cN3.Chr NOT IN ('[',']')
        WHERE cN.Chr = ',' 
    )
    SELECT @SnailFish = REPLACE(@SnailFish, Pair, Val)
    FROM cte_Magnitudes

END

SELECT @SnailFish AS Part1

-- 3654 is correct for Part1


DECLARE @Results TABLE(Magnitudes BIGINT)

DECLARE cursor_name CURSOR FAST_FORWARD READ_ONLY FOR 
    SELECT '[' + I1.Line + ',' + I2.Line + ']'
    FROM ##Input I1
    CROSS APPLY ##Input I2
    WHERE I1.Line <> I2.Line

OPEN cursor_name

FETCH NEXT FROM cursor_name INTO @SnailFish

WHILE @@FETCH_STATUS = 0
BEGIN
    
    SET @Index = 1
    SET @Level = 0
    SET @CheckingForExpl = 1

    --PRINT @SnailFish

    WHILE @Index < LEN(@SnailFish) OR @CheckingForExpl = 1
    BEGIN

        IF SUBSTRING(@SnailFish, @Index, 1) = '[' 
        BEGIN            
            SET @Level = @Level + 1
            SET @Index = @Index + 1
        END
        ELSE IF SUBSTRING(@SnailFish, @Index, 1) = ']' 
        BEGIN
            SET @Level = @Level - 1
            SET @Index = @Index + 1
        END
        ELSE IF SUBSTRING(@SnailFish, @Index, 1) = ','
        BEGIN
            SET @Index = @Index + 1
        END
        ELSE 
        BEGIN
            
            IF (@Level >= 5 
                AND CHARINDEX('[',SUBSTRING(@SnailFish, @Index, CHARINDEX(']', @SnailFish, @Index) - @Index)) = 0)
                AND @CheckingForExpl = 1
            BEGIN

                SET @StartIndexNumber = @Index
                SET @FirstNumber = SUBSTRING(@SnailFish, @Index, 1)

                WHILE TRY_CAST(SUBSTRING(@SnailFish, @Index + 1, 1) AS INT) IS NOT NULL
                BEGIN
                    SET @Index = @Index + 1
                    SET @FirstNumber = 10 * @FirstNumber + SUBSTRING(@SnailFish, @Index, 1)  
                END

                SET @Index = @Index + 2 -- Skip comma

                SET @SecondNumber = SUBSTRING(@SnailFish, @Index, 1)
      
                WHILE TRY_CAST(SUBSTRING(@SnailFish, @Index + 1, 1) AS INT) IS NOT NULL
                BEGIN
                    SET @Index = @Index + 1
                    SET @SecondNumber = 10 * @SecondNumber + SUBSTRING(@SnailFish, @Index, 1)  
                END
       
                WHILE TRY_CAST(SUBSTRING(@SnailFish, @Index + 1, 1) AS INT) IS NULL AND @Index < LEN(@SnailFish)
                BEGIN
                    SET @Index = @Index + 1
                END

                SET @Index = @Index + 1

                SET @ThisNumber = SUBSTRING(@SnailFish, @Index, 1)
       
                WHILE TRY_CAST(SUBSTRING(@SnailFish, @Index + 1, 1) AS INT) IS NOT NULL AND @Index < LEN(@SnailFish)
                BEGIN
                    SET @Index = @Index + 1
                    SET @ThisNumber = 10 * @ThisNumber + SUBSTRING(@SnailFish, @Index, 1)  
                END

                IF @Index < LEN(@SnailFish)
                SET @SnailFish = LEFT(@SnailFish, @StartIndexNumber - 2) + '0' + 
                    SUBSTRING(@SnailFish, @StartIndexNumber + LEN(@FirstNumber) + LEN(@SecondNumber) + 2, @Index - @StartIndexNumber - LEN(@FirstNumber) - LEN(@SecondNumber) - 2 - (LEN(@ThisNumber) - 1)) +
                    CAST(@SecondNumber + @ThisNumber AS VARCHAR(4)) + 
                    SUBSTRING(@SnailFish, @Index + 1, LEN(@SnailFish))
                ELSE
                SET @SnailFish = LEFT(@SnailFish, @StartIndexNumber - 2) + '0' + 
                    SUBSTRING(@SnailFish, @StartIndexNumber + LEN(@FirstNumber) + LEN(@SecondNumber) + 2, @Index - @StartIndexNumber - LEN(@FirstNumber) - LEN(@SecondNumber) - 2) +
                    SUBSTRING(@SnailFish, @Index + 1, LEN(@SnailFish))


                SET @StartIndexNumber = @StartIndexNumber - 1
      
                WHILE TRY_CAST(SUBSTRING(@SnailFish, @StartIndexNumber - 1, 1) AS INT) IS NULL AND @StartIndexNumber > 0
                BEGIN
                    SET @StartIndexNumber = @StartIndexNumber - 1
                END

                SET @StartIndexNumber = @StartIndexNumber - 1

                WHILE TRY_CAST(SUBSTRING(@SnailFish, @StartIndexNumber - 1, 1) AS INT) IS NOT NULL AND @StartIndexNumber > 0
                BEGIN
                    SET @StartIndexNumber = @StartIndexNumber - 1
                END

                IF @StartIndexNumber > 0
                BEGIN
                
                SET @ThisNumber = SUBSTRING(@SnailFish, @StartIndexNumber, 1)

                WHILE TRY_CAST(SUBSTRING(@SnailFish, @StartIndexNumber + 1, 1) AS INT) IS NOT NULL
                BEGIN
                    SET @StartIndexNumber = @StartIndexNumber + 1
                    SET @ThisNumber = 10 * @ThisNumber + SUBSTRING(@SnailFish, @StartIndexNumber, 1)  
                END

                SET @SnailFish = LEFT(@SnailFish, @StartIndexNumber - 1 - LEN(@ThisNumber) + 1) +
                    CAST(@FirstNumber + @ThisNumber AS VARCHAR(4)) + 
                    SUBSTRING(@SnailFish, @StartIndexNumber + 1, LEN(@SnailFish))
                END
          
                SET @Index = 0
                SET @Level = 0

            END
            ELSE
            --Split
            IF TRY_CAST(SUBSTRING(@SnailFish, @Index + 1, 1) AS INT) IS NOT NULL AND @CheckingForExpl = 0
            BEGIN
                SET @StartIndexNumber = @Index
                SET @ThisNumber = SUBSTRING(@SnailFish, @Index, 1)

                WHILE TRY_CAST(SUBSTRING(@SnailFish, @Index + 1, 1) AS INT) IS NOT NULL
                BEGIN
                    SET @Index = @Index + 1
                    SET @ThisNumber = 10 * @ThisNumber + SUBSTRING(@SnailFish, @Index, 1)  
                END

                SET @SnailFish = LEFT(@SnailFish, @StartIndexNumber-1) + 
                                '[' + CAST(FLOOR(@ThisNumber / 2.0) AS VARCHAR(4)) + ',' + CAST(CEILING(@ThisNumber / 2.0) AS VARCHAR(4)) +']' + 
                                SUBSTRING(@SnailFish, @Index + 1, LEN(@SnailFish))

                SET @Index = 0
                SET @Level = 0
                SET @CheckingForExpl = 1

            END
            ELSE
                SET @Index = @Index + 1


            IF @Index >= LEN(@SnailFish) AND @CheckingForExpl = 1 -- Checking for explosions done
            BEGIN
                SET @CheckingForExpl = 0
                SET @Index = 0
                SET @Level = 0
            END

        END

    END

    --PRINT @SnailFish

    --Calculate magnitude
    WHILE LEFT(@SnailFish,1) = '['
    BEGIN

        ;WITH cte_Numbers AS (
            SELECT 1 AS Ind
            ,      CAST(LEFT(@SnailFish, 1) AS VARCHAR(100)) AS Chr
            ,      SUBSTRING(@SnailFish, 2, LEN(@SnailFish)) AS LeftOver
            UNION ALL

            SELECT Ind + 1
            ,      CAST(CASE WHEN LEFT(LeftOver, 1) IN ('[',']',',') 
                        THEN LEFT(LeftOver, 1)
                        ELSE CASE WHEN CHARINDEX(',', LeftOver + ',') < CHARINDEX(']',LeftOver)
                                  THEN SUBSTRING(LeftOver, 1, CHARINDEX(',', LeftOver) - 1)
                                  ELSE SUBSTRING(LeftOver, 1, CHARINDEX(']', LeftOver) - 1)
                             END
                        END AS VARCHAR(100)) AS Chr
            ,      CASE WHEN LEFT(LeftOver, 1) IN ('[',']',',') 
                        THEN SUBSTRING(LeftOver, 2, LEN(@SnailFish))
                        ELSE CASE WHEN CHARINDEX(',', LeftOver + ',') < CHARINDEX(']',LeftOver)
                                  THEN SUBSTRING(LeftOver, CHARINDEX(',', LeftOver), LEN(@SnailFish))
                                  ELSE SUBSTRING(LeftOver, CHARINDEX(']', LeftOver), LEN(@SnailFish))
                             END
                        END
    
            FROM cte_Numbers
            WHERE LEN(LeftOVer) > 0
        ), cte_Magnitudes AS (
        SELECT '[' + cN2.Chr + ',' + cN3.Chr + ']' AS Pair
        ,       3*CAST(cN2.Chr AS INT) + 2*CAST(cN3.Chr AS INT) AS Val
        FROM cte_Numbers c1
        INNER JOIN cte_Numbers cN2 ON c1.Ind = cN2.Ind + 1 AND cN2.Chr NOT IN ('[',']')
        INNER JOIN cte_Numbers cN3 ON c1.Ind = cN3.Ind - 1 AND cN3.Chr NOT IN ('[',']')
        WHERE c1.Chr = ',' 
        )
        SELECT @SnailFish = REPLACE(@SnailFish, Pair, Val)
        FROM cte_Magnitudes

    END

    INSERT @Results
    (
        Magnitudes
    )
    SELECT CAST(@SnailFish AS BIGINT)

    --PRINT @SnailFish

    FETCH NEXT FROM cursor_name INTO @SnailFish
END

CLOSE cursor_name
DEALLOCATE cursor_name

SELECT TOP(1) R.Magnitudes AS Part2 FROM @Results R ORDER BY 1 DESC


-- 4578 is correct for part 2
-- Runtime ~ 10 min