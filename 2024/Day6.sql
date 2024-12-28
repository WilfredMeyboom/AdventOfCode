USE Test_WME

SET NOCOUNT ON

DECLARE @year VARCHAR(4) = '2024'
DECLARE @day VARCHAR(2)  = '6'

EXEC dbo.GetInput @year = @year, @day = @day
EXEC dbo.ParseInput @year = @year, @day = @day 

--SELECT TOP 10 * FROM ##Input
--SELECT TOP 10 * FROM ##InputInts
--SELECT TOP 10 * FROM ##InputNumbered
--SELECT TOP 10 * FROM ##InputGrid
--SELECT TOP 10 * FROM ##InputSplit
--SELECT TOP 10 * FROM ##InputSplitCust

DECLARE @X INT
DECLARE @Y INT
DECLARE @Dir CHAR

SELECT @X = ColNr, @Y = RowNr, @Dir = 'N' FROM ##InputGrid WHERE Val = '^'

CREATE TABLE ##Steps (ID INT IDENTITY, X INT, Y INT, Dir CHAR)

INSERT ##Steps (X, Y, Dir) SELECT @X, @Y, @Dir

WHILE EXISTS (SELECT 1 FROM ##InputGrid WHERE ColNr = @X AND RowNr = @Y)
BEGIN

    IF @Dir = 'N' SET @Y = @Y - 1
    IF @Dir = 'S' SET @Y = @Y + 1
    IF @Dir = 'W' SET @X = @X - 1
    IF @Dir = 'E' SET @X = @X + 1

    IF (SELECT Val FROM ##InputGrid WHERE ColNr = @X AND RowNr = @Y) = '#'
    BEGIN
    -- Step back and turn
        IF @Dir = 'N' SET @Y = @Y + 1
        IF @Dir = 'S' SET @Y = @Y - 1
        IF @Dir = 'W' SET @X = @X + 1
        IF @Dir = 'E' SET @X = @X - 1

        IF @Dir = 'N' SET @Dir = 'E'
        ELSE IF @Dir = 'E' SET @Dir = 'S'
        ELSE IF @Dir = 'S' SET @Dir = 'W'
        ELSE IF @Dir = 'W' SET @Dir = 'N'

    END
    ELSE
    BEGIN
        INSERT ##Steps (X, Y, Dir) SELECT @X, @Y, @Dir
    END

END

--Don't forget to disregard the last step
DELETE FROM ##Steps WHERE X = @X AND Y = @Y AND Dir = @Dir

;WITH cte_Pos AS (
    SELECT X, Y FROM ##Steps GROUP BY X, Y
)
SELECT COUNT(1) Part1 FROM cte_Pos


--Refocus on the starting position
SELECT @X = ColNr, @Y = RowNr, @Dir = 'N' FROM ##InputGrid WHERE Val = '^'

-- We'll be using the Steps table to create parallel versions of the grid
-- But we don't need the starting position for that
DELETE FROM ##Steps WHERE X = @X AND Y = @Y AND Dir = @Dir

-- Prepare all the guards (at the same starting position & direction)
CREATE TABLE ##Guards (ID INT IDENTITY(1,1), X INT, Y INT, Z INT, Dir CHAR, Active BIT)

INSERT ##Guards(X, Y, Z, Dir, Active)
SELECT @X, @Y, ROW_NUMBER() OVER (ORDER BY (SELECT 0)), @Dir, 1
FROM ##Steps
GROUP BY X, Y

CREATE TABLE ##PossibleLayouts (ID INT IDENTITY(1,1), RowNr INT, ColNr INT, LayoutNr INT, Val CHAR)

-- 8 min
INSERT ##PossibleLayouts (RowNr, ColNr, LayoutNr, Val)
SELECT RowNr
,      ColNr
,      S.LayoutNr
,      Val--CASE WHEN X = ColNr AND Y = RowNr THEN '#' ELSE Val END AS Val
FROM ##InputGrid I
CROSS APPLY (
    SELECT X, Y, ROW_NUMBER() OVER (ORDER BY (SELECT 0)) AS LayoutNr
    FROM ##Steps
    GROUP BY X, Y
    ) S

UPDATE P
SET Val = '#'
FROM ##PossibleLayouts P
INNER JOIN (
    SELECT X, Y, ROW_NUMBER() OVER (ORDER BY (SELECT 0)) AS LayoutNr
    FROM ##Steps
    GROUP BY X, Y
    ) S ON S.X = P.ColNr AND S.Y = P.RowNr AND S.LayoutNr = P.LayoutNr

-- 5 min
CREATE UNIQUE INDEX UQ_PL ON ##PossibleLayouts(RowNr, ColNr, LayoutNr)

CREATE TABLE ##MultipleSteps (ID INT IDENTITY, X INT, Y INT, Z INT, Dir CHAR)

INSERT ##MultipleSteps (X, Y, Z, Dir) SELECT X, Y, Z, Dir FROM ##Guards

CREATE NONCLUSTERED INDEX IX_MS
ON [dbo].[##MultipleSteps] ([X],[Y],[Z],[Dir])
INCLUDE ([ID])

DECLARE @I INT = 1

WHILE (SELECT COUNT(1) FROM ##Guards WHERE Active = 1) > 0
BEGIN

    UPDATE G
    SET X = CASE WHEN Dir = 'E' THEN X + 1
                 WHEN Dir = 'W' THEN X - 1
                 ELSE X END
    ,   Y = CASE WHEN Dir = 'N' THEN Y - 1
                 WHEN Dir = 'S' THEN Y + 1
                 ELSE Y END
    FROM ##Guards G
    WHERE G.Active = 1

    INSERT ##MultipleSteps (X, Y, Z, Dir) 
    SELECT X, Y, Z, Dir 
    FROM ##Guards G
    LEFT JOIN ##PossibleLayouts P ON G.X = P.ColNr AND G.Y = P.RowNr AND G.Z = P.LayoutNr
    WHERE P.Val <> '#' AND G.Active = 1

    UPDATE G
    SET X = CASE WHEN Dir = 'E' THEN X - 1
                 WHEN Dir = 'W' THEN X + 1
                 ELSE X END
    ,   Y = CASE WHEN Dir = 'N' THEN Y + 1
                 WHEN Dir = 'S' THEN Y - 1
                 ELSE Y END
    ,   Dir = CASE WHEN Dir = 'N' THEN 'E'
                   WHEN Dir = 'E' THEN 'S'
                   WHEN Dir = 'S' THEN 'W'
                   WHEN Dir = 'W' THEN 'N'
                END
    FROM ##Guards G
    INNER JOIN ##PossibleLayouts P ON G.X = P.ColNr AND G.Y = P.RowNr AND G.Z = P.LayoutNr AND P.Val = '#'
    WHERE G.Active = 1

    ;WITH cte_Loop AS (
        SELECT M1.Z
        FROM ##MultipleSteps M1
        INNER JOIN ##MultipleSteps M2 ON M1.X = M2.X AND M1.Y = M2.Y AND M1.Z = M2.Z AND M1.Dir = M2.Dir AND M1.ID <> M2.ID
        GROUP BY M1.Z
    )
    UPDATE G
    SET Active = 0
    FROM ##Guards G
    LEFT JOIN ##PossibleLayouts P ON G.X = P.ColNr AND G.Y = P.RowNr AND G.Z = P.LayoutNr
    LEFT JOIN cte_Loop c ON c.Z = G.Z
    WHERE (P.ID IS NULL OR c.Z IS NOT NULL) AND G.Active = 1

    PRINT 'Iteration: ' + CAST(@I AS VARCHAR(5)) + ' ' + CAST(GETDATE() AS VARCHAR(50))
    SET @I = @I + 1

END


SELECT COUNT(1) AS Part2
FROM ##Guards G
INNER JOIN ##PossibleLayouts P ON G.X = P.ColNr AND G.Y = P.RowNr AND G.Z = P.LayoutNr


/*
DROP TABLE ##Steps
DROP TABLE ##PossibleLayouts
DROP TABLE ##Guards
DROP TABLE ##MultipleSteps
*/

--4933 is too high
-- 6091 iteraties nodig