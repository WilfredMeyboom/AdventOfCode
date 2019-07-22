/*
Begin in state A.
Perform a diagnostic checksum after 12302209 steps.

In state A:
  If the current value is 0:
    - Write the value 1.
    - Move one slot to the right.
    - Continue with state B.
  If the current value is 1:
    - Write the value 0.
    - Move one slot to the left.
    - Continue with state D.

In state B:
  If the current value is 0:
    - Write the value 1.
    - Move one slot to the right.
    - Continue with state C.
  If the current value is 1:
    - Write the value 0.
    - Move one slot to the right.
    - Continue with state F.

In state C:
  If the current value is 0:
    - Write the value 1.
    - Move one slot to the left.
    - Continue with state C.
  If the current value is 1:
    - Write the value 1.
    - Move one slot to the left.
    - Continue with state A.

In state D:
  If the current value is 0:
    - Write the value 0.
    - Move one slot to the left.
    - Continue with state E.
  If the current value is 1:
    - Write the value 1.
    - Move one slot to the right.
    - Continue with state A.

In state E:
  If the current value is 0:
    - Write the value 1.
    - Move one slot to the left.
    - Continue with state A.
  If the current value is 1:
    - Write the value 0.
    - Move one slot to the right.
    - Continue with state B.

In state F:
  If the current value is 0:
    - Write the value 0.
    - Move one slot to the right.
    - Continue with state C.
  If the current value is 1:
    - Write the value 0.
    - Move one slot to the right.
    - Continue with state E.
*/

SET NOCOUNT ON
CREATE TABLE ##Blueprints (ID INT IDENTITY(1,1), State CHAR(1), Value INT, Write INT, Move CHAR(1), NextState CHAR(1))

INSERT ##Blueprints (State, Value, Write, Move, NextState) VALUES ('A', 0, 1, 'R', 'B')
INSERT ##Blueprints (State, Value, Write, Move, NextState) VALUES ('A', 1, 0, 'L', 'D')
INSERT ##Blueprints (State, Value, Write, Move, NextState) VALUES ('B', 0, 1, 'R', 'C')
INSERT ##Blueprints (State, Value, Write, Move, NextState) VALUES ('B', 1, 0, 'R', 'F')
INSERT ##Blueprints (State, Value, Write, Move, NextState) VALUES ('C', 0, 1, 'L', 'C')
INSERT ##Blueprints (State, Value, Write, Move, NextState) VALUES ('C', 1, 1, 'L', 'A')
INSERT ##Blueprints (State, Value, Write, Move, NextState) VALUES ('D', 0, 0, 'L', 'E')
INSERT ##Blueprints (State, Value, Write, Move, NextState) VALUES ('D', 1, 1, 'R', 'A')
INSERT ##Blueprints (State, Value, Write, Move, NextState) VALUES ('E', 0, 1, 'L', 'A')
INSERT ##Blueprints (State, Value, Write, Move, NextState) VALUES ('E', 1, 0, 'R', 'B')
INSERT ##Blueprints (State, Value, Write, Move, NextState) VALUES ('F', 0, 0, 'R', 'C')
INSERT ##Blueprints (State, Value, Write, Move, NextState) VALUES ('F', 1, 0, 'R', 'E')

DECLARE @CurrentState CHAR(1) = 'A'
DECLARE @NrOfSteps BIGINT = 12302209 
DECLARE @Counter INT = 0
DECLARE @CurrentValue INT = 0
DECLARE @CurrentPos INT = 0

CREATE TABLE ##Tape (ID INT IDENTITY(1,1), Pos INT, Value INT)

INSERT ##Tape (Pos, Value) VALUES (0, 0)

ALTER TABLE ##Tape ADD CONSTRAINT UQ_Pos UNIQUE (Pos)

SELECT @Counter, GETDATE(), SUM(Value) FROM ##Tape

WHILE @Counter < @NrOfSteps
BEGIN

    SELECT @CurrentValue = Value FROM ##Tape WHERE Pos = @CurrentPos

    UPDATE T 
    SET T.Value = B.Write
    ,   @CurrentPos = @CurrentPos + CASE WHEN B.Move = 'L' THEN -1 ELSE 1 END
    ,   @CurrentState = B.NextState
    FROM ##Tape T
    INNER JOIN ##Blueprints B ON B.State = @CurrentState AND B.Value = @CurrentValue
    WHERE Pos = @CurrentPos

    IF NOT EXISTS (SELECT 1 FROM ##Tape WHERE Pos = @CurrentPos)
        INSERT ##Tape (Pos, Value) VALUES (@CurrentPos, 0)

    SET @Counter = @Counter + 1

    --SELECT @CurrentState, @CurrentPos, * FROM ##Tape
    --PRINT @CurrentState

    IF (@Counter % 1000000 = 0) SELECT @Counter, GETDATE(), SUM(Value) FROM ##Tape

END

SELECT SUM(Value) FROM ##Tape



/*

DROP TABLE ##Tape
DROP TABLE ##Blueprints


*/