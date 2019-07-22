USE Test_WME

/*
Sprinkles: capacity 5, durability -1, flavor 0, texture 0, calories 5
PeanutButter: capacity -1, durability 3, flavor 0, texture 0, calories 1
Frosting: capacity 0, durability -1, flavor 4, texture 0, calories 6
Sugar: capacity -1, durability 0, flavor 0, texture 2, calories 8
*/


CREATE TABLE ##Ingredients (ID INT IDENTITY(1,1), Name VARCHAR(20), Capacity INT, Durability INT, Flavor INT, Texture INT, Calories INT)

INSERT ##Ingredients (Name, Capacity, Durability, Flavor, Texture, Calories) VALUES 
('Sprinkles',    5, -1, 0, 0, 5),
('PeanutButter',-1,  3, 0, 0, 1),
('Frosting',     0, -1, 4, 0, 6),
('Sugar',       -1,  0, 0, 2, 8)

CREATE TABLE ##Cookies (ID INT IDENTITY(1,1), Sprinkles INT, PeanutButter INT, Frosting INT, Sugar INT)


;WITH cte_Nrs AS (
    SELECT TOP 101 ROW_NUMBER() OVER (ORDER BY (SELECT 0)) - 1 AS Nr FROM sys.messages
)
INSERT ##Cookies (Sprinkles, PeanutButter, Frosting, Sugar)
SELECT Nr1.Nr, Nr2.Nr, Nr3.Nr, Nr4.Nr
FROM cte_Nrs Nr1
CROSS APPLY cte_Nrs Nr2
CROSS APPLY cte_Nrs Nr3
CROSS APPLY cte_Nrs Nr4
WHERE Nr1.Nr + Nr2.Nr + Nr3.Nr + Nr4.Nr = 100


;WITH cte_Combined AS (
    SELECT C.ID
    ,      CASE WHEN I.Name = 'Sprinkles'    THEN C.Sprinkles    * I.Capacity
                WHEN I.Name = 'PeanutButter' THEN C.PeanutButter * I.Capacity
                WHEN I.Name = 'Frosting'     THEN C.Frosting     * I.Capacity
                WHEN I.Name = 'Sugar'        THEN C.Sugar        * I.Capacity
                ELSE 0
           END AS Capacity
    ,      CASE WHEN I.Name = 'Sprinkles'    THEN C.Sprinkles    * I.Durability
                WHEN I.Name = 'PeanutButter' THEN C.PeanutButter * I.Durability
                WHEN I.Name = 'Frosting'     THEN C.Frosting     * I.Durability
                WHEN I.Name = 'Sugar'        THEN C.Sugar        * I.Durability
                ELSE 0
           END AS Durability
    ,      CASE WHEN I.Name = 'Sprinkles'    THEN C.Sprinkles    * I.Flavor
                WHEN I.Name = 'PeanutButter' THEN C.PeanutButter * I.Flavor
                WHEN I.Name = 'Frosting'     THEN C.Frosting     * I.Flavor
                WHEN I.Name = 'Sugar'        THEN C.Sugar        * I.Flavor
                ELSE 0
           END AS Flavor
    ,      CASE WHEN I.Name = 'Sprinkles'    THEN C.Sprinkles    * I.Texture
                WHEN I.Name = 'PeanutButter' THEN C.PeanutButter * I.Texture
                WHEN I.Name = 'Frosting'     THEN C.Frosting     * I.Texture
                WHEN I.Name = 'Sugar'        THEN C.Sugar        * I.Texture
                ELSE 0
           END AS Texture
    ,      CASE WHEN I.Name = 'Sprinkles'    THEN C.Sprinkles    * I.Calories
                WHEN I.Name = 'PeanutButter' THEN C.PeanutButter * I.Calories
                WHEN I.Name = 'Frosting'     THEN C.Frosting     * I.Calories
                WHEN I.Name = 'Sugar'        THEN C.Sugar        * I.Calories
                ELSE 0
           END AS Calories
    FROM ##Cookies C
    CROSS APPLY ##Ingredients I
)
SELECT ID
,      CASE WHEN SUM(cC.Capacity)   > 0 THEN SUM(cC.Capacity)   ELSE 0 END 
    *  CASE WHEN SUM(cC.Durability) > 0 THEN SUM(cC.Durability) ELSE 0 END 
    *  CASE WHEN SUM(cC.Flavor)     > 0 THEN SUM(cC.Flavor)     ELSE 0 END 
    *  CASE WHEN SUM(cC.Texture)    > 0 THEN SUM(cC.Texture)    ELSE 0 END 
,      SUM(cC.Calories)
FROM cte_Combined cC
GROUP BY ID
HAVING SUM(cC.Calories) = 500 --Part 2
ORDER BY 2 DESC

--13882464 is correct for part 1
--11171160 is correct for part 2

/*
DROP TABLE ##Cookies
DROP TABLE ##Ingedients

*/