use Test_WME

SET NOCOUNT ON

CREATE TABLE ##Input (Line NVARCHAR(MAX));

BULK INSERT ##Input
FROM 'C:\Users\a-wilfred.meyboom\Documents\SQL Server Management Studio\AoC\input21.txt'
WITH (ROWTERMINATOR = '0x0A');


CREATE TABLE ##Ingredients (ID INT IDENTITY(1,1), DishNr INT, IngrNr INT, IngrName VARCHAR(20))
CREATE TABLE ##Allergens (ID INT IDENTITY(1,1), DishNr INT, AllergenNr INT, AllergenName VARCHAR(20))

DECLARE @Counter INT = 1
DECLARE @NrOfDishes INT 
DECLARE @IngredientList VARCHAR(1500)
DECLARE @AllergenList VARCHAR(1500)

SELECT @NrOfDishes = COUNT(Line) FROM ##Input

WHILE @Counter <= @NrOfDishes
BEGIN

    SELECT TOP 1 @IngredientList = LEFT(Line, CHARINDEX('(', Line) - 2)
    ,      @AllergenList = REPLACE(SUBSTRING(Line, CHARINDEX('(', Line) + 10, LEN(Line)), ')','')
    FROM ##Input

    DELETE TOP (1) FROM ##Input
    
    INSERT ##Ingredients (DishNr, IngrNr, IngrName)
    SELECT @Counter, ROW_NUMBER() OVER (ORDER BY (SELECT 0)), LTRIM(RTRIM(Value)) FROM string_split(@IngredientList, ' ')

    PRINT @AllergenList
    INSERT ##Allergens (DishNr, AllergenNr, AllergenName)
    SELECT @Counter, ROW_NUMBER() OVER (ORDER BY (SELECT 0)), LTRIM(RTRIM(Value)) FROM string_split(@AllergenList, ',') 

    SET @Counter = @Counter + 1
END

SELECT DishNr, IngrName FROM ##Ingredients GROUP BY DishNr, IngrName HAVING COUNT(1) > 1
--> No duplicate ingredients in a dish


-- These ingredient / allergen combi's are not possible because we have two dishes with the same allergen but the ingredient is not present in both
;WITH cte_AllCombis AS (
    SELECT I.IngrName, A.AllergenName
    FROM ##Ingredients I
    INNER JOIN ##Allergens A ON I.DishNr = A.DishNr
), cte_InvalidCombis AS (
    SELECT I.IngrName, A.AllergenName
    FROM ##Ingredients I
    INNER JOIN ##Allergens A ON I.DishNr = A.DishNr
    INNER JOIN ##Allergens A2 ON A.AllergenName = A2.AllergenName AND A.DishNr <> A2.DishNr
    LEFT JOIN ##Ingredients I2 ON A2.DishNr = I2.DishNr AND I.IngrName = I2.IngrName
    WHERE I2.ID IS NULL
    GROUP BY I.IngrName, A.AllergenName
), cte_DangerousIngr AS (
    SELECT DISTINCT c1.IngrName
    FROM cte_AllCombis c1
    LEFT JOIN cte_InvalidCombis c2 ON c1.IngrName = c2.IngrName AND c1.AllergenName = c2.AllergenName
    WHERE c2.IngrName IS NULL
    --ORDER BY IngrName
)
SELECT *
FROM ##Ingredients
WHERE IngrName NOT IN (SELECT IngrName FROM cte_DangerousIngr)




--2267 is too low for part 1
--2287 is correct for part 1

SELECT DISTINCT AllergenName FROM ##Allergens

