USE Test_WME

SET NOCOUNT ON

-- Create a table for all possible states
CREATE TABLE ##States (ID INT IDENTITY(1,1), SRGen INT, SRChip INT, PLGen INT, PLChip INT, TMGen INT, TMChip INT, RUGen INT, RUChip INT, CUGen INT, CUChip INT, Lift INT, FloorState BIGINT, Step INT)

-- Populate it with all possible states and summarize the state in the floorstate column
;WITH cte_1To4 AS (
    SELECT TOP(4) ROW_NUMBER() OVER (ORDER BY (SELECT 0)) AS RN FROM sys.messages
)
INSERT ##States (SRGen, SRChip, PLGen, PLChip, TMGen, TMChip, RUGen, RUChip, CUGen, CUChip, Lift, FloorState)
SELECT T1.RN, T2.RN, T3.RN, T4.RN, T5.RN, T6.RN, T7.RN, T8.RN, T9.RN, T10.RN, T11.RN,
    10000000000*T1.RN + 1000000000*T2.RN + 100000000*T3.RN + 10000000*T4.RN + 1000000*T5.RN + 100000*T6.RN + 10000*T7.RN + 1000*T8.RN + 100*T9.RN + 10*T10.RN + T11.RN
FROM cte_1To4 T1
CROSS APPLY cte_1To4 T2
CROSS APPLY cte_1To4 T3
CROSS APPLY cte_1To4 T4
CROSS APPLY cte_1To4 T5
CROSS APPLY cte_1To4 T6
CROSS APPLY cte_1To4 T7
CROSS APPLY cte_1To4 T8
CROSS APPLY cte_1To4 T9
CROSS APPLY cte_1To4 T10
CROSS APPLY cte_1To4 T11

-- Remove all states that have an unprotected chip
DELETE FROM ##States
WHERE SRGen <> SRChip
AND SRChip IN (PLGen, TMGen, RUGen, CUGen)

DELETE FROM ##States
WHERE PLGen <> PLChip
AND PLChip IN (SRGen, TMGen, RUGen, CUGen)

DELETE FROM ##States
WHERE TMGen <> TMChip
AND TMChip IN (PLGen, SRGen, RUGen, CUGen)

DELETE FROM ##States
WHERE RUGen <> RUChip
AND RUChip IN (PLGen, TMGen, SRGen, CUGen)

DELETE FROM ##States
WHERE CUGen <> CUChip
AND CUChip IN (PLGen, TMGen, RUGen, SRGen)

-- And remove all states where the elevator is at a level without chips or generators
DELETE FROM ##States WHERE Lift NOT IN ([SRGen],[SRChip],[PLGen],[PLChip],[TMGen],[TMChip],[RUGen],[RUChip],[CUGen],[CUChip])

-- We'll be looking at floorstates a lot so let's index that
CREATE CLUSTERED INDEX IX_States_FloorState ON ##States(FloorState)
--CREATE NONCLUSTERED INDEX IX_State_Step ON [dbo].[##States] ([Step]) INCLUDE ([FloorState])

-- Define the end point as the start point ;)
UPDATE ##States
SET Step = 0 
WHERE SRGen = 4 AND PLGen = 4 AND TMGen = 4 AND RUGen = 4 AND CUGen = 4 AND SRChip = 4 AND PLChip = 4 AND TMChip = 4 AND RUChip = 4 AND CUChip = 4 AND Lift = 4

