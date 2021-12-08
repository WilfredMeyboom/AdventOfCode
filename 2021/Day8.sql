USE Test_WME

SET NOCOUNT ON

DECLARE @year VARCHAR(4) = '2021'
DECLARE @day VARCHAR(2)  = '8'

EXEC dbo.GetInput @year = @year, @day = @day
EXEC dbo.ParseInput @year = @year, @day = @day 

--SELECT TOP 10 * FROM ##InputNumbered
SELECT TOP 10 * FROM ##InputGrid
--SELECT TOP 10 * FROM ##InputInts
SELECT TOP 10 * FROM ##InputSplit
--SELECT TOP 10 * FROM ##InputSplitCust



SELECT COUNT(1) AS Part1
FROM ##InputSplit
WHERE PieceNr > 10
AND LEN(LTRIM(RTRIM(Piece))) IN (2,4,3,7)



/*
0 = 6
    1 = 2
2 = 5
3 = 5
    4 = 4
5 = 5
6 = 6
    7 = 3
    8 = 7
9 = 6

*/

--Put everything we know in here
CREATE TABLE ##Digits (ID INT IDENTITY(1,1), RowNr INT, PieceNr INT, Val INT)

INSERT ##Digits (RowNr, PieceNr, Val)
SELECT RowNr, PieceNr
, CASE WHEN LEN(Piece) = 2 THEN 1
       WHEN LEN(Piece) = 4 THEN 4
       WHEN LEN(Piece) = 3 THEN 7
       WHEN LEN(Piece) = 7 THEN 8
        END
FROM ##InputSplit
WHERE LEN(Piece) IN (2,4,3,7)

--SELECT * FROM ##Digits D ORDER BY RowNr, PieceNr

CREATE TABLE ##Ones (ID INT IDENTITY(1,1), RowNr INT, Letter CHAR(1))
CREATE TABLE ##Fours (ID INT IDENTITY(1,1), RowNr INT, Letter CHAR(1))
CREATE TABLE ##Sevens (ID INT IDENTITY(1,1), RowNr INT, Letter CHAR(1))

INSERT ##Ones (RowNr, Letter)
SELECT RowNr, LEFT(Piece,1) AS Letter
FROM ##InputSplit
WHERE LEN(Piece) = 2
GROUP BY RowNr, LEFT(Piece,1)
UNION
SELECT RowNr, RIGHT(Piece,1)
FROM ##InputSplit
WHERE LEN(Piece) = 2
GROUP BY RowNr, RIGHT(Piece,1)

INSERT ##Sevens (RowNr, Letter)
SELECT RowNr, LEFT(Piece,1)
FROM ##InputSplit
WHERE LEN(Piece) = 3
GROUP BY RowNr, LEFT(Piece,1)
UNION
SELECT RowNr, RIGHT(Piece,1)
FROM ##InputSplit
WHERE LEN(Piece) = 3
GROUP BY RowNr, RIGHT(Piece,1)
UNION
SELECT RowNr, SUBSTRING(Piece,2,1)
FROM ##InputSplit
WHERE LEN(Piece) = 3
GROUP BY RowNr, SUBSTRING(Piece,2,1)

INSERT ##Fours (RowNr, Letter)
SELECT RowNr, LEFT(Piece,1)
FROM ##InputSplit
WHERE LEN(Piece) = 4
GROUP BY RowNr, LEFT(Piece,1)
UNION
SELECT RowNr, RIGHT(Piece,1)
FROM ##InputSplit
WHERE LEN(Piece) = 4
GROUP BY RowNr, RIGHT(Piece,1)
UNION
SELECT RowNr, SUBSTRING(Piece,2,1)
FROM ##InputSplit
WHERE LEN(Piece) = 4
GROUP BY RowNr, SUBSTRING(Piece,2,1)
UNION
SELECT RowNr, SUBSTRING(Piece,3,1)
FROM ##InputSplit
WHERE LEN(Piece) = 4
GROUP BY RowNr, SUBSTRING(Piece,3,1)



--Looking at the difference between Fours and Ones gives us the letters for the upperleft and middle dashes
SELECT S.RowNr, S.Letter 
INTO ##UpLeftAndMiddle
FROM ##Fours S
LEFT JOIN ##Ones O ON O.RowNr = S.RowNr AND O.Letter = S.Letter
WHERE O.ID IS NULL

--Similarly, substracting the Fours and the Sevens from the Eights gives the letters for the lowerleft and lowermiddle dashes
;WITH cte_Letters AS (
SELECT 'a' Letter UNION
SELECT 'b' UNION
SELECT 'c' UNION
SELECT 'd' UNION
SELECT 'e' UNION
SELECT 'f' UNION
SELECT 'g'), cte_Eights AS (
    SELECT RowNr, Letter FROM ##InputSplit
    CROSS APPLY cte_Letters
    GROUP BY RowNr, Letter
)
SELECT E.RowNr, E.Letter
INTO ##LeftUnderAndMidUnder
FROM cte_Eights E
LEFT JOIN ##Sevens S ON E.RowNr = S.RowNr AND E.Letter = S.Letter
LEFT JOIN ##Fours F ON F.RowNr = E.RowNr AND F.Letter = E.Letter
WHERE S.ID IS NULL AND F.ID IS NULL
ORDER BY RowNr

