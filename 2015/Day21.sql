/*
Items available in the shop

Weapons:    Cost  Damage  Armor
Dagger        8     4       0
Shortsword   10     5       0
Warhammer    25     6       0
Longsword    40     7       0
Greataxe     74     8       0

Armor:      Cost  Damage  Armor
Leather      13     0       1
Chainmail    31     0       2
Splintmail   53     0       3
Bandedmail   75     0       4
Platemail   102     0       5

Rings:      Cost  Damage  Armor
Damage +1    25     1       0
Damage +2    50     2       0
Damage +3   100     3       0
Defense +1   20     0       1
Defense +2   40     0       2
Defense +3   80     0       3
*/

CREATE TABLE ##Items (ID INT IDENTITY(1,1), Name VARCHAR(25), Type VARCHAR(10), Cost INT, Damage INT, Armor INT)

INSERT ##Items (Name, Type, Cost, Damage, Armor) VALUES
('Dagger',     'Weapon', 8,   4, 0),
('Shortsword', 'Weapon', 10,  5, 0),
('Warhammer',  'Weapon', 25,  6, 0),
('Longsword',  'Weapon', 40,  7, 0),
('Greataxe',   'Weapon', 74,  8, 0),
('Leather',    'Armor',  13,  0, 1),
('Chainmail',  'Armor',  31,  0, 2),
('Splintmail', 'Armor',  53,  0, 3),
('Bandedmail', 'Armor',  75,  0, 4),
('Platemail',  'Armor',  102, 0, 5),
('Damage +1',  'Ring',   25,  1, 0),
('Damage +2',  'Ring',   50,  2, 0),
('Damage +3',  'Ring',   100, 3, 0),
('Defense +1', 'Ring',   20,  0, 1),
('Defense +2', 'Ring',   40,  0, 2),
('Defense +3', 'Ring',   80,  0, 3)


--SELECT * FROM ##Items

CREATE TABLE ##Heroes (ID INT IDENTITY(1,1), Weapon VARCHAR(25), Armor VARCHAR(25), Ring1 VARCHAR(25), Ring2 VARCHAR(25), 
                       Cost INT, Damage INT, Defense INT, Wins INT)

-- Create a list of all possible outfits. And calculate the damage and defense values
;WITH cte_Weapons AS (
    SELECT Name
    FROM ##Items
    WHERE Type = 'Weapon'
), cte_Armor AS (
    SELECT Name
    FROM ##Items
    WHERE Type = 'Armor'
    UNION SELECT NULL
), cte_Rings AS (
    SELECT Name
    FROM ##Items
    WHERE Type = 'Ring'
    UNION SELECT NULL
)
INSERT ##Heroes (Weapon, Armor, Ring1, Ring2, Cost, Damage, Defense)
SELECT IW.Name
,      IA.Name
,      IR1.Name
,      IR2.Name
,      ISNULL(IW.Cost, 0) + ISNULL(IA.Cost, 0) + ISNULL(IR1.Cost, 0) + ISNULL(IR2.Cost, 0)
,      ISNULL(IW.Damage, 0) + ISNULL(IA.Damage, 0) + ISNULL(IR1.Damage, 0) + ISNULL(IR2.Damage, 0)
,      ISNULL(IW.Armor, 0) + ISNULL(IA.Armor, 0) + ISNULL(IR1.Armor, 0) + ISNULL(IR2.Armor, 0)
FROM cte_Weapons W
LEFT JOIN ##Items IW ON W.Name = IW.Name
OUTER APPLY cte_Armor A
LEFT JOIN ##Items IA ON A.Name = IA.Name
OUTER APPLY cte_Rings R1
LEFT JOIN ##Items IR1 ON R1.Name = IR1.Name
OUTER APPLY cte_Rings R2
LEFT JOIN ##Items IR2 ON R2.Name = IR2.Name
WHERE R1.Name <> R2.Name
    OR R1.Name IS NULL
    OR R2.Name IS NULL

--SELECT * FROM ##Heroes

--The number of rounds to defeat the boss (or defeat the hero) are independent of eachother
--So calculate the number of rounds the hero will need
--And calculate the number of rounds the boss will need
--The one with the least number of rounds will win (with ties going to the hero)

DECLARE @PlayerHitPoints INT = 100
DECLARE @MinimumDamage INT = 1

DECLARE @BossHitPoints INT = 109
DECLARE @BossDamage INT = 8
DECLARE @BossArmor INT = 2

UPDATE ##Heroes
SET Wins =
 CASE WHEN 
       @BossHitPoints / (CASE WHEN Damage - @BossArmor < 1 THEN 1 ELSE Damage - @BossArmor END)
       + CASE WHEN @BossHitPoints % (CASE WHEN Damage - @BossArmor < 1 THEN 1 ELSE Damage - @BossArmor END) = 0 THEN 0 ELSE 1 END
    <      
       @PlayerHitPoints / (CASE WHEN @BossDamage - Defense < 1 THEN 1 ELSE @BossDamage - Defense END)
       + CASE WHEN @PlayerHitPoints % (CASE WHEN @BossDamage - Defense < 1 THEN 1 ELSE @BossDamage - Defense END) = 0 THEN 0 ELSE 1 END
    THEN 1
    ELSE 0
    END
FROM ##Heroes


SELECT TOP 1 Cost AS Part1 FROM ##Heroes WHERE Wins = 1 ORDER BY Cost

SELECT TOP 1 Cost AS Part2 FROM ##Heroes WHERE Wins = 0 ORDER BY Cost DESC

DROP TABLE ##Heroes
DROP TABLE ##Items