--Create a table with all possible moves
CREATE TABLE ##Moves (ID INT IDENTITY(1,1), FloorStateChange BIGINT)
INSERT ##Moves (FloorStateChange) VALUES 
                 -- The elevator moves 1 item
                 (10000000001)
                ,(1000000001)
                ,(100000001)
                ,(10000001)
                ,(1000001)
                ,(100001)
                ,(10001)
                ,(1001)
                ,(101)
                ,(11)
  
                -- The elevator moves 2 items; SRGen fixed
                ,(11000000001)
                ,(10100000001)
                ,(10010000001)
                ,(10001000001)
                ,(10000100001)
                ,(10000010001)
                ,(10000001001)
                ,(10000000101)
                ,(10000000011)
                
                -- The elevator moves 2 items; SRChip fixed
                ,(1100000001)
                ,(1010000001)
                ,(1001000001)
                ,(1000100001)
                ,(1000010001)
                ,(1000001001)
                ,(1000000101)
                ,(1000000011)
  
                -- The elevator moves 2 items; PLGen fixed
                ,(110000001)
                ,(101000001)
                ,(100100001)
                ,(100010001)
                ,(100001001)
                ,(100000101)
                ,(100000011)
  
                -- The elevator moves 2 items; PLChip fixed
                ,(11000001)
                ,(10100001)
                ,(10010001)
                ,(10001001)
                ,(10000101)
                ,(10000011)
  
                -- The elevator moves 2 items; TMGen fixed
                ,(1100001)
                ,(1010001)
                ,(1001001)
                ,(1000101)
                ,(1000011)
  
                -- The elevator moves 2 items; TMChip fixed
                ,(110001)
                ,(101001)
                ,(100101)
                ,(100011)
                
                -- The elevator moves 2 items; RUGen fixed
                ,(11001)
                ,(10101)
                ,(10011)
                
                -- The elevator moves 2 items; RUChip fixed
                ,(1101)
                ,(1011)
  
                -- The elevator moves 2 items; SUGen fixed
                ,(111)
                

-- Also add moves in the other direction
INSERT ##Moves (FloorStateChange) SELECT -1 * FloorStateChange FROM ##Moves

DECLARE @Step INT = 0
DECLARE @Count INT = 1

WHILE @Count > 0
BEGIN

    UPDATE S1
    SET S1.Step = @Step + 1
    FROM ##States S1
    WHERE S1.Step IS NULL
      AND S1.FloorState IN (SELECT FloorState + FloorStateChange FROM ##States CROSS APPLY ##Moves WHERE Step = @Step)

    SET @Count = @@ROWCOUNT

    SET @Step = @Step + 1

    --PRINT CAST(GETDATE() AS VARCHAR(100)) + ' Step: ' + CAST(@Step AS VARCHAR(3))
END

SELECT Step AS Part1 FROM ##States WHERE SRGen = 1 AND SRChip = 1 AND PLGen = 1 AND PLChip = 1 AND TMGen = 2 AND TMChip = 3 AND RUGen = 2 AND RUChip = 2 AND CUGen = 2 AND CUChip = 2 AND Lift = 1


-- Adding two extra chips and two extra generators

;WITH cte_1To4 AS (
    SELECT TOP(4) ROW_NUMBER() OVER (ORDER BY (SELECT 0)) AS RN FROM sys.messages
), cte_NewStates AS (
    SELECT T1.RN AS ELGen, T2.RN AS ELChip, T3.RN AS DIGen, T4.RN AS DIChip
    FROM cte_1To4 T1
    CROSS APPLY cte_1To4 T2
    CROSS APPLY cte_1To4 T3
    CROSS APPLY cte_1To4 T4
)
SELECT 100000000000000 * ElGen + 10000000000000 * ElChip + 1000000000000 * DiGen + 100000000000 * DiChip + FloorState AS FloorState
, ELGen, ELChip, DIGen, DIChip, SRGen, SRChip, PLGen, PLChip, TMGen, TMChip, RUGen, RUChip, CUGen, CUChip, Lift
, NULL AS Step --CASE WHEN ELGen = 4 AND ELChip = 4 AND DIGen = 4 AND DIChip = 4 THEN Step ELSE NULL END AS Step -- We'll recalculate all steps
INTO ##AllStates
FROM cte_NewStates
CROSS APPLY ##States
WHERE Step IS NOT NULL -- Leave out unreachable states
-- And leave out states where a chip is unprotected
AND (ELChip = ELGen OR ELChip NOT IN (DIGen, SRGen, PLGen, TMGen, RUGen, CUGen))
AND (DIChip = DIGen OR DIChip NOT IN (ELGen, SRGen, PLGen, TMGen, RUGen, CUGen))
AND (SRChip = SRGen OR SRChip NOT IN (DIGen, ELGen, PLGen, TMGen, RUGen, CUGen))
AND (PLChip = PLGen OR PLChip NOT IN (DIGen, SRGen, ELGen, TMGen, RUGen, CUGen))
AND (TMChip = TMGen OR TMChip NOT IN (DIGen, SRGen, PLGen, ELGen, RUGen, CUGen))
AND (RUChip = RUGen OR RUChip NOT IN (DIGen, SRGen, PLGen, TMGen, ELGen, CUGen))
AND (CUChip = CUGen OR CUChip NOT IN (DIGen, SRGen, PLGen, TMGen, RUGen, ELGen))


-- We'll still be looking at floorstates a lot so let's index that
CREATE CLUSTERED INDEX IX_AllStates_FloorState ON ##AllStates(FloorState)

-- Expand the moves table
INSERT ##Moves (FloorStateChange) VALUES 
                 -- The elevator moves 1 (new) item
                 (100000000000001)
                ,(10000000000001)
                ,(1000000000001)
                ,(100000000001)

                -- The elevator moves 2 items; ELGen fixed
                ,(110000000000001)
                ,(101000000000001)
                ,(100100000000001)
                ,(100010000000001)
                ,(100001000000001)
                ,(100000100000001)
                ,(100000010000001)
                ,(100000001000001)
                ,(100000000100001)
                ,(100000000010001)
                ,(100000000001001)
                ,(100000000000101)
                ,(100000000000011)

                -- The elevator moves 2 items; ELChip fixed
                ,(11000000000001)
                ,(10100000000001)
                ,(10010000000001)
                ,(10001000000001)
                ,(10000100000001)
                ,(10000010000001)
                ,(10000001000001)
                ,(10000000100001)
                ,(10000000010001)
                ,(10000000001001)
                ,(10000000000101)
                ,(10000000000011)

                -- The elevator moves 2 items; DIGen fixed
                ,(1100000000001)
                ,(1010000000001)
                ,(1001000000001)
                ,(1000100000001)
                ,(1000010000001)
                ,(1000001000001)
                ,(1000000100001)
                ,(1000000010001)
                ,(1000000001001)
                ,(1000000000101)
                ,(1000000000011)

                -- The elevator moves 2 items; DIChip fixed
                ,(110000000001)
                ,(101000000001)
                ,(100100000001)
                ,(100010000001)
                ,(100001000001)
                ,(100000100001)
                ,(100000010001)
                ,(100000001001)
                ,(100000000101)
                ,(100000000011)


INSERT ##Moves (FloorStateChange) SELECT -1 * FloorStateChange FROM ##Moves WHERE -1 * FloorStateChange NOT IN (SELECT FloorStateChange FROM ##Moves)

-- Define the end point as the start point ;)
UPDATE ##AllStates
SET Step = 0 
WHERE DIGen = 4 AND DIChip = 4 AND ELGen = 4 AND ELChip = 4 AND SRGen = 4 AND PLGen = 4 AND TMGen = 4 AND RUGen = 4 AND CUGen = 4 AND SRChip = 4 AND PLChip = 4 AND TMChip = 4 AND RUChip = 4 AND CUChip = 4 AND Lift = 4