-- Looking at the pieces consisting of 6 letters only 1 (the zero) hasn't both its upperleft and middle dashes filled
INSERT ##Digits (RowNr, PieceNr, Val)
SELECT I.RowNr, I.PieceNr, 0--I.Piece
FROM ##InputSplit I
LEFT JOIN ##UpLeftAndMiddle U ON I.RowNr = U.RowNr AND I.Piece LIKE  '%' + U.Letter + '%'
WHERE LEN(I.Piece) = 6
GROUP BY I.RowNr, I.PieceNr, I.Piece
HAVING COUNT(1) = 1
ORDER BY I.RowNr, PieceNr

-- Looking at the pieces consisting of 6 letters only 1 (the nine) hasn't both its lowerleft and lower middle dashes filled
INSERT ##Digits (RowNr, PieceNr, Val)
SELECT I.RowNr, I.PieceNr, 9--I.Piece
FROM ##InputSplit I
LEFT JOIN ##LeftUnderAndMidUnder U ON I.RowNr = U.RowNr AND I.Piece LIKE  '%' + U.Letter + '%'
WHERE LEN(I.Piece) = 6
GROUP BY I.RowNr, I.PieceNr, I.Piece
HAVING COUNT(1) = 1
ORDER BY I.RowNr, PieceNr

-- Anything left with 6 characters is a 6
;WITH cte_ZeroesAndNines AS (
SELECT I.RowNr, I.PieceNr, I.Piece
FROM ##InputSplit I
LEFT JOIN ##UpLeftAndMiddle U ON I.RowNr = U.RowNr AND I.Piece LIKE  '%' + U.Letter + '%'
WHERE LEN(I.Piece) = 6
GROUP BY I.RowNr, I.PieceNr, I.Piece
HAVING COUNT(1) = 1
UNION
SELECT I.RowNr, I.PieceNr, I.Piece
FROM ##InputSplit I
LEFT JOIN ##LeftUnderAndMidUnder U ON I.RowNr = U.RowNr AND I.Piece LIKE  '%' + U.Letter + '%'
WHERE LEN(I.Piece) = 6
GROUP BY I.RowNr, I.PieceNr, I.Piece
HAVING COUNT(1) = 1
)
INSERT ##Digits (RowNr, PieceNr, Val)
SELECT I.RowNr, I.PieceNr, 6
FROM ##InputSplit I
LEFT JOIN cte_ZeroesAndNines U ON I.RowNr = U.RowNr AND I.Piece = U.Piece
WHERE LEN(I.Piece) = 6 AND U.RowNr IS NULL
ORDER BY I.RowNr, I.PieceNr

--So... that worked. Let's do that again for the five-length-numbers

-- Looking at the pieces consisting of 5 letters only 1 (the two) has both its lowerleft and lower middle dashes filled
INSERT ##Digits (RowNr, PieceNr, Val)
SELECT I.RowNr, I.PieceNr, 2 -- I.Piece
FROM ##InputSplit I
LEFT JOIN ##LeftUnderAndMidUnder U ON I.RowNr = U.RowNr AND I.Piece LIKE  '%' + U.Letter + '%'
WHERE LEN(I.Piece) = 5
GROUP BY I.RowNr, I.PieceNr, I.Piece
HAVING COUNT(1) = 2

-- Looking at the pieces consisting of 5 letters only 1 (the five) has both its upperleft and middle dashes filled
INSERT ##Digits (RowNr, PieceNr, Val)
SELECT I.RowNr, I.PieceNr, 5 --I.Piece
FROM ##InputSplit I
LEFT JOIN ##UpLeftAndMiddle U ON I.RowNr = U.RowNr AND I.Piece LIKE  '%' + U.Letter + '%'
WHERE LEN(I.Piece) = 5
GROUP BY I.RowNr, I.PieceNr, I.Piece
HAVING COUNT(1) = 2
ORDER BY I.RowNr, PieceNr

-- Anything left with 5 characters is a 3
;WITH cte_TwosAndFives AS (
SELECT I.RowNr, I.PieceNr, I.Piece
FROM ##InputSplit I
LEFT JOIN ##UpLeftAndMiddle U ON I.RowNr = U.RowNr AND I.Piece LIKE  '%' + U.Letter + '%'
WHERE LEN(I.Piece) = 5
GROUP BY I.RowNr, I.PieceNr, I.Piece
HAVING COUNT(1) = 2
UNION
SELECT I.RowNr, I.PieceNr, I.Piece
FROM ##InputSplit I
LEFT JOIN ##LeftUnderAndMidUnder U ON I.RowNr = U.RowNr AND I.Piece LIKE  '%' + U.Letter + '%'
WHERE LEN(I.Piece) = 5
GROUP BY I.RowNr, I.PieceNr, I.Piece
HAVING COUNT(1) = 2
)
INSERT ##Digits (RowNr, PieceNr, Val)
SELECT I.RowNr, I.PieceNr, 3
FROM ##InputSplit I
LEFT JOIN cte_TwosAndFives U ON I.RowNr = U.RowNr AND I.Piece = U.Piece
WHERE LEN(I.Piece) = 5 AND U.RowNr IS NULL
ORDER BY I.RowNr, I.PieceNr


SELECT SUM([11] * 1000 + [12] * 100 + [13] * 10 + [14]) AS Part2
FROM (
    SELECT RowNr, PieceNr, Val 
    FROM ##Digits
    WHERE PieceNr > 10
    ) T
PIVOT (
    SUM(Val)
    FOR PieceNr
    IN ([11],[12],[13],[14])
) PivotTable

DROP TABLE ##Digits
DROP TABLE ##Ones
DROP TABLE ##Fours
DROP TABLE ##Sevens
DROP TABLE ##LeftUnderAndMidUnder
DROP TABLE ##UpLeftAndMiddle

