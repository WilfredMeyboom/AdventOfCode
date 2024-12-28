USE Test_WME

SET NOCOUNT ON

DECLARE @year VARCHAR(4) = '2024'
DECLARE @day VARCHAR(2)  = '21'

EXEC dbo.GetInput @year = @year, @day = @day
EXEC dbo.ParseInput @year = @year, @day = @day 

--SELECT TOP 10 * FROM ##Input
--SELECT TOP 10 * FROM ##InputInts
--SELECT TOP 10 * FROM ##InputNumbered
--SELECT TOP 10 * FROM ##InputGrid
--SELECT TOP 10 * FROM ##InputSplit
--SELECT TOP 10 * FROM ##InputSplitCust

--SELECT TOP 10 * FROM ##InputNumbered

--CREATE TABLE ##Results (ID INT IDENTITY(1,1), Input VARCHAR(5), Res1 VARCHAR(100), Res2 VARCHAR(200), Res3 VARCHAR(500))
--INSERT ##Results (Input) SELECT Line FROM ##InputNumbered

--671A
--^^A^<<AvvA>>vA
--<AA>A<Av<AA>>^A

CREATE TABLE ##Keypad (ID INT IDENTITY(1,1), x INT, y INT, Val CHAR(1))
INSERT ##Keypad (x, y, Val) VALUES (0,0,'7'), (1,0,'8'), (2,0,'9'), (0,1,'4'), (1,1,'5'), (2,1,'6'), (0,2,'1'), (1,2,'2'), (2,2,'3'), (1,3,'0'), (2,3,'A')

CREATE TABLE ##ConvertNumeric (ID INT IDENTITY(1,1), FVal CHAR(1), TVal CHAR(1), Steps1 VARCHAR(10), Steps2 VARCHAR(100), Steps3 VARCHAR(500))

INSERT ##ConvertNumeric (FVal, TVal, Steps1)
SELECT F.Val AS FVal, T.Val AS TVal
,      CASE WHEN S.VFirst = 0 
       THEN
       ISNULL(CASE WHEN F.X < T.X THEN REPLICATE('>', T.X - F.X) END, '') 
+      ISNULL(CASE WHEN F.X > T.X THEN REPLICATE('<', F.X - T.X) END, '')
+      ISNULL(CASE WHEN F.Y > T.Y THEN REPLICATE('^', F.Y - T.Y) END, '')
+      ISNULL(CASE WHEN F.Y < T.Y THEN REPLICATE('v', T.Y - F.Y) END, '') 
       ELSE   
       ISNULL(CASE WHEN F.Y > T.Y THEN REPLICATE('^', F.Y - T.Y) END, '')
+      ISNULL(CASE WHEN F.Y < T.Y THEN REPLICATE('v', T.Y - F.Y) END, '') 
+      ISNULL(CASE WHEN F.X < T.X THEN REPLICATE('>', T.X - F.X) END, '') 
+      ISNULL(CASE WHEN F.X > T.X THEN REPLICATE('<', F.X - T.X) END, '') END + 'A' AS Steps

FROM ##Keypad F--romKey
CROSS APPLY ##Keypad T--oKey
CROSS APPLY (SELECT 0 AS VFirst UNION SELECT 1) S--tartDir
--ORDER BY FVal, TVal

--Remove unallowed moves
DELETE FROM ##ConvertNumeric
WHERE (FVal = 'A' AND Steps1 LIKE '<<%')
   OR (FVal = '0' AND Steps1 LIKE '<%')
   OR (FVal = '1' AND Steps1 LIKE 'v%')
   OR (FVal = '4' AND Steps1 LIKE 'vv%')
   OR (FVal = '7' AND Steps1 LIKE 'vvv%')

CREATE TABLE ##DirKeypad (ID INT IDENTITY(1,1), x INT, y INT, Val CHAR(1))
INSERT ##DirKeypad (x, y, Val) VALUES (1,0,'^'), (2,0,'A'), (0,1,'<'), (1,1,'v'), (2,1,'>')

CREATE TABLE ##ConvertDirectional (ID INT IDENTITY(1,1), FVal CHAR(1), TVal CHAR(1), Steps VARCHAR(10))

