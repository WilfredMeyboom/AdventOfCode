USE Test_WME

SET NOCOUNT ON

DECLARE @year VARCHAR(4) = '2015'
DECLARE @day VARCHAR(2)  = '18'

EXEC dbo.GetInput @year = @year, @day = @day
EXEC dbo.ParseInput @year = @year, @day = @day

CREATE TABLE ##Lights (ID INT IDENTITY(1,1), X INT, Y INT, IsOn INT)
CREATE UNIQUE INDEX UQ_Lights ON ##Lights (X,Y) INCLUDE (IsOn)

INSERT ##Lights (X, Y, IsOn)
SELECT RowNr, ColNr, CASE WHEN Val = '#' THEN 1 ELSE 0 END FROM ##InputGrid


DECLARE @Counter INT = 0

WHILE @Counter < 100
BEGIN

    ;WITH cte_Neigbours AS (
        SELECT L1.ID, SUM(L2.IsOn) AS AreOn
        FROM ##Lights L1
        INNER JOIN ##Lights L2 ON (ABS(L1.X - L2.X) <= 1 AND ABS(L1.Y - L2.Y) <= 1) AND L1.ID <> L2.ID
        GROUP BY L1.ID
    )
    UPDATE L
    SET L.IsOn = CASE WHEN L.IsOn = 1 AND N.AreOn IN (2,3) THEN 1
                      WHEN L.IsOn = 0 AND N.AreOn = 3      THEN 1
                      ELSE 0 END
    FROM ##Lights L
    INNER JOIN cte_Neigbours N ON L.ID = N.ID

    SET @Counter = @Counter + 1

    PRINT 'Counter: ' + CAST(@Counter AS VARCHAR(3)) + ' at ' + CAST(GETDATE() AS VARCHAR(100))

END

SELECT SUM(IsOn) AS Part1 FROM ##Lights

-- Runtime 00:12:00

TRUNCATE TABLE ##Lights

INSERT ##Lights (X, Y, IsOn)
SELECT RowNr, ColNr, CASE WHEN Val = '#' THEN 1 ELSE 0 END FROM ##InputGrid


UPDATE L
SET L.IsOn = 1
FROM ##Lights L
    WHERE (L.X = 0 AND L.Y = 0)
       OR (L.X = 0 AND L.Y = 99)
       OR (L.X = 99 AND L.Y = 0)
       OR (L.X = 99 AND L.Y = 99)

SET @Counter = 0

WHILE @Counter < 100
BEGIN

    ;WITH cte_Neigbours AS (
        SELECT L1.ID, SUM(L2.IsOn) AS AreOn
        FROM ##Lights L1
        INNER JOIN ##Lights L2 ON (ABS(L1.X - L2.X) <= 1 AND ABS(L1.Y - L2.Y) <= 1) AND L1.ID <> L2.ID
        GROUP BY L1.ID
    )
    UPDATE L
    SET L.IsOn = CASE WHEN L.IsOn = 1 AND N.AreOn IN (2,3) THEN 1
                      WHEN L.IsOn = 0 AND N.AreOn = 3      THEN 1
                      ELSE 0 END
    FROM ##Lights L
    INNER JOIN cte_Neigbours N ON L.ID = N.ID

    UPDATE L
    SET L.IsOn = 1
    FROM ##Lights L
    WHERE (L.X = 0 AND L.Y = 0)
       OR (L.X = 0 AND L.Y = 99)
       OR (L.X = 99 AND L.Y = 0)
       OR (L.X = 99 AND L.Y = 99)

    SET @Counter = @Counter + 1

    PRINT 'Counter: ' + CAST(@Counter AS VARCHAR(3)) + ' at ' + CAST(GETDATE() AS VARCHAR(100))

END

SELECT SUM(IsOn) AS Part2 FROM ##Lights


DROP TABLE ##Lights

--Total runtime 00:20:43
