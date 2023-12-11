USE Test_WME

SET NOCOUNT ON

DECLARE @year VARCHAR(4) = '2023'
DECLARE @day VARCHAR(2)  = '10'

EXEC dbo.GetInput @year = @year, @day = @day
EXEC dbo.ParseInput @year = @year, @day = @day 

--SELECT TOP 10 * FROM ##Input
--SELECT TOP 10 * FROM ##InputInts
--SELECT TOP 10 * FROM ##InputNumbered

--SELECT TOP 10 * FROM ##InputSplit
--SELECT TOP 10 * FROM ##InputSplitCust

DECLARE @StartRow INT
DECLARE @StartCol INT

SELECT @StartRow = RowNr, @StartCol = ColNr 
FROM ##InputGrid I1
WHERE I1.Val = 'S'

DECLARE @PieceUnderStart VARCHAR(2) = ''

SELECT @PieceUnderStart = @PieceUnderStart + 'N' FROM ##InputGrid I1 WHERE RowNr = @StartRow - 1 AND ColNr = @StartCol AND I1.Val IN ('|','7','F')
SELECT @PieceUnderStart = @PieceUnderStart + 'S' FROM ##InputGrid I1 WHERE RowNr = @StartRow + 1 AND ColNr = @StartCol AND I1.Val IN ('|','J','L')
SELECT @PieceUnderStart = @PieceUnderStart + 'W' FROM ##InputGrid I1 WHERE RowNr = @StartRow AND ColNr = @StartCol - 1 AND I1.Val IN ('-','L','F')
SELECT @PieceUnderStart = @PieceUnderStart + 'E' FROM ##InputGrid I1 WHERE RowNr = @StartRow AND ColNr = @StartCol + 1 AND I1.Val IN ('-','J','7')

UPDATE I
SET Val = CASE WHEN @PieceUnderStart = 'NS' THEN '|'
               WHEN @PieceUnderStart = 'WE' THEN '-' 
               WHEN @PieceUnderStart = 'NW' THEN 'J' 
               WHEN @PieceUnderStart = 'NE' THEN 'L' 
               WHEN @PieceUnderStart = 'SW' THEN '7' 
               WHEN @PieceUnderStart = 'SE' THEN 'F' 
          END
FROM ##InputGrid I
WHERE I.RowNr = @StartRow AND I.ColNr = @StartCol


DECLARE @Count INT = 1
DECLARE @Step INT = 0

CREATE TABLE ##Steps (ID INT IDENTITY(1,1), RowNr INT, ColNr INT, Val CHAR, Steps INT, InsideDir VARCHAR(2))

CREATE UNIQUE INDEX Ind_IGRowCol ON ##InputGrid (ColNr, RowNr)
CREATE UNIQUE INDEX Ind_STRowCol ON ##Steps (ColNr, RowNr)

INSERT ##Steps (RowNr, ColNr, Val, Steps, InsideDir)
SELECT RowNr,
       ColNr,
       Val,
       0 AS Step,
       CASE WHEN Val = '|' THEN 'E'
            WHEN Val = '-' THEN 'S'
            WHEN Val IN ('F', 'J') THEN 'SE'
            ELSE 'SW' END
FROM ##InputGrid I
WHERE I.RowNr = @StartRow AND I.ColNr = @StartCol

WHILE @Count > 0
BEGIN

    INSERT ##Steps
    (
        RowNr,
        ColNr,
        Val,
        Steps,
        InsideDir
    )
    SELECT DISTINCT IG.RowNr
    ,      IG.ColNr
    ,      IG.Val
    ,      S.Steps + 1
    ,      CASE WHEN (S.Val = '|' AND IG.Val = '|')
                      OR (S.Val = '-' AND IG.Val = '-')
                      OR (S.Val IN ('7','L') AND IG.Val IN ('7','L'))
                      OR (S.Val IN ('J','F') AND IG.Val IN ('J','F')) THEN S.InsideDir 

                    WHEN IG.Val = '|' THEN RIGHT(S.InsideDir,1)

                    WHEN IG.Val = '-' THEN LEFT(S.InsideDir,1) 

                    WHEN (S.Val IN ('7','F') AND IG.Val IN ('7','F'))
                      OR (S.Val IN ('J','L') AND IG.Val IN ('J','L')) THEN LEFT(S.InsideDir,1) + CASE WHEN RIGHT(S.InsideDir,1) = 'W' THEN 'E' ELSE 'W' END

                    WHEN (S.Val IN ('7','J') AND IG.Val IN ('7','J'))
                      OR (S.Val IN ('F','L') AND IG.Val IN ('F','L')) THEN CASE WHEN LEFT(S.InsideDir,1) = 'N' THEN 'S' ELSE 'N' END + RIGHT(S.InsideDir,1)

                    WHEN IG.Val IN ('7','L') THEN CASE WHEN S.InsideDir IN ('N','E') THEN 'NE' ELSE 'SW' END

                    WHEN IG.Val IN ('F','J') THEN CASE WHEN S.InsideDir IN ('N','W') THEN 'NW' ELSE 'SE' END

                    END
    FROM ##Steps S
    INNER JOIN ##InputGrid IG ON (S.RowNr = IG.RowNr + 1 AND S.ColNr = IG.ColNr AND S.Val IN ('|','L','J') AND IG.Val IN ('|','F','7'))  -- Connection to the north
                              OR (S.RowNr = IG.RowNr - 1 AND S.ColNr = IG.ColNr AND S.Val IN ('|','F','7') AND IG.Val IN ('|','L','J'))  -- Connection to the south
                              OR (S.RowNr = IG.RowNr AND S.ColNr = IG.ColNr + 1 AND S.Val IN ('-','J','7') AND IG.Val IN ('-','L','F'))  -- Connection to the west
                              OR (S.RowNr = IG.RowNr AND S.ColNr = IG.ColNr - 1 AND S.Val IN ('-','L','F') AND IG.Val IN ('-','J','7'))  -- Connection to the east
    LEFT JOIN ##Steps S2 ON IG.RowNr = S2.RowNr AND IG.ColNr = S2.ColNr
    WHERE S.Steps = @Step
    AND S2.ID IS NULL

    SET @Count = @@ROWCOUNT

    SET @Step = @Step + 1

