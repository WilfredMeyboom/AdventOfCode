USE Test_WME

SET NOCOUNT ON

DECLARE @Input VARCHAR(9) = '394618527'

--SET @Input = '389125467' --Example 1
--SET @Input = '123456789' --Private example

DECLARE @DoPart1 INT = 0

IF @DoPart1 = 1
BEGIN

CREATE TABLE ##Game(ID INT IDENTITY(1,1), Pos INT, CupNr INT)

;WITH cte_Cups AS (
    SELECT 0 AS Pos
    ,      LEFT(@Input,1) AS CupNr
    ,      SUBSTRING(@Input, 2, LEN(@Input)) AS LeftOver

    UNION ALL

    SELECT Pos + 1
    ,      LEFT(LeftOver,1) AS CupNr
    ,      CASE WHEN LEN(LeftOver) = 1 THEN '' ELSE SUBSTRING(LeftOver, 2, LEN(LeftOver)) END AS LeftOver
    FROM cte_Cups
    WHERE LEN(LeftOver) > 0

)
INSERT ##Game(Pos, CupNr)
SELECT Pos, CupNr
FROM cte_Cups
ORDER BY Pos

INSERT ##Game(Pos, CupNr)
SELECT TOP(91) ROW_Number() OVER (ORDER BY (SELECT 0)) + 9, ROW_Number() OVER (ORDER BY (SELECT 0)) + 9 FROM Sys.messages

--SELECT * FROM ##Game ORDER BY Pos


DECLARE @CurrentCup INT
DECLARE @CurrentPos INT = 0
DECLARE @NrOfCups INT
DECLARE @DestinationCup INT
DECLARE @DestinationPos INT
DECLARE @Circle VARCHAR(50)
DECLARE @Pos1 INT
DECLARE @Pos2 INT

SELECT @CurrentCup = CupNr FROM ##Game WHERE Pos = 0
SELECT @NrOfCups = COUNT(1) FROM ##Game

DECLARE @Counter INT = 0

DECLARE @LiftedCups TABLE (Pos INT, CupNr INT)

WHILE @Counter < 100
BEGIN

    INSERT @LiftedCups (Pos, CupNr)
    SELECT Pos, CupNr
    FROM ##Game
    WHERE Pos IN ((@CurrentPos + 1)%@NrOfCups, (@CurrentPos + 2)%@NrOfCups, (@CurrentPos + 3)%@NrOfCups)
     
    SET @DestinationCup = @CurrentCup - 1

    WHILE @DestinationCup < 1 OR EXISTS (SELECT 1 FROM @LiftedCups WHERE CupNr = @DestinationCup)
    BEGIN
        IF @DestinationCup < 1 SET @DestinationCup = @DestinationCup + @NrOfCups --We moved outside the range. So loop around
        ELSE SET @DestinationCup = @DestinationCup - 1                          --We picked a lifted cup, try one lower
    END

    SELECT @DestinationPos = (Pos + 1) % @NrOfCups FROM ##Game WHERE CupNr = @DestinationCup

--IF @Counter = 2
--BEGIN
--        SELECT * FROM ##Game
--        SELECT @CurrentPos, @CurrentCup

--        SELECT 0 Pos, @DestinationCup AS CupNr

--        SELECT ROW_NUMBER() OVER (ORDER BY CASE WHEN Pos < @CurrentPos THEN Pos + @NrOfCups ELSE Pos END), CupNr
--        FROM @LiftedCups

--        SELECT ROW_NUMBER() OVER (ORDER BY Pos) + 3, CupNr
--        FROM ##Game
--        WHERE CupNr NOT IN (SELECT CupNr FROM @LiftedCups UNION SELECT @DestinationCup) AND Pos > @DestinationPos - 1

