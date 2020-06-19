use Test_WME

SET NOCOUNT ON

CREATE TABLE #Input (Nr NVARCHAR(MAX));

BULK INSERT #Input
FROM 'C:\Source\AdventOfCode\input22.txt'
WITH (ROWTERMINATOR = '0x0A');

--SELECT *,REPLACE(Nr, 'deal with increment ', '') FROM #Input

CREATE TABLE ##Instructions (ID INT IDENTITY(1,1), InstrType INT, InstrCount INT)

INSERT ##Instructions (InstrType, InstrCount)
SELECT CASE WHEN Nr LIKE 'deal with increment%' THEN 3
            WHEN Nr LIKE 'cut%' THEN 2
            WHEN Nr LIKE 'deal into new stack%' THEN 1
            END
,      REPLACE(REPLACE(REPLACE(Nr, 'deal with increment ', ''), 'deal into new stack', '0'), 'cut ', '')
FROM #Input

DECLARE @DeckSize NUMERIC(38,0) = 10007
--SET @DeckSize = 119315717514047

CREATE TABLE ##StepSize(ID INT IDENTITY(1,1), DealSize NUMERIC(38,0), StepSize NUMERIC(38,0))

CREATE TABLE ##Results(Position NUMERIC(38,0), Step NUMERIC(38,0), Direction NUMERIC(38,0), Iteration INT)


DECLARE @Iteration INT
SET @Iteration = 0

DECLARE @DealSize NUMERIC(38,0)
DECLARE @n NUMERIC(38,0)

DECLARE DealStepCursor CURSOR FOR
    SELECT DISTINCT InstrCount FROM ##Instructions WHERE InstrType = 3

OPEN DealStepCursor

FETCH NEXT FROM DealStepCursor INTO @DealSize

WHILE @@FETCH_STATUS = 0
BEGIN

    SET @n = 1

    WHILE ((CAST(CEILING(@DeckSize * @n * 1.0/ @DealSize) AS NUMERIC(38,0))) * @DealSize) % @DeckSize <> 1
    BEGIN 
        SET @n = @n + 1
    END

    INSERT ##StepSize (DealSize, StepSize) 
    SELECT @DealSize, CAST(CEILING(@DeckSize * @n * 1.0 / @DealSize) AS NUMERIC(38,0)) 

    FETCH NEXT FROM DealStepCursor INTO @DealSize

END

CLOSE DealStepCursor
DEALLOCATE DealStepCursor


DECLARE @Pos NUMERIC(38,0) = 0
DECLARE @Direction NUMERIC(38,0) = 1
DECLARE @Step NUMERIC(38,0) = 1
DECLARE @InstrType NUMERIC(38,0)
DECLARE @InstrCount NUMERIC(38,0)
DECLARE @Res VARCHAR(MAX)
DECLARE @Res2 VARCHAR(10)

WHILE @Iteration < 1--0000
BEGIN

DECLARE ShuffleCursor CURSOR
FOR SELECT InstrType, InstrCount FROM ##Instructions ORDER BY ID

OPEN ShuffleCursor

FETCH NEXT FROM ShuffleCursor INTO @InstrType, @InstrCount

WHILE @@FETCH_STATUS = 0
BEGIN

    IF @InstrType = 1
    BEGIN

        SELECT @Pos = (@Pos + @Step * CASE WHEN @Direction = 1 THEN -1 ELSE 1 END) % @DeckSize
        IF @Pos < 0 SET @Pos = @Pos + @DeckSize
        SET @Direction = -1 * @Direction

    END

    IF @InstrType = 2
    BEGIN

        SELECT @Pos = (@Pos + @InstrCount * @Step * @Direction) % @DeckSize
        IF @Pos < 0 SET @Pos = @Pos + @DeckSize

    END

    IF @InstrType = 3
    BEGIN
   
        SELECT @Step = (@Step * StepSize) % @DeckSize FROM ##StepSize WHERE DealSize = @InstrCount
        --SET @Step = @Step % @DeckSize

    END

--SET @Res = 'Pos: ' + CAST(@Pos AS VARCHAR(6)) + ', @Step: ' + CAST(@Step AS VARCHAR(6)) + ', @Dir: ' + CAST(@Direction AS VARCHAR(6))
--PRINT @Res

    FETCH NEXT FROM ShuffleCursor INTO @InstrType, @InstrCount
END
CLOSE ShuffleCursor
DEALLOCATE ShuffleCursor


DECLARE @Counter NUMERIC(38,0) = 0
DECLARE @CardPos NUMERIC(38,0)

--SET @Res = 'Pos: ' + CAST(@Pos AS VARCHAR(38)) + ', @Step: ' + CAST(@Step AS VARCHAR(38)) + ', @Dir: ' + CAST(@Direction AS VARCHAR(38))
--PRINT @Res

INSERT ##Results(Position, Step, Direction, Iteration) SELECT @Pos, @Step, @Direction, @Iteration

SET @Iteration = @Iteration + 1
END


/*
WHILE @Counter < @DeckSize + 1
BEGIN
    
    SET @CardPos = (@Pos + @Direction * @Step * @Counter) % @DeckSize

    IF @CardPos < 0 SET @CardPos = @CardPos + @DeckSize

    IF @CardPos = 2020
    BEGIN
        PRINT CAST(@CardPos AS VARCHAR(16)) + ' at ' + CAST(@Counter AS VARCHAR(16))
--        INSERT ##Results (Decksize, Iteration, Res) SELECT @DeckSize, @Iteration, @Counter
    END

    SET @Counter = @Counter + 1
END
*/

SELECT InstrType, Sum(InstrCount)
FROM ##Instructions
GROUP BY InstrType

DROP TABLE #Input
DROP TABLE ##Instructions
DROP TABLE ##StepSize
--DROP TABLE ##Results
--DROP TABLE ##Results2

--SELECT * FROM ##Results

--7962 is too high for part 1
--3589 is correct for part 1

CREATE TABLE ##Results2(Iteration INT, In2020 NUMERIC(38,0))
INSERT ##Results2 (Iteration, In2020)
SELECT Iteration, (Position + Direction * Step * 2020) % 10007-- 119315717514047
FROM ##Results

UPDATE ##Results2
SET In2020 = In2020 + 10007 --119315717514047
WHERE In2020 < 0

SELECT * FROM ##Results2

-- In 10007, card 5273 is at pos 2020