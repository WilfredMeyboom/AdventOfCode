USE Test_WME

SET NOCOUNT ON

DECLARE @year VARCHAR(4) = '2015'
DECLARE @day VARCHAR(2)  = '13'

EXEC dbo.GetInput @year = @year, @day = @day
EXEC dbo.ParseInput @year = @year, @day = @day

CREATE TABLE ##Happiness (ID INT IDENTITY(1,1), P_Left VARCHAR(10), P_Right VARCHAR(10), Happiness INT)


;WITH cte_PerPerson AS (
    SELECT [1] AS P1, CASE WHEN [3] = 'lose' THEN -1 ELSE 1 END * CAST([4] AS INT) AS Hap, [11] AS P2
    FROM (
        SELECT RowNr, PieceNr, Piece FROM ##InputSplit WHERE PieceNr IN (1,3,4,11)
    ) T
    PIVOT (
        MAX(Piece) FOR PieceNr IN ([1],[3],[4],[11])
    ) Pvt
)
INSERT ##Happiness (P_Left, P_Right, Happiness)
SELECT PP.P1, PP.P2, PP.Hap + OPP.Hap AS TotalHap
FROM cte_PerPerson PP
INNER JOIN cte_PerPerson OPP ON PP.P1 = OPP.P2 AND PP.P2 = OPP.P1    


;WITH cte_TablePlacement AS (
    SELECT P_Left
    ,      P_Right
    ,      CAST(P_Left + '|' + P_Right + '|' AS VARCHAR(MAX)) AS Placement
    ,      Happiness
    ,      Happiness AS MinHappy
    FROM ##Happiness

    UNION ALL

    SELECT c.P_Left
    ,      H.P_Right
    ,      CAST(c.Placement + H.P_Right + '|' AS VARCHAR(MAX))
    ,      c.Happiness + H.Happiness
    ,      CASE WHEN H.Happiness < MinHappy THEN H.Happiness ELSE MinHappy END
    FROM cte_TablePlacement c
    INNER JOIN ##Happiness H ON c.P_Right = H.P_Left AND c.Placement NOT LIKE '%' + H.P_Right + '%'

)
-- We assumed (correctly) that putting yourself in the best solution from part1 will give the best solution for part2
SELECT TOP 1 c.Happiness + H.Happiness AS Part1, c.Happiness + H.Happiness - MinHappy AS Part2
FROM cte_TablePlacement c
INNER JOIN ##Happiness H ON c.P_Left = H.P_Left AND c.P_Right = H.P_Right
ORDER BY c.Happiness + H.Happiness DESC


DROP TABLE ##Happiness