USE Test_WME

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

DECLARE @Results TABLE (PairNr INT, Result INT)

SELECT @NrOfLists = COUNT(1) / 2 FROM ##InputNumbered WHERE Line IS NOT NULL

WHILE @Counter < @NrOfLists
BEGIN

    SELECT @Line1 = Line FROM ##InputNumbered WHERE Ind = @Counter*3 + 1
    SELECT @Line1 = Line FROM ##InputNumbered WHERE Ind = @Counter*3 + 2

    INSERT @Results
    (
        PairNr,
        Result
    )
    SELECT @Counter + 1, dbo.AoCCompare(SUBSTRING(@Line1,2,LEN(@Line1-2))
                                      , SUBSTRING(@Line2,2,LEN(@Line2-2)))

    SET @Counter = @Counter + 1
END

SELECT * FROM @Results R

GO

CREATE OR ALTER FUNCTION AoCCompare (@Line1 VARCHAR(MAX), @Line2 VARCHAR(MAX)) RETURNS INT
BEGIN
--    INSERT Test VALUES ('Test')
    DECLARE @InOrder INT = NULL

    DECLARE @Part1 VARCHAR(50)
    DECLARE @Part2 VARCHAR(50)

    DECLARE @Backup INT = 0

    WHILE @Inorder IS NULL
    BEGIN
       
       SET @Part1 = SUBSTRING(@Line1, 1, CHARINDEX(',',@Line1)) 
       SET @Part2 = SUBSTRING(@Line2, 1, CHARINDEX(',',@Line2)) 

       IF TRY_CAST(@Part1 AS INT) IS NOT NULL AND TRY_CAST(@Part2 AS INT) IS NOT NULL
       BEGIN
            
            IF CAST(@Part1 AS INT) < CAST(@Part2 AS INT) SET @InOrder = 1
            IF CAST(@Part1 AS INT) > CAST(@Part2 AS INT) SET @InOrder = 0

            SET @Line1 = SUBSTRING(@Line1, CHARINDEX(',',@Line1)+ 1, LEN(@Line1))
            SET @Line2 = SUBSTRING(@Line2, CHARINDEX(',',@Line2)+ 1, LEN(@Line2))
       END
       ELSE
       BEGIN
            IF LEN(@Line1) = 0 OR LEN(@Line2) = 0
            BEGIN
                IF LEN(@Line1) = 0 SET @InOrder = 1 
                IF LEN(@Line2) = 0 SET @InOrder = 2

            END



       END

       SET @Backup = @Backup + 1
       IF @Backup = 100 SET @InOrder = 2

    END
    

    
    RETURN @InOrder
END


