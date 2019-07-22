SET NOCOUNT ON

--405 players; last marble is worth 70953 points

DECLARE @NrOfPlayers BIGINT = 405
DECLARE @NrOfMarbles BIGINT = 7095300

CREATE TABLE #Circle (ID BIGINT IDENTITY(1,1) PRIMARY KEY, PrevID BIGINT NOT NULL, NextID BIGINT NOT NULL, MarbleValue BIGINT)

INSERT #Circle (PrevID, NextID, MarbleValue) VALUES (0, 0, 0)
DECLARE @CurrentID BIGINT = @@IDENTITY
UPDATE #Circle SET PrevID = @@IDENTITY, NextID = @@IDENTITY 


DECLARE @MarbleNr BIGINT = 1
DECLARE @PlayerNr BIGINT = 1
DECLARE @NextID BIGINT = 0
DECLARE @PrevID BIGINT = 0
DECLARE @StepBack BIGINT = 1

CREATE TABLE #Scores (ID BIGINT IDENTITY(1,1), PlayerID BIGINT, MarbleValue BIGINT)

WHILE (@MarbleNr < @NrOfMarbles)
BEGIN
    
    WHILE (@MarbleNr % 23 <> 0 AND @MarbleNr <= @NrOfMarbles)
    BEGIN
        SELECT @PrevID = NextID FROM #Circle WHERE ID = @CurrentID
        SELECT @NextID = NextID FROM #Circle WHERE ID = @PrevID

        INSERT #Circle (PrevID, NextID, MarbleValue) VALUES (@PrevID, @NextID, @MarbleNr)
        SET @CurrentID = @@IDENTITY
        
        UPDATE #Circle
        SET NextID = @CurrentID
        WHERE ID = @PrevID

        UPDATE #Circle
        SET PrevID = @CurrentID
        WHERE ID = @NextID

        SET @MarbleNr = @MarbleNr + 1
        SET @PlayerNr = (@PlayerNr + 1) % @NrOfPlayers

--        SELECT * FROM #Circle

    END

    SET @StepBack = 1

    --PRINT @MarbleNr
    --PRINT @PlayerNr


    WHILE (@StepBack <= 7)
    BEGIN
    
        SELECT @CurrentID = PrevID
        FROM #Circle
        WHERE ID = @CurrentID

        SET @StepBack = @StepBack + 1
    END

    SELECT @PrevID = PrevID, @NextID = NextID
    FROM #Circle
    WHERE ID = @CurrentID

    IF (@MarbleNr < @NrOfMarbles)
    BEGIN
        
        INSERT #Scores (PlayerID, MarbleValue) VALUES (@PlayerNr, @MarbleNr)
        INSERT #Scores (PlayerID, MarbleValue) SELECT @PlayerNr, MarbleValue FROM #Circle WHERE ID = @CurrentID

        DELETE #Circle WHERE ID = @CurrentID

        UPDATE #Circle
        SET NextID = @NextID
        WHERE ID = @PrevID

        UPDATE #Circle
        SET PrevID = @PrevID
        WHERE ID = @NextID

        SET @MarbleNr = @MarbleNr + 1
        SET @PlayerNr = (@PlayerNr + 1) % @NrOfPlayers
        SET @CurrentID = @NextID
    END
END

--SELECT * FROM #Circle 
--SELECT * FROM #Scores

SELECT PlayerID, SUM(MarbleValue) FROM #Scores GROUP BY PlayerID ORDER BY 2 DESC
--337073 Too low
--428980 Too high


/*

DROP TABLE #Circle
DROP TABLE #Scores

*/