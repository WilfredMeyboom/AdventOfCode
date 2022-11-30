USE Test_WME

SET NOCOUNT ON

DECLARE @year VARCHAR(4) = '2015'
DECLARE @day VARCHAR(2)  = '8'

EXEC dbo.GetInput @year = @year, @day = @day
EXEC dbo.ParseInput @year = @year, @day = @day 

;WITH cte_RemoveQuotes AS (
    SELECT ROW_NUMBER() OVER (ORDER BY (SELECT 0)) AS RowNr
    , SUBSTRING(Line, 2, LEN(Line) - 2) AS Line
    , LEN(Line) AS OriginalLength
    , Line AS OriginalLine
    FROM ##Input
), cte_Escaped AS (
    SELECT RowNr
    , REPLACE(REPLACE(Line, '\"', '"'), '\\', '/') AS Line
    , OriginalLength
    , OriginalLine
    FROM cte_RemoveQuotes
), cte_Hex AS (
    SELECT RowNr
    ,   1 AS Iteration
    ,   CASE WHEN CHARINDEX('\x', Line) > 0 THEN 
            REPLACE(Line, SUBSTRING(Line, CHARINDEX('\x', Line), 4), CHAR(CONVERT(INT, CONVERT(VARBINARY, SUBSTRING(Line, CHARINDEX('\x', Line) + 2, 2), 2)))) 
            ELSE Line END AS Line
    ,   OriginalLength
    ,   OriginalLine
    ,   Line AS EscapedLine
    FROM cte_Escaped
    UNION ALL
    SELECT RowNr
    ,   Iteration + 1
    ,   CASE WHEN CHARINDEX('\x', Line) > 0 THEN 
            REPLACE(Line, SUBSTRING(Line, CHARINDEX('\x', Line), 4), CHAR(CONVERT(INT, CONVERT(VARBINARY, SUBSTRING(Line, CHARINDEX('\x', Line) + 2, 2), 2)))) ELSE Line END AS Line
    ,   OriginalLength
    ,   OriginalLine
    ,   Line AS EscapedLine
    FROM cte_Hex
    WHERE CHARINDEX('\x', Line) > 0 
) 
SELECT --*, LEN(Line) AS NewLength
SUM(OriginalLength) AS TotalOriginalLength, SUM(LEN(Line)) AS TotalNewLength, SUM(OriginalLength) - SUM(LEN(Line)) AS Part1
FROM cte_Hex cH
INNER JOIN (SELECT RowNr, MAX(Iteration) AS MaxIter FROM cte_Hex GROUP BY RowNr) Sub ON cH.RowNr = Sub.RowNr AND cH.Iteration = Sub.MaxIter

-- 1371 is correct for Part 1


SELECT SUM(LEN(Line)) AS OriginalLength, SUM(LEN('"' + REPLACE(REPLACE(Line, '\', '\\'), '"', '\"') + '"')) AS NewLength
, SUM(LEN('"' + REPLACE(REPLACE(Line, '\', '\\'), '"', '\"') + '"')) - SUM(LEN(Line)) AS Part2
FROM ##Input

--2117 is correct for part 2
