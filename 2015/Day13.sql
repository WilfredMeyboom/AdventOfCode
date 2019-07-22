use Test_WME

SET NOCOUNT ON

CREATE TABLE ##Input (Line NVARCHAR(MAX));

BULK INSERT ##Input
FROM 'D:\Wilfred\AdventOfCode\2015\input13.txt'
WITH (ROWTERMINATOR = '0x0A');

CREATE TABLE ##Happiness (ID INT IDENTITY(1,1), P_Left VARCHAR(10), P_Right VARCHAR(10), Happiness INT)

;WITH cte_Scrubbed AS (
    SELECT REPLACE(REPLACE(REPLACE(REPLACE(LEFT(Line, LEN(Line)-1), 'lose ', '-'), 'gain ', '+'), 'would ', ','), 'happiness units by sitting next to ','|') AS NewLine FROM ##Input
)
INSERT ##Happiness (P_Left, Happiness, P_Right)
SELECT LTRIM(RTRIM(LEFT(NewLine, CHARINDEX(' ,', NewLine)))) AS P1
,      LTRIM(RTRIM(SUBSTRING(NewLine, CHARINDEX(' ,', NewLine) + 2, CHARINDEX(' |', NewLine) - CHARINDEX(' ,', NewLine) - 2))) AS Value
,      LTRIM(RTRIM(SUBSTRING(NewLine, CHARINDEX(' |', NewLine) + 2, LEN(NewLine)))) AS P2
FROM cte_Scrubbed


;WITH cte_Players AS (
    SELECT DISTINCT P_Left AS Person FROM ##Happiness
), cte_Seats AS (
    SELECT P1.Person AS Seat1
    ,      P2.Person AS Seat2
    ,      P3.Person AS Seat3
    ,      P4.Person AS Seat4
    ,      P5.Person AS Seat5
    ,      P6.Person AS Seat6
    ,      P7.Person AS Seat7
    ,      P8.Person AS Seat8
    FROM cte_Players P1
    INNER JOIN cte_Players P2 ON P1.Person <> P2.Person
    INNER JOIN cte_Players P3 ON P1.Person <> P3.Person AND P2.Person <> P3.Person
    INNER JOIN cte_Players P4 ON P1.Person <> P4.Person AND P2.Person <> P4.Person AND P3.Person <> P4.Person
    INNER JOIN cte_Players P5 ON P1.Person <> P5.Person AND P2.Person <> P5.Person AND P3.Person <> P5.Person AND P4.Person <> P5.Person
    INNER JOIN cte_Players P6 ON P1.Person <> P6.Person AND P2.Person <> P6.Person AND P3.Person <> P6.Person AND P4.Person <> P6.Person AND P5.Person <> P6.Person
    INNER JOIN cte_Players P7 ON P1.Person <> P7.Person AND P2.Person <> P7.Person AND P3.Person <> P7.Person AND P4.Person <> P7.Person AND P5.Person <> P7.Person AND P6.Person <> P7.Person
    INNER JOIN cte_Players P8 ON P1.Person <> P8.Person AND P2.Person <> P8.Person AND P3.Person <> P8.Person AND P4.Person <> P8.Person AND P5.Person <> P8.Person AND P6.Person <> P8.Person AND P7.Person <> P8.Person
)
SELECT S.*, H1.Happiness + H2.Happiness + H3.Happiness + H4.Happiness + H5.Happiness + H6.Happiness + H7.Happiness + H8.Happiness
     + H1M.Happiness + H2M.Happiness + H3M.Happiness + H4M.Happiness + H5M.Happiness + H6M.Happiness + H7M.Happiness + H8M.Happiness AS TotalHappiness, H1.Happiness, H1M.Happiness, H1.Happiness + H1M.Happiness
FROM cte_Seats S
INNER JOIN ##Happiness H1 ON S.Seat1 = H1.P_Left AND S.Seat2 = H1.P_Right
INNER JOIN ##Happiness H2 ON S.Seat2 = H2.P_Left AND S.Seat3 = H2.P_Right
INNER JOIN ##Happiness H3 ON S.Seat3 = H3.P_Left AND S.Seat4 = H3.P_Right
INNER JOIN ##Happiness H4 ON S.Seat4 = H4.P_Left AND S.Seat5 = H4.P_Right
INNER JOIN ##Happiness H5 ON S.Seat5 = H5.P_Left AND S.Seat6 = H5.P_Right
INNER JOIN ##Happiness H6 ON S.Seat6 = H6.P_Left AND S.Seat7 = H6.P_Right
INNER JOIN ##Happiness H7 ON S.Seat7 = H7.P_Left AND S.Seat8 = H7.P_Right
INNER JOIN ##Happiness H8 ON S.Seat8 = H8.P_Left AND S.Seat1 = H8.P_Right

INNER JOIN ##Happiness H1M ON S.Seat1 = H1M.P_Right AND S.Seat2 = H1M.P_Left
INNER JOIN ##Happiness H2M ON S.Seat2 = H2M.P_Right AND S.Seat3 = H2M.P_Left
INNER JOIN ##Happiness H3M ON S.Seat3 = H3M.P_Right AND S.Seat4 = H3M.P_Left
INNER JOIN ##Happiness H4M ON S.Seat4 = H4M.P_Right AND S.Seat5 = H4M.P_Left
INNER JOIN ##Happiness H5M ON S.Seat5 = H5M.P_Right AND S.Seat6 = H5M.P_Left
INNER JOIN ##Happiness H6M ON S.Seat6 = H6M.P_Right AND S.Seat7 = H6M.P_Left
INNER JOIN ##Happiness H7M ON S.Seat7 = H7M.P_Right AND S.Seat8 = H7M.P_Left
INNER JOIN ##Happiness H8M ON S.Seat8 = H8M.P_Right AND S.Seat1 = H8M.P_Left

WHERE H1.Happiness + H2.Happiness + H3.Happiness + H4.Happiness + H5.Happiness + H6.Happiness + H7.Happiness + H8.Happiness
     + H1M.Happiness + H2M.Happiness + H3M.Happiness + H4M.Happiness + H5M.Happiness + H6M.Happiness + H7M.Happiness + H8M.Happiness = 664
ORDER BY TotalHappiness DESC


/* 

DROP TABLE ##Happiness
DROP TABLE ##Input

*/

--664 is correct for part 1

SELECT 664 - 24

--562 is too low
--640 is correct for part 2