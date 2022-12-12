USE Test_WME

SET NOCOUNT ON

DECLARE @year VARCHAR(4) = '2022'
DECLARE @day VARCHAR(2)  = '10'

EXEC dbo.GetInput @year = @year, @day = @day
EXEC dbo.ParseInput @year = @year, @day = @day 

--SELECT TOP 10 * FROM ##Input
--SELECT TOP 10 * FROM ##InputInts
--SELECT TOP 10 * FROM ##InputNumbered
--SELECT TOP 10 * FROM ##InputGrid
--SELECT TOP 10 * FROM ##InputSplit
--SELECT TOP 10 * FROM ##InputSplitCust
  

DECLARE @RegX BIGINT = 1
DECLARE @Cycle BIGINT = 1

CREATE TABLE ##Register (ID BIGINT IDENTITY(1,1), Cycle BIGINT, X BIGINT)

DECLARE @Instr VARCHAR(4)
DECLARE @Amount INT

DECLARE instrCurosr CURSOR FAST_FORWARD READ_ONLY FOR SELECT LEFT(Line, 4) AS Instr, TRY_CAST(SUBSTRING(Line, CHARINDEX(' ', Line), LEN(Line)) AS INT) FROM ##InputNumbered

OPEN instrCurosr

FETCH NEXT FROM instrCurosr INTO @Instr, @Amount

WHILE @@FETCH_STATUS = 0
BEGIN
    
    IF @Instr = 'noop' 
    BEGIN
        SET @Cycle = @Cycle + 1
        INSERT ##Register (Cycle,X) VALUES (@Cycle, @RegX)
    END
    
    IF @Instr = 'addx' 
    BEGIN
        SET @Cycle = @Cycle + 1
        INSERT ##Register (Cycle,X) VALUES (@Cycle, @RegX)

        SET @Cycle = @Cycle + 1
        SET @RegX = @RegX + @Amount
        INSERT ##Register (Cycle,X) VALUES (@Cycle, @RegX)
    END

    FETCH NEXT FROM instrCurosr INTO @Instr, @Amount
END

CLOSE instrCurosr
DEALLOCATE instrCurosr

SELECT SUM(Cycle * X) AS Part1
FROM ##Register R
WHERE (R.Cycle - 20) % 40 = 0


-- A little cleanup before drawing
INSERT ##Register (Cycle,x) VALUES (1,1)
DELETE FROM ##Register WHERE Cycle > 239

SELECT 
    [0]+[1]+[2]+[3]+[4]+[5]+[6]+[7]+[8]+[9]+[10]+
    [11]+[12]+[13]+[14]+[15]+[16]+[17]+[18]+[19]+[20]+
    [21]+[22]+[23]+[24]+[25]+[26]+[27]+[28]+[29]+[30]+
    [31]+[32]+[33]+[34]+[35]+[36]+[37]+[38] AS Part2
FROM (
SELECT (Cycle%40)-1 AS DrawPosition, Cycle/40 AS RowNr, CASE WHEN ABS((Cycle%40) -1 - X) <= 1 THEN '||' ELSE '  ' END AS Pixel 
FROM ##Register R
) T
PIVOT(MAX(Pixel) FOR DrawPosition IN ([0],[1],[2],[3],[4],[5],[6],[7],[8],[9],[10],
                                      [11],[12],[13],[14],[15],[16],[17],[18],[19],[20],
                                      [21],[22],[23],[24],[25],[26],[27],[28],[29],[30],
                                      [31],[32],[33],[34],[35],[36],[37],[38],[39])
)  PVT

/*

||||||||  ||||||    ||    ||  ||||||    ||    ||  ||||||||    ||||    ||    ||
||        ||    ||  ||    ||  ||    ||  ||    ||        ||  ||    ||  ||    ||
||||||    ||||||    ||    ||  ||    ||  ||||||||      ||    ||        ||||||||
||        ||    ||  ||    ||  ||||||    ||    ||    ||      ||        ||    ||
||        ||    ||  ||    ||  ||  ||    ||    ||  ||        ||    ||  ||    ||
||        ||||||      ||||    ||    ||  ||    ||  ||||||||    ||||    ||    ||

*/

DROP TABLE ##Register


