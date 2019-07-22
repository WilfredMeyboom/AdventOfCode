use Test_WME

SET NOCOUNT ON

CREATE TABLE ##Input (Name NVARCHAR(MAX));

BULK INSERT ##Input
FROM 'D:\Wilfred\AdventOfCode\input24.txt'
WITH (ROWTERMINATOR = '0x0A');


--SELECT * FROM ##Input

--DELETE FROM ##Input
--INSERT ##Input VALUES 
--('Immune System:'),
--('17 units each with 5390 hit points (weak to radiation, bludgeoning) with an attack that does 4507 fire damage at initiative 2'),
--('989 units each with 1274 hit points (immune to fire; weak to bludgeoning, slashing) with an attack that does 25 slashing damage at initiative 3'),
--(NULL),
--('Infection:'),
--('801 units each with 4706 hit points (weak to radiation) with an attack that does 116 bludgeoning damage at initiative 1'),
--('4485 units each with 2961 hit points (immune to radiation; weak to fire, cold) with an attack that does 12 slashing damage at initiative 4')


CREATE TABLE ##Armies (ID INT IDENTITY(1,1), Descr VARCHAR(MAX), Side VARCHAR(15), Size INT, HP INT, Attack INT, Initiative INT)

CREATE TABLE ##AttackModifiers (ID INT IDENTITY(1,1), ArmyID INT, AttackType VARCHAR(20), IsAttack BIT, IsWeakTo BIT, IsImmuneTo BIT)

INSERT ##Armies (Descr, Size, HP, Attack, Initiative)
SELECT Name 
,      LEFT(Name, CHARINDEX(' units', Name))
,      SUBSTRING(Name, CHARINDEX(' with ', Name) + 5, CHARINDEX(' hit ', Name) - CHARINDEX(' with ', Name) - 5)
,      LEFT(SUBSTRING(Name, CHARINDEX(' does ', Name) + 5, LEN(Name)), CHARINDEX(' ',SUBSTRING(Name, CHARINDEX(' does ', Name) + 6, LEN(Name))))
,      SUBSTRING(Name, CHARINDEX(' initiative ', Name) + 12, LEN(Name))
FROM ##Input
WHERE LEN(Name) > 20 OR Name IS NULL


DECLARE @NULLRowID INT

SELECT @NullRowID = ID FROM ##Armies WHERE Descr IS NULL

UPDATE ##Armies
SET Side = CASE WHEN ID < @NULLRowID THEN 'Immune' ELSE 'Infection' END

DELETE FROM ##Armies WHERE ID = @NULLRowID




INSERT ##AttackModifiers (ArmyID, AttackType, IsAttack, IsWeakTo, IsImmuneTo)
SELECT ID
,      RTRIM(LTRIM(SUBSTRING(Descr, CHARINDEX(N' ' + CAST(Attack AS VARCHAR(8)), Descr) + LEN(CAST(Attack AS VARCHAR(8))) + 1,  CHARINDEX(' damage', Descr) - CHARINDEX(N' ' + CAST(Attack AS VARCHAR(8)), Descr) - LEN(CAST(Attack AS VARCHAR(8))))))
,      1
,      0
,      0
FROM ##Armies


DECLARE @Boost INT = 78

UPDATE ##Armies
SET Attack = Attack + @Boost
WHERE Side = 'Immune'

