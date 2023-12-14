USE Test_WME

SET NOCOUNT ON

DECLARE @year VARCHAR(4) = '2023'
DECLARE @day VARCHAR(2)  = '14'

EXEC dbo.GetInput @year = @year, @day = @day
EXEC dbo.ParseInput @year = @year, @day = @day 

--SELECT TOP 10 * FROM ##Input
--SELECT TOP 10 * FROM ##InputInts
--SELECT TOP 10 * FROM ##InputNumbered
--SELECT TOP 10 * FROM ##InputSplit
--SELECT TOP 10 * FROM ##InputSplitCust
  
CREATE UNIQUE INDEX IX_InputGrid_UQ ON ##InputGrid(RowNr,ColNr)

DECLARE @Count INT = 1

WHILE @Count > 0
BEGIN
    
    UPDATE I1
    SET I1.Val = 'X'
    FROM ##InputGrid I1
    INNER JOIN ##InputGrid I2 ON I1.RowNr = I2.RowNr - 1 AND I1.ColNr = I2.ColNr
    WHERE I1.Val = '.' AND I2.Val = 'O'

    UPDATE I1
    SET I1.Val = '.'
    FROM ##InputGrid I1
    INNER JOIN ##InputGrid I2 ON I1.RowNr = I2.RowNr + 1 AND I1.ColNr = I2.ColNr
    WHERE I1.Val = 'O' AND I2.Val = 'X'

    UPDATE I1
    SET I1.Val = 'O'
    FROM ##InputGrid I1
    WHERE I1.Val = 'X' 

    SET @Count = @@ROWCOUNT
END

DECLARE @MaxRowNr INT
SELECT @MaxRowNr = MAX(RowNr) FROM ##InputGrid
SELECT SUM(@MaxRowNr - RowNr + 1) AS Part1 FROM ##InputGrid WHERE Val = 'O'

CREATE TABLE ##Result (ID INT IDENTITY, Result INT)

--north, then west, then south, then east

DECLARE @Cycle INT = 0
DECLARE @NrOfBoulders INT

WHILE @Cycle < 200
BEGIN
    
    SET @Count = 1

    --North
    WHILE @Count > 0
    BEGIN
    
        UPDATE I1
        SET I1.Val = 'X'
        FROM ##InputGrid I1
        INNER JOIN ##InputGrid I2 ON I1.RowNr = I2.RowNr - 1 AND I1.ColNr = I2.ColNr
        WHERE I1.Val = '.' AND I2.Val = 'O'

        UPDATE I1
        SET I1.Val = '.'
        FROM ##InputGrid I1
        INNER JOIN ##InputGrid I2 ON I1.RowNr = I2.RowNr + 1 AND I1.ColNr = I2.ColNr
        WHERE I1.Val = 'O' AND I2.Val = 'X'

        UPDATE I1
        SET I1.Val = 'O'
        FROM ##InputGrid I1
        WHERE I1.Val = 'X' 

        SET @Count = @@ROWCOUNT
    END

    SET @Count = 1

    --West
    WHILE @Count > 0
    BEGIN
    
        UPDATE I1
        SET I1.Val = 'X'
        FROM ##InputGrid I1
        INNER JOIN ##InputGrid I2 ON I1.RowNr = I2.RowNr AND I1.ColNr = I2.ColNr - 1
        WHERE I1.Val = '.' AND I2.Val = 'O'

        UPDATE I1
        SET I1.Val = '.'
        FROM ##InputGrid I1
        INNER JOIN ##InputGrid I2 ON I1.RowNr = I2.RowNr AND I1.ColNr = I2.ColNr + 1
        WHERE I1.Val = 'O' AND I2.Val = 'X'

        UPDATE I1
        SET I1.Val = 'O'
        FROM ##InputGrid I1
        WHERE I1.Val = 'X' 

        SET @Count = @@ROWCOUNT
    END

    SET @Count = 1

    --South
    WHILE @Count > 0
    BEGIN
    
        UPDATE I1
        SET I1.Val = 'X'
        FROM ##InputGrid I1
        INNER JOIN ##InputGrid I2 ON I1.RowNr = I2.RowNr + 1 AND I1.ColNr = I2.ColNr
        WHERE I1.Val = '.' AND I2.Val = 'O'

        UPDATE I1
        SET I1.Val = '.'
        FROM ##InputGrid I1
        INNER JOIN ##InputGrid I2 ON I1.RowNr = I2.RowNr - 1 AND I1.ColNr = I2.ColNr
        WHERE I1.Val = 'O' AND I2.Val = 'X'

        UPDATE I1
        SET I1.Val = 'O'
        FROM ##InputGrid I1
        WHERE I1.Val = 'X' 

        SET @Count = @@ROWCOUNT
    END

    SET @Count = 1

    --East
    WHILE @Count > 0
    BEGIN
    
        UPDATE I1
        SET I1.Val = 'X'
        FROM ##InputGrid I1
        INNER JOIN ##InputGrid I2 ON I1.RowNr = I2.RowNr AND I1.ColNr = I2.ColNr + 1
        WHERE I1.Val = '.' AND I2.Val = 'O'

        UPDATE I1
        SET I1.Val = '.'
        FROM ##InputGrid I1
        INNER JOIN ##InputGrid I2 ON I1.RowNr = I2.RowNr AND I1.ColNr = I2.ColNr - 1
        WHERE I1.Val = 'O' AND I2.Val = 'X'

        UPDATE I1
        SET I1.Val = 'O'
        FROM ##InputGrid I1
        WHERE I1.Val = 'X' 

        SET @Count = @@ROWCOUNT
    END

    INSERT ##Result (Result)
    SELECT SUM(@MaxRowNr - RowNr + 1) FROM ##InputGrid WHERE Val = 'O'

    SET @Cycle = @Cycle + 1

END

SELECT R2.ID - R1.ID
FROM ##Result R1
INNER JOIN ##Result R2 ON R1.Result = R2.Result AND R1.ID < R2.ID
ORDER BY R1.ID


SELECT 1000000000 % 26 + ((153 / 26) + 1) * 26
SELECT (1000000000 - 168) % 26
SELECT Result AS Part2 FROM ##Result WHERE ID = 168