END


SELECT MAX(Steps) AS Part1
FROM ##Steps S

/*
-- Find a side of the tube to determine which side is the outside

SELECT MIN(RowNr), MAX(Rownr), MIN(ColNr), MAX(ColNr) FROM ##Steps
SELECT * FROM ##Steps WHERE ColNr = 5
SELECT * FROM ##InputGrid WHERE ColNr <= 5 AND RowNr = 79

*/




CREATE TABLE ##EmptySpaces (ID INT IDENTITY(1,1), RowNr INT, ColNr INT)

INSERT ##EmptySpaces
(
    RowNr,
    ColNr
)
SELECT IG.RowNr, IG.ColNr
FROM ##Steps S
INNER JOIN ##InputGrid IG ON (S.InsideDir = 'N' AND S.RowNr = IG.RowNr + 1 AND S.ColNr = IG.ColNr)
                          OR (S.InsideDir = 'S' AND S.RowNr = IG.RowNr - 1 AND S.ColNr = IG.ColNr)
                          OR (S.InsideDir = 'W' AND S.RowNr = IG.RowNr AND S.ColNr = IG.ColNr + 1)
                          OR (S.InsideDir = 'E' AND S.RowNr = IG.RowNr AND S.ColNr = IG.ColNr - 1)

                          OR (S.InsideDir = 'NW' AND S.RowNr - IG.RowNr IN (0, 1) AND S.ColNr - IG.Colnr IN (0, 1))
                          OR (S.InsideDir = 'NE' AND S.RowNr - IG.RowNr IN (0, 1) AND S.ColNr - IG.Colnr IN (-1, 0))
                          OR (S.InsideDir = 'SW' AND S.RowNr - IG.RowNr IN (-1, 0) AND S.ColNr - IG.Colnr IN (0, 1))
                          OR (S.InsideDir = 'SE' AND S.RowNr - IG.RowNr IN (-1, 0) AND S.ColNr - IG.Colnr IN (-1,0))
LEFT JOIN ##Steps S2 ON S2.RowNr = IG.RowNr AND S2.ColNr = IG.ColNr
WHERE S2.ID IS NULL
GROUP BY IG.RowNr,
         IG.ColNr

--SELECT COUNT(1) FROM ##EmptySpaces ES


--DECLARE @Count INT
SET @Count = 1

WHILE @Count > 0
BEGIN

    INSERT ##EmptySpaces
    (
        RowNr,
        ColNr
    )
    SELECT IG.RowNr, IG.ColNr
    FROM ##EmptySpaces ES
    INNER JOIN ##InputGrid IG ON ABS(ES.RowNr - IG.RowNr) <= 1 AND ABS(ES.ColNr - IG.ColNr) <= 1
                                 --(ABS(ES.RowNr - IG.RowNr) = 1 AND ES.ColNr = IG.ColNr) OR (ABS(ES.ColNr - IG.ColNr) = 1 AND ES.RowNr = IG.RowNr)
    LEFT JOIN ##EmptySpaces ES2 ON ES2.ColNr = IG.ColNr AND ES2.RowNr = IG.RowNr
    LEFT JOIN ##Steps S ON S.ColNr = IG.ColNr AND S.RowNr = IG.RowNr
    WHERE IG.Val = '.' AND ES2.ID IS NULL AND S.ID IS NULL
    GROUP BY IG.RowNr,
             IG.ColNr

    SET @Count = @@ROWCOUNT
END

SELECT COUNT(1) FROM ##EmptySpaces ES

/*

DROP TABLE ##Steps
DROP TABLE ##EmptySpaces

*/

-- 203 too low
--1094 too high
--1057 too high
-- 281 is incorrect


SELECT COUNT(1) FROM ##Steps S --ORDER BY RowNr, ColNr
SELECT COUNT(1) FROM ##EmptySpaces ES --ORDER BY RowNr, ColNr
SELECT COUNT(1) FROM ##InputGrid

--SELECT ColNr AS X, RowNr AS Y
--INTO ##Grid
--FROM ##Steps S

--EXEC [PrintGrid] @GridType = 'Sparse'