INSERT ##ConvertDirectional (FVal, TVal, Steps)
SELECT F.Val AS FVal, T.Val AS TVal
,      CASE WHEN S.VFirst = 0 
       THEN
       ISNULL(CASE WHEN F.X < T.X THEN REPLICATE('>', T.X - F.X) END, '') 
+      ISNULL(CASE WHEN F.X > T.X THEN REPLICATE('<', F.X - T.X) END, '')
+      ISNULL(CASE WHEN F.Y > T.Y THEN REPLICATE('^', F.Y - T.Y) END, '')
+      ISNULL(CASE WHEN F.Y < T.Y THEN REPLICATE('v', T.Y - F.Y) END, '') 
       ELSE   
       ISNULL(CASE WHEN F.Y > T.Y THEN REPLICATE('^', F.Y - T.Y) END, '')
+      ISNULL(CASE WHEN F.Y < T.Y THEN REPLICATE('v', T.Y - F.Y) END, '') 
+      ISNULL(CASE WHEN F.X < T.X THEN REPLICATE('>', T.X - F.X) END, '') 
+      ISNULL(CASE WHEN F.X > T.X THEN REPLICATE('<', F.X - T.X) END, '') END AS Steps
FROM ##DirKeypad F--romKey
CROSS APPLY ##DirKeypad T--oKey
CROSS APPLY (SELECT 0 AS VFirst UNION SELECT 1) S--tartDir

DELETE FROM ##ConvertDirectional
WHERE (FVal = '<' AND Steps LIKE '^%')
   OR (FVal = '^' AND Steps LIKE '<%')
   OR (FVal = 'A' AND Steps LIKE '<<%')



;WITH cte_Moves AS (
    SELECT C.Steps1
    , LEFT(C.Steps1, 1) AS CurrentPos
    , SUBSTRING(C.Steps1, 2, LEN(C.Steps1)) AS LeftOver
    , CAST(D.Steps + 'A' AS VARCHAR(200)) AS Steps
    FROM ##ConvertNumeric C
    INNER JOIN ##ConvertDirectional D ON D.FVal = 'A' AND D.TVal = LEFT(C.Steps1,1)

    UNION ALL

    SELECT c.Steps1
    , LEFT(c.LeftOver, 1) AS CurrentPos
    , SUBSTRING(c.LeftOver, 2, LEN(c.LeftOver)) AS LeftOver
    , CAST(c.Steps + D.Steps + 'A' AS VARCHAR(200)) AS Steps
    FROM cte_Moves c
    INNER JOIN ##ConvertDirectional D ON D.FVal = c.CurrentPos AND D.TVal = LEFT(c.LeftOver,1)
)
INSERT ##ConvertNumeric (FVal, TVal, Steps1, Steps2)
SELECT N.FVal, N.TVal, N.Steps1, c.Steps AS Steps2
FROM ##ConvertNumeric N
INNER JOIN cte_Moves c ON N.Steps1 = c.Steps1
WHERE LeftOver = ''
GROUP BY N.FVal, N.TVal, N.Steps1, c.Steps 
ORDER BY N.FVal, N.TVal, N.Steps1, c.Steps 

DELETE FROM ##ConvertNumeric WHERE Steps2 IS NULL

--SELECT * FROM ##ConvertNumeric N ORDER BY N.FVal, N.TVal

;WITH cte_Moves AS (
    SELECT C.Steps1, C.Steps2
    , LEFT(C.Steps2, 1) AS CurrentPos
    , SUBSTRING(C.Steps2, 2, LEN(C.Steps2)) AS LeftOver
    , CAST(D.Steps + 'A' AS VARCHAR(200)) AS Steps
    FROM ##ConvertNumeric C
    INNER JOIN ##ConvertDirectional D ON D.FVal = 'A' AND D.TVal = LEFT(C.Steps2,1)

    UNION ALL

    SELECT c.Steps1, c.Steps2
    , LEFT(c.LeftOver, 1) AS CurrentPos
    , SUBSTRING(c.LeftOver, 2, LEN(c.LeftOver)) AS LeftOver
    , CAST(c.Steps + D.Steps + 'A' AS VARCHAR(200)) AS Steps
    FROM cte_Moves c
    INNER JOIN ##ConvertDirectional D ON D.FVal = c.CurrentPos AND D.TVal = LEFT(c.LeftOver,1)
)
INSERT ##ConvertNumeric (FVal, TVal, Steps1, Steps2, Steps3)
SELECT N.FVal, N.TVal, N.Steps1, N.Steps2, c.Steps AS Steps3
FROM ##ConvertNumeric N
INNER JOIN cte_Moves c ON N.Steps2 = c.Steps2
WHERE LeftOver = ''
GROUP BY N.FVal, N.TVal, N.Steps1, N.Steps2,c.Steps 
ORDER BY N.FVal, N.TVal, N.Steps1, N.Steps2,c.Steps 

