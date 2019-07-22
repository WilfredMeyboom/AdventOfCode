DECLARE @StartCode BIGINT = 20151125

DECLARE @TargetPosX INT = 3019
DECLARE @TargetPosY INT = 3010

DECLARE @Factor BIGINT = 252533
DECLARE @Divider BIGINT = 33554393

DECLARE @PosX INT = 1
DECLARE @PosY INT = 1

DECLARE @Code BIGINT = @StartCode

WHILE @PosX <> @TargetPosX OR @PosY <> @TargetPosY
BEGIN

    SET @PosX = @PosX + 1
    SET @PosY = @PosY - 1

    IF @PosY = 0
    BEGIN
        SET @PosY = @PosX
        SET @PosX = 1
    END

    SET @Code = (@Code * @Factor) % @Divider


    --PRINT 'X: ' + CAST(@PosX AS VARCHAR(6)) + ', Y: ' + CAST(@PosY AS VARCHAR(6)) + ', Code: ' + CAST(@Code AS VARCHAR(10))

END


PRINT 'X: ' + CAST(@PosX AS VARCHAR(6)) + ', Y: ' + CAST(@PosY AS VARCHAR(6)) + ', Code: ' + CAST(@Code AS VARCHAR(10))

--26300009 is too high for part 1
--X: 3019, Y: 3010, Code: 8997277 -- is correct for part 1