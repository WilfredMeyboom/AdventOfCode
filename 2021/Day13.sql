USE Test_WME

SET NOCOUNT ON

DECLARE @year VARCHAR(4) = '2021'
DECLARE @day VARCHAR(2)  = '13'

EXEC dbo.GetInput @year = @year, @day = @day
EXEC dbo.ParseInput @year = @year, @day = @day

--SELECT TOP 10 * FROM ##InputNumbered
--SELECT TOP 10 * FROM ##InputGrid
--SELECT TOP 10 * FROM ##InputInts
--SELECT * FROM ##InputSplit
--SELECT TOP 10 * FROM ##InputSplitCust


CREATE TABLE ##Grid (ID INT IDENTITY(1,1), x INT, y INT)

INSERT ##Grid (x,y)
SELECT CAST(I.Piece AS INT), CAST(I2.Piece AS INT)
FROM ##InputSplit I
INNER JOIN ##InputSplit I2 ON I2.RowNr = I.RowNr AND I2.PieceNr > I.PieceNr
WHERE TRY_CAST(I.Piece AS INT) IS NOT NULL AND I.Piece IS NOT NULL


DECLARE @FoldDirection CHAR(1)
DECLARE @FoldLine INT 
DECLARE @FirstFold INT = 1

DECLARE fold_cursor CURSOR FAST_FORWARD READ_ONLY FOR 
    SELECT CAST(REPLACE(REPLACE(Line, 'fold along x=',''), 'fold along y=','') AS INT) 
    ,   CASE WHEN Line LIKE '%x%' THEN 'x' ELSE 'y' END
    FROM ##InputNumbered INU WHERE Line LIKE '%fold%'


OPEN fold_cursor

FETCH NEXT FROM fold_cursor INTO @FoldLine, @FoldDirection

WHILE @@FETCH_STATUS = 0
BEGIN

    IF @FoldDirection = 'y'

        UPDATE ##Grid
        SET y = y - 2*(y-@FoldLine)
        WHERE y > @FoldLine

    ELSE

        UPDATE ##Grid
        SET x = x - 2*(x-@FoldLine)
        WHERE x > @FoldLine
    
    IF @FirstFold = 1
    BEGIN
        ;WITH cte_DistinctPoints AS (
            SELECT x,y FROM ##Grid GROUP BY x,y
        )
        SELECT COUNT(1) AS Part1 FROM cte_DistinctPoints

        SET @FirstFold = 0
    END

    FETCH NEXT FROM fold_cursor INTO @FoldLine, @FoldDirection
END

CLOSE fold_cursor
DEALLOCATE fold_cursor

--850 is correct for part 1


EXEC PrintGrid 'Sparse'

--AHGCPGAU is correct for part 2

DROP TABLE ##Grid