--DECLARE @Count INT, @Step INT

SET @Count = 1
SET @Step = 0

WHILE @Count > 0
BEGIN

    UPDATE S1
    SET S1.Step = @Step + 1
    FROM ##AllStates S1
    WHERE S1.Step IS NULL
      AND S1.FloorState IN (SELECT FloorState + FloorStateChange FROM ##AllStates CROSS APPLY ##Moves WHERE Step = @Step)

    SET @Count = @@ROWCOUNT

    SET @Step = @Step + 1

    PRINT CAST(GETDATE() AS VARCHAR(100)) + ' Step: ' + CAST(@Step AS VARCHAR(3))
END

SELECT MIN(Step) AS Part1 FROM ##AllStates WHERE SRGen = 1 AND SRChip = 1 AND PLGen = 1 AND PLChip = 1 AND TMGen = 2 AND TMChip = 3 AND RUGen = 2 AND RUChip = 2 AND CUGen = 2 AND CUChip = 2 AND Lift = 1
SELECT Step AS Part2 FROM ##AllStates WHERE DIGen = 1 AND DIChip = 1 AND ELGen = 1 AND ELChip = 1 AND SRGen = 1 AND SRChip = 1 AND PLGen = 1 AND PLChip = 1 AND TMGen = 2 AND TMChip = 3 AND RUGen = 2 AND RUChip = 2 AND CUGen = 2 AND CUChip = 2 AND Lift = 1


-- Part 1: 37
-- Part 2: 61

/*

--Runtime about 30 minutes when running it seperate sequential parts

DROP TABLE ##States
DROP TABLE ##AllStates
DROP TABLE ##Moves

*/

