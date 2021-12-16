USE Test_WME

SET NOCOUNT ON

DECLARE @year VARCHAR(4) = '2021'
DECLARE @day VARCHAR(2)  = '10'

EXEC dbo.GetInput @year = @year, @day = @day
EXEC dbo.ParseInput @year = @year, @day = @day 

--SELECT TOP 10 * FROM ##InputNumbered
--SELECT * FROM ##InputGrid
--SELECT TOP 10 * FROM ##InputInts
--SELECT TOP 10 * FROM ##InputSplit
--SELECT TOP 10 * FROM ##InputSplitCust

DECLARE @CleanupOngoing INT = 1

WHILE @CleanupOngoing > 0
BEGIN

    ;WITH cte_combiVal AS( 
        SELECT RowNr
        ,      ColNr
        ,      Val
        ,      LEAD(ColNr) OVER (PARTITION BY RowNr ORDER BY ColNr) AS NextColNr
        ,      LEAD(Val) OVER (PARTITION BY RowNr ORDER BY ColNr) AS NextVal
        FROM ##InputGrid
        GROUP BY RowNr, ColNr, Val
    )
    DELETE I
    FROM ##InputGrid I
    INNER JOIN cte_combiVal c ON I.RowNr = c.RowNr AND (I.ColNr = c.ColNr OR I.ColNr = c.NextColNr)
    WHERE (c.Val = '(' AND c.NextVal = ')')
       OR (c.Val = '[' AND c.NextVal = ']')
       OR (c.Val = '{' AND c.NextVal = '}')
       OR (c.Val = '<' AND c.NextVal = '>')

    SET @CleanupOngoing = @@ROWCOUNT

END


;WITH cte_IncorrectLines AS (
    SELECT RowNr, MIN(ColNr) AS ColNr FROM ##InputGrid G 
    WHERE Val IN (')',']','}','>')
    GROUP BY RowNr
)
SELECT SUM(CASE WHEN Val = ')' THEN 3
               WHEN Val = ']' THEN 57
               WHEN Val = '}' THEN 1197
               WHEN Val = '>' THEN 25137
               END) AS Part1
FROM ##InputGrid g
INNER JOIN cte_IncorrectLines c ON G.RowNr = c.RowNr AND G.ColNr= C.ColNr

--367059 is correct for part 1

;WITH cte_IncorrectLines AS (
    SELECT RowNr
    FROM ##InputGrid G 
    WHERE Val IN (')',']','}','>')
    GROUP BY RowNr
), cte_LeftOvers AS (
    SELECT g.RowNr, ROW_NUMBER() OVER (PARTITION BY g.RowNr ORDER BY g.ColNr) AS ColNr,
    CASE WHEN Val = '(' THEN 1
         WHEN Val = '[' THEN 2
         WHEN Val = '{' THEN 3
         WHEN Val = '<' THEN 4
         END AS IntVal
    FROM ##InputGrid g
    LEFT JOIN cte_IncorrectLines c ON G.RowNr = c.RowNr     --Exclude incorrect lines
    WHERE c.RowNr IS NULL
), cte_Scores AS (
    SELECT c.RowNr
    ,      SUM(POWER(CAST(5 AS BIGINT),c.ColNr-1) * c.IntVal ) AS Score
    FROM cte_LeftOvers c
    GROUP BY c.RowNR
), cte_OrderScores AS (
    SELECT Score
    ,      COUNT(1) OVER (PARTITION BY '1') AS TotalRows
    ,      ROW_NUMBER() OVER (ORDER BY Score ASC) AS RowOrder 
    FROM   cte_Scores
)
SELECT c.Score AS Part2
FROM cte_OrderScores c 
WHERE c.RowOrder = ROUND(c.TotalRows / 2.0, 0)  

-- 1952146692 is correct for part 2