;WITH cte_AttackMods AS (
    SELECT ID
    ,      CASE WHEN CHARINDEX('(', Descr) > 0  THEN SUBSTRING(Descr, CHARINDEX('(', Descr) + 1, CHARINDEX(')', Descr) - CHARINDEX('(', Descr) - 1) ELSE '' END AS BetweenBrackets
    ,      CHARINDEX('Weak', Descr) AS ContainsWeak
    ,      CHARINDEX('Immune', Descr) AS ContainsImmune
    FROM ##Armies
), cte_ModifiersTypes AS (
    SELECT DISTINCT AttackType
    FROM ##AttackModifiers
)
, cte_SplitAttackMods AS (
    SELECT ID
    ,      SUBSTRING(BetweenBrackets, 0, CHARINDEX(';', BetweenBrackets)) AS BetweenBrackets
    ,      CHARINDEX('Weak', SUBSTRING(BetweenBrackets, 0, CHARINDEX(';', BetweenBrackets))) AS ContainsWeak
    ,      CHARINDEX('Immune', SUBSTRING(BetweenBrackets, 0, CHARINDEX(';', BetweenBrackets))) AS ContainsImmune
    FROM cte_AttackMods
    WHERE ContainsWeak > 0 AND ContainsImmune > 0 
    UNION
    SELECT ID
    ,      SUBSTRING(BetweenBrackets, CHARINDEX(';', BetweenBrackets) + 1, LEN(BetweenBrackets)) AS BetweenBrackets
    ,      CHARINDEX('Weak', SUBSTRING(BetweenBrackets, CHARINDEX(';', BetweenBrackets) + 1, LEN(BetweenBrackets))) AS ContainsWeak
    ,      CHARINDEX('Immune', SUBSTRING(BetweenBrackets, CHARINDEX(';', BetweenBrackets) + 1, LEN(BetweenBrackets))) AS ContainsImmune
    FROM cte_AttackMods
    WHERE ContainsWeak > 0 AND ContainsImmune > 0 
)
INSERT ##AttackModifiers (ArmyID, AttackType, IsAttack, IsImmuneTo, IsWeakTo)
SELECT cAM.ID, cMT.AttackType, 0, 0, 1
FROM cte_AttackMods cAM
INNER JOIN cte_ModifiersTypes cMT ON cAM.BetweenBrackets LIKE '%' + cMT.AttackType + '%'
WHERE ContainsWeak > 0 AND ContainsImmune = 0 
UNION
SELECT cAM.ID, cMT.AttackType, 0, 1, 0
FROM cte_AttackMods cAM
INNER JOIN cte_ModifiersTypes cMT ON cAM.BetweenBrackets LIKE '%' + cMT.AttackType + '%'
WHERE ContainsWeak = 0 AND ContainsImmune > 0 
UNION
SELECT cAM.ID, cMT.AttackType, 0, 0, 1
FROM cte_SplitAttackMods cAM
LEFT JOIN cte_ModifiersTypes cMT ON cAM.BetweenBrackets LIKE '%' + cMT.AttackType + '%'
WHERE ContainsWeak > 0 AND ContainsImmune = 0 
UNION
SELECT cAM.ID, cMT.AttackType, 0, 1, 0
FROM cte_SplitAttackMods cAM
LEFT JOIN cte_ModifiersTypes cMT ON cAM.BetweenBrackets LIKE '%' + cMT.AttackType + '%'
WHERE ContainsWeak = 0 AND ContainsImmune > 0 

--SELECT * FROM ##Armies

DECLARE @Counter INT = 1

CREATE TABLE ##Targets (ID INT IDENTITY(1,1), ArmyID INT, TargetArmyID INT)

DECLARE @ArmyID INT
DECLARE @TargetID INT
DECLARE @Damage INT
DECLARE @IsWeak BIT

