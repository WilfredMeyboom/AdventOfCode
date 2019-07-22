use Test_WME

SET NOCOUNT ON

CREATE TABLE ##Input (Line NVARCHAR(MAX));

BULK INSERT ##Input
FROM 'D:\Wilfred\AdventOfCode\2016\input04.txt'
WITH (ROWTERMINATOR = '0x0A');


CREATE TABLE ##Rooms (ID INT IDENTITY(1,1), RoomNr INT, RoomID VARCHAR(100), SectorID INT, Checksum VARCHAR(10))

INSERT ##Rooms (RoomNr, RoomID, SectorID, Checksum)
SELECT ROW_NUMBER() OVER (ORDER BY (SELECT 0)) AS RoomNr
,      SUBSTRING(Line, 1, LEN(Line) - CHARINDEX('-', REVERSE(Line))) AS RoomID
,      REVERSE(LEFT(REVERSE(SUBSTRING(Line, 1, CHARINDEX('[', Line) - 1)), CHARINDEX('-', REVERSE(SUBSTRING(Line, 1, CHARINDEX('[', Line) - 1))) - 1)) AS SectorID
,      SUBSTRING(Line, CHARINDEX('[', Line) + 1, CHARINDEX(']', Line) - CHARINDEX('[', Line) - 1) AS Checksum     
FROM ##Input

;WITH cte_Letters AS (
    SELECT RoomNr
    ,      1 AS LetterNr
    ,      LEFT(RoomID, 1) AS Letter
    ,      SUBSTRING(RoomID, 2, LEN(RoomID)) AS Remainder
    FROM ##Rooms
    UNION ALL
    SELECT RoomNr
    ,      LetterNr + 1
    ,      LEFT(Remainder, 1) AS Letter
    ,      SUBSTRING(Remainder, 2, LEN(Remainder)) AS Remainder
    FROM cte_Letters
    WHERE LEN(Remainder) > 0
), cte_Top5 AS (
    SELECT RoomNr, Letter, COUNT(1) AS Amount, ROW_NUMBER() OVER (PARTITION BY RoomNr ORDER BY RoomNr, COUNT(1) DESC, Letter) AS Top5
    FROM cte_Letters
    WHERE Letter <> '-'
    GROUP BY RoomNr, Letter
), cte_Comparision AS (
    SELECT L1.RoomNr
    ,      L1.Letter + L2.Letter + L3.Letter + L4.Letter + L5.Letter AS RealChecksum
    ,      R.Checksum 
    ,      CASE WHEN L1.Letter + L2.Letter + L3.Letter + L4.Letter + L5.Letter = R.Checksum THEN SectorID ELSE 0 END AS RealRoom
    FROM cte_Top5 L1
    INNER JOIN cte_Top5 L2 ON L1.RoomNr = L2.RoomNr AND L1.Top5 = L2.Top5 - 1
    INNER JOIN cte_Top5 L3 ON L2.RoomNr = L3.RoomNr AND L2.Top5 = L3.Top5 - 1
    INNER JOIN cte_Top5 L4 ON L3.RoomNr = L4.RoomNr AND L3.Top5 = L4.Top5 - 1
    INNER JOIN cte_Top5 L5 ON L4.RoomNr = L5.RoomNr AND L4.Top5 = L5.Top5 - 1
    INNER JOIN ##Rooms R ON L1.RoomNr = R.RoomNr
    WHERE L1.Top5 = 1
)
SELECT SUM(RealRoom) FROM cte_Comparision

--173787 Is correct for part 1


;WITH cte_Letters AS (
    SELECT RoomNr
    ,      1 AS LetterNr
    ,      LEFT(RoomID, 1) AS Letter
    ,      SUBSTRING(RoomID, 2, LEN(RoomID)) AS Remainder
    ,      SectorID
    FROM ##Rooms
    UNION ALL
    SELECT RoomNr
    ,      LetterNr + 1
    ,      LEFT(Remainder, 1) AS Letter
    ,      SUBSTRING(Remainder, 2, LEN(Remainder)) AS Remainder
    ,      SectorID
    FROM cte_Letters
    WHERE LEN(Remainder) > 0
)--, cte_Corrected AS (
SELECT RoomNr, Letter, LetterNr
,      CASE WHEN Letter = '-' THEN ' '
            WHEN ASCII(Letter) + SectorID % 26 > 122 THEN CHAR(ASCII(Letter) + SectorID % 26 - 26) ELSE CHAR(ASCII(Letter) + SectorID % 26) END AS RotatedLetter
FROM cte_Letters
WHERE RoomNr = 300
ORDER BY RoomNr, LetterNr
--)
--SELECT * FROM cte_Corrected WHERE RotatedLetter = 'n' AND LetterNr = 1

SELECT * FROM ##Rooms WHERE RoomNr = 300

/*

DROP TABLE ##Rooms
DROP TABLE ##Input

*/

