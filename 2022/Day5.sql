USE Test_WME

DECLARE @year VARCHAR(4) = '2022'
DECLARE @day VARCHAR(2)  = '5'

EXEC dbo.GetInput @year = @year, @day = @day
EXEC dbo.ParseInput @year = @year, @day = @day, @SplitCustom ='{ }' 

--SELECT TOP 10 * FROM ##Input
--SELECT TOP 10 * FROM ##InputInts
--SELECT TOP 10 * FROM ##InputNumbered
--SELECT TOP 10 * FROM ##InputGrid
--SELECT TOP 1000 * FROM ##InputSplit
--SELECT TOP 10 * FROM ##InputSplitCust


CREATE TABLE ##Stacks (ID INT IDENTITY(1,1), Stack INT, Pos INT, Letter CHAR)
CREATE UNIQUE INDEX uq_stacks ON ##Stacks (Stack, Pos)

INSERT ##Stacks(Stack, Pos, Letter)
SELECT REPLACE(Col, 'Col', '') AS Stack, Pos, Val
FROM (
SELECT 9 - Ind AS Pos
,      SUBSTRING(Line,2,1) AS Col1
,      SUBSTRING(Line,6,1) AS Col2
,      SUBSTRING(Line,10,1) AS Col3
,      SUBSTRING(Line,14,1) AS Col4
,      SUBSTRING(Line,18,1) AS Col5
,      SUBSTRING(Line,22,1) AS Col6
,      SUBSTRING(Line,26,1) AS Col7
,      SUBSTRING(Line,30,1) AS Col8
,      SUBSTRING(Line,34,1) AS Col9
FROM ##InputNumbered WHERE Ind < 9
) P
UNPIVOT (Val FOR Col IN (Col1, Col2, Col3, Col4, Col5, Col6, Col7, Col8, Col9)
) AS P2
WHERE Val <> ''
ORDER BY Stack, Pos

SELECT * 
INTO ##Stacks2
FROM ##Stacks 
ORDER BY Stack, Pos

CREATE UNIQUE INDEX uq_stacks2 ON ##Stacks2 (Stack, Pos)



/*
[P]     [L]         [T]            
[L]     [M] [G]     [G]     [S]    
[M]     [Q] [W]     [H] [R] [G]    
[N]     [F] [M]     [D] [V] [R] [N]
[W]     [G] [Q] [P] [J] [F] [M] [C]
[V] [H] [B] [F] [H] [M] [B] [H] [B]
[B] [Q] [D] [T] [T] [B] [N] [L] [D]
[H] [M] [N] [Z] [M] [C] [M] [P] [P]
 1   2   3   4   5   6   7   8   9 
*/



/* declare variables */
DECLARE @RowNr INT
DECLARE @BoxAmount INT
DECLARE @FromStack INT
DECLARE @ToStack INT


DECLARE actionCursor CURSOR FAST_FORWARD READ_ONLY FOR 
SELECT Rownr
, CAST([2]AS INT) AS BoxAmount
, CAST([4]AS INT) AS FromStack
, CAST([6]AS INT) AS ToStack
FROM (   
SELECT RowNr, Piecenr, Piece FROM ##InputSplit WHERE ind > 66 AND Piecenr IN (2,4,6) --ORDER BY RowNr, Piecenr
) t
PIVOT (MAX(Piece) FOR PieceNr IN ([2],[4],[6])) AS PT
ORDER BY RowNr

OPEN actionCursor

FETCH NEXT FROM actionCursor INTO @RowNr, @BoxAmount, @FromStack, @ToStack

DECLARE @Counter INT

WHILE @@FETCH_STATUS = 0
BEGIN
    
    SET @Counter = 0

    WHILE @Counter < @BoxAmount
    BEGIN
    
        ;WITH cte_NewPos AS (
            SELECT MAX(S.Pos) + 1 AS np FROM ##Stacks S WHERE S.Stack = @ToStack
        )
        UPDATE S 
        SET Stack = @ToStack, Pos = ISNULL(C.np, 1)
        FROM ##Stacks S
        CROSS APPLY cte_NewPos C
        WHERE S.Stack = @FromStack
        AND S.Pos = (SELECT MAX(Pos) FROM ##Stacks S2 WHERE S2.Stack = @FromStack)

        SET @Counter = @Counter + 1
    END

    FETCH NEXT FROM actionCursor INTO @RowNr, @BoxAmount, @FromStack, @ToStack
END

CLOSE actionCursor
DEALLOCATE actionCursor


;WITH cte_Max AS (
    SELECT Stack, MAX(Pos) AS MaxPos
    FROM ##Stacks S
    GROUP BY Stack
)
SELECT [1]+[2]+[3]+[4]+[5]+[6]+[7]+[8]+[9] AS Part1
FROM (
    SELECT S.Stack, S.Letter FROM ##Stacks S 
    INNER JOIN cte_Max c ON c.Stack = S.Stack AND c.MaxPos = S.Pos
    --ORDER BY S.Stack, Pos
) T
PIVOT (MAX(Letter) FOR Stack IN ([1],[2],[3],[4],[5],[6],[7],[8],[9])
) AS pvt


-- WHTLRMZRC is correct for Part1


DECLARE actionCursor2 CURSOR FAST_FORWARD READ_ONLY FOR 
SELECT Rownr
, CAST([2]AS INT) AS BoxAmount
, CAST([4]AS INT) AS FromStack
, CAST([6]AS INT) AS ToStack
FROM (   
SELECT RowNr, Piecenr, Piece FROM ##InputSplit WHERE ind > 66 AND Piecenr IN (2,4,6) --ORDER BY RowNr, Piecenr
) t
PIVOT (MAX(Piece) FOR PieceNr IN ([2],[4],[6])) AS PT
ORDER BY RowNr

OPEN actionCursor2

FETCH NEXT FROM actionCursor2 INTO @RowNr, @BoxAmount, @FromStack, @ToStack

WHILE @@FETCH_STATUS = 0
BEGIN
    
    ;WITH cte_NewPos AS (
        SELECT MAX(S.Pos) + 1 AS np FROM ##Stacks2 S WHERE S.Stack = @ToStack
    ), cte_OldPos AS (
        SELECT MAX(Pos) - @BoxAmount AS op FROM ##Stacks2 S2 WHERE S2.Stack = @FromStack
    )
    UPDATE S
    SET Stack = @ToStack, Pos = ISNULL(C.np, 1) + S.Pos - C2.op - 1
    FROM ##Stacks2 S
    CROSS APPLY cte_NewPos C
    CROSS APPLY cte_OldPos C2
    WHERE S.Stack = @FromStack
    AND S.Pos > C2.op

    FETCH NEXT FROM actionCursor2 INTO @RowNr, @BoxAmount, @FromStack, @ToStack
END

CLOSE actionCursor2
DEALLOCATE actionCursor2


;WITH cte_Max AS (
    SELECT Stack, MAX(Pos) AS MaxPos
    FROM ##Stacks2 S
    GROUP BY Stack
)
SELECT [1]+[2]+[3]+[4]+[5]+[6]+[7]+[8]+[9] AS Part2 
FROM (
    SELECT S.Stack, S.Letter FROM ##Stacks2 S 
    INNER JOIN cte_Max c ON c.Stack = S.Stack AND c.MaxPos = S.Pos
    --ORDER BY S.Stack, Pos
) T
PIVOT (MAX(Letter) FOR Stack IN ([1],[2],[3],[4],[5],[6],[7],[8],[9])
) AS pvt

DROP TABLE ##Stacks
DROP TABLE ##Stacks2

-- GMPMLWNMG is correct for Part2