WHILE (SELECT COUNT(DISTINCT Side) FROM ##Armies WHERE Size > 0) > 1 AND @Counter < 6000
BEGIN

    DELETE FROM ##Targets

    INSERT ##Targets (ArmyID)
    SELECT ID FROM ##Armies WHERE Size > 0

    DECLARE ArmyCursor CURSOR FOR
    SELECT ID FROM ##Armies WHERE Size > 0 ORDER BY Attack * Size DESC, Initiative DESC

    OPEN ArmyCursor
    FETCH NEXT FROM ArmyCursor INTO @ArmyID

    WHILE @@FETCH_STATUS = 0
    BEGIN
        
        SET @TargetID = -1

        SELECT TOP(1) @TargetID = A2.ID
        FROM ##Armies A 
        INNER JOIN ##AttackModifiers AM ON A.ID = AM.ArmyID AND AM.IsAttack = 1
        INNER JOIN ##Armies A2 ON A.Side <> A2.Side AND A2.Size > 0
        LEFT JOIN ##AttackModifiers AM2 ON A2.ID = AM2.ArmyID AND AM2.AttackType = AM.AttackType AND AM2.IsAttack = 0
        WHERE A.ID = @ArmyID 
          AND A2.ID NOT IN (SELECT TargetArmyID FROM ##Targets WHERE TargetArmyID IS NOT NULL)
          AND (AM2.ID IS NULL OR AM2.IsImmuneTo = 0)
        ORDER BY ISNULL(AM2.IsWeakTo, 0) DESC, A2.Attack * A2.Size DESC, A2.Initiative DESC

        UPDATE ##Targets
        SET TargetArmyID = @TargetID
        WHERE ArmyID = @ArmyID

        FETCH NEXT FROM ArmyCursor INTO @ArmyID

    END

    CLOSE ArmyCursor
    DEALLOCATE ArmyCursor

--    SELECT * FROM ##Targets

--Effective Power = Size * Attack

    DECLARE AttackCursor CURSOR FOR
    SELECT T.ArmyID, T.TargetArmyID 
    FROM ##Targets T
    INNER JOIN ##Armies A ON T.ArmyID = A.ID
    WHERE T.TargetArmyID >= 0 AND A.Size > 0
    ORDER BY A.Initiative DESC

    OPEN AttackCursor
    FETCH NEXT FROM AttackCursor INTO @ArmyID, @TargetID

    WHILE @@FETCH_STATUS = 0
    BEGIN

        IF (SELECT Size FROM ##Armies WHERE ID = @ArmyID) > 0
        BEGIN
            
            SET @IsWeak = 0
            
            SELECT @IsWeak = 1
            FROM ##Armies A
            INNER JOIN ##AttackModifiers AM ON A.ID = AM.ArmyID AND AM.IsAttack = 1
            INNER JOIN ##AttackModifiers AM2 ON AM2.ArmyID = @TargetID AND AM.AttackType = AM2.AttackType AND AM2.IsWeakTo = 1
            WHERE A.ID = @ArmyID

            SELECT @Damage = (A.Size * CASE WHEN @IsWeak = 1 THEN 2 ELSE 1 END * A.Attack) --+ CASE WHEN Side = 'Immune' THEN @Boost ELSE 0 END))
            FROM ##Armies A
            WHERE A.ID = @ArmyID

            UPDATE ##Armies
            SET Size = Size - @Damage / HP
            WHERE ID = @TargetID

         --   PRINT 'Army: ' + CAST(@ArmyID AS VARCHAR(2)) + ', Target: ' + CAST(@TargetID AS VARCHAR(2)) + ', Damage: ' + CAST(@Damage AS VARCHAR(10))

        END

        FETCH NEXT FROM AttackCursor INTO @ArmyID, @TargetID

    END
    
    CLOSE AttackCursor
    DEALLOCATE AttackCursor

--    SELECT @Counter, * FROM ##Armies
    IF (@Counter % 10) = 0 PRINT 'End of round ' + CAST(@Counter AS VARCHAR(10)) + ' at time ' + CAST(GETDATE() AS VARCHAR(50))

    SET @Counter = @Counter + 1

--    SELECT * FROM ##Armies

END

PRINT 'End of fight ' + CAST(@Counter AS VARCHAR(10)) + ' at time ' + CAST(GETDATE() AS VARCHAR(50))

--SELECT * FROM ##Armies A INNER JOIN ##AttackModifiers AM ON A.ID = AM.ArmyID

SELECT SUM(Size), MAX(Side) FROM ##Armies WHERE Size > 0
SELECT * FROM ##Armies






DROP TABLE ##Targets

DROP TABLE ##AttackModifiers

DROP TABLE ##Armies

DROP TABLE ##Input





/*

145581 --> Too high
2303 --> Too high


Boost 1500 16550	Immune 31 rounds
Boost 500 14425	Immune 96 rounds
Boost 200 10188	Immune 263 rounds
Boost 100 5987	Immune 690 rounds
Boost 50 17675	Infection 764 rounds
Boost 75 6614	Infection 1561 rounds
Boost 87 4112	Immune 1023 rounds
Boost 81 2768  Immune 1376 rounds
Boost 79 1852	Immune 1920 rounds           <------ Correct answer part 2
Boost 77 4481	Infection 2243 rounds
Boost 78 STAND OFF

*/

