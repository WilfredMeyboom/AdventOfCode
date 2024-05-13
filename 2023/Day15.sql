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
    SELECT @CurrentValue = CASE WHEN LeftChar = '' THEN CurrentValue END
    ,      @BoxNr = BoxNr
    FROM cte_Hash
    WHERE LeftChar = ''

    UPDATE ##Hashes
    SET NextValue = @CurrentValue
    ,   BoxNr = @BoxNr
    WHERE Ind = @Index


    FETCH NEXT FROM hashcursor INTO @Index, @Hash
END

CLOSE hashcursor
DEALLOCATE hashcursor


SELECT SUM(NextValue) AS Part1 FROM ##Hashes H

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

CREATE TABLE ##Boxes (ID INT IDENTITY(1,1), BoxNr INT, Lens VARCHAR(10), FocalLength INT)

/* declare variables */
DECLARE @LensLabel VARCHAR(10)
DECLARE @FocalLength INT

DECLARE InstrCursor CURSOR FAST_FORWARD READ_ONLY FOR SELECT BoxNr, LensLabel, FocalLength FROM ##Instructions I

OPEN InstrCursor

FETCH NEXT FROM InstrCursor INTO @BoxNr, @LensLabel, @FocalLength

WHILE @@FETCH_STATUS = 0
BEGIN
    
    IF @FocalLength = -1 DELETE FROM ##Boxes WHERE BoxNr = @BoxNr AND Lens = @LensLabel
    ELSE
        IF EXISTS (SELECT 1 FROM ##Boxes B WHERE B.BoxNr = @BoxNr AND B.Lens = @LensLabel)
            UPDATE ##Boxes SET FocalLength = @FocalLength WHERE BoxNr = @BoxNr AND Lens = @LensLabel
        ELSE 
            INSERT ##Boxes (BoxNr, Lens, FocalLength) SELECT @BoxNr, @LensLabel, @FocalLength

    FETCH NEXT FROM InstrCursor INTO @BoxNr, @LensLabel, @FocalLength
END

CLOSE InstrCursor
DEALLOCATE InstrCursor

;WITH cte_FocusPower AS (
    SELECT (BoxNr + 1) * ROW_NUMBER() OVER (PARTITION BY BoxNr ORDER BY ID) * B.FocalLength AS FocusPower
    FROM ##Boxes B 
)
SELECT SUM(FocusPower) AS Part2
FROM cte_FocusPower


/*

DROP TABLE ##Hashes
DROP TABLE ##Instructions
DROP TABLE ##Boxes

*/

