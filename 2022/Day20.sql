USE Test_WME

SET NOCOUNT ON

DECLARE @year VARCHAR(4) = '2022'
DECLARE @day VARCHAR(2)  = '20'

EXEC dbo.GetInput @year = @year, @day = @day
EXEC dbo.ParseInput @year = @year, @day = @day 

--SELECT TOP 10 * FROM ##Input
--SELECT TOP 10 * FROM ##InputInts
--SELECT TOP 10 * FROM ##InputNumbered
--SELECT TOP 10 * FROM ##InputGrid
--SELECT TOP 10 * FROM ##InputSplit
--SELECT TOP 10 * FROM ##InputSplitCust
  
DECLARE @ListLength INT

SELECT @ListLength = COUNT(1) FROM ##InputInts

CREATE TABLE ##LinkedList (ID INT IDENTITY(1,1), StartInd INT, PrevInd INT, NextInd INT, Val BIGINT)
CREATE INDEX Ind_LinkedList ON ##LinkedList (StartInd) INCLUDE (NextInd)

INSERT ##LinkedList
(
    StartInd,
    PrevInd,
    NextInd,
    Val
)
-- Change list to start at 0 and include all edges
SELECT (Ind - 1 + @ListLength) % @ListLength AS StartInd
,      (Ind - 2 + @ListLength) % @ListLength AS PrevInd
,      (Ind + @ListLength) % @ListLength AS NextInd
,      Val
FROM ##InputInts


DECLARE @Counter INT = 0
DECLARE @Move INT
DECLARE @MoveCounter INT
DECLARE @PrevInd INT
DECLARE @NextInd INT


WHILE @Counter < @ListLength
BEGIN

    SELECT @Move = CASE WHEN Val >= @ListLength OR VaL <= -@ListLength THEN Val % (@ListLength - 1) ELSE Val END 
    , @PrevInd = LL.PrevInd
    , @NextInd = LL.NextInd FROM ##LinkedList LL WHERE LL.StartInd = @Counter
    IF @Move < 0 SET @Move = @Move + @ListLength - 1 --Always move forward
    
    IF @Move > 0
    BEGIN
        -- Remove item from current position
        UPDATE ##LinkedList SET PrevInd = @PrevInd WHERE PrevInd = @Counter
        UPDATE ##LinkedList SET NextInd = @NextInd WHERE NextInd = @Counter

        SET @MoveCounter = 0

        WHILE @MoveCounter < @Move
        BEGIN

            SELECT @NextInd = NextInd FROM ##LinkedList LL WHERE LL.StartInd = @NextInd
            SET @MoveCounter = @MoveCounter + 1

        END

        SELECT @PrevInd = PrevInd FROM ##LinkedList LL WHERE LL.StartInd = @NextInd

        --Insert item in new location
        UPDATE ##LinkedList SET NextInd = @Counter WHERE StartInd = @PrevInd
        UPDATE ##LinkedList SET PrevInd = @Counter WHERE StartInd = @NextInd
        UPDATE ##LinkedList SET NextInd = @NextInd, PrevInd = @PrevInd WHERE StartInd = @Counter
    END
    
    SET @Counter = @Counter + 1

    IF @Counter%100 = 0 PRINT CAST(@Counter AS VARCHAR(10)) + ' : ' + CAST(GETDATE() AS VARCHAR(100))

END

PRINT 'Shifting done'


DECLARE @Grove1 INT = 1000 --% @ListLength
DECLARE @Grove2 INT = 2000 --% @ListLength
DECLARE @Grove3 INT = 3000 --% @ListLength
DECLARE @Coord1 BIGINT
DECLARE @Coord2 BIGINT
DECLARE @Coord3 BIGINT

SET @MoveCounter = 0
SELECT @NextInd = NextInd FROM ##LinkedList LL WHERE Val = 0 

WHILE @Coord1 IS NULL OR @Coord2 IS NULL OR @Coord3 IS NULL
BEGIN

    SET @MoveCounter = @MoveCounter + 1
    
    IF @MoveCounter = @Grove1 SELECT @Coord1 = Val FROM ##LinkedList LL WHERE LL.StartInd = @NextInd
    IF @MoveCounter = @Grove2 SELECT @Coord2 = Val FROM ##LinkedList LL WHERE LL.StartInd = @NextInd
    IF @MoveCounter = @Grove3 SELECT @Coord3 = Val FROM ##LinkedList LL WHERE LL.StartInd = @NextInd

    SELECT @NextInd = NextInd FROM ##LinkedList LL WHERE LL.StartInd = @NextInd
    

