USE Test_WME

SET NOCOUNT ON

DECLARE @PublicKey1 BIGINT = 335121
DECLARE @PublicKey2 BIGINT = 363891

DECLARE @Subj BIGINT = 7
DECLARE @Val BIGINT = 1
DECLARE @Mod BIGINT = 20201227
DECLARE @Loop1 BIGINT = 0
DECLARE @Loop2 BIGINT = 0
DECLARE @Target1 BIGINT = 335121
DECLARE @Target2 BIGINT = 363891
DECLARE @Counter BIGINT = 0
DECLARE @Done INT = 0

   
SET @Val = 1
SET @Loop1 = 0
SET @Loop2 = 0

WHILE @Val <> @Target1
BEGIN
    
    SET @Val = @Val * @Subj
    SET @Val = @Val % @Mod

    SET @Loop1 = @Loop1 + 1

END

SET @Val = 1

WHILE @Val <> @Target2
BEGIN
    
    SET @Val = @Val * @Subj
    SET @Val = @Val % @Mod

    SET @Loop2 = @Loop2 + 1

END

PRINT @Loop1
PRINT @Loop2

SET @Counter = 0
SET @Val = 1
SET @Subj = @PublicKey2

WHILE @Counter < @Loop1
BEGIN
    
    SET @Val = @Val * @Subj
    SET @Val = @Val % @Mod

    SET @Counter = @Counter + 1

END

PRINT @Val

SET @Counter = 0
SET @Val = 1
SET @Subj = @PublicKey1

WHILE @Counter < @Loop2
BEGIN
    
    SET @Val = @Val * @Subj
    SET @Val = @Val % @Mod

    SET @Counter = @Counter + 1

END

PRINT @Val




-- 12909639 is too high for part 1
-- 9420461 is correct for part 1

