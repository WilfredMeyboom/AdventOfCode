DECLARE @Input INT = 29000000
--29.000.000

SET NOCOUNT ON

--Assumption: the number we're looking for is below 1 million

SELECT TOP 1000000 ROW_Number() OVER (ORDER BY (SELECT 0)) AS Rn, 0 AS Part1, 0 AS Part2
INTO ##Nrs
FROM sys.messages T1
CROSS APPLY sys.messages T2

DECLARE @Counter INT = 2

--And we assume the first 10 elves will all visit this number (i.e. the number is divisable by 2 through 10)
WHILE @Counter <= 10
BEGIN
    DELETE FROM ##Nrs WHERE Rn % @Counter <> 0

    SET @Counter = @Counter + 1
END


-- Just 396 numbers left. We can calculate the number of presents they'll be getting
--SELECT * FROM ##Nrs ORDER BY 1

DECLARE @Number INT
DECLARE @NrOfPresents INT
DECLARE @NrOfPresents2 INT
DECLARE @HalfWayPoint INT
DECLARE NumberCursor CURSOR FOR SELECT Rn FROM ##Nrs

OPEN NumberCursor

FETCH NEXT FROM NumberCursor INTO @Number

WHILE @@FETCH_STATUS = 0
BEGIN
    
    SET @Counter = 1
    SET @NrOfPresents = 0
    SET @NrOfPresents2 = 0
    SET @HalfWayPoint = FLOOR(SQRT(@Number))

    WHILE @Counter < @HalfWayPoint
    BEGIN

        IF @Number % @Counter = 0
        BEGIN
            --Part 1
            SET @NrOfPresents = @NrOfPresents + @Counter * 10
            SET @NrOfPresents = @NrOfPresents + (@Number / @Counter) * 10

            --Part 2
            IF @Counter * 50 >= @Number SET @NrOfPresents2 = @NrOfPresents2 + @Counter * 11
            IF (@Number / @Counter) * 50 >= @Number SET @NrOfPresents2 = @NrOfPresents2 + (@Number / @Counter) * 11
        END

        SET @Counter = @Counter + 1

    END

    UPDATE ##Nrs 
    SET Part1 = @NrOfPresents 
    ,   Part2 = @NrOfPresents2
    WHERE Rn = @Number

    FETCH NEXT FROM NumberCursor INTO @Number

END

CLOSE NumberCursor
DEALLOCATE NumberCursor

SELECT TOP 1 Rn As Part1 FROM ##Nrs WHERE Part1 > @Input ORDER BY Rn
SELECT TOP 1 Rn As Part2 FROM ##Nrs WHERE Part2 > @Input ORDER BY Rn

DROP TABLE ##Nrs