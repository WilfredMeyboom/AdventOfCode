DECLARE @StartCode BIGINT = 20151125

-- According to puzzle input
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

END


SELECT CAST(@Code AS VARCHAR(10)) AS Part1