END


PRINT @Grove1
PRINT @Grove2
PRINT @Grove3

PRINT @Coord1
PRINT @Coord2
PRINT @Coord3

SELECT @Coord1 + @Coord2 + @Coord3 AS Part1

-------------------------------------------- End of part 1


DECLARE @DecryptionKey BIGINT = 811589153

TRUNCATE TABLE ##LinkedList

INSERT ##LinkedList
(
    StartInd,
    PrevInd,
    NextInd,
    Val
)
-- Change list to start at 0 and include all edges
SELECT (Ind - 1 + @ListLength) % @ListLength AS StartInd
,      (Ind - 2 + @ListLength) % @ListLength AS PrevInd
,      (Ind + @ListLength) % @ListLength AS NextInd
,      Val * @DecryptionKey
FROM ##InputInts


SET @Counter = 0

WHILE @Counter < @ListLength * 10
BEGIN

    SELECT @Move = CASE WHEN Val >= @ListLength OR VaL <= -@ListLength THEN Val % (@ListLength - 1) ELSE Val END 
    , @PrevInd = LL.PrevInd
    , @NextInd = LL.NextInd FROM ##LinkedList LL WHERE LL.StartInd = @Counter % @ListLength
    IF @Move < 0 SET @Move = @Move + @ListLength - 1 --Always move forward
    
    IF @Move > 0
    BEGIN
        -- Remove item from current position
        UPDATE ##LinkedList SET PrevInd = @PrevInd WHERE PrevInd = @Counter % @ListLength
        UPDATE ##LinkedList SET NextInd = @NextInd WHERE NextInd = @Counter % @ListLength

        SET @MoveCounter = 0

        WHILE @MoveCounter < @Move
        BEGIN

            SELECT @NextInd = NextInd FROM ##LinkedList LL WHERE LL.StartInd = @NextInd
            SET @MoveCounter = @MoveCounter + 1

        END

        SELECT @PrevInd = PrevInd FROM ##LinkedList LL WHERE LL.StartInd = @NextInd

        --Insert item in new location
        UPDATE ##LinkedList SET NextInd = @Counter % @ListLength WHERE StartInd = @PrevInd
        UPDATE ##LinkedList SET PrevInd = @Counter % @ListLength WHERE StartInd = @NextInd
        UPDATE ##LinkedList SET NextInd = @NextInd, PrevInd = @PrevInd WHERE StartInd = @Counter % @ListLength
    END
    
    SET @Counter = @Counter + 1

    IF @Counter%100 = 0 PRINT CAST(@Counter AS VARCHAR(10)) + ' : ' + CAST(GETDATE() AS VARCHAR(100))

END

SET @Coord1 = NULL
SET @Coord2 = NULL
SET @Coord3 = NULL

SET @MoveCounter = 0
SELECT @NextInd = NextInd FROM ##LinkedList LL WHERE Val = 0 

WHILE @Coord1 IS NULL OR @Coord2 IS NULL OR @Coord3 IS NULL
BEGIN

    SET @MoveCounter = @MoveCounter + 1
    
    IF @MoveCounter = @Grove1 SELECT @Coord1 = Val FROM ##LinkedList LL WHERE LL.StartInd = @NextInd
    IF @MoveCounter = @Grove2 SELECT @Coord2 = Val FROM ##LinkedList LL WHERE LL.StartInd = @NextInd
    IF @MoveCounter = @Grove3 SELECT @Coord3 = Val FROM ##LinkedList LL WHERE LL.StartInd = @NextInd

    SELECT @NextInd = NextInd FROM ##LinkedList LL WHERE LL.StartInd = @NextInd
    

END


PRINT @Grove1
PRINT @Grove2
PRINT @Grove3

PRINT @Coord1
PRINT @Coord2
PRINT @Coord3

SELECT @Coord1 + @Coord2 + @Coord3 AS Part2


DROP TABLE ##LinkedList


-- Runtime : ±00:25:00