SET NOCOUNT ON

/*
The first floor contains a strontium generator, a strontium-compatible microchip, a plutonium generator, and a plutonium-compatible microchip.
The second floor contains a thulium generator, a ruthenium generator, a ruthenium-compatible microchip, a curium generator, and a curium-compatible microchip.
The third floor contains a thulium-compatible microchip.
The fourth floor contains nothing relevant.
*/

/*
CREATE TABLE ##Items (ID INT IDENTITY(1,1), Step INT, Attempt INT, PreviousAttempt INT, Item VARCHAR(10), Position INT, IsValid BIT, ElevatorPos INT)
CREATE TABLE ##ItemsToBe (ID INT IDENTITY(1,1), Step INT, Attempt INT, PreviousAttempt INT, Item VARCHAR(10), Position INT, IsValid BIT, ElevatorPos INT)

INSERT ##Items (Step, Attempt, Item, Position, IsValid, ElevatorPos) VALUES (0, 0, 'Sr-Gen', 1, 1, 1)
INSERT ##Items (Step, Attempt, Item, Position, IsValid, ElevatorPos) VALUES (0, 0, 'Sr-Chp', 1, 1, 1)
INSERT ##Items (Step, Attempt, Item, Position, IsValid, ElevatorPos) VALUES (0, 0, 'Th-Gen', 2, 1, 1)
INSERT ##Items (Step, Attempt, Item, Position, IsValid, ElevatorPos) VALUES (0, 0, 'Th-Chp', 3, 1, 1)
INSERT ##Items (Step, Attempt, Item, Position, IsValid, ElevatorPos) VALUES (0, 0, 'Pl-Gen', 1, 1, 1)
INSERT ##Items (Step, Attempt, Item, Position, IsValid, ElevatorPos) VALUES (0, 0, 'Pl-Chp', 1, 1, 1)
INSERT ##Items (Step, Attempt, Item, Position, IsValid, ElevatorPos) VALUES (0, 0, 'Ru-Gen', 2, 1, 1)
INSERT ##Items (Step, Attempt, Item, Position, IsValid, ElevatorPos) VALUES (0, 0, 'Ru-Chp', 2, 1, 1)
INSERT ##Items (Step, Attempt, Item, Position, IsValid, ElevatorPos) VALUES (0, 0, 'Cm-Gen', 2, 1, 1)
INSERT ##Items (Step, Attempt, Item, Position, IsValid, ElevatorPos) VALUES (0, 0, 'Cm-Chp', 2, 1, 1)


--TRUNCATE TABLE ##Items

--INSERT ##Items (Step, Attempt, Item, Position, IsValid, ElevatorPos) VALUES (0, 0, 'Li-Gen', 3, 1, 1)
--INSERT ##Items (Step, Attempt, Item, Position, IsValid, ElevatorPos) VALUES (0, 0, 'Li-Chp', 1, 1, 1)
--INSERT ##Items (Step, Attempt, Item, Position, IsValid, ElevatorPos) VALUES (0, 0, 'He-Gen', 2, 1, 1)
--INSERT ##Items (Step, Attempt, Item, Position, IsValid, ElevatorPos) VALUES (0, 0, 'He-Chp', 1, 1, 1)


--SELECT * FROM ##Items


/*
In Psuedo

Loop
    Pak alle valid step-attempt combi's
    Kijk welke mogelijkheden er zijn (voor het verplaatsen van 1 of 2 items
    Loop over alle nieuwe combinaties
        Zijn deze valide?
        Bestaat al met een lagere step?
    Kijk of een tak doodloopt
    Kijk of alles op 4 ligt
*/

DECLARE @AllOnFour BIT = 0

DECLARE @Step INT
DECLARE @Attempt INT
DECLARE @Item VARCHAR(10)
DECLARE @Item2 VARCHAR(10)
DECLARE @CurrentAttempt INT = 0
DECLARE @Counter INT = 0
DECLARE @Target INT

SELECT @Target = COUNT(1) FROM ##Items

WHILE @AllOnFour = 0 AND @Counter < 500
BEGIN

    SET @Counter = @Counter + 1

    DELETE FROM ##ItemsToBe
