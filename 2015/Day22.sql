SET NOCOUNT ON

/*
    Magic Missile costs 53 mana. It instantly does 4 damage.
    Drain costs 73 mana. It instantly does 2 damage and heals you for 2 hit points.
    Shield costs 113 mana. It starts an effect that lasts for 6 turns. While it is active, your armor is increased by 7.
    Poison costs 173 mana. It starts an effect that lasts for 6 turns. At the start of each turn while it is active, it deals the boss 3 damage.
    Recharge costs 229 mana. It starts an effect that lasts for 5 turns. At the start of each turn while it is active, it gives you 101 new mana.
You start with 50 hit points and 500 mana points

Boss:
Hit Points: 55
Damage: 8

*/

CREATE TABLE ##Spells (ID INT IDENTITY(1,1), Name VARCHAR(20), ManaCost INT, Duration INT, Damage INT, Armor INT, Health INT, Mana INT)

INSERT ##Spells (Name, ManaCost, Duration, Damage, Armor, Health, Mana) VALUES
('MagicMissile', 53, 1, 4, 0, 0, 0),
('Drain'       , 73, 1, 2, 0, 2, 0),
('Shield'     , 113, 6, 0, 7, 0, 0),
('Poison'     , 173, 6, 3, 0, 0, 0),
('Recharge'   , 229, 5, 2, 0, 0, 101)


CREATE TABLE ##FightStatus (ID INT IDENTITY(1,1), PreviousID INT, Round INT, PlayerHealth INT, PlayerMana INT, BossHealth INT, ShieldActive INT, ShieldValue INT, PoisonActive INT, PoisonValue INT, RechargeActive INT, RechargeValue INT, ManaSpent INT)

INSERT ##FightStatus (Round, PlayerHealth, PlayerMana, BossHealth, ShieldActive, ShieldValue, PoisonActive, PoisonValue, RechargeActive, RechargeValue, ManaSpent) VALUES (0, 50, 500, 55, 0, 7, 0, 3, 0, 101, 0)
--INSERT ##FightStatus (Round, PlayerHealth, PlayerMana, BossHealth, ShieldActive, ShieldValue, PoisonActive, PoisonValue, RechargeActive, RechargeValue) VALUES (0, 10, 250, 14, 0, 7, 0, 3, 0, 101)

CREATE TABLE ##HistoricFightStatus (ID INT, PreviousID INT, Round INT, PlayerHealth INT, PlayerMana INT, BossHealth INT, ShieldActive INT, ShieldValue INT, PoisonActive INT, PoisonValue INT, RechargeActive INT, RechargeValue INT, ManaSpent INT)

DECLARE @BossDamage INT = 8
DECLARE @Round INT = 0

WHILE EXISTS (SELECT 1 FROM ##FightStatus) AND @Round < 13
BEGIN
    
    SET @Round = @Round + 1

    -- Store what happened
    INSERT ##HistoricFightStatus SELECT * FROM ##FightStatus

    -- Change for part 2
    UPDATE ##FightStatus SET PlayerHealth = PlayerHealth - 1

    -- Remove any fights that are over due to the player dying, the boss dying or the player running out of mana
    DELETE FROM ##FightStatus
    WHERE PlayerHealth <= 0 OR BossHealth <= 0 OR PlayerMana <= 0
   
    INSERT ##FightStatus (Round, PreviousID, PlayerHealth, PlayerMana, BossHealth, ShieldActive, ShieldValue, PoisonActive, PoisonValue, RechargeActive, RechargeValue, ManaSpent)
    SELECT @Round
    ,      F.ID AS PreviousID
    ,      F.PlayerHealth - CASE WHEN (F.ShieldActive > 1 OR S.Armor > 0)         -- Is the shield (just) activated?
                                 THEN CASE WHEN F.ShieldValue - @BossDamage > 1   -- Does the boss do more damage than our shield
                                      THEN F.ShieldValue - @BossDamage            -- Take the difference in damage
                                      ELSE 1 END                                  -- Always take at least 1 damage
                                 ELSE @BossDamage END                             -- Take the full boss damage
                          + S.Health AS PlayerHealth
    ,      F.PlayerMana - S.ManaCost + CASE WHEN F.RechargeActive > 1 OR S.Mana > 0 
                                            THEN 2*F.RechargeValue 
                                            ELSE CASE WHEN F.RechargeActive = 1 
                                                      THEN F.RechargeValue
                                                      ELSE 0 
                                                      END
                                        END AS PlayerMana
    ,      F.BossHealth - S.Damage - CASE WHEN F.PoisonActive > 1 
                                          THEN 2*F.PoisonValue 
                                          ELSE CASE WHEN F.PoisonActive = 1 
                                                    THEN F.PoisonValue
                                                    ELSE 0 
                                                    END
                                          END AS BossHealth
    ,      CASE WHEN S.Name = 'Shield' 
                THEN S.Duration - 2 
                ELSE CASE WHEN F.ShieldActive > 0
                          THEN F.ShieldActive - 2
                          ELSE 0 END
                END AS ShieldActive
    ,      ShieldValue
    ,      CASE WHEN S.Name = 'Poison' 
                THEN S.Duration - 2 
                ELSE CASE WHEN F.PoisonActive > 0 
                          THEN F.PoisonActive - 2
                          ELSE 0 END                
                END AS PoisonActive
    ,      PoisonValue
    ,      CASE WHEN S.Name = 'Recharge' 
                THEN S.Duration - 2 
                ELSE CASE WHEN F.RechargeActive > 0 
                          THEN F.RechargeActive - 2
                          ELSE 0 END
                END AS RechargeActive
    ,      RechargeValue
    ,      ManaSpent + S.ManaCost AS ManaSpent
    FROM ##FightStatus F
    CROSS APPLY ##Spells S
    WHERE NOT ((F.PoisonActive > 0 AND S.Name = 'Poison') OR
               (F.ShieldActive > 0 AND S.Name = 'Shield') OR
               (F.RechargeActive > 0 AND S.Name = 'Recharge'))
               
    DELETE FROM ##FightStatus WHERE Round = @Round - 1

PRINT 'Round: ' + CAST(@Round AS VARCHAR(6)) 

END

-- 900 is too low for part 1
-- 953 is correct for part 1

-- 1066 is too low for part 2
-- 1289 is correct for part 2
/*

DROP TABLE ##FightStatus
DROP TABLE ##HistoricFightStatus
DROP TABLE ##Spells

*/

--SELECT * FROM ##HistoricFightStatus WHERE Round = 1
----ID 5
--SELECT * FROM ##HistoricFightStatus WHERE PreviousID = 6

--SELECT * FROM ##HistoricFightStatus WHERE PreviousID = 27

--SELECT * FROM ##HistoricFightStatus WHERE PreviousID = 49

--SELECT * FROM ##HistoricFightStatus WHERE PreviousID = 85

--SELECT * FROM ##FightStatus

--SELECT * FROM ##HistoricFightStatus WHERE BossHealth <= 0 ORDER BY Round