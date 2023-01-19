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
('Poison'     , 173, 6, 0, 0, 0, 0), -- Poisondamage is tracked through a variable
('Recharge'   , 229, 5, 0, 0, 0, 101)


CREATE TABLE ##FightStatus (ID INT IDENTITY(1,1), RoundNr INT, PlayerHealth INT, PlayerMana INT, BossHealth INT, ShieldActive INT, PoisonActive INT, RechargeActive INT, ManaSpent INT, SpellsPath VARCHAR(MAX))

INSERT ##FightStatus (RoundNr, PlayerHealth, PlayerMana, BossHealth, ShieldActive, PoisonActive, RechargeActive, ManaSpent, SpellsPath) VALUES (0, 50, 500, 55, 0, 0, 0, 0, '')
--INSERT ##FightStatus (RoundNr, PlayerHealth, PlayerMana, BossHealth, ShieldActive, PoisonActive, RechargeActive, ManaSpent, SpellsPath) VALUES (0, 10, 250, 14, 0, 0, 0, 0, '')

DECLARE @BossDamage INT = 8
DECLARE @Round INT = 0
DECLARE @ShieldValue INT = 7
DECLARE @PoisonValue INT = 3
DECLARE @RechargeValue INT = 101

WHILE NOT EXISTS (SELECT 1 FROM ##FightStatus WHERE BossHealth <= 0) AND @Round < 25
BEGIN
    
    SET @Round = @Round + 1

    INSERT ##FightStatus (RoundNr, PlayerHealth, PlayerMana, BossHealth, ShieldActive, PoisonActive, RechargeActive, ManaSpent, SpellsPath)
    SELECT @Round
    ,      F.PlayerHealth + S.Health AS PlayerHealth                                          -- If we just cast Drain
    ,      F.PlayerMana - S.ManaCost + CASE WHEN F.RechargeActive > 1                         -- Has recharge been cast? 
                                            THEN @RechargeValue                               -- We recharge twice (once during player turn and once during boss turn)
                                            ELSE 0
                                        END AS PlayerMana
    ,      F.BossHealth - S.Damage - CASE WHEN F.PoisonActive > 1                             -- Has poison (just) been cast? 
                                          THEN @PoisonValue 
                                          ELSE 0 
                                          END AS BossHealth
    ,      CASE WHEN S.Name = 'Shield' 
                THEN S.Duration + 1                 --Correction because SQL does everything at once
                ELSE CASE WHEN F.ShieldActive > 0
                          THEN F.ShieldActive - 1
                          ELSE 0 END
                END AS ShieldActive
    ,      CASE WHEN S.Name = 'Poison' 
                THEN S.Duration + 1                 --Correction because SQL does everything at once
                ELSE CASE WHEN F.PoisonActive > 0 
                          THEN F.PoisonActive - 1
                          ELSE 0 END                
                END AS PoisonActive
    ,      CASE WHEN S.Name = 'Recharge' 
                THEN S.Duration + 1                 --Correction because SQL does everything at once
                ELSE CASE WHEN F.RechargeActive > 0 
                          THEN F.RechargeActive - 1
                          ELSE 0 END
                END AS RechargeActive
    ,      ManaSpent + S.ManaCost AS ManaSpent
    ,      SpellsPath + ' | ' + S.Name
    FROM ##FightStatus F
    CROSS APPLY ##Spells S
    WHERE NOT ((F.PoisonActive > 2 AND S.Name = 'Poison') OR
               (F.ShieldActive > 1 AND S.Name = 'Shield') OR
               (F.RechargeActive > 1 AND S.Name = 'Recharge'))
              
    DELETE FROM ##FightStatus WHERE PlayerHealth <= 0 OR PlayerMana <= 0

    SET @Round = @Round + 1

    UPDATE F
    SET RoundNr = @Round
    ,   PlayerHealth = F.PlayerHealth - CASE WHEN F.ShieldActive > 1                          -- Is the shield activated?
                                             THEN CASE WHEN @ShieldValue - @BossDamage > 1    -- Does the boss do more damage than our shield
                                                       THEN @ShieldValue - @BossDamage        -- Take the difference in damage
                                                       ELSE 1 END                             -- Always take at least 1 damage
                                             ELSE @BossDamage END                             -- Take the full boss damage
    ,  PlayerMana = F.PlayerMana + CASE WHEN F.RechargeActive > 1                             -- Has recharge been cast? 
                                        THEN @RechargeValue                                   -- We recharge twice (once during player turn and once during boss turn)
                                        ELSE 0
                                        END 
    ,  BossHealth = F.BossHealth - CASE WHEN F.PoisonActive > 1                               -- Has poison (just) been cast? 
                                          THEN @PoisonValue 
                                          ELSE 0 
                                          END 
    ,  ShieldActive = CASE WHEN F.ShieldActive > 0
                           THEN F.ShieldActive - 1
                           ELSE 0 END
    ,  PoisonActive = CASE WHEN F.PoisonActive > 0 
                           THEN F.PoisonActive - 1
                           ELSE 0 END                
    ,  RechargeActive = CASE WHEN F.RechargeActive > 0 
                             THEN F.RechargeActive - 1
                             ELSE 0 END
    FROM ##FightStatus F
    WHERE BossHealth > 0 AND RoundNr = @Round - 1

    DELETE FROM ##FightStatus WHERE PlayerHealth <= 0 OR PlayerMana <= 0

    DELETE FROM ##FightStatus WHERE RoundNr = @Round - 2

    PRINT 'Round: ' + CAST(@Round AS VARCHAR(6)) 

END

SELECT MIN(ManaSpent) AS Part1 FROM ##FightStatus WHERE BossHealth <= 0


--Reset for part2
TRUNCATE TABLE ##FightStatus

INSERT ##FightStatus (RoundNr, PlayerHealth, PlayerMana, BossHealth, ShieldActive, PoisonActive, RechargeActive, ManaSpent, SpellsPath) VALUES (0, 50, 500, 55, 0, 0, 0, 0, '')

SET @Round = 0

WHILE NOT EXISTS (SELECT 1 FROM ##FightStatus WHERE BossHealth <= 0) AND @Round < 25
BEGIN

    -- Change for part 2
    UPDATE ##FightStatus SET PlayerHealth = PlayerHealth - 1 WHERE RoundNr = @Round 

    SET @Round = @Round + 1
   
    INSERT ##FightStatus (RoundNr, PlayerHealth, PlayerMana, BossHealth, ShieldActive, PoisonActive, RechargeActive, ManaSpent, SpellsPath)
    SELECT @Round
    ,      F.PlayerHealth + S.Health AS PlayerHealth                                          -- If we just cast Drain
    ,      F.PlayerMana - S.ManaCost + CASE WHEN F.RechargeActive > 1                         -- Has recharge been cast? 
                                            THEN @RechargeValue                               -- We recharge twice (once during player turn and once during boss turn)
                                            ELSE 0
                                        END AS PlayerMana
    ,      F.BossHealth - S.Damage - CASE WHEN F.PoisonActive > 1                             -- Has poison (just) been cast? 
                                          THEN @PoisonValue 
                                          ELSE 0 
                                          END AS BossHealth
    ,      CASE WHEN S.Name = 'Shield' 
                THEN S.Duration + 1                 --Correction because SQL does everything at once
                ELSE CASE WHEN F.ShieldActive > 0
                          THEN F.ShieldActive - 1
                          ELSE 0 END
                END AS ShieldActive
    ,      CASE WHEN S.Name = 'Poison' 
                THEN S.Duration + 1                  --Correction because SQL does everything at once
                ELSE CASE WHEN F.PoisonActive > 0 
                          THEN F.PoisonActive - 1
                          ELSE 0 END                
                END AS PoisonActive
    ,      CASE WHEN S.Name = 'Recharge' 
                THEN S.Duration + 1                 --Correction because SQL does everything at once
                ELSE CASE WHEN F.RechargeActive > 0 
                          THEN F.RechargeActive - 1
                          ELSE 0 END
                END AS RechargeActive
    ,      ManaSpent + S.ManaCost AS ManaSpent
    ,      SpellsPath + ' | ' + S.Name
    FROM ##FightStatus F
    CROSS APPLY ##Spells S
    WHERE NOT ((F.PoisonActive > 2 AND S.Name = 'Poison') OR
               (F.ShieldActive > 1 AND S.Name = 'Shield') OR
               (F.RechargeActive > 1 AND S.Name = 'Recharge'))
               
    DELETE FROM ##FightStatus WHERE PlayerHealth <= 0 OR PlayerMana <= 0
    DELETE FROM ##FightStatus WHERE RoundNr = @Round - 1


    SET @Round = @Round + 1

    UPDATE F
    SET RoundNr = @Round
    ,   PlayerHealth = F.PlayerHealth - CASE WHEN F.ShieldActive > 1                          -- Is the shield activated?
                                             THEN CASE WHEN @ShieldValue - @BossDamage > 1    -- Does the boss do more damage than our shield
                                                       THEN @ShieldValue - @BossDamage        -- Take the difference in damage
                                                       ELSE 1 END                             -- Always take at least 1 damage
                                             ELSE @BossDamage END                             -- Take the full boss damage
    ,  PlayerMana = F.PlayerMana + CASE WHEN F.RechargeActive > 1                             -- Has recharge been cast? 
                                        THEN @RechargeValue                                   -- We recharge twice (once during player turn and once during boss turn)
                                        ELSE 0
                                        END 
    ,  BossHealth = F.BossHealth - CASE WHEN F.PoisonActive > 1                               -- Has poison (just) been cast? 
                                          THEN @PoisonValue 
                                          ELSE 0 
                                          END 
    ,  ShieldActive = CASE WHEN F.ShieldActive > 0
                           THEN F.ShieldActive - 1
                           ELSE 0 END
    ,  PoisonActive = CASE WHEN F.PoisonActive > 0 
                           THEN F.PoisonActive - 1
                           ELSE 0 END                
    ,  RechargeActive = CASE WHEN F.RechargeActive > 0 
                             THEN F.RechargeActive - 1
                             ELSE 0 END
    FROM ##FightStatus F
    WHERE BossHealth > 0 AND RoundNr = @Round - 1

    DELETE FROM ##FightStatus WHERE PlayerHealth <= 0 OR PlayerMana <= 0

    DELETE FROM ##FightStatus WHERE RoundNr = @Round - 2

    PRINT 'Round: ' + CAST(@Round AS VARCHAR(6)) 


END

SELECT MIN(ManaSpent) AS Part2 FROM ##FightStatus WHERE BossHealth <= 0

DROP TABLE ##FightStatus

DROP TABLE ##Spells



