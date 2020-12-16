USE Test_WME

SET NOCOUNT ON

CREATE TABLE ##Input (Line NVARCHAR(MAX));

BULK INSERT ##Input
FROM 'C:\Source\AdventOfCode\2020\input16.txt'
WITH (ROWTERMINATOR = '0x0A');


CREATE TABLE ##TicketFields (ID INT IDENTITY(1,1), FieldName VARCHAR(100), Range1Low INT, Range1High INT, Range2Low INT, Range2High INT)

CREATE TABLE ##Tickets (ID INT IDENTITY(1,1), TicketNr INT, FieldNr INT, Val INT)

;WITH cte_CutUpFields AS (
    SELECT TOP 20 TRIM(LEFT(Line, CHARINDEX(':', Line) - 1)) AS FieldName
    , TRIM(SUBSTRING(Line, CHARINDEX(':', Line) + 1, CHARINDEX(' or ', Line) - CHARINDEX(':', Line))) AS Range1
    , TRIM(SUBSTRING(Line, CHARINDEX(' or ', Line) + 3, LEN(Line))) AS Range2
    , Line
    FROM ##Input
)
INSERT ##TicketFields (FieldName, Range1Low, Range1High, Range2Low, Range2High)
SELECT FieldName
,      LEFT(Range1, CHARINDEX('-', Range1) - 1) AS Range1Low
,      SUBSTRING(Range1, CHARINDEX('-', Range1) + 1, LEN(Range1)) AS Range1High
,      LEFT(Range2, CHARINDEX('-', Range2) - 1) AS Range2Low
,      SUBSTRING(Range2, CHARINDEX('-', Range2) + 1, LEN(Range2)) AS Range2High
FROM cte_CutUpFields


;WITH cte_TicketData AS (
    SELECT ROW_NUMBER() OVER (ORDER BY (SELECT 0)) AS TicketNr
    ,      1 AS FieldNr
    ,      LEFT(Line, CHARINDEX(',',Line) - 1) AS FieldVal
    ,      SUBSTRING(Line, CHARINDEX(',',Line) + 1, LEN(Line)) AS LeftOver
    FROM ##Input
    WHERE LEFT(Line, 1) IN ('0','1','2','3','4','5','6','7','8','9')

    UNION ALL

    SELECT TicketNr
    ,      FieldNr + 1
    ,      CASE WHEN CHARINDEX(',',LeftOver) > 1 THEN LEFT(LeftOver, CHARINDEX(',',LeftOver) - 1) ELSE LeftOver END
    ,      CASE WHEN CHARINDEX(',',LeftOver) > 1 THEN SUBSTRING(LeftOver, CHARINDEX(',',LeftOver) + 1, LEN(LeftOver)) ELSE '' END    
    FROM cte_TicketData
    WHERE LEN(LeftOver) > 0
)
INSERT ##Tickets (TicketNr, FieldNr, Val)
SELECT TicketNr, FieldNr, FieldVal
FROM cte_TicketData

SELECT SUM(Val)
FROM ##Tickets T
LEFT JOIN ##TicketFields TF ON (T.Val BETWEEN TF.Range1Low AND TF.Range1High)
                            OR (T.Val BETWEEN TF.Range2Low AND TF.Range2High)
WHERE TF.ID IS NULL

--27802 is correct for part 1

DELETE FROM ##Tickets 
WHERE TicketNr IN (SELECT DISTINCT TicketNr
                     FROM ##Tickets T
                     LEFT JOIN ##TicketFields TF ON (T.Val BETWEEN TF.Range1Low AND TF.Range1High)
                                                 OR (T.Val BETWEEN TF.Range2Low AND TF.Range2High)
                     WHERE TF.ID IS NULL
                     )


ALTER TABLE ##Tickets ADD FieldName VARCHAR(100)

CREATE TABLE ##ValidCombos (ID INT IDENTITY(1,1), FieldNr INT, FieldName VARCHAR(100))

;WITH cte_InvalidCombos AS (
       SELECT T.FieldNr, TF.FieldName
       FROM ##Tickets T
       INNER JOIN ##TicketFields TF ON T.Val > Range1High AND T.Val < TF.Range2Low
), cte_AllCombos AS (
    SELECT TF.FieldName, T.FieldNr
    FROM ##Tickets T
    CROSS APPLY ##TicketFields TF
    GROUP BY TF.FieldName, T.FieldNr
)
INSERT ##ValidCombos (FieldNr, FieldName)
SELECT cAC.FieldNr, cAC.FieldName
FROM cte_AllCombos cAC
LEFT JOIN cte_InvalidCombos cIC ON cAC.FieldNr = cIC.FieldNr AND cAC.FieldName = cIC.FieldName
WHERE cIC.FieldNr IS NULL



WHILE (SELECT COUNT(1) FROM ##Tickets WHERE FieldName IS NULL) > 0
BEGIN

    ;WITH cte_UniqueNr AS (
        SELECT FieldNr
        FROM ##ValidCombos
        GROUP BY FieldNr
        HAVING COUNT(1) = 1
    ), cte_UniqueFieldName AS (
        SELECT FieldName
        FROM ##ValidCombos
        GROUP BY FieldName
        HAVING COUNT(1) = 1
    ), cte_Updateable AS (
        SELECT VC.FieldNr, VC.FieldName
        FROM ##ValidCombos VC
        INNER JOIN cte_UniqueNr cU ON cU.FieldNr = VC.FieldNr
        
        UNION 

        SELECT VC.FieldNr, VC.FieldName
        FROM ##ValidCombos VC
        INNER JOIN cte_UniqueFieldName cU ON cU.FieldName = VC.FieldName
    )
    UPDATE T
    SET T.FieldName = cU.FieldName
    FROM ##Tickets T
    INNER JOIN cte_Updateable cU ON T.FieldNr = cU.FieldNr

    DELETE FROM ##ValidCombos
    WHERE FieldName IN (SELECT DISTINCT FieldName FROM ##Tickets WHERE FieldName IS NOT NULL)

END

/*

DROP TABLE ##ValidCombos
DROP TABLE ##TicketFields
DROP TABLE ##Tickets
DROP TABLE ##Input

*/


SELECT *
FROM ##Tickets 
WHERE TicketNr = 1
AND FieldName LIKE 'departure%'

SELECT CAST(67 AS BIGINT)*139*127*53*73*61
