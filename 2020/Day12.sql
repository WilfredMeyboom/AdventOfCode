USE Test_WME

SET NOCOUNT ON

CREATE TABLE ##Input (Line NVARCHAR(MAX));

BULK INSERT ##Input
FROM 'C:\Source\AdventOfCode\2020\input12.txt'
WITH (ROWTERMINATOR = '0x0A');

CREATE TABLE ##Instructions (ID INt IDENTITY(1,1), Dir CHAR(1), Val INT)

INSERT ##Instructions (Dir, Val)
SELECT LEFT(Line, 1) AS Dir, SUBSTRING(Line, 2, LEN(Line)) AS Val FROM ##Input

DECLARE @Counter INT = 1
DECLARE @Dir INT = 90 -- 90 = East
DECLARE @X INT = 0
DECLARE @Y INT = 0

DECLARE @DoPart1 INT = 0

IF @DoPart1 = 1
BEGIN 

WHILE @Counter <= (SELECT COUNT(1) FROM ##Instructions) 
BEGIN

    SELECT @X = @X + CASE WHEN Dir IN ('N', 'S', 'L', 'R') THEN 0
                          WHEN Dir = 'W' THEN - Val
                          WHEN Dir = 'E' THEN  Val
                          WHEN Dir = 'F' THEN CASE WHEN @Dir = 270 THEN - Val
                                                   WHEN @Dir = 90 THEN  Val
                                                   ELSE 0 END
                          ELSE -99999
                          END
    ,      @Y = @Y + CASE WHEN Dir IN ('W', 'E', 'L', 'R') THEN 0
                          WHEN Dir = 'N' THEN - Val
                          WHEN Dir = 'S' THEN  Val
                          WHEN Dir = 'F' THEN CASE WHEN @Dir = 0 THEN - Val
                                                   WHEN @Dir = 180 THEN  Val
                                                   ELSE 0 END
                          ELSE -99999
                          END
    ,      @Dir = (@Dir + CASE WHEN Dir IN ('W', 'E', 'N', 'S', 'F') THEN 0
                              WHEN Dir = 'L' THEN - Val
                              WHEN Dir = 'R' THEN  Val
                          ELSE -99999
                          END + 360) % 360
    FROM ##Instructions
    WHERE ID = @Counter

    SET @Counter = @Counter + 1


END

PRINT @Dir
PRINT @X
PRINT @Y

SELECT ABS(@X) + ABS(@Y)

END

--757 is correct for part 1

ELSE

BEGIN 

SET @X = 10
SET @Y = -1
DECLARE @XCur INT
DECLARE @YCur INT

DECLARE @ShipX INT = 0
DECLARE @ShipY INT = 0

WHILE @Counter <= (SELECT COUNT(1) FROM ##Instructions) 
BEGIN

    SET @XCur = @X
    SET @YCur = @Y

    SELECT @X = CASE WHEN Dir IN ('N', 'S', 'F') THEN @XCur
                     WHEN Dir = 'W' THEN @XCur - Val
                     WHEN Dir = 'E' THEN @XCur + Val
                     WHEN Dir = 'R' THEN CASE WHEN Val = 90  THEN - @YCur
                                              WHEN Val = 180 THEN - @XCur
                                              WHEN Val = 270 THEN @YCur
                                              ELSE @XCur END
                     WHEN Dir = 'L' THEN CASE WHEN Val = 90  THEN @YCur
                                              WHEN Val = 180 THEN - @XCur
                                              WHEN Val = 270 THEN - @YCur
                                              ELSE @XCur END
                     ELSE -99999
                          END
    ,      @Y = CASE WHEN Dir IN ('W', 'E', 'F') THEN @YCur
                     WHEN Dir = 'N' THEN @YCur - Val
                     WHEN Dir = 'S' THEN @YCur + Val
                     WHEN Dir = 'R' THEN CASE WHEN Val = 90  THEN @XCur
                                              WHEN Val = 180 THEN - @YCur
                                              WHEN Val = 270 THEN - @XCur
                                              ELSE @XCur END
                     WHEN Dir = 'L' THEN CASE WHEN Val = 90  THEN - @XCur
                                              WHEN Val = 180 THEN - @YCur
                                              WHEN Val = 270 THEN @XCur
                                              ELSE @XCur END
                          ELSE -99999
                          END
    FROM ##Instructions
    WHERE ID = @Counter

    --SET @X = @XCur
    --SET @Y = @YCur

    SELECT @ShipX = @ShipX + Val * @X
    ,      @ShipY = @ShipY + Val * @Y
    FROM ##Instructions
    WHERE ID = @Counter AND Dir = 'F'

    SET @Counter = @Counter + 1


    PRINT @X
    PRINT @Y
    PRINT @ShipX
    PRINT @ShipY
    PRINT ''

END

SELECT ABS(@ShipX) + ABS(@ShipY)

--51249 is correct for part 2

END
/*

DROP TABLE ##Instructions
DROP TABLE ##Input

*/



