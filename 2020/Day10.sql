USE Test_WME

SET NOCOUNT ON

CREATE TABLE ##Input (Line NVARCHAR(MAX));

BULK INSERT ##Input
FROM 'C:\Source\AdventOfCode\2020\input10.txt'
WITH (ROWTERMINATOR = '0x0A');

CREATE TABLE ##Seq (ID INT IDENTITY(1,1), Nr INT, NextNr INT)

;WITH cte_CInput AS (
    SELECT CAST(Line AS BIGINT) Nr
    FROM ##Input
    UNION SELECT 0
), cte_Seq AS (
    SELECT Nr, ISNULL(LEAD(Nr, 1) OVER (ORDER BY Nr), Nr+3) AS NextNr
    FROM cte_CInput
--    ORDER BY Nr
)
INSERT ##Seq (Nr, NextNr)
SELECT *
FROM cte_Seq

SELECT SUM(CASE WHEN NextNr-Nr = 1 THEN 1 ELSE 0 END) 
,      SUM(CASE WHEN NextNr-Nr = 3 THEN 1 ELSE 0 END) 
,      SUM(CASE WHEN NextNr-Nr = 1 THEN 1 ELSE 0 END) * SUM(CASE WHEN NextNr-Nr = 3 THEN 1 ELSE 0 END) 
FROM ##Seq

--2013 is too low
--2046 is correct for part 1

INSERT ##Seq (Nr, NextNr) SELECT MAX(Nr) + 3, NULL FROM ##Seq --Add the final port

CREATE TABLE ##Anchors (ID INT IDENTITY(1,1), Nr INT)

INSERT ##Anchors (Nr) 
SELECT NextNr
FROM ##Seq
WHERE NextNr - Nr = 3

--SELECT * FROM ##Seq
--SELECT * FROM ##Anchors

DECLARE @Counter INT = 1
DECLARE @Result BIGINT
DECLARE @RunningResult BIGINT = 1
DECLARE @Start INT = 0
DECLARE @Stop INT 

CREATE TABLE ##Result (ID INT IDENTITY(1,1), Result BIGINT)

WHILE @Counter <= (SELECT COUNT(1) FROM ##Anchors)
BEGIN
    
    SELECT @Stop = Nr FROM ##Anchors WHERE ID = @Counter

    ;WITH cte_Paths AS (
        SELECT Nr
        ,      CAST(Nr AS VARCHAR(500)) AS NrPath
        ,      CASE WHEN Nr = @Stop THEN 1 ELSE 0 END AS FullPath
        FROM ##Seq
        WHERE Nr = @Start

        UNION ALL

        SELECT S.Nr
        ,      CAST(NrPath + '|' + CAST(S.Nr AS VARCHAR(3)) AS VARCHAR(500))
        ,      CASE WHEN S.Nr = @Stop THEN 1 ELSE 0 END AS FullPath
        FROM cte_Paths cP
        INNER JOIN ##Seq S ON S.Nr - cP.Nr BETWEEN 1 AND 3
        WHERE S.Nr <= @Stop
    )
    SELECT @Result = COUNT(1) 
    FROM cte_Paths WHERE FullPath = 1

    SET @RunningResult = @Result * @RunningResult
    INSERT ##Result (Result) SELECT @Result

    SET @Start = @Stop
    SET @Counter = @Counter + 1

END

PRINT @RunningResult
SELECT * FROM ##Result
SELECT * FROM ##Anchors
SELECT * FROM ##Seq
/*

DROP TABLE ##Result
DROP TABLE ##Anchors
DROP TABLE ##Seq
DROP TABLE ##Input

*/

--165288374272 is too low
--1157018619904 is correct for part 2