--    SET @CurrentAttempt = 0

    --Move 1 item 1 step (up or down)
    DECLARE SingleTransport CURSOR FAST_FORWARD FOR SELECT Step, Attempt, Item FROM ##Items WHERE IsValid = 1 AND Position = ElevatorPos
    OPEN SingleTransport
    FETCH NEXT FROM SingleTransport INTO @Step, @Attempt, @Item

    WHILE @@FETCH_STATUS = 0
    BEGIN

        SET @CurrentAttempt = @CurrentAttempt + 1

        --Move 1 item 1 step up
        INSERT ##ItemsToBe (Step, Attempt, PreviousAttempt, Item, Position, IsValid, ElevatorPos)
        SELECT Step + 1
        ,      @CurrentAttempt
        ,      Attempt
        ,      Item
        ,      CASE WHEN Item = @Item THEN Position + 1 ELSE Position END
        ,      IsValid = 1
        ,      ElevatorPos + 1
        FROM ##Items
        WHERE Step = @Step AND Attempt = @Attempt

        SET @CurrentAttempt = @CurrentAttempt + 1

        --Move 1 item 1 step down
        INSERT ##ItemsToBe (Step, Attempt, PreviousAttempt, Item, Position, IsValid, ElevatorPos)
        SELECT Step + 1
        ,      @CurrentAttempt
        ,      Attempt
        ,      Item
        ,      CASE WHEN Item = @Item THEN Position - 1 ELSE Position END
        ,      IsValid = 1
        ,      ElevatorPos - 1
        FROM ##Items
        WHERE Step = @Step AND Attempt = @Attempt

        FETCH NEXT FROM SingleTransport INTO @Step, @Attempt, @Item

    END

    CLOSE SingleTransport
    DEALLOCATE SingleTransport


    -- Move 2 items one step (up or down)
    DECLARE DoubleTransport CURSOR FAST_FORWARD FOR SELECT I1.Step, I1.Attempt, I1.Item, I2.Item
                                                    FROM ##Items I1
                                                    INNER JOIN ##Items I2 ON I1.Step = I2.Step AND I1.Attempt = I2.Attempt AND I1.Position = I2.Position AND I1.Item < I2.Item
                                                    WHERE I1.IsValid = 1 AND I1.Position = I1.ElevatorPos
    OPEN DoubleTransport
    FETCH NEXT FROM DoubleTransport INTO @Step, @Attempt, @Item, @Item2

    WHILE @@FETCH_STATUS = 0
    BEGIN

        SET @CurrentAttempt = @CurrentAttempt + 1

        --Move 1 item 1 step up
        INSERT ##ItemsToBe (Step, Attempt, PreviousAttempt, Item, Position, IsValid, ElevatorPos)
        SELECT Step + 1
        ,      @CurrentAttempt
        ,      Attempt
        ,      Item
        ,      CASE WHEN Item = @Item OR Item = @Item2 THEN Position + 1 ELSE Position END
        ,      IsValid = 1
        ,      ElevatorPos + 1
        FROM ##Items
        WHERE Step = @Step AND Attempt = @Attempt

        SET @CurrentAttempt = @CurrentAttempt + 1

        --Move 1 item 1 step down
        INSERT ##ItemsToBe (Step, Attempt, PreviousAttempt, Item, Position, IsValid, ElevatorPos)
        SELECT Step + 1
        ,      @CurrentAttempt
        ,      Attempt
        ,      Item
        ,      CASE WHEN Item = @Item OR Item = @Item2  THEN Position - 1 ELSE Position END
        ,      IsValid = 1
        ,      ElevatorPos - 1
        FROM ##Items
        WHERE Step = @Step AND Attempt = @Attempt

        FETCH NEXT FROM DoubleTransport INTO @Step, @Attempt, @Item, @Item2

    END

    CLOSE DoubleTransport
    DEALLOCATE DoubleTransport


    -- Did we move something outside the building? ;)
    ;WITH cte_Invalid AS (
        SELECT DISTINCT Step, Attempt
        FROM ##ItemsToBe
        WHERE Position NOT BETWEEN 1 AND 4
    )
    DELETE ITB
    FROM ##ItemsToBe ITB
    INNER JOIN cte_Invalid cI ON cI.Step = ITB.Step AND cI.Attempt = ITB.Attempt

    -- Do we have radiated unprotected chips?
    ;WITH cte_Invalid AS (
        SELECT ITB_Gen.Step, ITB_Gen.Attempt
        FROM ##ItemsToBe ITB_Gen
        INNER JOIN ##ItemsToBe ITB_Chp ON ITB_Gen.Step = ITB_Chp.Step
                                      AND ITB_Gen.Attempt = ITB_Chp.Attempt
                                      AND ITB_Gen.Position = ITB_Chp.Position
                                      AND RIGHT(ITB_Chp.Item, 3) = 'Chp'
                                      AND LEFT(ITB_Gen.Item, 2) <> LEFT(ITB_Chp.Item, 2)
        LEFT JOIN ##ItemsToBe ITB_GC ON ITB_Gen.Step = ITB_GC.Step
                                    AND ITB_Gen.Attempt = ITB_GC.Attempt
                                    AND ITB_Gen.Position = ITB_GC.Position
                                    AND RIGHT(ITB_GC.Item, 3) = 'Gen'
                                    AND LEFT(ITB_GC.Item, 2) = LEFT(ITB_Chp.Item, 2)
        WHERE RIGHT(ITB_Gen.Item, 3) = 'Gen'
        AND ITB_GC.ID IS NULL
    )
    DELETE ITB
    FROM ##ItemsToBe ITB
    INNER JOIN cte_Invalid cI ON cI.Step = ITB.Step AND cI.Attempt = ITB.Attempt

    -- Have we already seen this exact situation?
    ;WITH cte_Duplicate AS (
        SELECT DISTINCT ITB.Step, ITB.Attempt
        FROM ##ItemsToBe ITB
        INNER JOIN ##Items I ON ITB.ElevatorPos = I.ElevatorPos
                            AND ITB.Item = I.Item
                            AND ITB.Position = I.Position
        GROUP BY I.Step, I.Attempt, ITB.Step, ITB.Attempt
        HAVING COUNT(1) % @Target = 0
    )
    DELETE ITB
    FROM ##ItemsToBe ITB
    INNER JOIN cte_Duplicate cD ON ITB.Step = cD.Step AND ITB.Attempt = cD.Attempt


    UPDATE ##Items SET IsValid = 0

    INSERT ##Items (Step, Attempt, PreviousAttempt, Item, Position, IsValid, ElevatorPos) SELECT Step, Attempt, PreviousAttempt, Item, Position, IsValid, ElevatorPos FROM ##ItemsToBe

    IF (SELECT TOP(1) COUNT(1) FROM ##Items WHERE Position = 4 GROUP BY Step, Attempt ORDER BY 1 DESC) = @Target SET @AllOnFour = 1

    IF (@Counter % 50) = 0 SELECT * FROM ##Items

    PRINT 'Step ' + CAST(@Counter AS VARCHAR(10)) + ' at ' + CAST(GETDATE() AS VARCHAR(50))

END

PRINT @Counter

/*
--DROP TABLE ##Building
DROP TABLE ##Items
DROP TABLE ##ItemsToBe
*/


/*
SELECT * 
FROM ##Items I1
INNER JOIN ##Items I2 ON I1.Step = I2.Step -1 AND I1.Attempt = I2.PreviousAttempt AND I1.Item = I2.Item
WHERE I1.Step = 2

SELECT * 
FROM ##Items I1
INNER JOIN ##Items I2 ON I1.Step = I2.Step -1 AND I1.Attempt = I2.PreviousAttempt AND I1.Item = I2.Item
WHERE I1.Step = 3 AND I1.PreviousAttempt = 4


SELECT Step, COUNT(1) FROM ##Items GROUP BY Step ORDER BY Step

SELECT * FROM ##Items WHERE Attempt = 7
SELECT * FROM ##Items WHERE Attempt = 13
SELECT * FROM ##Items WHERE PreviousAttempt = 13

--INSERT ##ItemsToBe (Step, Attempt, PreviousAttempt, Item, Position, ElevatorPos)
--SELECT Step, Attempt, PreviousAttempt, Item, Position, ElevatorPos FROM ##Items WHERE Attempt = 32

--DELETE FROM ##ItemsToBe

SELECT * FROM ##ItemsToBe WHERE PreviousAttempt = 13

        SELECT DISTINCT ITB.Step, ITB.Attempt
        FROM ##ItemsToBe ITB
        INNER JOIN ##Items I ON ITB.ElevatorPos = I.ElevatorPos
                            AND ITB.Item = I.Item
                            AND ITB.Position = I.Position
                            AND ITB.Attempt > I.Attempt
WHERE ITB.Attempt = 32
        GROUP BY I.Step, I.Attempt, ITB.Step, ITB.Attempt
        HAVING COUNT(1) = @Target


*/


SELECT * FROM ##ItemsToBe
SELECT * FROM ##Items
*/


/*
Een alternatieve methode zou zijn om alle mogelijke situaties te plotten (dit zijn er 4.194.304).
Deze vervolgens te filteren op alles wat legaal is
En vervolgens het minimale aantal stappen tot elke situatie te bepalen 
Je kan dan per situatie een code bepalen zodat je makkelijker kan vergelijken


*/




CREATE TABLE ##Building (ID BIGINT IDENTITY(1,1), Step INT, SR_Gen INT, SR_Chip INT, PL_Gen INT, PL_Chip INT, TM_Gen INT, TM_Chip INT, RU_Gen INT, RU_Chip INT, CM_Gen INT, CM_Chip INT, Elevator INT, Code BIGINT)


;WITH cte_Floors AS (
SELECT 1 AS Floor UNION SELECT 2 UNION SELECT 3 UNION SELECT 4
)
INSERT ##Building (SR_Gen, SR_Chip, PL_Gen, PL_Chip, TM_Gen, TM_Chip, RU_Gen, RU_Chip, CM_Gen, CM_Chip, Elevator)
SELECT T1.Floor, T2.Floor, T3.Floor, T4.Floor, T5.Floor, T6.Floor, T7.Floor, T8.Floor, T9.Floor, T10.Floor, T11.Floor
FROM cte_Floors T1
CROSS APPLY cte_Floors T2
CROSS APPLY cte_Floors T3
CROSS APPLY cte_Floors T4
CROSS APPLY cte_Floors T5
CROSS APPLY cte_Floors T6
CROSS APPLY cte_Floors T7
CROSS APPLY cte_Floors T8
CROSS APPLY cte_Floors T9
CROSS APPLY cte_Floors T10
CROSS APPLY cte_Floors T11

UPDATE ##Building SET Code = CAST(SR_Gen AS BIGINT)* 10000000000 + CAST(SR_Chip AS BIGINT)* 1000000000 + CAST(PL_Gen AS BIGINT) * 100000000 + CAST(PL_Chip AS BIGINT) * 10000000 + TM_Gen * 1000000 + TM_Chip * 100000 + RU_Gen * 10000 + RU_Chip * 1000 + CM_Gen * 100 + CM_Chip * 10 +  Elevator 

PRINT '##Building filled'

--SELECT TOP 100 * FROM ##Building

CREATE INDEX UQ_Building_Code ON ##Building (Code)

UPDATE ##Building SET Step = 0 WHERE Code = 11112322221

--SELECT COUNT(1) FROM ##Building

--Remove all invalid records (where we have an unprotected chip)
DELETE
FROM ##Building
WHERE SR_Chip <> SR_Gen AND (SR_Chip = PL_Gen OR SR_Chip = TM_Gen OR SR_Chip = RU_Gen OR SR_Chip = CM_Gen)

DELETE
FROM ##Building
WHERE PL_Chip <> PL_Gen AND (PL_Chip = SR_Gen OR PL_Chip = TM_Gen OR PL_Chip = RU_Gen OR PL_Chip = CM_Gen)

DELETE
FROM ##Building
WHERE TM_Chip <> TM_Gen AND (TM_Chip = PL_Gen OR TM_Chip = SR_Gen OR TM_Chip = RU_Gen OR TM_Chip = CM_Gen)

DELETE
FROM ##Building
WHERE RU_Chip <> RU_Gen AND (RU_Chip = PL_Gen OR RU_Chip = TM_Gen OR RU_Chip = SR_Gen OR RU_Chip = CM_Gen)

DELETE
FROM ##Building
WHERE CM_Chip <> CM_Gen AND (CM_Chip = PL_Gen OR CM_Chip = TM_Gen OR CM_Chip = RU_Gen OR CM_Chip = SR_Gen)



--Remove all impossible records (where the elevator is at a floor where there are no components)

DELETE
FROM ##Building
WHERE Elevator <> SR_Gen
  AND Elevator <> SR_Chip
  AND Elevator <> PL_Gen
  AND Elevator <> PL_Chip
  AND Elevator <> TM_Gen
  AND Elevator <> TM_Chip
  AND Elevator <> RU_Gen
  AND Elevator <> RU_Chip
  AND Elevator <> CM_Gen
  AND Elevator <> CM_Chip

PRINT '##Building illegal removed'

DECLARE @TargetID INT
SELECT @TargetID = ID FROM ##Building WHERE Code = 44444444444
--SELECT * FROM ##Building WHERE ID = @TargetID

DECLARE @Step INT = 0

CREATE TABLE ##StepCodes (Code BIGINT)
CREATE TABLE ##PossibleStepCodes (Code BIGINT)

WHILE (SELECT Step FROM ##Building WHERE ID = @TargetID) IS NULL
BEGIN

    DELETE FROM ##StepCodes
    DELETE FROM ##PossibleStepCodes

    INSERT ##StepCodes
    SELECT Code FROM ##Building WHERE Step = @Step

    SET @Step = @Step + 1

    --Single transportations
    INSERT ##PossibleStepCodes SELECT Code + 10000000001 FROM ##StepCodes WHERE SUBSTRING(CAST(Code AS VARCHAR(15)),1,1) = RIGHT(Code, 1) AND RIGHT(Code, 1) < 4
    INSERT ##PossibleStepCodes SELECT Code - 10000000001 FROM ##StepCodes WHERE SUBSTRING(CAST(Code AS VARCHAR(15)),1,1) = RIGHT(Code, 1) AND RIGHT(Code, 1) > 1

    INSERT ##PossibleStepCodes SELECT Code + 1000000001 FROM ##StepCodes WHERE SUBSTRING(CAST(Code AS VARCHAR(15)),2,1) = RIGHT(Code, 1) AND RIGHT(Code, 1) < 4
    INSERT ##PossibleStepCodes SELECT Code - 1000000001 FROM ##StepCodes WHERE SUBSTRING(CAST(Code AS VARCHAR(15)),2,1) = RIGHT(Code, 1) AND RIGHT(Code, 1) > 1

    INSERT ##PossibleStepCodes SELECT Code + 100000001 FROM ##StepCodes WHERE SUBSTRING(CAST(Code AS VARCHAR(15)),3,1) = RIGHT(Code, 1) AND RIGHT(Code, 1) < 4
    INSERT ##PossibleStepCodes SELECT Code - 100000001 FROM ##StepCodes WHERE SUBSTRING(CAST(Code AS VARCHAR(15)),3,1) = RIGHT(Code, 1) AND RIGHT(Code, 1) > 1

    INSERT ##PossibleStepCodes SELECT Code + 10000001 FROM ##StepCodes WHERE SUBSTRING(CAST(Code AS VARCHAR(15)),4,1) = RIGHT(Code, 1) AND RIGHT(Code, 1) < 4
    INSERT ##PossibleStepCodes SELECT Code - 10000001 FROM ##StepCodes WHERE SUBSTRING(CAST(Code AS VARCHAR(15)),4,1) = RIGHT(Code, 1) AND RIGHT(Code, 1) > 1

    INSERT ##PossibleStepCodes SELECT Code + 1000001 FROM ##StepCodes WHERE SUBSTRING(CAST(Code AS VARCHAR(15)),5,1) = RIGHT(Code, 1) AND RIGHT(Code, 1) < 4
    INSERT ##PossibleStepCodes SELECT Code - 1000001 FROM ##StepCodes WHERE SUBSTRING(CAST(Code AS VARCHAR(15)),5,1) = RIGHT(Code, 1) AND RIGHT(Code, 1) > 1

    INSERT ##PossibleStepCodes SELECT Code + 100001 FROM ##StepCodes WHERE SUBSTRING(CAST(Code AS VARCHAR(15)),6,1) = RIGHT(Code, 1) AND RIGHT(Code, 1) < 4
    INSERT ##PossibleStepCodes SELECT Code - 100001 FROM ##StepCodes WHERE SUBSTRING(CAST(Code AS VARCHAR(15)),6,1) = RIGHT(Code, 1) AND RIGHT(Code, 1) > 1

    INSERT ##PossibleStepCodes SELECT Code + 10001 FROM ##StepCodes WHERE SUBSTRING(CAST(Code AS VARCHAR(15)),7,1) = RIGHT(Code, 1) AND RIGHT(Code, 1) < 4
    INSERT ##PossibleStepCodes SELECT Code - 10001 FROM ##StepCodes WHERE SUBSTRING(CAST(Code AS VARCHAR(15)),7,1) = RIGHT(Code, 1) AND RIGHT(Code, 1) > 1

    INSERT ##PossibleStepCodes SELECT Code + 1001 FROM ##StepCodes WHERE SUBSTRING(CAST(Code AS VARCHAR(15)),8,1) = RIGHT(Code, 1) AND RIGHT(Code, 1) < 4
    INSERT ##PossibleStepCodes SELECT Code - 1001 FROM ##StepCodes WHERE SUBSTRING(CAST(Code AS VARCHAR(15)),8,1) = RIGHT(Code, 1) AND RIGHT(Code, 1) > 1

    INSERT ##PossibleStepCodes SELECT Code + 101 FROM ##StepCodes WHERE SUBSTRING(CAST(Code AS VARCHAR(15)),9,1) = RIGHT(Code, 1) AND RIGHT(Code, 1) < 4
    INSERT ##PossibleStepCodes SELECT Code - 101 FROM ##StepCodes WHERE SUBSTRING(CAST(Code AS VARCHAR(15)),9,1) = RIGHT(Code, 1) AND RIGHT(Code, 1) > 1

    INSERT ##PossibleStepCodes SELECT Code + 11 FROM ##StepCodes WHERE SUBSTRING(CAST(Code AS VARCHAR(15)),10,1) = RIGHT(Code, 1) AND RIGHT(Code, 1) < 4
    INSERT ##PossibleStepCodes SELECT Code - 11 FROM ##StepCodes WHERE SUBSTRING(CAST(Code AS VARCHAR(15)),10,1) = RIGHT(Code, 1) AND RIGHT(Code, 1) > 1

    --Double transportations
    INSERT ##PossibleStepCodes SELECT Code + 11000000001 FROM ##StepCodes WHERE SUBSTRING(CAST(Code AS VARCHAR(15)),1,1) = RIGHT(Code, 1) AND SUBSTRING(CAST(Code AS VARCHAR(15)),2,1) = RIGHT(Code, 1) AND RIGHT(Code, 1) < 4
    INSERT ##PossibleStepCodes SELECT Code - 11000000001 FROM ##StepCodes WHERE SUBSTRING(CAST(Code AS VARCHAR(15)),1,1) = RIGHT(Code, 1) AND SUBSTRING(CAST(Code AS VARCHAR(15)),2,1) = RIGHT(Code, 1) AND RIGHT(Code, 1) > 1
    INSERT ##PossibleStepCodes SELECT Code + 10100000001 FROM ##StepCodes WHERE SUBSTRING(CAST(Code AS VARCHAR(15)),1,1) = RIGHT(Code, 1) AND SUBSTRING(CAST(Code AS VARCHAR(15)),3,1) = RIGHT(Code, 1) AND RIGHT(Code, 1) < 4
    INSERT ##PossibleStepCodes SELECT Code - 10100000001 FROM ##StepCodes WHERE SUBSTRING(CAST(Code AS VARCHAR(15)),1,1) = RIGHT(Code, 1) AND SUBSTRING(CAST(Code AS VARCHAR(15)),3,1) = RIGHT(Code, 1) AND RIGHT(Code, 1) > 1
    INSERT ##PossibleStepCodes SELECT Code + 10010000001 FROM ##StepCodes WHERE SUBSTRING(CAST(Code AS VARCHAR(15)),1,1) = RIGHT(Code, 1) AND SUBSTRING(CAST(Code AS VARCHAR(15)),4,1) = RIGHT(Code, 1) AND RIGHT(Code, 1) < 4
    INSERT ##PossibleStepCodes SELECT Code - 10010000001 FROM ##StepCodes WHERE SUBSTRING(CAST(Code AS VARCHAR(15)),1,1) = RIGHT(Code, 1) AND SUBSTRING(CAST(Code AS VARCHAR(15)),4,1) = RIGHT(Code, 1) AND RIGHT(Code, 1) > 1
    INSERT ##PossibleStepCodes SELECT Code + 10001000001 FROM ##StepCodes WHERE SUBSTRING(CAST(Code AS VARCHAR(15)),1,1) = RIGHT(Code, 1) AND SUBSTRING(CAST(Code AS VARCHAR(15)),5,1) = RIGHT(Code, 1) AND RIGHT(Code, 1) < 4
    INSERT ##PossibleStepCodes SELECT Code - 10001000001 FROM ##StepCodes WHERE SUBSTRING(CAST(Code AS VARCHAR(15)),1,1) = RIGHT(Code, 1) AND SUBSTRING(CAST(Code AS VARCHAR(15)),5,1) = RIGHT(Code, 1) AND RIGHT(Code, 1) > 1
    INSERT ##PossibleStepCodes SELECT Code + 10000100001 FROM ##StepCodes WHERE SUBSTRING(CAST(Code AS VARCHAR(15)),1,1) = RIGHT(Code, 1) AND SUBSTRING(CAST(Code AS VARCHAR(15)),6,1) = RIGHT(Code, 1) AND RIGHT(Code, 1) < 4
    INSERT ##PossibleStepCodes SELECT Code - 10000100001 FROM ##StepCodes WHERE SUBSTRING(CAST(Code AS VARCHAR(15)),1,1) = RIGHT(Code, 1) AND SUBSTRING(CAST(Code AS VARCHAR(15)),6,1) = RIGHT(Code, 1) AND RIGHT(Code, 1) > 1
    INSERT ##PossibleStepCodes SELECT Code + 10000010001 FROM ##StepCodes WHERE SUBSTRING(CAST(Code AS VARCHAR(15)),1,1) = RIGHT(Code, 1) AND SUBSTRING(CAST(Code AS VARCHAR(15)),7,1) = RIGHT(Code, 1) AND RIGHT(Code, 1) < 4
    INSERT ##PossibleStepCodes SELECT Code - 10000010001 FROM ##StepCodes WHERE SUBSTRING(CAST(Code AS VARCHAR(15)),1,1) = RIGHT(Code, 1) AND SUBSTRING(CAST(Code AS VARCHAR(15)),7,1) = RIGHT(Code, 1) AND RIGHT(Code, 1) > 1
    INSERT ##PossibleStepCodes SELECT Code + 10000001001 FROM ##StepCodes WHERE SUBSTRING(CAST(Code AS VARCHAR(15)),1,1) = RIGHT(Code, 1) AND SUBSTRING(CAST(Code AS VARCHAR(15)),8,1) = RIGHT(Code, 1) AND RIGHT(Code, 1) < 4
    INSERT ##PossibleStepCodes SELECT Code - 10000001001 FROM ##StepCodes WHERE SUBSTRING(CAST(Code AS VARCHAR(15)),1,1) = RIGHT(Code, 1) AND SUBSTRING(CAST(Code AS VARCHAR(15)),8,1) = RIGHT(Code, 1) AND RIGHT(Code, 1) > 1
    INSERT ##PossibleStepCodes SELECT Code + 10000000101 FROM ##StepCodes WHERE SUBSTRING(CAST(Code AS VARCHAR(15)),1,1) = RIGHT(Code, 1) AND SUBSTRING(CAST(Code AS VARCHAR(15)),9,1) = RIGHT(Code, 1) AND RIGHT(Code, 1) < 4
    INSERT ##PossibleStepCodes SELECT Code - 10000000101 FROM ##StepCodes WHERE SUBSTRING(CAST(Code AS VARCHAR(15)),1,1) = RIGHT(Code, 1) AND SUBSTRING(CAST(Code AS VARCHAR(15)),9,1) = RIGHT(Code, 1) AND RIGHT(Code, 1) > 1
    INSERT ##PossibleStepCodes SELECT Code + 10000000011 FROM ##StepCodes WHERE SUBSTRING(CAST(Code AS VARCHAR(15)),1,1) = RIGHT(Code, 1) AND SUBSTRING(CAST(Code AS VARCHAR(15)),10,1) = RIGHT(Code, 1) AND RIGHT(Code, 1) < 4
    INSERT ##PossibleStepCodes SELECT Code - 10000000011 FROM ##StepCodes WHERE SUBSTRING(CAST(Code AS VARCHAR(15)),1,1) = RIGHT(Code, 1) AND SUBSTRING(CAST(Code AS VARCHAR(15)),10,1) = RIGHT(Code, 1) AND RIGHT(Code, 1) > 1

    INSERT ##PossibleStepCodes SELECT Code + 1100000001 FROM ##StepCodes WHERE SUBSTRING(CAST(Code AS VARCHAR(15)),2,1) = RIGHT(Code, 1) AND SUBSTRING(CAST(Code AS VARCHAR(15)),3,1) = RIGHT(Code, 1) AND RIGHT(Code, 1) < 4
    INSERT ##PossibleStepCodes SELECT Code - 1100000001 FROM ##StepCodes WHERE SUBSTRING(CAST(Code AS VARCHAR(15)),2,1) = RIGHT(Code, 1) AND SUBSTRING(CAST(Code AS VARCHAR(15)),3,1) = RIGHT(Code, 1) AND RIGHT(Code, 1) > 1
    INSERT ##PossibleStepCodes SELECT Code + 1010000001 FROM ##StepCodes WHERE SUBSTRING(CAST(Code AS VARCHAR(15)),2,1) = RIGHT(Code, 1) AND SUBSTRING(CAST(Code AS VARCHAR(15)),4,1) = RIGHT(Code, 1) AND RIGHT(Code, 1) < 4
    INSERT ##PossibleStepCodes SELECT Code - 1010000001 FROM ##StepCodes WHERE SUBSTRING(CAST(Code AS VARCHAR(15)),2,1) = RIGHT(Code, 1) AND SUBSTRING(CAST(Code AS VARCHAR(15)),4,1) = RIGHT(Code, 1) AND RIGHT(Code, 1) > 1
    INSERT ##PossibleStepCodes SELECT Code + 1001000001 FROM ##StepCodes WHERE SUBSTRING(CAST(Code AS VARCHAR(15)),2,1) = RIGHT(Code, 1) AND SUBSTRING(CAST(Code AS VARCHAR(15)),5,1) = RIGHT(Code, 1) AND RIGHT(Code, 1) < 4
    INSERT ##PossibleStepCodes SELECT Code - 1001000001 FROM ##StepCodes WHERE SUBSTRING(CAST(Code AS VARCHAR(15)),2,1) = RIGHT(Code, 1) AND SUBSTRING(CAST(Code AS VARCHAR(15)),5,1) = RIGHT(Code, 1) AND RIGHT(Code, 1) > 1
    INSERT ##PossibleStepCodes SELECT Code + 1000100001 FROM ##StepCodes WHERE SUBSTRING(CAST(Code AS VARCHAR(15)),2,1) = RIGHT(Code, 1) AND SUBSTRING(CAST(Code AS VARCHAR(15)),6,1) = RIGHT(Code, 1) AND RIGHT(Code, 1) < 4
    INSERT ##PossibleStepCodes SELECT Code - 1000100001 FROM ##StepCodes WHERE SUBSTRING(CAST(Code AS VARCHAR(15)),2,1) = RIGHT(Code, 1) AND SUBSTRING(CAST(Code AS VARCHAR(15)),6,1) = RIGHT(Code, 1) AND RIGHT(Code, 1) > 1
    INSERT ##PossibleStepCodes SELECT Code + 1000010001 FROM ##StepCodes WHERE SUBSTRING(CAST(Code AS VARCHAR(15)),2,1) = RIGHT(Code, 1) AND SUBSTRING(CAST(Code AS VARCHAR(15)),7,1) = RIGHT(Code, 1) AND RIGHT(Code, 1) < 4
    INSERT ##PossibleStepCodes SELECT Code - 1000010001 FROM ##StepCodes WHERE SUBSTRING(CAST(Code AS VARCHAR(15)),2,1) = RIGHT(Code, 1) AND SUBSTRING(CAST(Code AS VARCHAR(15)),7,1) = RIGHT(Code, 1) AND RIGHT(Code, 1) > 1
    INSERT ##PossibleStepCodes SELECT Code + 1000001001 FROM ##StepCodes WHERE SUBSTRING(CAST(Code AS VARCHAR(15)),2,1) = RIGHT(Code, 1) AND SUBSTRING(CAST(Code AS VARCHAR(15)),8,1) = RIGHT(Code, 1) AND RIGHT(Code, 1) < 4
    INSERT ##PossibleStepCodes SELECT Code - 1000001001 FROM ##StepCodes WHERE SUBSTRING(CAST(Code AS VARCHAR(15)),2,1) = RIGHT(Code, 1) AND SUBSTRING(CAST(Code AS VARCHAR(15)),8,1) = RIGHT(Code, 1) AND RIGHT(Code, 1) > 1
    INSERT ##PossibleStepCodes SELECT Code + 1000000101 FROM ##StepCodes WHERE SUBSTRING(CAST(Code AS VARCHAR(15)),2,1) = RIGHT(Code, 1) AND SUBSTRING(CAST(Code AS VARCHAR(15)),9,1) = RIGHT(Code, 1) AND RIGHT(Code, 1) < 4
    INSERT ##PossibleStepCodes SELECT Code - 1000000101 FROM ##StepCodes WHERE SUBSTRING(CAST(Code AS VARCHAR(15)),2,1) = RIGHT(Code, 1) AND SUBSTRING(CAST(Code AS VARCHAR(15)),9,1) = RIGHT(Code, 1) AND RIGHT(Code, 1) > 1
    INSERT ##PossibleStepCodes SELECT Code + 1000000011 FROM ##StepCodes WHERE SUBSTRING(CAST(Code AS VARCHAR(15)),2,1) = RIGHT(Code, 1) AND SUBSTRING(CAST(Code AS VARCHAR(15)),10,1) = RIGHT(Code, 1) AND RIGHT(Code, 1) < 4
    INSERT ##PossibleStepCodes SELECT Code - 1000000011 FROM ##StepCodes WHERE SUBSTRING(CAST(Code AS VARCHAR(15)),2,1) = RIGHT(Code, 1) AND SUBSTRING(CAST(Code AS VARCHAR(15)),10,1) = RIGHT(Code, 1) AND RIGHT(Code, 1) > 1

    INSERT ##PossibleStepCodes SELECT Code + 110000001 FROM ##StepCodes WHERE SUBSTRING(CAST(Code AS VARCHAR(15)),3,1) = RIGHT(Code, 1) AND SUBSTRING(CAST(Code AS VARCHAR(15)),4,1) = RIGHT(Code, 1) AND RIGHT(Code, 1) < 4
    INSERT ##PossibleStepCodes SELECT Code - 110000001 FROM ##StepCodes WHERE SUBSTRING(CAST(Code AS VARCHAR(15)),3,1) = RIGHT(Code, 1) AND SUBSTRING(CAST(Code AS VARCHAR(15)),4,1) = RIGHT(Code, 1) AND RIGHT(Code, 1) > 1
    INSERT ##PossibleStepCodes SELECT Code + 101000001 FROM ##StepCodes WHERE SUBSTRING(CAST(Code AS VARCHAR(15)),3,1) = RIGHT(Code, 1) AND SUBSTRING(CAST(Code AS VARCHAR(15)),5,1) = RIGHT(Code, 1) AND RIGHT(Code, 1) < 4
    INSERT ##PossibleStepCodes SELECT Code - 101000001 FROM ##StepCodes WHERE SUBSTRING(CAST(Code AS VARCHAR(15)),3,1) = RIGHT(Code, 1) AND SUBSTRING(CAST(Code AS VARCHAR(15)),5,1) = RIGHT(Code, 1) AND RIGHT(Code, 1) > 1
    INSERT ##PossibleStepCodes SELECT Code + 100100001 FROM ##StepCodes WHERE SUBSTRING(CAST(Code AS VARCHAR(15)),3,1) = RIGHT(Code, 1) AND SUBSTRING(CAST(Code AS VARCHAR(15)),6,1) = RIGHT(Code, 1) AND RIGHT(Code, 1) < 4
    INSERT ##PossibleStepCodes SELECT Code - 100100001 FROM ##StepCodes WHERE SUBSTRING(CAST(Code AS VARCHAR(15)),3,1) = RIGHT(Code, 1) AND SUBSTRING(CAST(Code AS VARCHAR(15)),6,1) = RIGHT(Code, 1) AND RIGHT(Code, 1) > 1
    INSERT ##PossibleStepCodes SELECT Code + 100010001 FROM ##StepCodes WHERE SUBSTRING(CAST(Code AS VARCHAR(15)),3,1) = RIGHT(Code, 1) AND SUBSTRING(CAST(Code AS VARCHAR(15)),7,1) = RIGHT(Code, 1) AND RIGHT(Code, 1) < 4
    INSERT ##PossibleStepCodes SELECT Code - 100010001 FROM ##StepCodes WHERE SUBSTRING(CAST(Code AS VARCHAR(15)),3,1) = RIGHT(Code, 1) AND SUBSTRING(CAST(Code AS VARCHAR(15)),7,1) = RIGHT(Code, 1) AND RIGHT(Code, 1) > 1
    INSERT ##PossibleStepCodes SELECT Code + 100001001 FROM ##StepCodes WHERE SUBSTRING(CAST(Code AS VARCHAR(15)),3,1) = RIGHT(Code, 1) AND SUBSTRING(CAST(Code AS VARCHAR(15)),8,1) = RIGHT(Code, 1) AND RIGHT(Code, 1) < 4
    INSERT ##PossibleStepCodes SELECT Code - 100001001 FROM ##StepCodes WHERE SUBSTRING(CAST(Code AS VARCHAR(15)),3,1) = RIGHT(Code, 1) AND SUBSTRING(CAST(Code AS VARCHAR(15)),8,1) = RIGHT(Code, 1) AND RIGHT(Code, 1) > 1
    INSERT ##PossibleStepCodes SELECT Code + 100000101 FROM ##StepCodes WHERE SUBSTRING(CAST(Code AS VARCHAR(15)),3,1) = RIGHT(Code, 1) AND SUBSTRING(CAST(Code AS VARCHAR(15)),9,1) = RIGHT(Code, 1) AND RIGHT(Code, 1) < 4
    INSERT ##PossibleStepCodes SELECT Code - 100000101 FROM ##StepCodes WHERE SUBSTRING(CAST(Code AS VARCHAR(15)),3,1) = RIGHT(Code, 1) AND SUBSTRING(CAST(Code AS VARCHAR(15)),9,1) = RIGHT(Code, 1) AND RIGHT(Code, 1) > 1
    INSERT ##PossibleStepCodes SELECT Code + 100000011 FROM ##StepCodes WHERE SUBSTRING(CAST(Code AS VARCHAR(15)),3,1) = RIGHT(Code, 1) AND SUBSTRING(CAST(Code AS VARCHAR(15)),10,1) = RIGHT(Code, 1) AND RIGHT(Code, 1) < 4
    INSERT ##PossibleStepCodes SELECT Code - 100000011 FROM ##StepCodes WHERE SUBSTRING(CAST(Code AS VARCHAR(15)),3,1) = RIGHT(Code, 1) AND SUBSTRING(CAST(Code AS VARCHAR(15)),10,1) = RIGHT(Code, 1) AND RIGHT(Code, 1) > 1

    INSERT ##PossibleStepCodes SELECT Code + 11000001 FROM ##StepCodes WHERE SUBSTRING(CAST(Code AS VARCHAR(15)),4,1) = RIGHT(Code, 1) AND SUBSTRING(CAST(Code AS VARCHAR(15)),5,1) = RIGHT(Code, 1) AND RIGHT(Code, 1) < 4
    INSERT ##PossibleStepCodes SELECT Code - 11000001 FROM ##StepCodes WHERE SUBSTRING(CAST(Code AS VARCHAR(15)),4,1) = RIGHT(Code, 1) AND SUBSTRING(CAST(Code AS VARCHAR(15)),5,1) = RIGHT(Code, 1) AND RIGHT(Code, 1) > 1
    INSERT ##PossibleStepCodes SELECT Code + 10100001 FROM ##StepCodes WHERE SUBSTRING(CAST(Code AS VARCHAR(15)),4,1) = RIGHT(Code, 1) AND SUBSTRING(CAST(Code AS VARCHAR(15)),6,1) = RIGHT(Code, 1) AND RIGHT(Code, 1) < 4
    INSERT ##PossibleStepCodes SELECT Code - 10100001 FROM ##StepCodes WHERE SUBSTRING(CAST(Code AS VARCHAR(15)),4,1) = RIGHT(Code, 1) AND SUBSTRING(CAST(Code AS VARCHAR(15)),6,1) = RIGHT(Code, 1) AND RIGHT(Code, 1) > 1
    INSERT ##PossibleStepCodes SELECT Code + 10010001 FROM ##StepCodes WHERE SUBSTRING(CAST(Code AS VARCHAR(15)),4,1) = RIGHT(Code, 1) AND SUBSTRING(CAST(Code AS VARCHAR(15)),7,1) = RIGHT(Code, 1) AND RIGHT(Code, 1) < 4
    INSERT ##PossibleStepCodes SELECT Code - 10010001 FROM ##StepCodes WHERE SUBSTRING(CAST(Code AS VARCHAR(15)),4,1) = RIGHT(Code, 1) AND SUBSTRING(CAST(Code AS VARCHAR(15)),7,1) = RIGHT(Code, 1) AND RIGHT(Code, 1) > 1
    INSERT ##PossibleStepCodes SELECT Code + 10001001 FROM ##StepCodes WHERE SUBSTRING(CAST(Code AS VARCHAR(15)),4,1) = RIGHT(Code, 1) AND SUBSTRING(CAST(Code AS VARCHAR(15)),8,1) = RIGHT(Code, 1) AND RIGHT(Code, 1) < 4
    INSERT ##PossibleStepCodes SELECT Code - 10001001 FROM ##StepCodes WHERE SUBSTRING(CAST(Code AS VARCHAR(15)),4,1) = RIGHT(Code, 1) AND SUBSTRING(CAST(Code AS VARCHAR(15)),8,1) = RIGHT(Code, 1) AND RIGHT(Code, 1) > 1
    INSERT ##PossibleStepCodes SELECT Code + 10000101 FROM ##StepCodes WHERE SUBSTRING(CAST(Code AS VARCHAR(15)),4,1) = RIGHT(Code, 1) AND SUBSTRING(CAST(Code AS VARCHAR(15)),9,1) = RIGHT(Code, 1) AND RIGHT(Code, 1) < 4
    INSERT ##PossibleStepCodes SELECT Code - 10000101 FROM ##StepCodes WHERE SUBSTRING(CAST(Code AS VARCHAR(15)),4,1) = RIGHT(Code, 1) AND SUBSTRING(CAST(Code AS VARCHAR(15)),9,1) = RIGHT(Code, 1) AND RIGHT(Code, 1) > 1
    INSERT ##PossibleStepCodes SELECT Code + 10000011 FROM ##StepCodes WHERE SUBSTRING(CAST(Code AS VARCHAR(15)),4,1) = RIGHT(Code, 1) AND SUBSTRING(CAST(Code AS VARCHAR(15)),10,1) = RIGHT(Code, 1) AND RIGHT(Code, 1) < 4
    INSERT ##PossibleStepCodes SELECT Code - 10000011 FROM ##StepCodes WHERE SUBSTRING(CAST(Code AS VARCHAR(15)),4,1) = RIGHT(Code, 1) AND SUBSTRING(CAST(Code AS VARCHAR(15)),10,1) = RIGHT(Code, 1) AND RIGHT(Code, 1) > 1

    INSERT ##PossibleStepCodes SELECT Code + 1100001 FROM ##StepCodes WHERE SUBSTRING(CAST(Code AS VARCHAR(15)),5,1) = RIGHT(Code, 1) AND SUBSTRING(CAST(Code AS VARCHAR(15)),6,1) = RIGHT(Code, 1) AND RIGHT(Code, 1) < 4
    INSERT ##PossibleStepCodes SELECT Code - 1100001 FROM ##StepCodes WHERE SUBSTRING(CAST(Code AS VARCHAR(15)),5,1) = RIGHT(Code, 1) AND SUBSTRING(CAST(Code AS VARCHAR(15)),6,1) = RIGHT(Code, 1) AND RIGHT(Code, 1) > 1
    INSERT ##PossibleStepCodes SELECT Code + 1010001 FROM ##StepCodes WHERE SUBSTRING(CAST(Code AS VARCHAR(15)),5,1) = RIGHT(Code, 1) AND SUBSTRING(CAST(Code AS VARCHAR(15)),7,1) = RIGHT(Code, 1) AND RIGHT(Code, 1) < 4
    INSERT ##PossibleStepCodes SELECT Code - 1010001 FROM ##StepCodes WHERE SUBSTRING(CAST(Code AS VARCHAR(15)),5,1) = RIGHT(Code, 1) AND SUBSTRING(CAST(Code AS VARCHAR(15)),7,1) = RIGHT(Code, 1) AND RIGHT(Code, 1) > 1
    INSERT ##PossibleStepCodes SELECT Code + 1001001 FROM ##StepCodes WHERE SUBSTRING(CAST(Code AS VARCHAR(15)),5,1) = RIGHT(Code, 1) AND SUBSTRING(CAST(Code AS VARCHAR(15)),8,1) = RIGHT(Code, 1) AND RIGHT(Code, 1) < 4
    INSERT ##PossibleStepCodes SELECT Code - 1001001 FROM ##StepCodes WHERE SUBSTRING(CAST(Code AS VARCHAR(15)),5,1) = RIGHT(Code, 1) AND SUBSTRING(CAST(Code AS VARCHAR(15)),8,1) = RIGHT(Code, 1) AND RIGHT(Code, 1) > 1
    INSERT ##PossibleStepCodes SELECT Code + 1000101 FROM ##StepCodes WHERE SUBSTRING(CAST(Code AS VARCHAR(15)),5,1) = RIGHT(Code, 1) AND SUBSTRING(CAST(Code AS VARCHAR(15)),9,1) = RIGHT(Code, 1) AND RIGHT(Code, 1) < 4
    INSERT ##PossibleStepCodes SELECT Code - 1000101 FROM ##StepCodes WHERE SUBSTRING(CAST(Code AS VARCHAR(15)),5,1) = RIGHT(Code, 1) AND SUBSTRING(CAST(Code AS VARCHAR(15)),9,1) = RIGHT(Code, 1) AND RIGHT(Code, 1) > 1
    INSERT ##PossibleStepCodes SELECT Code + 1000011 FROM ##StepCodes WHERE SUBSTRING(CAST(Code AS VARCHAR(15)),5,1) = RIGHT(Code, 1) AND SUBSTRING(CAST(Code AS VARCHAR(15)),10,1) = RIGHT(Code, 1) AND RIGHT(Code, 1) < 4
    INSERT ##PossibleStepCodes SELECT Code - 1000011 FROM ##StepCodes WHERE SUBSTRING(CAST(Code AS VARCHAR(15)),5,1) = RIGHT(Code, 1) AND SUBSTRING(CAST(Code AS VARCHAR(15)),10,1) = RIGHT(Code, 1) AND RIGHT(Code, 1) > 1

    INSERT ##PossibleStepCodes SELECT Code + 110001 FROM ##StepCodes WHERE SUBSTRING(CAST(Code AS VARCHAR(15)),6,1) = RIGHT(Code, 1) AND SUBSTRING(CAST(Code AS VARCHAR(15)),7,1) = RIGHT(Code, 1) AND RIGHT(Code, 1) < 4
    INSERT ##PossibleStepCodes SELECT Code - 110001 FROM ##StepCodes WHERE SUBSTRING(CAST(Code AS VARCHAR(15)),6,1) = RIGHT(Code, 1) AND SUBSTRING(CAST(Code AS VARCHAR(15)),7,1) = RIGHT(Code, 1) AND RIGHT(Code, 1) > 1
    INSERT ##PossibleStepCodes SELECT Code + 101001 FROM ##StepCodes WHERE SUBSTRING(CAST(Code AS VARCHAR(15)),6,1) = RIGHT(Code, 1) AND SUBSTRING(CAST(Code AS VARCHAR(15)),8,1) = RIGHT(Code, 1) AND RIGHT(Code, 1) < 4
    INSERT ##PossibleStepCodes SELECT Code - 101001 FROM ##StepCodes WHERE SUBSTRING(CAST(Code AS VARCHAR(15)),6,1) = RIGHT(Code, 1) AND SUBSTRING(CAST(Code AS VARCHAR(15)),8,1) = RIGHT(Code, 1) AND RIGHT(Code, 1) > 1
    INSERT ##PossibleStepCodes SELECT Code + 100101 FROM ##StepCodes WHERE SUBSTRING(CAST(Code AS VARCHAR(15)),6,1) = RIGHT(Code, 1) AND SUBSTRING(CAST(Code AS VARCHAR(15)),9,1) = RIGHT(Code, 1) AND RIGHT(Code, 1) < 4
    INSERT ##PossibleStepCodes SELECT Code - 100101 FROM ##StepCodes WHERE SUBSTRING(CAST(Code AS VARCHAR(15)),6,1) = RIGHT(Code, 1) AND SUBSTRING(CAST(Code AS VARCHAR(15)),9,1) = RIGHT(Code, 1) AND RIGHT(Code, 1) > 1
    INSERT ##PossibleStepCodes SELECT Code + 100011 FROM ##StepCodes WHERE SUBSTRING(CAST(Code AS VARCHAR(15)),6,1) = RIGHT(Code, 1) AND SUBSTRING(CAST(Code AS VARCHAR(15)),10,1) = RIGHT(Code, 1) AND RIGHT(Code, 1) < 4
    INSERT ##PossibleStepCodes SELECT Code - 100011 FROM ##StepCodes WHERE SUBSTRING(CAST(Code AS VARCHAR(15)),6,1) = RIGHT(Code, 1) AND SUBSTRING(CAST(Code AS VARCHAR(15)),10,1) = RIGHT(Code, 1) AND RIGHT(Code, 1) > 1

    INSERT ##PossibleStepCodes SELECT Code + 11001 FROM ##StepCodes WHERE SUBSTRING(CAST(Code AS VARCHAR(15)),7,1) = RIGHT(Code, 1) AND SUBSTRING(CAST(Code AS VARCHAR(15)),8,1) = RIGHT(Code, 1) AND RIGHT(Code, 1) < 4
    INSERT ##PossibleStepCodes SELECT Code - 11001 FROM ##StepCodes WHERE SUBSTRING(CAST(Code AS VARCHAR(15)),7,1) = RIGHT(Code, 1) AND SUBSTRING(CAST(Code AS VARCHAR(15)),8,1) = RIGHT(Code, 1) AND RIGHT(Code, 1) > 1
    INSERT ##PossibleStepCodes SELECT Code + 10101 FROM ##StepCodes WHERE SUBSTRING(CAST(Code AS VARCHAR(15)),7,1) = RIGHT(Code, 1) AND SUBSTRING(CAST(Code AS VARCHAR(15)),9,1) = RIGHT(Code, 1) AND RIGHT(Code, 1) < 4
    INSERT ##PossibleStepCodes SELECT Code - 10101 FROM ##StepCodes WHERE SUBSTRING(CAST(Code AS VARCHAR(15)),7,1) = RIGHT(Code, 1) AND SUBSTRING(CAST(Code AS VARCHAR(15)),9,1) = RIGHT(Code, 1) AND RIGHT(Code, 1) > 1
    INSERT ##PossibleStepCodes SELECT Code + 10011 FROM ##StepCodes WHERE SUBSTRING(CAST(Code AS VARCHAR(15)),7,1) = RIGHT(Code, 1) AND SUBSTRING(CAST(Code AS VARCHAR(15)),10,1) = RIGHT(Code, 1) AND RIGHT(Code, 1) < 4
    INSERT ##PossibleStepCodes SELECT Code - 10011 FROM ##StepCodes WHERE SUBSTRING(CAST(Code AS VARCHAR(15)),7,1) = RIGHT(Code, 1) AND SUBSTRING(CAST(Code AS VARCHAR(15)),10,1) = RIGHT(Code, 1) AND RIGHT(Code, 1) > 1

    INSERT ##PossibleStepCodes SELECT Code + 1101 FROM ##StepCodes WHERE SUBSTRING(CAST(Code AS VARCHAR(15)),8,1) = RIGHT(Code, 1) AND SUBSTRING(CAST(Code AS VARCHAR(15)),9,1) = RIGHT(Code, 1) AND RIGHT(Code, 1) < 4
    INSERT ##PossibleStepCodes SELECT Code - 1101 FROM ##StepCodes WHERE SUBSTRING(CAST(Code AS VARCHAR(15)),8,1) = RIGHT(Code, 1) AND SUBSTRING(CAST(Code AS VARCHAR(15)),9,1) = RIGHT(Code, 1) AND RIGHT(Code, 1) > 1
    INSERT ##PossibleStepCodes SELECT Code + 1011 FROM ##StepCodes WHERE SUBSTRING(CAST(Code AS VARCHAR(15)),8,1) = RIGHT(Code, 1) AND SUBSTRING(CAST(Code AS VARCHAR(15)),10,1) = RIGHT(Code, 1) AND RIGHT(Code, 1) < 4
    INSERT ##PossibleStepCodes SELECT Code - 1011 FROM ##StepCodes WHERE SUBSTRING(CAST(Code AS VARCHAR(15)),8,1) = RIGHT(Code, 1) AND SUBSTRING(CAST(Code AS VARCHAR(15)),10,1) = RIGHT(Code, 1) AND RIGHT(Code, 1) > 1

    INSERT ##PossibleStepCodes SELECT Code + 111 FROM ##StepCodes WHERE SUBSTRING(CAST(Code AS VARCHAR(15)),9,1) = RIGHT(Code, 1) AND SUBSTRING(CAST(Code AS VARCHAR(15)),10,1) = RIGHT(Code, 1) AND RIGHT(Code, 1) < 4
    INSERT ##PossibleStepCodes SELECT Code - 111 FROM ##StepCodes WHERE SUBSTRING(CAST(Code AS VARCHAR(15)),9,1) = RIGHT(Code, 1) AND SUBSTRING(CAST(Code AS VARCHAR(15)),10,1) = RIGHT(Code, 1) AND RIGHT(Code, 1) > 1

    UPDATE ##Building
    SET Step = @Step
    WHERE Code IN (SELECT Code FROM ##PossibleStepCodes) AND Step IS NULL

    PRINT 'Step ' + CAST(@Step AS VARCHAR(10)) + ' at ' + CAST(GETDATE() AS VARCHAR(50))

END


--SELECT * FROM ##StepCodes
--SELECT * FROM ##PossibleStepCodes

SELECT * FROM ##Building WHERE ID = @TargetID


DROP TABLE ##Building
DROP TABLE ##StepCodes
DROP TABLE ##PossibleStepCodes



---------------Part 2: just more items :S


--Should be more than 37 
--Less than 100
--58 niet goed
--59 niet goed
--62 niet goed
--63 niet goed
--64 niet goed
--65 niet goed
--66 niet goed
--67 niet goed
--68 niet goed

--61 IS GOED!!!


/*


2 = 4
4 = 11  (+7)
6 = 17  (+6)
8 = 25  (+8)
10 = 37 (+12)
14 =    (~ +12 + 24 => 49 - 61)



*/
