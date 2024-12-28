USE Test_WME

SET NOCOUNT ON

DECLARE @year VARCHAR(4) = '2024'
DECLARE @day VARCHAR(2)  = '3'

EXEC dbo.GetInput @year = @year, @day = @day
EXEC dbo.ParseInput @year = @year, @day = @day, @SplitCustom = 'mul' 

--SELECT TOP 10 * FROM ##Input
--SELECT TOP 10 * FROM ##InputInts
--SELECT TOP 10 * FROM ##InputNumbered
--SELECT TOP 10 * FROM ##InputGrid
--SELECT TOP 10 * FROM ##InputSplit
--SELECT TOP 10 * FROM ##InputSplitCust

;WITH cte_CutMul AS (
    SELECT LEFT(Line,  CHARINDEX('mul',Line) - 1) AS Piece
    , SUBSTRING(Line, CHARINDEX('mul',Line) + 3, LEN(Line)) AS LeftOver
    , CASE WHEN CHARINDEX('mul',Line) > 0 THEN 0 ELSE 1 END AS LastPiece
    --, Line AS OriginalLine
    FROM ##Input
 
    UNION ALL

    SELECT LEFT(LeftOver,  CHARINDEX('mul',LeftOver) - 1) 
    ,      SUBSTRING(LeftOver, CHARINDEX('mul',LeftOver) + 3, LEN(LeftOver))
    , CASE WHEN CHARINDEX('mul',SUBSTRING(LeftOver, CHARINDEX('mul',LeftOver) + 3, LEN(LeftOver))) > 0 THEN 0 ELSE 1 END 
    FROM cte_CutMul
    WHERE CHARINDEX('mul',LeftOver) > 0
), cte_ShreddedInput AS (
    SELECT Piece
    FROM cte_CutMul
    UNION ALL 
    SELECT LeftOver
    FROM cte_CutMul
    WHERE LastPiece = 1
)
SELECT SUM(
    CAST(SUBSTRING(Piece, 2, CHARINDEX(',',Piece) - 2) AS INT) * -- First Nr
    CAST(SUBSTRING(Piece, CHARINDEX(',',Piece) + 1, CHARINDEX(')',Piece) - CHARINDEX(',', Piece) - 1) AS INT)
    ) AS Part1
FROM cte_ShreddedInput
WHERE LEFT(Piece,1) = '('
AND CHARINDEX(',',Piece) > 1
AND TRY_CAST(SUBSTRING(Piece, 2, CHARINDEX(',',Piece) - 2) AS INT) IS NOT NULL
AND CHARINDEX(')',Piece) > 1
AND TRY_CAST(SUBSTRING(Piece, CHARINDEX(',',Piece) + 1, CHARINDEX(')',Piece) - CHARINDEX(',', Piece) - 1) AS INT) IS NOT NULL
OPTION (MAXRECURSION 20000)

DECLARE @Input VARCHAR(MAX) = ''

SELECT @Input = [1] + [2] + [3] + [4] + [5] + [6]
FROM (SELECT Ind, Line FROM ##InputNumbered) AS Src
PIVOT (
    MAX(Line)
    FOR Ind IN ([1], [2], [3], [4], [5], [6])
    ) AS Pvt


;WITH cte_CutDo AS (
    SELECT LEFT(@Input,  CHARINDEX('do',@Input) - 1) AS Piece
    , SUBSTRING(@Input, CHARINDEX('do',@Input) + 2, LEN(@Input)) AS LeftOver
    , CASE WHEN CHARINDEX('do',@Input) > 0 THEN 0 ELSE 1 END AS LastPiece
    --, @Input AS OriginalLine
    , 1 AS Lvl
    
    UNION ALL

    SELECT LEFT(LeftOver,  CHARINDEX('do',LeftOver) - 1) 
    ,      SUBSTRING(LeftOver, CHARINDEX('do',LeftOver) + 2, LEN(LeftOver))
    , CASE WHEN CHARINDEX('do',SUBSTRING(LeftOver, CHARINDEX('do',LeftOver) + 2, LEN(LeftOver))) > 0 THEN 0 ELSE 1 END 
    , Lvl + 1
    FROM cte_CutDo
    WHERE CHARINDEX('do',LeftOver) > 0
), cte_newInput AS (
    SELECT Piece AS Line
    FROM cte_CutDo
    WHERE (LEFT(Piece, 2) = '()' OR Lvl = 1)
    AND CHARINDEX('mul', Piece) > 0
    UNION ALL
    SELECT LeftOver
    FROM cte_CutDo 
    WHERE LastPiece = 1
    AND (LEFT(LeftOver, 2) = '()' OR Lvl = 1)
    AND CHARINDEX('mul', LeftOver) > 0
)
SELECT Line
INTO ##Input2
FROM cte_newInput

--SELECT * FROM ##Input2

;WITH cte_CutMul AS (
    SELECT LEFT(Line,  CHARINDEX('mul',Line) - 1) AS Piece
    , SUBSTRING(Line, CHARINDEX('mul',Line) + 3, LEN(Line)) AS LeftOver
    , CASE WHEN CHARINDEX('mul',SUBSTRING(Line, CHARINDEX('mul',Line) + 3, LEN(Line))) > 0 THEN 0 ELSE 1 END AS LastPiece
    --, Line AS OriginalLine
    FROM ##Input2
    UNION ALL

    SELECT LEFT(LeftOver,  CHARINDEX('mul',LeftOver) - 1) 
    ,      SUBSTRING(LeftOver, CHARINDEX('mul',LeftOver) + 3, LEN(LeftOver))
    , CASE WHEN CHARINDEX('mul',SUBSTRING(LeftOver, CHARINDEX('mul',LeftOver) + 3, LEN(LeftOver))) > 0 THEN 0 ELSE 1 END 
    FROM cte_CutMul
    WHERE CHARINDEX('mul',LeftOver) > 0
), cte_ShreddedInput AS (
    SELECT Piece
    FROM cte_CutMul
    UNION ALL 
    SELECT LeftOver
    FROM cte_CutMul
    WHERE LastPiece = 1
)
SELECT SUM(
    CAST(SUBSTRING(Piece, 2, CHARINDEX(',',Piece) - 2) AS INT) * -- First Nr
    CAST(SUBSTRING(Piece, CHARINDEX(',',Piece) + 1, CHARINDEX(')',Piece) - CHARINDEX(',', Piece) - 1) AS INT)
    ) AS Part2
    --CAST(SUBSTRING(Piece, 2, CHARINDEX(',',Piece) - 2) AS INT) , -- First Nr
    --CAST(SUBSTRING(Piece, CHARINDEX(',',Piece) + 1, CHARINDEX(')',Piece) - CHARINDEX(',', Piece) - 1) AS INT)

FROM cte_ShreddedInput
WHERE LEFT(Piece,1) = '('
AND CHARINDEX(',',Piece) > 1
AND TRY_CAST(SUBSTRING(Piece, 2, CHARINDEX(',',Piece) - 2) AS INT) IS NOT NULL
AND CHARINDEX(')',Piece) > 1
AND TRY_CAST(SUBSTRING(Piece, CHARINDEX(',',Piece) + 1, CHARINDEX(')',Piece) - CHARINDEX(',', Piece) - 1) AS INT) IS NOT NULL
OPTION (MAXRECURSION 20000)


DROP TABLE ##Input2

-- 107991598 Too high
--  98754185 Too high
--  93572208 is incorrect