SET NOCOUNT ON

--DECLARE @Input VARCHAR(10) = 'abc'
DECLARE @Input VARCHAR(10) = 'ahsbgdzn'
DECLARE @Hash CHAR(32)

--SELECT CONVERT(VARCHAR(32), HASHBYTES('MD5', 'abc22728'), 2)

DECLARE @Counter BIGINT = 0
DECLARE @CurrentID INT
DECLARE @Letter CHAR 
DECLARE @HashCounter INT = 0

CREATE TABLE ##Keys (ID INT IDENTITY(1,1), Input VARCHAR(20), Hash VARCHAR(32), ThreeTimes CHAR)
CREATE TABLE ##5Seq (ID INT IDENTITY(1,1), KeyID INT, FiveTimes CHAR)

CREATE TABLE ##ValidKeys (ID INT IDENTITY(1,1), KeyID INT)


WHILE (SELECT COUNT(1) FROM ##ValidKeys) < 64 --AND @Counter < 25000
BEGIN
    
    SET @Letter = NULL
    
    SELECT @Hash = LOWER(CONVERT(CHAR(32), HASHBYTES('MD5', @Input + CAST(@Counter AS VARCHAR(15))), 2))

    SET @HashCounter = 0

    WHILE @HashCounter < 2016
    BEGIN
        SELECT @Hash = LOWER(CONVERT(CHAR(32), HASHBYTES('MD5', @Hash), 2))
        SET @HashCounter = @HashCounter + 1
    END

    ;WITH cte_Letters AS (
    SELECT 0 AS Similar
    ,      LEFT(@Hash, 1) AS Letter
    ,      SUBSTRING(@Hash, 2, LEN(@Hash)) AS Remainder
    UNION ALL
    SELECT CASE WHEN LEFT(Remainder, 1) = Letter THEN Similar + 1 ELSE 0 END
    ,      LEFT(Remainder, 1)
    ,      SUBSTRING(Remainder, 2, LEN(Remainder)) 
    FROM cte_Letters
    WHERE LEN(Remainder) > 0 AND Similar < 2
    )
    SELECT @Letter = Letter FROM cte_Letters WHERE Similar = 2

    INSERT ##Keys (Input, Hash, ThreeTimes) SELECT @Input + CAST(@Counter AS VARCHAR(15)), @Hash, @Letter 

    SET @CurrentID = @@IDENTITY

    ;WITH cte_Letters AS (
    SELECT 0 AS Similar
    ,      LEFT(@Hash, 1) AS Letter
    ,      SUBSTRING(@Hash, 2, LEN(@Hash)) AS Remainder
    UNION ALL
    SELECT CASE WHEN LEFT(Remainder, 1) = Letter THEN Similar + 1 ELSE 0 END
    ,      LEFT(Remainder, 1)
    ,      SUBSTRING(Remainder, 2, LEN(Remainder)) 
    FROM cte_Letters
    WHERE LEN(Remainder) > 0
    )
    INSERT ##5Seq (KeyID, FiveTimes) SELECT @CurrentID, Letter FROM cte_Letters WHERE Similar >= 4

    INSERT ##ValidKeys (KeyID)
    SELECT DISTINCT K.ID
    FROM ##5Seq T
    INNER JOIN ##Keys K ON T.FiveTimes = K.ThreeTimes AND T.KeyID - K.ID BETWEEN 1 AND 1000
    LEFT JOIN ##ValidKeys VK ON VK.KeyID = K.ID
    WHERE T.KeyID = @CurrentID AND VK.ID IS NULL 
    ORDER BY K.ID
    
    SET @Counter = @Counter + 1

END


--SELECT * FROM ##Keys ORDER BY ID
--SELECT * FROM ##5Seq
--SELECT * FROM ##ValidKeys ORDER BY KeyID

/*

DROP TABLE ##Keys
DROP TABLE ##5Seq
DROP TABLE ##ValidKeys

*/

--96906 too high
--23974 too high
--23890 is goed (Maar waarom het bij mij key 63 is :?

-- 22761 for part 2 too high
-- 22696 is correct (for part 2)

/*
--SELECT * FROM ##Keys WHERE ThreeTimes IS NOT NULL ORDER BY ID
SELECT * FROM ##ValidKeys VK
INNER JOIN ##Keys K ON VK.KeyID = K.ID ORDER BY 1
SELECT * FROM ##5Seq



Andere opties voor part 2 of we proberen eerst weer het voorbeeld te reproduceren

*/


