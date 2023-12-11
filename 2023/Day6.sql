USE Test_WME

SET NOCOUNT ON

DECLARE @year VARCHAR(4) = '2023'
DECLARE @day VARCHAR(2)  = '6'

EXEC dbo.GetInput @year = @year, @day = @day
EXEC dbo.ParseInput @year = @year, @day = @day 

--SELECT TOP 10 * FROM ##Input
--SELECT TOP 10 * FROM ##InputInts
--SELECT TOP 10 * FROM ##InputNumbered
--SELECT TOP 10 * FROM ##InputGrid
--SELECT TOP 10 * FROM ##InputSplitCust
  
/*
    This is a formula puzzle. 
    
    From the text we know:
    D = v*t2        -- The distance travelled is the speed times the time left over to race
    v = t1          -- The speed is the time we took to charge the boat
    t_t = t1 + t2   -- The total time (t_t) is equal to the time we took to charge plus the time to race

    Combining these formulas gets us a quadratic formula for t1 (the charging time)
    D = t1*t2
    D = t1 * (t_t - t1)
    D = -t1^2 + t1*t_t
    t1^2 - t_t * t1 - D = 0

    If we assume D to be the current distance, we can solve for t1 thus getting two times in between which we would get a new record distance

    The quadratic formula states:
    ax^2 + bx + c = 0
    x = (-b +/- SQRT(b^2 - 4ac)) / (2*a)

    In our situation:
    a = 1
    b = -1 * t_t 
    c = D

    The example from the text
    Total_Time (t_t) = 7   and  Current Distance (D) = 9 
    -> t1^2 - 7t1 + 9 = 0

    t1 = (7 +/- SQRT(13)) / 2   =>  t1 = 1.7 or t2 = 5.3   which means we have a better distance from 2 to 5
    
*/

-- Combine the information about the race in one row
;WITH cte_input AS (
    SELECT CAST(I1.PieceNr AS INT) - 1 AS RaceNr, CAST(I1.Piece AS DECIMAL(18,2)) AS Total_Time, CAST(I2.Piece AS DECIMAL(18,2)) AS Current_Distance
    FROM ##InputSplit I1
    INNER JOIN ##InputSplit I2 ON I2.RowNr = 2 AND I1.PieceNr = I2.PieceNr 
    WHERE I1.PieceNr <> 1 AND I1.RowNr = 1
), cte_breakpoints AS (
    -- Apply the quadratic formula
    SELECT RaceNr
    ,      (Total_Time - SQRT(Total_Time*Total_Time - 4 * Current_Distance)) / 2 AS P1      -- Calculate the two points where between we get a better distance
    ,      (Total_Time + SQRT(Total_Time*Total_Time - 4 * Current_Distance)) / 2 AS P2
    FROM cte_input
)
SELECT ISNULL([1],1) * ISNULL([2],1) * ISNULL([3],1) * ISNULL([4],1) * ISNULL([5],1) * ISNULL([6],1) AS Part1
FROM  (
    SELECT RaceNr
    , FLOOR(P2) - CEILING(P1) + 1                                       -- Don't forget to include the border values
    - CASE WHEN FLOOR(P2) = P2 THEN 1 ELSE 0 END                        -- Correct the values if they end up exactly on an integer
    - CASE WHEN CEILING(P1) = P1 THEN 1 ELSE 0 END AS WinPossibilities  --  such a value would give you the same distance as the Current_Distance which isn't good enough to win the race
    FROM cte_breakpoints
) Sub
PIVOT (
    SUM(WinPossibilities)
    FOR RaceNr IN ([1],[2],[3],[4],[5],[6])    
) PVT


-- For part 2 we get bigger values but since we didn't brute force the previous answer we can apply the same solution (accounting for BIGINTs)
;WITH cte_input AS (
    SELECT CAST(REPLACE(SUBSTRING(I1.Line, 6, LEN(I1.Line)), ' ', '') AS BIGINT) AS Total_Time
    ,      CAST(REPLACE(SUBSTRING(I2.Line, 10, LEN(I2.Line)), ' ', '') AS BIGINT) AS Current_Distance
    FROM ##InputNumbered I1
    INNER JOIN ##InputNumbered I2 ON I1.Ind <> I2.Ind
    WHERE I1.Ind = 1

), cte_breakpoints AS (
    -- Calculate the quadratic formula
    SELECT (Total_Time - SQRT(Total_Time*Total_Time - 4 * Current_Distance)) / 2 AS P1
    ,      (Total_Time + SQRT(Total_Time*Total_Time - 4 * Current_Distance)) / 2 AS P2
    FROM cte_input
)
SELECT FLOOR(P2) - CEILING(P1) + 1 AS Part2 -- Don't forget to include the border values
FROM cte_breakpoints