DELETE FROM ##ConvertNumeric WHERE Steps3 IS NULL

;WITH cte_Result AS (
    SELECT I.Line
    ,      CAST(SUBSTRING(I.Line, 1, LEN(I.Line) - 1) AS INT) AS LineValue
    ,      CAST('A' AS CHAR(1)) FVal
    ,      LEFT(I.Line,1) AS TVal
    ,      SUBSTRING(I.Line, 2, LEN(I.Line)) AS LeftOver
    ,      CAST(N.Steps3 AS VARCHAR(200)) AS Steps3
    ,      CAST(N.Steps2 AS VARCHAR(200)) AS Steps2
    ,      CAST(N.Steps1 AS VARCHAR(200)) AS Steps1
    FROM ##Input I
    INNER JOIN ##ConvertNumeric N ON N.FVal = 'A' AND N.TVal = LEFT(I.Line,1)
    
    UNION ALL

    SELECT R.Line
    ,      R.LineValue
    ,      CAST(R.TVal AS CHAR(1)) AS FVal
    ,      LEFT(R.LeftOver, 1) AS TVal
    ,      SUBSTRING(R.LeftOver, 2, LEN(R.LeftOver)) AS LeftOver
    ,      CAST(R.Steps3 + N.Steps3 AS VARCHAR(200))
    ,      CAST(R.Steps2 + N.Steps2 AS VARCHAR(200))
    ,      CAST(R.Steps1 + N.Steps1 AS VARCHAR(200))
    FROM cte_Result R
    INNER JOIN ##ConvertNumeric N ON R.TVal = N.FVal AND N.TVal = LEFT(R.LeftOver,1)
), cte_TempRes AS (
    SELECT Line, LineValue, MIN(LEN(Steps3)) AS StepLen, MIN(LEN(Steps2)) AS StepLen2, MIN(LEN(Steps1)) AS StepLen1
    FROM cte_Result
    WHERE LeftOver = ''
    GROUP BY Line, LineValue
)
SELECT SUM(LineValue * StepLen) AS Part1
FROM cte_TempRes 


;WITH cte_Min AS (
    SELECT FVal, TVal, MIN(LEN(Steps3)) AS MinS3
    FROM ##ConvertNumeric
    GROUP BY FVal, TVal
) 
SELECT CN.FVal, CN.TVal, CN.Steps1
INTO ##ConvertNumeric2
FROM ##ConvertNumeric CN
INNER JOIN cte_Min cM ON CN.FVal = cM.FVal AND CN.TVal = cM.TVal AND LEN(CN.Steps3) = cM.MinS3
GROUP BY CN.FVal, CN.TVal, CN.Steps1

