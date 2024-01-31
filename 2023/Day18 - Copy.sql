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
  

CREATE TABLE ##Grid(ID INT IDENTITY(1,1), RowNr INT, ColNr INT, InsideDir CHAR)

CREATE TABLE ##Instructions (ID INT IDENTITY(1,1), RowNr INT, Dir CHAR, Dist INT)

INSERT ##Instructions
(
    RowNr,
    Dir,
    Dist
)
SELECT RowNr, [1] AS Dir, [2] AS Dist
FROM (
    SELECT RowNr, PieceNr, Piece FROM ##InputSplit WHERE PieceNr IN (1,2)
) Sub
PIVOT (
    MAX(Piece)
    FOR PieceNr IN ([1],[2])
) Pvt


--SELECT * FROM ##Instructions I


DECLARE @CurrentRow INT = 0
DECLARE @CurrentCol INT = 0
DECLARE @CurrentInsideDir CHAR = 'N'

--INSERT ##Grid (RowNr, ColNr) SELECT @CurrentRow, @CurrentCol

CREATE UNIQUE INDEX IX_Grid_UQ ON ##Grid (RowNr, ColNr)

DECLARE @Dir CHAR
DECLARE @PreviousDir CHAR = ''
DECLARE @Dist INT

DECLARE InstrCursor CURSOR FAST_FORWARD READ_ONLY FOR SELECT Dir, Dist FROM ##Instructions I ORDER BY I.RowNr 

OPEN InstrCursor

FETCH NEXT FROM InstrCursor INTO @Dir, @Dist

WHILE @@FETCH_STATUS = 0
BEGIN
    
    IF @PreviousDir = 'L' AND @Dir = 'U' AND @CurrentInsideDir = 'S' SET @CurrentInsideDir = 'W'
    IF @PreviousDir = 'L' AND @Dir = 'U' AND @CurrentInsideDir = 'N' SET @CurrentInsideDir = 'E'
    IF @PreviousDir = 'L' AND @Dir = 'D' AND @CurrentInsideDir = 'S' SET @CurrentInsideDir = 'E'
    IF @PreviousDir = 'L' AND @Dir = 'D' AND @CurrentInsideDir = 'N' SET @CurrentInsideDir = 'W'

    IF @PreviousDir = 'R' AND @Dir = 'U' AND @CurrentInsideDir = 'S' SET @CurrentInsideDir = 'E'
    IF @PreviousDir = 'R' AND @Dir = 'U' AND @CurrentInsideDir = 'N' SET @CurrentInsideDir = 'W'
    IF @PreviousDir = 'R' AND @Dir = 'D' AND @CurrentInsideDir = 'S' SET @CurrentInsideDir = 'W'
    IF @PreviousDir = 'R' AND @Dir = 'D' AND @CurrentInsideDir = 'N' SET @CurrentInsideDir = 'E'

    IF @PreviousDir = 'U' AND @Dir = 'L' AND @CurrentInsideDir = 'W' SET @CurrentInsideDir = 'S'
    IF @PreviousDir = 'U' AND @Dir = 'L' AND @CurrentInsideDir = 'E' SET @CurrentInsideDir = 'N'
    IF @PreviousDir = 'U' AND @Dir = 'R' AND @CurrentInsideDir = 'W' SET @CurrentInsideDir = 'N'
    IF @PreviousDir = 'U' AND @Dir = 'R' AND @CurrentInsideDir = 'E' SET @CurrentInsideDir = 'S'

    IF @PreviousDir = 'D' AND @Dir = 'L' AND @CurrentInsideDir = 'W' SET @CurrentInsideDir = 'N'
    IF @PreviousDir = 'D' AND @Dir = 'L' AND @CurrentInsideDir = 'E' SET @CurrentInsideDir = 'S'
    IF @PreviousDir = 'D' AND @Dir = 'R' AND @CurrentInsideDir = 'W' SET @CurrentInsideDir = 'S'
    IF @PreviousDir = 'D' AND @Dir = 'R' AND @CurrentInsideDir = 'E' SET @CurrentInsideDir = 'N'


    ;WITH cte_Nrs AS
    (
        SELECT TOP (@Dist) ROW_NUMBER() OVER (ORDER BY (SELECT 0)) AS Nr FROM sys.messages
    )
    INSERT ##Grid(RowNr, ColNr, InsideDir)
    SELECT CASE WHEN @Dir = 'U' THEN @CurrentRow - c.Nr
                WHEN @Dir = 'D' THEN @CurrentRow + c.Nr
                ELSE @CurrentRow END AS RowNr
    ,      CASE WHEN @Dir = 'L' THEN @CurrentCol - c.Nr
                WHEN @Dir = 'R' THEN @CurrentCol + c.Nr
                ELSE @CurrentCol END AS ColNr
    ,      @CurrentInsideDir
    FROM cte_Nrs c

    IF @Dir = 'U' SET @CurrentRow = @CurrentRow - @Dist
    IF @Dir = 'D' SET @CurrentRow = @CurrentRow + @Dist
    IF @Dir = 'L' SET @CurrentCol = @CurrentCol - @Dist
    IF @Dir = 'R' SET @CurrentCol = @CurrentCol + @Dist

    SET @PreviousDir = @Dir

    FETCH NEXT FROM InstrCursor INTO @Dir, @Dist
END

CLOSE InstrCursor
DEALLOCATE InstrCursor

DECLARE @Count INT = 1


INSERT ##Grid
(
    RowNr,
    ColNr
)
SELECT DISTINCT 
       G.RowNr + CASE WHEN G.InsideDir = 'S' THEN 1 
                      WHEN G.InsideDir = 'N' THEN -1 
                      ELSE 0 END AS RowNr
,      G.ColNr + CASE WHEN G.InsideDir = 'E' THEN 1
                      WHEN G.InsideDir = 'W' THEN -1
                      ELSE 0 END AS ColNr
FROM ##Grid G
LEFT JOIN ##Grid G2 ON G2.RowNr = G.RowNr + CASE WHEN G.InsideDir = 'S' THEN 1 
                                                 WHEN G.InsideDir = 'N' THEN -1 
                                                 ELSE 0 END 
                    AND G2.ColNr = G.ColNr + CASE WHEN G.InsideDir = 'E' THEN 1
                                                  WHEN G.InsideDir = 'W' THEN -1
                                                  ELSE 0 END
WHERE G2.ID IS NULL


WHILE @Count > 0
BEGIN


    ;WITH cte_Cross AS (
        SELECT  0 AS RowChange,  1 AS ColChange UNION
        SELECT  0 AS RowChange, -1 AS ColChange UNION
        SELECT  1 AS RowChange,  0 AS ColChange UNION
        SELECT -1 AS RowChange,  0 AS ColChange 
    )
    INSERT ##Grid (RowNr, ColNr)
    SELECT DISTINCT
           G.RowNr + c.RowChange
    ,      G.ColNr + c.ColChange
    FROM ##Grid G
    CROSS APPLY cte_Cross c
    LEFT JOIN ##Grid G2 ON G2.ColNr = G.ColNr + c.ColChange AND G2.RowNr = G.RowNr + c.RowChange
    WHERE G.InsideDir IS NULL
        AND G2.ID IS NULL

    SET @Count = @@ROWCOUNT
END

SELECT COUNT(1) AS Part1 FROM ##Grid G


/*

DROP TABLE ##Grid
DROP TABLE ##Instructions


*/