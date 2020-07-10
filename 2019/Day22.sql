use Test_WME

--It is slow but we can simply execute the instructions and see the result

SET NOCOUNT ON

CREATE TABLE #Input (Nr NVARCHAR(MAX));

BULK INSERT #Input
FROM 'C:\Source\AdventOfCode\2019\input22.txt'
WITH (ROWTERMINATOR = '0x0A');

CREATE TABLE ##Instructions (ID INT IDENTITY(1,1), InstrType INT, InstrCount INT)

INSERT ##Instructions (InstrType, InstrCount)
SELECT CASE WHEN Nr LIKE 'deal with increment%' THEN 3
            WHEN Nr LIKE 'cut%' THEN 2
            WHEN Nr LIKE 'deal into new stack%' THEN 1
            END
,      REPLACE(REPLACE(REPLACE(Nr, 'deal with increment ', ''), 'deal into new stack', '0'), 'cut ', '')
FROM #Input

--DELETE FROM ##Instructions
--INSERT ##Instructions VALUES (2,6), (3,7), (1,-2)

--SELECT * FROM ##Instructions

CREATE TABLE ##Cards (ID INT IDENTITY(0,1), CardNr INT)
CREATE TABLE ##CardsTemp (ID INT IDENTITY(0,1), CardNr INT)


INSERT ##Cards (CardNr)
SELECT TOP 10007 ROW_NUMBER() OVER (ORDER BY (SELECT 0)) - 1
FROM sys.messages

INSERT ##CardsTemp (CardNr)
SELECT TOP 10007 ROW_NUMBER() OVER (ORDER BY (SELECT 0)) - 1
FROM sys.messages


DECLARE @InstrType INT
DECLARE @InstrCount INT
DECLARE @NrOfCards INT
DECLARE @Counter INT = 0 
DECLARE @Res VARCHAR(MAX)
DECLARE @Res2 VARCHAR(10)

SELECT @NrOfCards = COUNT(1) FROM ##Cards

DECLARE ShuffleCursor CURSOR
FOR SELECT InstrType, InstrCount FROM ##Instructions ORDER BY ID

OPEN ShuffleCursor

FETCH NEXT FROM ShuffleCursor INTO @InstrType, @InstrCount

WHILE @@FETCH_STATUS = 0
BEGIN

    IF @InstrType = 1
    BEGIN
     
        UPDATE C
        SET CardNr = CT.CardNr
        --SELECT C.ID, C.CardNr, CT.ID, CT.CardNr
        FROM ##Cards C
        INNER JOIN ##Cards CT ON C.ID = @NrOfCards - CT.ID - 1
     
    END

    IF @InstrType = 2
    BEGIN

        IF (@InstrCount < 0) SET @InstrCount = @InstrCount + @NrOfCards
        IF (@InstrCount < 0) PRINT 'ERROR 1'

        UPDATE C
        SET CardNr = CT.CardNr
        --SELECT C.ID, C.CardNr, CT.ID, CT.CardNr
        FROM ##Cards C
        INNER JOIN ##Cards CT ON C.ID = CT.ID - @InstrCount
                              OR C.ID = CT.ID - @InstrCount + @NrOfCards
        

    END

    IF @InstrType = 3
    BEGIN

        SET @Counter = 0

        WHILE @Counter < @NrOfCards
        BEGIN

            UPDATE CT
            SET CardNr = C.CardNr
            --SELECT CT.ID, C.CardNr
            FROM ##CardsTemp CT
            INNER JOIN ##Cards C ON C.ID = @Counter
            WHERE CT.ID = (@Counter * @InstrCount) % @NrOfCards 
            
            SET @Counter = @Counter + 1
        END

        UPDATE C
        SET CardNr = CT.CardNr
        FROM ##Cards C
        INNER JOIn ##CardsTemp CT ON C.ID = CT.ID
    END

    PRINT 'Done | InstrType: ' + CAST(@InstrType AS VARCHAR(2)) + ' InstrCount: ' + CAST(@InstrCount AS VARCHAR(6)) + ' Time: ' + CAST(GETDATE() AS VARCHAR(50))

    FETCH NEXT FROM ShuffleCursor INTO @InstrType, @InstrCount
END

--SELECT * FROM ##Cards

SELECT * FROM ##Cards WHERE CardNr = 2019


CLOSE ShuffleCursor
DEALLOCATE ShuffleCursor

DROP TABLE #Input
DROP TABLE ##Cards
DROP TABLE ##CardsTemp
DROP TABLE ##Instructions

--7962 is too high for part 1
--3589 is correct for part 1