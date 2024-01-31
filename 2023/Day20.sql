USE Test_WME

SET NOCOUNT ON

DECLARE @year VARCHAR(4) = '2023'
DECLARE @day VARCHAR(2)  = '20'

EXEC dbo.GetInput @year = @year, @day = @day
EXEC dbo.ParseInput @year = @year, @day = @day, @SplitCustom = ',->' 

--SELECT TOP 10 * FROM ##Input
--SELECT TOP 10 * FROM ##InputInts
--SELECT TOP 10 * FROM ##InputNumbered
--SELECT TOP 10 * FROM ##InputGrid
--SELECT TOP 10 * FROM ##InputSplit
  
CREATE TABLE ##Pulses (ID INT IDENTITY(1,1), Src VARCHAR(20), Trg VARCHAR(20), IsHigh INT, PulseHandled INT)

CREATE TABLE ##Modules (ID INT IDENTITY(1,1), ModName VARCHAR(20), ModType VARCHAR(20), ModStatus VARCHAR(50))

CREATE TABLE ##Links (ID INT IDENTITY(1,1), Src VARCHAR(20), Trg VARCHAR(20))

INSERT ##Links (Src, Trg)
SELECT TRIM(REPLACE(REPLACE(I1.Piece, '%', ''), '&', '')), TRIM(I2.Piece)
FROM ##InputSplitCust I1
INNER JOIN ##InputSplitCust I2 ON  I1.RowNr = I2.RowNr AND I2.PieceNr > 1
WHERE I1.PieceNr = 1

INSERT ##Modules (ModName, ModType, ModStatus)
SELECT TRIM(REPLACE(REPLACE(I1.Piece, '%', ''), '&', ''))
,      CASE WHEN LEFT(I1.Piece, 1) = '%' THEN 'FlipFlop'
            WHEN LEFT(I1.Piece, 1) = '&' THEN 'Conjunction'
            ELSE 'Broadcaster' END
,      CASE WHEN LEFT(I1.Piece, 1) = '%' THEN 'Off'
            WHEN LEFT(I1.Piece, 1) = '&' THEN ''
            ELSE 'Broadcast' END
FROM ##InputSplitCust I1
WHERE I1.PieceNr = 1
 

CREATE TABLE ##ModulesHistory (ID INT IDENTITY(1,1), Iteration INT, ModName VARCHAR(20), ModType VARCHAR(20), ModStatus VARCHAR(50))

DECLARE @ID INT = 0
DECLARE @Src VARCHAR(20)
DECLARE @Trg VARCHAR(20)
DECLARE @IsHigh INT
DECLARE @ModType VARCHAR(20)
DECLARE @ModStatus VARCHAR(50)

DECLARE @Count INT = 0

WHILE @Count < 1000
BEGIN

INSERT ##Pulses (Src, Trg, IsHigh, PulseHandled)
SELECT 'button', 'broadcaster', 0, 0


