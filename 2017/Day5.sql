use Test_WME

CREATE TABLE Input (Nr NVARCHAR(MAX));

BULK INSERT Input
FROM 'D:\Wilfred\AdventOfCode\2017\input5.txt'
WITH (ROWTERMINATOR = '0x0A');


--SELECT * FROM Input 

CREATE TABLE #Nrs (ID INT IDENTITY(1,1), Nr INT)

INSERT #Nrs (Nr)
SELECT CAST(Nr AS INT) FROM Input

SELECT * FROM #Nrs

/*
DECLARE @ID INT = 1
DECLARE @Jump INT = 0
DECLARE @Step INT = 0


WHILE (@ID BETWEEN 1 AND (SELECT COUNT(1) FROM #Nrs))
BEGIN
    SET @Step = @Step + 1
    SELECT @Jump = Nr FROM #Nrs WHERE ID = @ID

    UPDATE #Nrs
    SET Nr = Nr + 1
    WHERE ID = @ID

    SET @ID = @ID + @Jump
    
END

PRINT @Step

--DROP TABLE Input
--DROP TABLE #Nrs

-- 381680
*/


DECLARE @ID INT = 1046
DECLARE @Jump INT = 3
DECLARE @Step INT = 0

WHILE (@ID BETWEEN 1 AND (SELECT COUNT(1) FROM #Nrs) AND @Step < 2500000)
BEGIN
    SET @Step = @Step + 1
    SELECT @Jump = Nr FROM #Nrs WHERE ID = @ID

    UPDATE #Nrs
    SET Nr = Nr + CASE WHEN @Jump > 2 THEN -1 ELSE 1 END
    WHERE ID = @ID

    SET @ID = @ID + @Jump
    
END

--PRINT @Id
--PRINT @Jump
--PRINT @Step

SELECT @Id AS Id, @Jump AS Jump, @Step AS Step

--Of zou het een absolute jump moeten zijn? --> Nee

-- 500000 XXXXXV
--SELECT 28.372.145
SELECT 500000*55 + 2217847