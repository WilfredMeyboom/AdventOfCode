USE Test_WME

DECLARE @year VARCHAR(4) = '2021'
DECLARE @day VARCHAR(2)  = '2'

EXEC dbo.GetInput @year = @year, @day = @day
EXEC dbo.ParseInput @year = @year, @day = @day 

;WITH cte_1 AS (
SELECT Ind, LEFT(Line, CHARINDEX(' ', Line)) AS Dir, SUBSTRING(Line,  CHARINDEX(' ', Line),5) AS Amount FROM ##InputNumbered --ORDER BY Ind
)
SELECT Dir, SUM(CAST(cte_1.Amount AS INT))
FROM cte_1
GROUP BY cte_1.Dir

SELECT 1967 --Forward
    * (2077-1046) --Difference between down and up
    AS Part1

-- 2027977 is correct for part 1


DECLARE @amount INT
DECLARE @direction VARCHAR(10)

DECLARE @depth INT = 0 
DECLARE @position INT = 0 
DECLARE @aim INT = 0 

DECLARE cursor_course CURSOR LOCAL FAST_FORWARD READ_ONLY FOR SELECT LEFT(Line, CHARINDEX(' ', Line)) AS Dir, SUBSTRING(Line,  CHARINDEX(' ', Line),5) AS Amount FROM ##InputNumbered ORDER BY Ind

OPEN cursor_course

FETCH NEXT FROM cursor_course INTO @direction, @amount

WHILE @@FETCH_STATUS = 0
BEGIN
    
    IF @direction = 'up'
    BEGIN
        SET @aim = @aim - @amount
    END

    IF @direction = 'down'
    BEGIN
        SET @aim = @aim + @amount
    END

    IF @direction = 'forward'
    BEGIN
    SET @position = @position + @amount
    SET @depth = @depth + @aim * @amount
    END

    --Debug line
    --SELECT @direction, @amount, @aim, @position, @depth, @position * @depth


    FETCH NEXT FROM cursor_course INTO @direction, @amount
END

CLOSE cursor_course
DEALLOCATE cursor_course

SELECT @position, @depth, @position * @depth AS Part2

DROP TABLE ##Input

