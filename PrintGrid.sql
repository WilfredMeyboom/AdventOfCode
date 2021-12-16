CREATE OR ALTER PROCEDURE dbo.PrintGrid
(
    -- The Procedure assumes there is a ##Grid table containing x and y
    -- Allowed types are All, Sparse (meaning the grid contains only the interesting points)
    @GridType VARCHAR(20)
,   @PointChar CHAR(1) = '#'
,   @PointEmpty CHAR(1) = ' '
)
AS
BEGIN

    DECLARE @x INT 
    DECLARE @y INT
    DECLARE @output VARCHAR(1000)
    DECLARE @chr CHAR(1)

    IF (@GridType = 'Sparse')
    BEGIN

        SELECT @x = MIN(x) FROM ##Grid
        SELECT @y = MIN(y) FROM ##Grid

        WHILE @y <= (SELECT MAX(y) FROM ##Grid G)
        BEGIN

            SET @output = ''

            WHILE @x <= (SELECT MAX(x) FROM ##Grid G)
            BEGIN
        
                SET @chr = @PointEmpty

                SELECT @chr = @PointChar
                FROM ##Grid G
                WHERE x= @x AND y = @y

                SET @output = @output + @chr

                SET @x = @x + 1
            END

            PRINT @output

            SELECT @x = MIN(x) FROM ##Grid
            SET @y = @y + 1

        END

        SELECT 'Check print output for results' AS [Message]
    END

    IF (@GridType = 'All')
        SELECT 'NOT IMPLEMENTED!' AS [Message]

END