WHILE (SELECT COUNT(1) FROM ##Pulses P WHERE P.PulseHandled = 0) > 0
BEGIN

    SET @ID = @ID + 1

    SELECT @Src = Src, @Trg = Trg, @IsHigh = IsHigh FROM ##Pulses P WHERE ID = @ID AND P.PulseHandled = 0

    SELECT @ModType = ModType, @ModStatus = ModStatus FROM ##Modules M WHERE ModName = @Trg

    IF @ModType = 'Broadcaster'
    BEGIN
        INSERT ##Pulses (Src, Trg, IsHigh, PulseHandled)
        SELECT Src, Trg, @isHigh, 0
        FROM ##Links L
        WHERE src = @Trg       
    END

    IF @ModType = 'FlipFlop' AND @IsHigh = 0 --FlipFlops don't react to high pulses
    BEGIN
        UPDATE M
        SET ModStatus = CASE WHEN @ModStatus = 'Off'
                              THEN 'On'
                              ELSE 'Off'
                              END
        FROM ##Modules M
        WHERE ModName = @Trg

        INSERT ##Pulses (Src, Trg, IsHigh, PulseHandled)
        SELECT Src
        ,      Trg
        ,      CASE WHEN @ModStatus = 'Off'
                    THEN 1
                    ELSE 0
                    END
        ,      0
        FROM ##Links L
        WHERE src = @Trg 
 
    END

    IF @ModType = 'Conjunction'
    BEGIN

        IF (@IsHigh = 1 AND @ModStatus NOT LIKE '%'+@Src+'%') SET @ModStatus = @ModStatus + @Src + '|'
        ELSE IF (@IsHigh = 0 AND @ModStatus LIKE '%'+@Src+'%') SET @ModStatus = REPLACE(@ModStatus, @Src + '|', '')

        UPDATE ##Modules SET ModStatus = @ModStatus WHERE ModName = @Trg

        SET @IsHigh = 1
        --SELECT COUNT(1) * 2,  LEN (@ModStatus), @ModStatus FROM ##Links L WHERE Trg = @Trg 
        IF (SELECT SUM(LEN(Src)+1) FROM ##Links L WHERE Trg = @Trg) = LEN (@ModStatus) SET @IsHigh = 0

        INSERT ##Pulses (Src, Trg, IsHigh, PulseHandled)
        SELECT Src
        ,      Trg
        ,      @IsHigh
        ,      0
        FROM ##Links L
        WHERE src = @Trg          
    END

    UPDATE ##Pulses SET PulseHandled = 1 WHERE ID = @ID
END

INSERT ##ModulesHistory (Iteration, ModName, ModType, ModStatus)
SELECT @Count, M.ModName, M.ModType, M.ModStatus
FROM ##Modules M

SET @Count = @Count + 1

END -- Button pressed

--SELECT * FROM ##Links L
SELECT * FROM ##Modules M
SELECT * FROM ##Pulses P


SELECT IsHigh, COUNT(1) FROM ##Pulses GROUP BY IsHigh
--SELECT 4250*2750
--SELECT 18361*44384
--629325554 too low


SELECT * FROM ##ModulesHistory WHERE ModName = 'tg' AND ModStatus LIKE '%pf%' ORDER BY ID -- 0-0 2-2 4-4
SELECT * FROM ##ModulesHistory WHERE ModName = 'tg' AND ModStatus LIKE '%nv%' ORDER BY ID -- 1-2 5-6 9-10
SELECT * FROM ##ModulesHistory WHERE ModName = 'tg' AND ModStatus LIKE '%ht%' ORDER BY ID -- 3-6 11-14 19-22
SELECT * FROM ##ModulesHistory WHERE ModName = 'tg' AND ModStatus LIKE '%rr%' ORDER BY ID -- 7-14 23-30 39-46
SELECT * FROM ##ModulesHistory WHERE ModName = 'tg' AND ModStatus LIKE '%cf%' ORDER BY ID -- 63-126 191-254 319-382
SELECT * FROM ##ModulesHistory WHERE ModName = 'tg' AND ModStatus LIKE '%rq%' ORDER BY ID -- 255-510 767-1022?
SELECT * FROM ##ModulesHistory WHERE ModName = 'tg' AND ModStatus LIKE '%dx%' ORDER BY ID -- 511-
SELECT * FROM ##ModulesHistory WHERE ModName = 'tg' AND ModStatus LIKE '%hn%' ORDER BY ID  --?
SELECT * FROM ##ModulesHistory WHERE ModName = 'tg' AND ModStatus LIKE '%qn%' ORDER BY ID  --?

SELECT * FROM ##ModulesHistory WHERE ModName = 'xf' AND ModStatus LIKE '%kh%' ORDER BY ID -- 0-0 2-2 4-4
SELECT * FROM ##ModulesHistory WHERE ModName = 'xf' AND ModStatus LIKE '%cv%' ORDER BY ID -- 3-6 11-14 19-22
SELECT * FROM ##ModulesHistory WHERE ModName = 'xf' AND ModStatus LIKE '%gb%' ORDER BY ID -- 15-30 47-62
SELECT * FROM ##ModulesHistory WHERE ModName = 'xf' AND ModStatus LIKE '%ln%' ORDER BY ID -- 63-126 191-254
SELECT * FROM ##ModulesHistory WHERE ModName = 'xf' AND ModStatus LIKE '%qj%' ORDER BY ID -- 127-254 383-510
SELECT * FROM ##ModulesHistory WHERE ModName = 'xf' AND ModStatus LIKE '%sx%' ORDER BY ID -- 511- 1022?
SELECT * FROM ##ModulesHistory WHERE ModName = 'xf' AND ModStatus LIKE '%fb%' ORDER BY ID -- ?
SELECT * FROM ##ModulesHistory WHERE ModName = 'xf' AND ModStatus LIKE '%cq%' ORDER BY ID -- ?

SELECT * FROM ##ModulesHistory WHERE ModName = 'tz' AND ModStatus LIKE '%cn%' ORDER BY ID -- 0-0 2-2 4-4
SELECT * FROM ##ModulesHistory WHERE ModName = 'tz' AND ModStatus LIKE '%vm%' ORDER BY ID -- 1-2 5-6 9-10
SELECT * FROM ##ModulesHistory WHERE ModName = 'tz' AND ModStatus LIKE '%zl%' ORDER BY ID -- 3-6 11-14 19-22
SELECT * FROM ##ModulesHistory WHERE ModName = 'tz' AND ModStatus LIKE '%cm%' ORDER BY ID -- 7-14 23-30
SELECT * FROM ##ModulesHistory WHERE ModName = 'tz' AND ModStatus LIKE '%fj%' ORDER BY ID -- 31-62 95-126
SELECT * FROM ##ModulesHistory WHERE ModName = 'tz' AND ModStatus LIKE '%zt%' ORDER BY ID -- 63-126 191-254
SELECT * FROM ##ModulesHistory WHERE ModName = 'tz' AND ModStatus LIKE '%fq%' ORDER BY ID -- 127-254 383-510
SELECT * FROM ##ModulesHistory WHERE ModName = 'tz' AND ModStatus LIKE '%bn%' ORDER BY ID -- 255-510 767-1022?
SELECT * FROM ##ModulesHistory WHERE ModName = 'tz' AND ModStatus LIKE '%hx%' ORDER BY ID -- 511-1022?
SELECT * FROM ##ModulesHistory WHERE ModName = 'tz' AND ModStatus LIKE '%jx%' ORDER BY ID -- ?
SELECT * FROM ##ModulesHistory WHERE ModName = 'tz' AND ModStatus LIKE '%np%' ORDER BY ID -- ?

SELECT * FROM ##ModulesHistory WHERE ModName = 'mq' AND ModStatus LIKE '%sj%' ORDER BY ID -- 0-0 2-2 4-4
SELECT * FROM ##ModulesHistory WHERE ModName = 'mq' AND ModStatus LIKE '%pp%' ORDER BY ID -- 15-30 47-62
SELECT * FROM ##ModulesHistory WHERE ModName = 'mq' AND ModStatus LIKE '%jr%' ORDER BY ID -- 31-62 95-126
SELECT * FROM ##ModulesHistory WHERE ModName = 'mq' AND ModStatus LIKE '%zp%' ORDER BY ID -- 127-254 383-510
SELECT * FROM ##ModulesHistory WHERE ModName = 'mq' AND ModStatus LIKE '%xz%' ORDER BY ID -- 511-1022?
SELECT * FROM ##ModulesHistory WHERE ModName = 'mq' AND ModStatus LIKE '%gz%' ORDER BY ID -- ?
SELECT * FROM ##ModulesHistory WHERE ModName = 'mq' AND ModStatus LIKE '%lq%' ORDER BY ID -- ?


-- 2047-4094 6143-8190  (2047)
-- 1023-2046 3071-4094  (3071)
--  511-1022 1535-2046 2559-3070 3583-4094 (3583)
----> 2047 + 1024 + 512 + 256 + 128 + 64 + 32 + 16 + 8 + 4 + 2 + 1
SELECT 2047 + 1024 + 512 + 256 + 128 + 64 + 32 + 16 + 8 + 4 + 2 + 1

SELECT 2047*3071*3583*3839*3967*4031*4063*4079*4087*4091*4093*4094


/*

Prime factorizations
2047 = 23×89 (2 distinct prime factors)
3071 = 37×83 (2 distinct prime factors)
3583 is prime

3839 = 11×349 (2 distinct prime factors)
3967 is prime

4031 = 29×139 (2 distinct prime factors)
4063 = 17×239 (2 distinct prime factors)
4079 is prime

4087 = 61×67 (2 distinct prime factors)
4091 is prime
4093 is prime
4094 = 2×23×89 (3 distinct prime factors)

SELECT CAST(3583 AS BIGINT) *23*89*37*83
        *11*349*3967
        *29*139*17*239*4079
        *61*67*4091*4093*2

*/


--4094 is too low

-- 228282646835717 is correct. Maar waarom???

--228282646835717 = 3761×3797×3919×4079 (4 distinct prime factors)

/*

DROP TABLE ##Links
DROP TABLE ##Modules
DROP TABLE ##Pulses
DROP TABLE ##ModulesHistory

*/