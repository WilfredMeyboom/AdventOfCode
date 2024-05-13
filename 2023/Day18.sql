USE Test_WME

SET NOCOUNT ON

DECLARE @year VARCHAR(4) = '2023'
DECLARE @day VARCHAR(2)  = '18'

EXEC dbo.GetInput @year = @year, @day = @day
EXEC dbo.ParseInput @year = @year, @day = @day 

--SELECT TOP 10 * FROM ##Input
--SELECT TOP 10 * FROM ##InputInts
--SELECT TOP 10 * FROM ##InputNumbered
--SELECT TOP 10 * FROM ##InputGrid
--SELECT TOP 10 * FROM ##InputSplitCust
  

CREATE TABLE ##Points(ID INT IDENTITY(1,1), RowNr INT, ColNr INT)

CREATE TABLE ##Instructions (ID INT IDENTITY(1,1), RowNr INT, Dir CHAR, Dist INT)

INSERT ##Instructions
(
    RowNr,
    Dir,
    Dist
)
SELECT Ind
,      LEFT(Line, 1)
,      CAST(SUBSTRING(Line, 3, 2) AS INT)
FROM ##InputNumbered

--SELECT * FROM ##Instructions I


DECLARE @CurrentRow INT = 0
DECLARE @CurrentCol INT = 0

DECLARE @Dir CHAR
DECLARE @Dist INT

DECLARE InstrCursor CURSOR FAST_FORWARD READ_ONLY FOR SELECT Dir, Dist FROM ##Instructions I ORDER BY I.RowNr 

OPEN InstrCursor

FETCH NEXT FROM InstrCursor INTO @Dir, @Dist

WHILE @@FETCH_STATUS = 0
BEGIN
    
    INSERT ##Points
    (
        RowNr,
        ColNr
    )
    SELECT @CurrentRow, @CurrentCol
    
    IF @Dir = 'U' SET @CurrentRow = @CurrentRow - @Dist
    IF @Dir = 'D' SET @CurrentRow = @CurrentRow + @Dist
    IF @Dir = 'L' SET @CurrentCol = @CurrentCol - @Dist
    IF @Dir = 'R' SET @CurrentCol = @CurrentCol + @Dist

    FETCH NEXT FROM InstrCursor INTO @Dir, @Dist
END

CLOSE InstrCursor
DEALLOCATE InstrCursor

DECLARE @MaxID INT
SELECT @MaxID = MAX(ID) FROM ##Points P

SELECT SUM ((P.ColNr - P2.ColNr) * (P.RowNr)) -- AS Area
+  (SUM(CASE WHEN P.ColNr <> P2.ColNr THEN ABS(P.ColNr - P2.ColNr)
         ELSE ABS(P.RowNr - P2.RowNr)
         END) --AS [Edge]
         )/2 + 1 AS Part1
FROM ##Points P
INNER JOIN ##Points P2 ON P2.ID = P.ID + 1 OR (P.ID = @MaxID AND P2.ID = 1)


--53844


TRUNCATE TABLE ##Points
DELETE FROM ##Instructions

INSERT ##Instructions
(
    RowNr,
    Dir,
    Dist
)
SELECT Ind
,      CASE WHEN LEFT(RIGHT(Line,2),1) = '0' THEN 'R'
            WHEN LEFT(RIGHT(Line,2),1) = '1' THEN 'D'
            WHEN LEFT(RIGHT(Line,2),1) = '2' THEN 'L'
            WHEN LEFT(RIGHT(Line,2),1) = '3' THEN 'U' END
,      CAST(CONVERT(VARBINARY,'0x0'+SUBSTRING(Line, CHARINDEX('(',Line)+2, 5),1) AS INT)
FROM ##InputNumbered


SET @CurrentCol = 0
SET @CurrentRow = 0

DECLARE InstrCursor CURSOR FAST_FORWARD READ_ONLY FOR SELECT Dir, Dist FROM ##Instructions I ORDER BY I.RowNr 

OPEN InstrCursor

FETCH NEXT FROM InstrCursor INTO @Dir, @Dist

WHILE @@FETCH_STATUS = 0
BEGIN
    
    INSERT ##Points
    (
        RowNr,
        ColNr
    )
    SELECT @CurrentRow, @CurrentCol
    
    IF @Dir = 'U' SET @CurrentRow = @CurrentRow - @Dist
    IF @Dir = 'D' SET @CurrentRow = @CurrentRow + @Dist
    IF @Dir = 'L' SET @CurrentCol = @CurrentCol - @Dist
    IF @Dir = 'R' SET @CurrentCol = @CurrentCol + @Dist

    FETCH NEXT FROM InstrCursor INTO @Dir, @Dist
END

CLOSE InstrCursor
DEALLOCATE InstrCursor

--DECLARE @MaxID INT

SELECT @MaxID = MAX(ID) FROM ##Points P

SELECT SUM ((P.ColNr - P2.ColNr) * CAST(P.RowNr AS BIGINT)) -- AS Area
+  (SUM(CASE WHEN P.ColNr <> P2.ColNr THEN ABS(P.ColNr - P2.ColNr)
         ELSE ABS(P.RowNr - P2.RowNr)
         END) --AS [Edge]
         )/2 + 1 AS Part2 
-- select *
FROM ##Points P
INNER JOIN ##Points P2 ON P2.ID = P.ID + 1 OR (P.ID = @MaxID AND P2.ID = 1)

-- Too Low

--SELECT * FROM ##Points P
/*


DROP TABLE ##Points
DROP TABLE ##Instructions


*/