--        SELECT @NrOfCups - ROW_NUMBER() OVER (ORDER BY Pos DESC), CupNr
--        FROM ##Game
--        WHERE CupNr NOT IN (SELECT CupNr FROM @LiftedCups UNION SELECT @DestinationCup) AND Pos < @DestinationPos
--        ORDER BY 1
--END


    ;WITH cte_NewOrder AS (
        SELECT 0 Pos, @DestinationCup AS CupNr
        UNION ALL
        SELECT ROW_NUMBER() OVER (ORDER BY CASE WHEN Pos < @CurrentPos THEN Pos + @NrOfCups ELSE Pos END), CupNr
        FROM @LiftedCups
        UNION ALL
        SELECT ROW_NUMBER() OVER (ORDER BY Pos) + 3, CupNr
        FROM ##Game
        WHERE CupNr NOT IN (SELECT CupNr FROM @LiftedCups UNION SELECT @DestinationCup) AND Pos > @DestinationPos - 1
        UNION ALL
        SELECT @NrOfCups - ROW_NUMBER() OVER (ORDER BY Pos DESC), CupNr
        FROM ##Game
        WHERE CupNr NOT IN (SELECT CupNr FROM @LiftedCups UNION SELECT @DestinationCup) AND Pos < @DestinationPos
    )
    UPDATE G
    SET CupNr = cNO.CupNr
    FROM ##Game G
    INNER JOIN cte_NewOrder cNO ON G.Pos = cNO.Pos

    IF @Counter < 100 
    BEGIN
        SET @Circle = ''
        SELECT @Circle = @Circle + '|' + CAST(CupNr AS VARCHAR(3)) FROM ##Game ORDER BY Pos
        SELECT @Pos1 = Pos FROM ##Game WHERE CupNr = 1
        SELECT @Pos2 = CupNr FROM ##Game WHERE Pos = @Pos1 - 1
        PRINT 'Round: ' + CAST(@Counter AS VARCHAR(10)) + ' circle: ' + @Circle + ' with selecte cup: ' + CAST(@CurrentCup AS VARCHAR(3)) + 
              ' and dest cup: ' + CAST(@DestinationCup AS VARCHAR(3)) + ' Pos 1: ' + CAST(@Pos1 AS VARCHAR(3)) + ' Pos 2: ' + CAST(@Pos2 AS VARCHAR(3)) 
    END


    SELECT @CurrentPos = (Pos  + 1) % @NrOfCups FROM ##Game WHERE CupNr = @CurrentCup
    SELECT @CurrentCup = CupNr FROM ##Game WHERE Pos = @CurrentPos

    DELETE FROM @LiftedCups
    
    SET @Counter = @Counter + 1
END

--Round: 99 circle: |1|7|8|5|6|9|2|3|4

--78569234

DROP TABLE ##Game

END

ELSE --DoPart1
BEGIN


CREATE TABLE ##Circle(CupNr INT NOT NULL, NextCupNr INT NOT NULL, PRIMARY KEY (CupNr))

;WITH cte_Cups AS (
    SELECT 0 AS Pos
    ,      LEFT(@Input,1) AS CupNr
    ,      SUBSTRING(@Input, 2, LEN(@Input)) AS LeftOver

    UNION ALL

    SELECT Pos + 1
    ,      LEFT(LeftOver,1) AS CupNr
    ,      CASE WHEN LEN(LeftOver) = 1 THEN '' ELSE SUBSTRING(LeftOver, 2, LEN(LeftOver)) END AS LeftOver
    FROM cte_Cups
    WHERE LEN(LeftOver) > 0

)
INSERT ##Circle(CupNr, NextCupNr)
SELECT CAST(CupNr AS INT), ISNULL(CAST(LEAD(CupNr) OVER (ORDER BY Pos) AS INT), 10)
FROM cte_Cups

DECLARE @FirstCup INT
SELECT @FirstCup = CupNr FROM ##Circle WHERE CupNr NOT IN (SELECT NextCupNr FROM ##Circle)


INSERT ##Circle (CupNr, NextCupNr)
SELECT TOP 999991 ROW_NUMBER() OVER (ORDER BY (SELECT 0)) + 9, ROW_NUMBER() OVER (ORDER BY (SELECT 0)) + 10
FROM sys.messages T1
CROSS APPLY sys.messages T2

--Close the loop
UPDATE ##Circle SET NextCupNr = @FirstCup WHERE NextCupNr = (SELECT MAX(NextCupNr) FROM ##Circle)

PRINT 'Table prepared. Playing "game" at ' + CAST(GETDATE() AS VARCHAR(50))

DECLARE @BigCounter BIGINT = 0
DECLARE @CurCup BIGINT 
DECLARE @DestCup BIGINT
DECLARE @OneOfThree BIGINT
DECLARE @TwoOfThree BIGINT
DECLARE @ThreeOfThree BIGINT
DECLARE @CloseCircleCup BIGINT
DECLARE @CircleSize BIGINT

SET @CurCup = @FirstCup
SELECT @CircleSize = COUNT(1) FROM ##Circle

