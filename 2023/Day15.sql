USE Test_WME

SET NOCOUNT ON

DECLARE @year VARCHAR(4) = '2023'
DECLARE @day VARCHAR(2)  = '15'

EXEC dbo.GetInput @year = @year, @day = @day
EXEC dbo.ParseInput @year = @year, @day = @day 

--SELECT TOP 10 * FROM ##Input
--SELECT TOP 10 * FROM ##InputInts
--SELECT TOP 10 * FROM ##InputNumbered
--SELECT TOP 10 * FROM ##InputGrid
--SELECT TOP 10 * FROM ##InputSplit
--SELECT TOP 10 * FROM ##InputSplitCust
  


CREATE TABLE ##Hashes (ID INT IDENTITY(1,1), Ind INT, HashString VARCHAR(10), NextValue INT, BoxNr INT)

/* declare variables */
DECLARE @Index INT
DECLARE @Hash VARCHAR(20)
DECLARE @BoxNr INT = 0
DECLARE @CurrentValue INT = 0

DECLARE hashcursor CURSOR FAST_FORWARD READ_ONLY FOR SELECT PieceNr, Piece FROM ##InputSplit ORDER BY RowNr, PieceNr

OPEN hashcursor

FETCH NEXT FROM hashcursor INTO @Index, @Hash

WHILE @@FETCH_STATUS = 0
BEGIN
    -- For each line in the input repeat (start at 0):
        -- Get ASCII value for the next character and add to previous value
        -- Multiply by 17
        -- Mod 256
        -- This gives the value for the calculation with the next character

    INSERT ##Hashes
    (
        Ind,
        HashString
    )
    SELECT @Index, @Hash

    ;WITH cte_Hash AS (

        SELECT @Hash AS Hsh
        ,      LEFT(@Hash, 1) AS LeftChar
        ,      SUBSTRING(@Hash, 2, LEN(@Hash)) AS LeftOver
        ,      0 AS CurrentValue
        ,      -1 AS BoxNr

        UNION ALL

        SELECT Hsh
        ,      LEFT(LeftOver,1)
        ,      SUBSTRING(LeftOVer, 2, LEN(LeftOver))
        ,      (CurrentValue + ASCII(LeftChar)) * 17 % 256
        ,      CASE WHEN LeftChar IN ('-','=') THEN CurrentValue ELSE BoxNr END
        FROM cte_Hash
        WHERE LeftChar <> ''
    )
    -- The recursive cte shows all intermediate steps, just keep the final value
    SELECT @CurrentValue = CASE WHEN LeftChar = '' THEN CurrentValue END
    ,      @BoxNr = BoxNr
    FROM cte_Hash
    WHERE LeftChar = ''

    -- And store it
    UPDATE ##Hashes
    SET NextValue = @CurrentValue
    ,   BoxNr = @BoxNr
    WHERE Ind = @Index


    FETCH NEXT FROM hashcursor INTO @Index, @Hash
END

CLOSE hashcursor
DEALLOCATE hashcursor

-- Sum values for part 1
SELECT SUM(NextValue) AS Part1 FROM ##Hashes H

-- Prepare the input as a series of instructions
SELECT ROW_NUMBER() OVER (ORDER BY BoxNr, Ind) AS RowNr
,      H.HashString
,      H.BoxNr
,      CASE WHEN H.HashString LIKE '%=%' 
            THEN LEFT(H.HashString, CHARINDEX('=', H.HashString) - 1) 
            ELSE LEFT(H.HashString, LEN(H.HashString) - 1) 
       END AS LensLabel
,      CASE WHEN H.HashString LIKE '%=%' 
            THEN SUBSTRING(H.HashString, CHARINDEX('=', H.HashString) + 1, LEN(H.HashString)) 
            ELSE '-1' 
       END AS FocalLength
INTO ##Instructions
FROM ##Hashes H ORDER BY BoxNr, Ind

-- We'll need a list of boxes, lenses and their focal lengths
CREATE TABLE ##Boxes (ID INT IDENTITY(1,1), BoxNr INT, Lens VARCHAR(10), FocalLength INT)

DECLARE @LensLabel VARCHAR(10)
DECLARE @FocalLength INT

DECLARE InstrCursor CURSOR FAST_FORWARD READ_ONLY FOR SELECT BoxNr, LensLabel, FocalLength FROM ##Instructions I

OPEN InstrCursor

FETCH NEXT FROM InstrCursor INTO @BoxNr, @LensLabel, @FocalLength

WHILE @@FETCH_STATUS = 0
BEGIN
    
    -- If the focal length is -1 remove the lens from box (SQL advantage: this statement also works if the lens is not there)
    IF @FocalLength = -1 DELETE FROM ##Boxes WHERE BoxNr = @BoxNr AND Lens = @LensLabel
    ELSE
    -- If the lens is already present in a box, update it's focal length
    IF EXISTS (SELECT 1 FROM ##Boxes B WHERE B.BoxNr = @BoxNr AND B.Lens = @LensLabel)
        UPDATE ##Boxes SET FocalLength = @FocalLength WHERE BoxNr = @BoxNr AND Lens = @LensLabel
    ELSE 
    -- Apparently this is a new lens, so add it to the box
        INSERT ##Boxes (BoxNr, Lens, FocalLength) SELECT @BoxNr, @LensLabel, @FocalLength

    FETCH NEXT FROM InstrCursor INTO @BoxNr, @LensLabel, @FocalLength
END

CLOSE InstrCursor
DEALLOCATE InstrCursor

-- Order the lenses (within each box) and calculate the value per box
;WITH cte_FocusPower AS (
    SELECT (BoxNr + 1) * ROW_NUMBER() OVER (PARTITION BY BoxNr ORDER BY ID) * B.FocalLength AS FocusPower
    FROM ##Boxes B 
)
-- Sum over all boxes for the answer to part 2
SELECT SUM(FocusPower) AS Part2
FROM cte_FocusPower


/*

DROP TABLE ##Hashes
DROP TABLE ##Instructions
DROP TABLE ##Boxes

*/

