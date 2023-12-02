USE Test_WME

SET NOCOUNT ON

DECLARE @year VARCHAR(4) = '2023'
DECLARE @day VARCHAR(2)  = '1'

EXEC dbo.GetInput @year = @year, @day = @day
EXEC dbo.ParseInput @year = @year, @day = @day 

--SELECT TOP 10 * FROM ##Input
--SELECT TOP 10 * FROM ##InputInts
--SELECT TOP 10 * FROM ##InputNumbered
--SELECT TOP 10 * FROM ##InputGrid
--SELECT TOP 10 * FROM ##InputSplit
--SELECT TOP 10 * FROM ##InputSplitCust


;WITH cte_Pos AS (
    SELECT RowNr, MIN(ColNr) AS MinColnr, MAX(ColNr) AS MaxColNr FROM ##InputGrid WHERE TRY_CAST(val AS INT) IS NOT NULL GROUP BY RowNr
)
SELECT SUM(CAST(IG1.val + IG2.val AS INT)) AS Part1
FROM cte_Pos cP
INNER JOIN ##InputGrid IG1 ON IG1.RowNr = cP.RowNr AND IG1.ColNr = cP.MinColNr
INNER JOIN ##InputGrid IG2 ON IG2.RowNr = cP.RowNr AND IG2.ColNr = cP.MaxColNr


-- Create a table of words we need to recognize
;WITH cte_Nrs AS (
    SELECT '1' AS Digit,'one' AS Nr UNION
    SELECT '2' AS Digit,'two' AS Nr UNION
    SELECT '3' AS Digit, 'three' AS Nr UNION
    SELECT '4' AS Digit, 'four' AS Nr UNION
    SELECT '5' AS Digit, 'five' AS Nr UNION
    SELECT '6' AS Digit, 'six' AS Nr UNION
    SELECT '7' AS Digit, 'seven' AS Nr UNION
    SELECT '8' AS Digit, 'eight' AS Nr UNION
    SELECT '9' AS Digit, 'nine' AS Nr
)
SELECT *
INTO ##Nrs
FROM cte_Nrs

-- Create a table to hold all temporary results
CREATE TABLE ##TransformedInput (ID INT IDENTITY(1,1), OriginalLine VARCHAR(MAX), FirstDigitLine VARCHAR(MAX), FirstDigit CHAR, LastDigitline VARCHAR(MAX), LastDigit CHAR)

-- Try to find a number as text, looking from the left. Change the text to a number and store the new string
;WITH cte_Replace AS (
    SELECT I.Line, MIN(CASE WHEN CHARINDEX(N.Nr, I.Line) > 0 THEN CHARINDEX(N.Nr, I.Line) ELSE NULL END) AS StartPos
    FROM ##Input I
    CROSS APPLY ##Nrs N
    GROUP BY I.Line
)
INSERT ##TransformedInput (OriginalLine, FirstDigitLine) 
SELECT I.Line
,      LEFT(I.Line, cR.StartPos - 1) + Digit + SUBSTRING(I.Line, cR.StartPos + LEN(N.Nr),LEN(I.Line))
FROM ##Input I
CROSS APPLY ##Nrs N
INNER JOIN cte_Replace cR ON I.Line = cR.Line AND CHARINDEX(N.Nr, I.Line) = cR.StartPos
UNION
SELECT I.Line
,      I.Line
FROM cte_Replace I
WHERE StartPos IS NULL


-- Repeat but now looking from the right. Store the new string in reverse for easy searching later on
;WITH cte_Replace AS (
    SELECT I.Line
    , MIN(CASE WHEN CHARINDEX(REVERSE(N.Nr), REVERSE(I.Line)) > 0 THEN CHARINDEX(REVERSE(N.Nr), REVERSE(I.Line)) ELSE NULL END) AS StartPos
    , REVERSE(I.Line) AS ReverseLine
    FROM ##Input I
    CROSS APPLY ##Nrs N
    GROUP BY I.Line
)
UPDATE I
SET LastDigitline = LEFT(REVERSE(I.OriginalLine), cR.StartPos - 1) + Digit + SUBSTRING(REVERSE(I.OriginalLine), cR.StartPos + LEN(N.Nr),LEN(I.OriginalLine))
FROM ##TransformedInput I
CROSS APPLY ##Nrs N
INNER JOIN cte_Replace cR ON I.OriginalLine = cR.Line AND CHARINDEX(REVERSE(N.Nr), REVERSE(I.OriginalLine)) = cR.StartPos

-- Fill in the blanks
UPDATE ##TransformedInput
SET LastDigitline = REVERSE(OriginalLine) 
WHERE LastDigitline IS NULL

-- Find the first digit, looking from the left
;WITH cte_FirstDigit AS (
    SELECT ID
    ,      LEFT(TI.FirstDigitLine, 1) AS FirstDigit
    ,      SUBSTRING(TI.FirstDigitLine, 2, LEN(TI.FirstDigitLine)) AS LeftOver
    FROM ##TransformedInput TI

    UNION ALL

    SELECT ID
    ,      LEFT(LeftOver, 1)
    ,      SUBSTRING(LeftOver, 2, LEN(LeftOver))
    FROM cte_FirstDigit
    WHERE TRY_CAST(FirstDigit AS INT) IS NULL
)
UPDATE T
SET FirstDigit = c.FirstDigit
FROM ##TransformedInput T
INNER JOIN cte_FirstDigit c ON T.ID = c.ID
WHERE TRY_CAST(c.FirstDigit AS INT) IS NOT NULL

-- Find the first digit, looking from the right
;WITH cte_LastDigit AS (
    SELECT ID
    ,      LEFT(TI.LastDigitLine, 1) AS LastDigit
    ,      SUBSTRING(TI.LastDigitLine, 2, LEN(TI.LastDigitLine)) AS LeftOver
    FROM ##TransformedInput TI

    UNION ALL

    SELECT ID
    ,      LEFT(LeftOver, 1)
    ,      SUBSTRING(LeftOver, 2, LEN(LeftOver))
    FROM cte_LastDigit
    WHERE TRY_CAST(LastDigit AS INT) IS NULL 
) 
UPDATE T
SET LastDigit = c.LastDigit
FROM ##TransformedInput T
INNER JOIN cte_LastDigit c ON T.ID = c.ID 
WHERE TRY_CAST(c.LastDigit AS INT) IS NOT NULL

-- So Part 2 is
SELECT SUM(CAST(TI.FirstDigit + TI.LastDigit AS INT)) AS Part2 FROM ##TransformedInput TI

DROP TABLE ##Nrs
DROP TABLE ##TransformedInput


