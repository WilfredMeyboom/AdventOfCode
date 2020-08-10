DECLARE @Input BIGINT = 846601

DECLARE @RequiredSize BIGINT = @Input + 10
--SET @RequiredSize = 20

CREATE TABLE ##Recipes (ID INT IDENTITY(0,1), Score INT)

ALTER TABLE ##Recipes ADD CONSTRAINT pkRecipes PRIMARY KEY (ID)

INSERT ##Recipes (Score) VALUES (3),(7)

DECLARE @PosElf1 BIGINT = 0
DECLARE @PosElf2 BIGINT = 1
DECLARE @RecipeElf1 INT
DECLARE @RecipeElf2 INT
DECLARE @NewRecipe INT
DECLARE @RecipesSize BIGINT

SET @RecipesSize = 2

DECLARE @SkipPart1 INT = 1

IF @SkipPart1 = 0
BEGIN

WHILE @RecipesSize < @RequiredSize
BEGIN

    SELECT @RecipeElf1 = Score FROM ##Recipes WHERE ID = @PosElf1
    SELECT @RecipeElf2 = Score FROM ##Recipes WHERE ID = @PosElf2

    SET @NewRecipe = @RecipeElf1 + @RecipeElf2

    IF @NewRecipe < 10
    BEGIN
        INSERT ##Recipes (Score) VALUES (@NewRecipe)
        SET @RecipesSize = @RecipesSize + 1
    END
    ELSE
    BEGIN
        INSERT ##Recipes (Score) VALUES (1), (@NewRecipe - 10)
        SET @RecipesSize = @RecipesSize + 2
    END
    
    SET @PosElf1 = (@PosElf1 + @RecipeElf1 + 1) % @RecipesSize
    SET @PosElf2 = (@PosElf2 + @RecipeElf2 + 1) % @RecipesSize

END

SELECT * FROM ##Recipes WHERE ID > 846600

--3811491411 is correct for part 1

END


CREATE TABLE ##Solution (Ind INT, Sol INT)

;WITH cte_Sol AS (
    SELECT 1 AS Ind
    ,      LEFT(CAST(@Input AS VARCHAR(10)), 1) AS Sol
    ,      SUBSTRING(CAST(@Input AS VARCHAR(10)), 2, LEN(CAST(@Input AS VARCHAR(10)))) AS Remainder
    UNION ALL
    SELECT Ind + 1
    ,      LEFT(Remainder, 1) AS Sol
    ,      SUBSTRING(Remainder, 2, LEN(CAST(@Input AS VARCHAR(10)))) AS Remainder
    FROM cte_Sol
    WHERE LEN(Remainder) > 0
)
INSERT ##Solution (Ind, Sol)
SELECT Ind, Sol FROM cte_Sol

DECLARE @SolutionIndex INT = 1
DECLARE @CurrentSolutionDigit INT
DECLARE @FirstDigit INT
DECLARE @SolutionLen INT

SELECT @CurrentSolutionDigit = Sol FROM ##Solution WHERE Ind = @SolutionIndex
SET @FirstDigit = @CurrentSolutionDigit
SELECT @SolutionLen = COUNT(1) FROM ##Solution

DECLARE @RecipeScoreFound INT = 0

WHILE @RecipeScoreFound = 0
BEGIN

    SELECT @RecipeElf1 = Score FROM ##Recipes WHERE ID = @PosElf1
    SELECT @RecipeElf2 = Score FROM ##Recipes WHERE ID = @PosElf2

    SET @NewRecipe = @RecipeElf1 + @RecipeElf2

    IF @NewRecipe < 10
    BEGIN
        INSERT ##Recipes (Score) VALUES (@NewRecipe)
        SET @RecipesSize = @RecipesSize + 1

        IF @NewRecipe = @CurrentSolutionDigit
        BEGIN

            SET @SolutionIndex = @SolutionIndex + 1
            IF @SolutionIndex > @SolutionLen
                SET @RecipeScoreFound = 1
            ELSE
                SELECT @CurrentSolutionDigit = Sol FROM ##Solution WHERE Ind = @SolutionIndex
            
        END
        ELSE
        BEGIN
            SET @CurrentSolutionDigit = @FirstDigit
            SET @SolutionIndex = 1
        END
    END
    ELSE
    BEGIN
        INSERT ##Recipes (Score) VALUES (1), (@NewRecipe - 10)
        SET @RecipesSize = @RecipesSize + 2
    END
    
    SET @PosElf1 = (@PosElf1 + @RecipeElf1 + 1) % @RecipesSize
    SET @PosElf2 = (@PosElf2 + @RecipeElf2 + 1) % @RecipesSize

END

-- Detection system is not working. Query stopped with 31M+ rows


    SELECT * 
    FROM ##Recipes R1
    INNER JOIN ##Recipes R2 ON R1.ID = R2.ID - 1
    INNER JOIN ##Recipes R3 ON R1.ID = R3.ID - 2
    INNER JOIN ##Recipes R4 ON R1.ID = R4.ID - 3
    INNER JOIN ##Recipes R5 ON R1.ID = R5.ID - 4
    INNER JOIN ##Recipes R6 ON R1.ID = R6.ID - 5
    WHERE R1.Score = 8
      AND R2.Score = 4
      AND R3.Score = 6
      AND R4.Score = 6
      AND R5.Score = 0
      AND R6.Score = 1

-- 20408083 is correct for part 2

/*

DROP TABLE ##Recipes
DROP TABLE ##Solution

*/