;WITH cte_AllCombis AS (
    SELECT I.IngrName, A.AllergenName
    FROM ##Ingredients I
    INNER JOIN ##Allergens A ON I.DishNr = A.DishNr
), cte_InvalidCombis AS (
    SELECT I.IngrName, A.AllergenName
    FROM ##Ingredients I
    INNER JOIN ##Allergens A ON I.DishNr = A.DishNr
    INNER JOIN ##Allergens A2 ON A.AllergenName = A2.AllergenName AND A.DishNr <> A2.DishNr
    LEFT JOIN ##Ingredients I2 ON A2.DishNr = I2.DishNr AND I.IngrName = I2.IngrName
    WHERE I2.ID IS NULL
    GROUP BY I.IngrName, A.AllergenName
)
SELECT DISTINCT c1.IngrName
INTO ##DangerousIngr
FROM cte_AllCombis c1
LEFT JOIN cte_InvalidCombis c2 ON c1.IngrName = c2.IngrName AND c1.AllergenName = c2.AllergenName
WHERE c2.IngrName IS NULL


;WITH cte_IngrAllerCombi AS (
    SELECT IngrName, AllergenName
    FROM ##Ingredients I
    INNER JOIN ##Allergens A ON I.DishNr = A.DishNr
    WHERE IngrName IN (SELECT IngrName FROM ##DangerousIngr)
    GROUP BY IngrName, AllergenName
), cte_InvalidCombis AS (
    SELECT I.IngrName, A.AllergenName
    FROM ##Ingredients I
    INNER JOIN ##Allergens A ON I.DishNr = A.DishNr
    INNER JOIN ##Allergens A2 ON A.AllergenName = A2.AllergenName AND A.DishNr <> A2.DishNr
    LEFT JOIN ##Ingredients I2 ON A2.DishNr = I2.DishNr AND I.IngrName = I2.IngrName
    WHERE I2.ID IS NULL
      AND I.IngrName IN (SELECT IngrName FROM ##DangerousIngr)
    GROUP BY I.IngrName, A.AllergenName
)
SELECT c1.IngrName, c1.AllergenName
INTO ##ValidIngrCombis
FROM cte_IngrAllerCombi c1
LEFT JOIN cte_InvalidCombis c2 ON c1.IngrName = c2.IngrName AND c1.AllergenName = c2.AllergenName
WHERE c2.IngrName IS NULL


ALTER TABLE ##ValidIngrCombis ADD Validated INT 


--SELECT * FROM ##ValidIngrCombis

WHILE (SELECT COUNT(1) FROM ##ValidIngrCombis WHERE Validated IS NULL) > 0
BEGIN
    
    ;WITH cte_Ingr AS (
        SELECT IngrName 
        FROM ##ValidIngrCombis 
        WHERE Validated IS NULL
        GROUP BY IngrName HAVING COUNT(1) = 1
    )
    UPDATE ##ValidIngrCombis
    SET Validated = 1
    WHERE IngrName IN (SELECT IngrName FROM cte_Ingr)
     AND Validated IS NULL

    DELETE 
    FROM ##ValidIngrCombis
    WHERE Validated IS NULL
    AND AllergenName IN (SELECT AllergenName FROM ##ValidIngrCombis WHERE Validated = 1)

    ;WITH cte_Allergen AS (
        SELECT AllergenName 
        FROM ##ValidIngrCombis 
        WHERE Validated IS NULL
        GROUP BY AllergenName HAVING COUNT(1) = 1
    )
    UPDATE ##ValidIngrCombis
    SET Validated = 1
    WHERE AllergenName IN (SELECT AllergenName FROM cte_Allergen)
      AND Validated IS NULL

    DELETE 
    FROM ##ValidIngrCombis
    WHERE Validated IS NULL
    AND IngrName IN (SELECT IngrName FROM ##ValidIngrCombis WHERE Validated = 1)
        

END

SELECT * FROM ##ValidIngrCombis ORDER BY AllergenName


-- fntg,fvjkp,gtqfrp,jtjtrd,rlsr,xlvrggj,xpbxbv,zhszc is incorrect for part 2
-- fntg,gtqfrp,jtjtrd,xlvrggj,rlsr,xpbxbv,fvjkp,zhszc is incorrect for part 2
-- fntg,gtqfrp,xlvrggj,rlsr,xpbxbv,jtjtrd,fvjkp,zhszc is correct for part 2

/*

DROP TABLE ##ValidIngrCombis
DROP TABLE ##DangerousIngr
DROP TABLE ##Ingredients
DROP TABLE ##Allergens
DROP TABLE ##Input


*/

