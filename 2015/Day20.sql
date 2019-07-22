DECLARE @Input INT = 29000000
--29.000.000

SET NOCOUNT ON

--SELECT @Input

--CREATE TABLE ##Results (ID INT IDENTITY(1,1), HouseNr INT, NrOfPresents INT)

--INSERT ##Results (HouseNr, NrOfPresents) SELECT TOP /*500000*/ 100 ROW_NUMBER() OVER (ORDER BY (SELECT 0)) /*+ 500000*/, 0 FROM sys.messages T1 --CROSS APPLY sys.messages T2

DECLARE @ElfNr INT = 471200



WHILE NOT EXISTS (SELECT 1 FROM ##Results WHERE NrOfPresents > @Input AND @ElfNr > HouseNr)
--WHILE @ElfNr < 10
BEGIN

    UPDATE ##Results
    SET NrOfPresents = NrOfPresents + 11 * @ElfNr
    WHERE HouseNr % @ElfNr = 0 AND HouseNr <= @ElfNr * 50

    SET @ElfNr = @ElfNr + 1

    IF @ElfNr % 1000 = 0 PRINT CAST(@ElfNr AS VARCHAR(10)) + ' ' + CAST(GETDATE() AS VARCHAR(50))

END


SELECT * FROM ##Results WHERE NrOfPresents > @Input


-- 942480 is too high for part 2
-- Elfs up to number 471200
-- 720720 is too high for part 2
-- 500000 is too low for part 2
-- 705600 is correct for part 2

-- 196560 is too low for part 1

/*

DROP TABLE ##Results

ID        HouseNr   NrOfPresents
196560	196560	 8.332.800
193120	393120	16.934.400

*/


/* Part 1
DECLARE @Input INT = 29000000

--DECLARE @House BIGINT = 635000
DECLARE @House BIGINT = 600000

--821000

DECLARE @Elf BIGINT = 1

DECLARE @NrPresents BIGINT = 0

WHILE @NrPresents < @Input
BEGIN

    SET @NrPresents = 0
    SET @Elf = 1
    SET @House = @House + 1

    WHILE @Elf <= @House
    BEGIN
        
        IF @House % @Elf = 0 SET @NrPresents = @NrPresents + (@Elf * 10)

        SET @Elf = @Elf + 1

    END

    IF @House % 1000 = 0 PRINT CAST(GETDATE() AS VARCHAR(50)) + ' House:' + CAST(@House AS VARCHAR(10)) + ' Presents:' + CAST(@NrPresents AS VARCHAR(10))

END

PRINT CAST(GETDATE() AS VARCHAR(50)) + ' House:' + CAST(@House AS VARCHAR(10)) + ' Presents:' + CAST(@NrPresents AS VARCHAR(10))


--1004640 is too high for part 1
-- 999600 is too high for part 1
-- 887040 is incorrect Presents:29393280
-- 800280 Presents:30492000

--665280 is correct for part 1
*/