;WITH cte_Moves AS (
    SELECT Line, 'A' AS F, LEFT(Line, 1) AS T FROM ##Input                    -- From A to first char
    UNION ALL
    SELECT Line, LEFT(Line, 1), SUBSTRING(Line, 2, 1) FROM ##Input            -- From first to second char
    UNION ALL
    SELECT Line, SUBSTRING(Line, 2, 1), SUBSTRING(Line, 3, 1) FROM ##Input    -- From second to third char
    UNION ALL
    SELECT Line, SUBSTRING(Line, 3, 1), SUBSTRING(Line, 4, 1) FROM ##Input    -- From third to fourth char
), cte_MoveCnt AS (
    SELECT Line, F, T, COUNT(1) AS MoveCnt
    FROM cte_Moves
    GROUP BY Line, F, T
), cte_Src AS (
    SELECT cM.Line, cM.F, cM.T, cM.MoveCnt, CN.Steps1
    FROM cte_MoveCnt cM
    INNER JOIN ##ConvertNumeric2 CN ON cM.F = CN.FVal AND cM.T = CN.TVal
), cte_Tally AS (
    SELECT Line
    ,      'A' AS T
    ,      LEFT(Steps1, 1) AS F
    ,      SUBSTRING(Steps1, 2, LEN(Steps1)) AS LeftOver
    ,      MoveCnt
    FROM cte_Src

    UNION ALL

    SELECT Line
    ,      F
    ,      LEFT(LeftOver, 1)
    ,      SUBSTRING(LeftOver, 2, LEN(LeftOver))
    ,      MoveCnt
    FROM cte_Tally
    WHERE LeftOver <> ''
)
SELECT Line, F, T, SUM(MoveCnt) AS CurrentCnt, 0 AS NextCnt
INTO ##TallyTable 
FROM cte_Tally
GROUP BY Line, F, T

;WITH cte_AddZeros AS (
    SELECT Line, FVal, TVal FROM ##ConvertDirectional 
    CROSS APPLY (SELECT Line FROM ##TallyTable GROUP BY Line) S
    GROUP BY Line, FVal, TVal
)
INSERT ##TallyTable (Line, F, T, CurrentCnt, NextCnt)
SELECT c.Line, c.FVal, c.TVal, 0, 0
FROM cte_AddZeros c
LEFT JOIN ##TallyTable TT ON c.FVal = TT.F AND c.TVal = TT.T AND c.Line = TT.Line
WHERE TT.Line IS NULL

;WITH cte_Expand AS (
    SELECT FVal
    ,      TVal
    ,      'A' AS F
    ,      LEFT(Steps,1) AS T
    ,      SUBSTRING(Steps,2,LEN(Steps)) AS LeftOver
    FROM ##ConvertDirectional
    WHERE Steps <> ''

    UNION ALL

    SELECT FVal
    ,      TVal
    ,      T
    ,      LEFT(LeftOver,1) AS T
    ,      SUBSTRING(LeftOver,2,LEN(LeftOver))
    FROM cte_Expand
    WHERE LeftOver <> ''
)
SELECT FVal, TVal, F, T
INTO ##ConvertDirectionalExpanded
FROM cte_Expand


SELECT Line, CDE.F, CDE.T
, SUM(TT.CurrentCnt)
--,*
FROM ##TallyTable TT
INNER JOIN ##ConvertDirectionalExpanded CDE ON TT.F = CDE.FVal AND TT.T = CDE.TVal
WHERE Line = '083a' AND CurrentCnt > 0 
GROUP BY Line, CDE.F, CDE.T


--DROP TABLE ##ConvertDirectionalExpanded

SELECT * FROM ##TallyTable WHERE Line = '083A' AND CurrentCnt <> 0
--SELECT SUM(LEN(Steps1)*Cnt) FROM ##ConvertNumeric2

SELECT * FROM ##ConvertNumeric ORDER BY FVal, TVal
SELECT * FROM ##ConvertDirectional
SELECT * FROM ##ConvertDirectionalExpanded WHERE FVal = 'A' AND TVal = '<'
SELECT * FROM ##ConvertDirectionalExpanded WHERE FVal = '<' AND TVal = 'A'

SELECT * FROM ##ConvertNumeric WHERE (FVal = 'A' AND TVal = '0')
                                  OR (FVal = '0' AND TVal = '8')
                                  OR (FVal = '8' AND TVal = '3')
                                  OR (FVal = '3' AND TVal = 'A')
/*
Line	LineValue	StepLen	StepLen2	StepLen1
083A	    83	        66	    28	        12
341A	    341	        72	    28	        12
582A	    582	        68	    28	        12
638A	    638	        70	    30	        14
671A	    671	        74	    30	        14
*/


/*

DROP TABLE ##Keypad
DROP TABLE ##ConvertNumeric
DROP TABLE ##ConvertNumeric2
DROP TABLE ##DirKeyPad
DROP TABLE ##ConvertDirectional
DROP TABLE ##TallyTable

*/


/*
169132 is too high

*/


