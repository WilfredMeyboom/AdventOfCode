USE Test_WME

SET NOCOUNT ON

DECLARE @year VARCHAR(4) = '2015'
DECLARE @day VARCHAR(2)  = '15'

EXEC dbo.GetInput @year = @year, @day = @day
EXEC dbo.ParseInput @year = @year, @day = @day

CREATE TABLE ##Ingredients (ID INT IDENTITY(1,1), Name VARCHAR(20), Capacity INT, Durability INT, Flavor INT, Texture INT, Calories INT)

INSERT ##Ingredients (Name, Capacity, Durability, Flavor, Texture, Calories)
SELECT [1],[3],[5],[7],[9],[11] FROM (
    SELECT RowNr, PieceNr, Piece FROM ##InputSplit WHERE PieceNr IN (1,3,5,7,9,11)
) T
PIVOT (
    MAX(Piece) FOR PieceNr IN ([1],[3],[5],[7],[9],[11])
) PVT


CREATE TABLE ##Cookies (ID INT IDENTITY(1,1), Sprinkles INT, PeanutButter INT, Frosting INT, Sugar INT)

CREATE TABLE ##CookieValues (ID INT, Score BIGINT, Calories BIGINT)

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
INSERT ##CookieValues (ID, Score, Calories)
SELECT ID
,      CASE WHEN SUM(cC.Capacity)   > 0 THEN SUM(cC.Capacity)   ELSE 0 END 
    *  CASE WHEN SUM(cC.Durability) > 0 THEN SUM(cC.Durability) ELSE 0 END 
    *  CASE WHEN SUM(cC.Flavor)     > 0 THEN SUM(cC.Flavor)     ELSE 0 END 
    *  CASE WHEN SUM(cC.Texture)    > 0 THEN SUM(cC.Texture)    ELSE 0 END 
,      SUM(cC.Calories)
FROM cte_Combined cC
GROUP BY ID


SELECT TOP 1 Score AS Part1
FROM ##CookieValues
ORDER BY Score DESC

SELECT TOP 1 Score AS Part2
FROM ##CookieValues
WHERE Calories = 500
ORDER BY Score DESC


DROP TABLE ##CookieValues
DROP TABLE ##Cookies
DROP TABLE ##Ingredients

