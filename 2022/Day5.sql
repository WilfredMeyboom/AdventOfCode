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
SELECT TOP 10 * FROM ##InputSplitCust
  

CREATE TABLE ##Stacks (ID INT IDENTITY(1,1), Stack INT, Pos INT, Letter CHAR)
CREATE UNIQUE INDEX uq_stacks ON ##Stacks (Stack, Pos)


INSERT ##Stacks(Stack,Pos,Letter) VALUES (1,1,'H')
INSERT ##Stacks(Stack,Pos,Letter) VALUES (1,2,'B')
INSERT ##Stacks(Stack,Pos,Letter) VALUES (1,3,'V')
INSERT ##Stacks(Stack,Pos,Letter) VALUES (1,4,'W')
INSERT ##Stacks(Stack,Pos,Letter) VALUES (1,5,'N')
INSERT ##Stacks(Stack,Pos,Letter) VALUES (1,6,'M')
INSERT ##Stacks(Stack,Pos,Letter) VALUES (1,7,'L')
INSERT ##Stacks(Stack,Pos,Letter) VALUES (1,8,'P')

INSERT ##Stacks(Stack,Pos,Letter) VALUES (2,1,'M')
INSERT ##Stacks(Stack,Pos,Letter) VALUES (2,2,'Q')
INSERT ##Stacks(Stack,Pos,Letter) VALUES (2,3,'H')

INSERT ##Stacks(Stack,Pos,Letter) VALUES (3,1,'N')
INSERT ##Stacks(Stack,Pos,Letter) VALUES (3,2,'D')
INSERT ##Stacks(Stack,Pos,Letter) VALUES (3,3,'B')
INSERT ##Stacks(Stack,Pos,Letter) VALUES (3,4,'G')
INSERT ##Stacks(Stack,Pos,Letter) VALUES (3,5,'F')
INSERT ##Stacks(Stack,Pos,Letter) VALUES (3,6,'Q')
INSERT ##Stacks(Stack,Pos,Letter) VALUES (3,7,'M')
INSERT ##Stacks(Stack,Pos,Letter) VALUES (3,8,'L')

INSERT ##Stacks(Stack,Pos,Letter) VALUES (4,1,'Z')
INSERT ##Stacks(Stack,Pos,Letter) VALUES (4,2,'T')
INSERT ##Stacks(Stack,Pos,Letter) VALUES (4,3,'F')
INSERT ##Stacks(Stack,Pos,Letter) VALUES (4,4,'Q')
INSERT ##Stacks(Stack,Pos,Letter) VALUES (4,5,'M')
INSERT ##Stacks(Stack,Pos,Letter) VALUES (4,6,'W')
INSERT ##Stacks(Stack,Pos,Letter) VALUES (4,7,'G')

INSERT ##Stacks(Stack,Pos,Letter) VALUES (5,1,'M')
INSERT ##Stacks(Stack,Pos,Letter) VALUES (5,2,'T')
INSERT ##Stacks(Stack,Pos,Letter) VALUES (5,3,'H')
INSERT ##Stacks(Stack,Pos,Letter) VALUES (5,4,'P')

INSERT ##Stacks(Stack,Pos,Letter) VALUES (6,1,'C')
INSERT ##Stacks(Stack,Pos,Letter) VALUES (6,2,'B')
INSERT ##Stacks(Stack,Pos,Letter) VALUES (6,3,'M')
INSERT ##Stacks(Stack,Pos,Letter) VALUES (6,4,'J')
INSERT ##Stacks(Stack,Pos,Letter) VALUES (6,5,'D')
INSERT ##Stacks(Stack,Pos,Letter) VALUES (6,6,'H')
INSERT ##Stacks(Stack,Pos,Letter) VALUES (6,7,'G')
INSERT ##Stacks(Stack,Pos,Letter) VALUES (6,8,'T')

INSERT ##Stacks(Stack,Pos,Letter) VALUES (7,1,'M')
INSERT ##Stacks(Stack,Pos,Letter) VALUES (7,2,'N')
INSERT ##Stacks(Stack,Pos,Letter) VALUES (7,3,'B')
INSERT ##Stacks(Stack,Pos,Letter) VALUES (7,4,'F')
INSERT ##Stacks(Stack,Pos,Letter) VALUES (7,5,'V')
INSERT ##Stacks(Stack,Pos,Letter) VALUES (7,6,'R')

INSERT ##Stacks(Stack,Pos,Letter) VALUES (8,1,'P')
INSERT ##Stacks(Stack,Pos,Letter) VALUES (8,2,'L')
INSERT ##Stacks(Stack,Pos,Letter) VALUES (8,3,'H')
INSERT ##Stacks(Stack,Pos,Letter) VALUES (8,4,'M')
INSERT ##Stacks(Stack,Pos,Letter) VALUES (8,5,'R')
INSERT ##Stacks(Stack,Pos,Letter) VALUES (8,6,'G')
INSERT ##Stacks(Stack,Pos,Letter) VALUES (8,7,'S')

INSERT ##Stacks(Stack,Pos,Letter) VALUES (9,1,'P')
INSERT ##Stacks(Stack,Pos,Letter) VALUES (9,2,'D')
INSERT ##Stacks(Stack,Pos,Letter) VALUES (9,3,'B')
INSERT ##Stacks(Stack,Pos,Letter) VALUES (9,4,'C')
INSERT ##Stacks(Stack,Pos,Letter) VALUES (9,5,'N')


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
    
    --SET @Counter = 0

    --WHILE @Counter < @BoxAmount
    --BEGIN
    
    --    ;WITH cte_NewPos AS (
    --        SELECT MAX(S.Pos) + 1 AS np FROM ##Stacks S WHERE S.Stack = @ToStack
    --    )
    --    UPDATE S 
    --    SET Stack = @ToStack, Pos = ISNULL(C.np, 1)
    --    FROM ##Stacks S
    --    CROSS APPLY cte_NewPos C
    --    WHERE S.Stack = @FromStack
    --    AND S.Pos = (SELECT MAX(Pos) FROM ##Stacks S2 WHERE S2.Stack = @FromStack)

    --    SET @Counter = @Counter + 1
    --END

    ;WITH cte_NewPos AS (
        SELECT MAX(S.Pos) + 1 AS np FROM ##Stacks S WHERE S.Stack = @ToStack
    ), cte_OldPos AS (
        SELECT MAX(Pos) - @BoxAmount AS op FROM ##Stacks S2 WHERE S2.Stack = @FromStack
    )
    UPDATE S
    SET Stack = @ToStack, Pos = ISNULL(C.np, 1) + S.Pos - C2.op - 1
    FROM ##Stacks S
    CROSS APPLY cte_NewPos C
    CROSS APPLY cte_OldPos C2
    WHERE S.Stack = @FromStack
    AND S.Pos > C2.op

    FETCH NEXT FROM actionCursor INTO @RowNr, @BoxAmount, @FromStack, @ToStack
END

CLOSE actionCursor
DEALLOCATE actionCursor

;WITH cte_Max AS (
    SELECT Stack, MAX(Pos) AS MaxPos
    FROM ##Stacks S
    GROUP BY Stack
)
SELECT * FROM ##Stacks S 
INNER JOIN cte_Max c ON c.Stack = S.Stack AND c.MaxPos = S.Pos
ORDER BY S.Stack, Pos

DROP TABLE ##Stacks

--WHTLRMZRC


--GMPMLWNMG