WHILE @BigCounter < 10000000
BEGIN

    --PRINT 'Counter ' + CAST(@BigCounter AS VARCHAR(20))
    --PRINT 'CurCup ' + CAST(@CurCup AS VARCHAR(20))

    --Step 1
    SELECT @OneOfThree = C1.NextCupNr
    ,      @TwoOfThree = C2.NextCupNr
    ,      @ThreeOfThree = C3.NextCupNr
    ,      @CloseCircleCup = C4.NextCupNr
    FROM ##Circle C1
    INNER JOIN ##Circle C2 ON C1.NextCupNr = C2.CupNr
    INNER JOIN ##Circle C3 ON C2.NextCupNr = C3.CupNr
    INNER JOIN ##Circle C4 ON C3.NextCupNr = C4.CupNr
    WHERE C1.CupNr = @CurCup

    UPDATE ##Circle
    SET NextCupNr = @CloseCircleCup
    WHERE CupNr = @CurCup

    --PRINT '1 Cup ' + CAST(@OneOfThree AS VARCHAR(20))
    --PRINT '2 Cup ' + CAST(@TwoOfThree AS VARCHAR(20))
    --PRINT '3 Cup ' + CAST(@ThreeOfThree AS VARCHAR(20))
    --PRINT '4 Cup ' + CAST(@CloseCircleCup AS VARCHAR(20))

    
    -- Step 2
    SET @DestCup = @CurCup - 1

    WHILE @DestCup < 1 OR @DestCup = @OneOfThree OR @DestCup = @TwoOfThree OR @DestCup = @ThreeOfThree
    BEGIN
        IF @DestCup < 1 SET @DestCup = @DestCup + @CircleSize --We moved outside the range. So loop around
        ELSE SET @DestCup = @DestCup - 1                      --We picked a lifted cup, try one lower
    END

    --PRINT 'DestCup ' + CAST(@DestCup AS VARCHAR(20))

    --Step 3
    SELECT @CloseCircleCup = NextCupNr
    FROM ##Circle
    WHERE CupNr = @DestCup

    UPDATE ##Circle
    SET NextCupNr = @OneOfThree
    WHERE CupNr = @DestCup
    
    UPDATE ##Circle
    SET NextCupNr = @CloseCircleCup
    WHERE CupNr = @ThreeOfThree

    --PRINT 'CloseCircle Cup ' + CAST(@CloseCircleCup AS VARCHAR(20))

    --Step 4
    SELECT @CurCup = NextCupNr
    FROM ##Circle
    WHERE CupNr = @CurCup

    IF @BigCounter % 100000 = 0 PRINT 'Round: ' + CAST(@BigCounter AS VARCHAR(15)) + ' at ' + CAST(GETDATE() AS VARCHAR(50))

    SET @BigCounter = @BigCounter + 1

END

    --SELECT '|' + CAST(C1.CupNr AS CHAR(1))
    --     + '|' + CAST(C2.CupNr AS CHAR(1))
    --     + '|' + CAST(C3.CupNr AS CHAR(1))
    --     + '|' + CAST(C4.CupNr AS CHAR(1))
    --     + '|' + CAST(C5.CupNr AS CHAR(1))
    --     + '|' + CAST(C6.CupNr AS CHAR(1))
    --     + '|' + CAST(C7.CupNr AS CHAR(1))
    --     + '|' + CAST(C8.CupNr AS CHAR(1))
    --     + '|' + CAST(C9.CupNr AS CHAR(1))
    --FROM ##Circle C1
    --INNER JOIN ##Circle C2 ON C1.NextCupNr = C2.CupNr
    --INNER JOIN ##Circle C3 ON C2.NextCupNr = C3.CupNr
    --INNER JOIN ##Circle C4 ON C3.NextCupNr = C4.CupNr
    --INNER JOIN ##Circle C5 ON C4.NextCupNr = C5.CupNr
    --INNER JOIN ##Circle C6 ON C5.NextCupNr = C6.CupNr
    --INNER JOIN ##Circle C7 ON C6.NextCupNr = C7.CupNr
    --INNER JOIN ##Circle C8 ON C7.NextCupNr = C8.CupNr
    --INNER JOIN ##Circle C9 ON C8.NextCupNr = C9.CupNr
    --WHERE C1.CupNr = 1

    SELECT CAST(CupNr AS BIGINT) * NextCupNr
    FROM ##Circle 
    WHERE CupNr = (SELECT NextCupNr FROM ##Circle WHERE CupNr = 1)

END

-- 245295743108 is too low for part 2
-- 565615814504 is correct for part 2




/*



DROP TABLE ##Circle

Step 1: The crab picks up the three cups that are immediately clockwise of the current cup. They are removed from the circle; cup spacing is adjusted as necessary to maintain the circle.
Step 2: The crab selects a destination cup: the cup with a label equal to the current cup's label minus one. If this would select one of the cups that was just picked up, the crab will keep subtracting one until it finds a cup that wasn't just picked up. If at any point in this process the value goes below the lowest value on any cup's label, it wraps around to the highest value on any cup's label instead.
Step 3: The crab places the cups it just picked up so that they are immediately clockwise of the destination cup. They keep the same order as when they were picked up.
Step 4: The crab selects a new current cup: the cup which is immediately clockwise of the current cup.


*/
