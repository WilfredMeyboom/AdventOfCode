USE Test_WME

SET NOCOUNT ON

CREATE TABLE ##Input (Line NVARCHAR(MAX));

BULK INSERT ##Input
FROM 'C:\Source\AdventOfCode\2017\input20.txt'
WITH (ROWTERMINATOR = '0x0A');

CREATE TABLE ##Particles (ID INT IDENTITY(1,1), ParticleNr INT, P VARCHAR(50), V VARCHAR(50), A VARCHAR(50), Px INT, Py INT, Pz INT, Vx INT, Vy INT, Vz INT, Ax INT, Ay INT, Az INT)

INSERT ##Particles(ParticleNr, P, V, A)
SELECT ROW_NUMBER() OVER (ORDER BY (SELECT 0)) - 1
,      SUBSTRING(Line,4, CHARINDEX(', v', Line)-5) AS P
,      SUBSTRING(
            SUBSTRING(Line, CHARINDEX(', v', Line) + 5, LEN(Line)),
            1,
            CHARINDEX(', a', SUBSTRING(Line, CHARINDEX(', v', Line) + 5, LEN(Line))) - 2
            ) AS V
,      REPLACE(
            SUBSTRING(
                SUBSTRING(Line, CHARINDEX(', v', Line) + 5, LEN(Line)),
                CHARINDEX(', a', SUBSTRING(Line, CHARINDEX(', v', Line) + 5, LEN(Line))) + 5,
                LEN(SUBSTRING(Line, CHARINDEX(', v', Line) + 5, LEN(Line)))
                )
             , '>', '')
             AS A
FROM ##Input

UPDATE ##Particles
SET Px = LEFT(P, CHARINDEX(',', P) - 1),
    Py = LEFT(SUBSTRING(P, CHARINDEX(',', P) + 1, LEN(P)), CHARINDEX(',', SUBSTRING(P, CHARINDEX(',', P) + 1, LEN(P))) - 1),
    Pz = SUBSTRING(SUBSTRING(P, CHARINDEX(',', P) + 2, LEN(P)), CHARINDEX(',', SUBSTRING(P, CHARINDEX(',', P) + 1, LEN(P))), LEN(P)),
    Vx = LEFT(V, CHARINDEX(',', V) - 1),
    Vy = LEFT(SUBSTRING(V, CHARINDEX(',', V) + 1, LEN(V)), CHARINDEX(',', SUBSTRING(V, CHARINDEX(',', V) + 1, LEN(V))) - 1),
    Vz = SUBSTRING(SUBSTRING(V, CHARINDEX(',', V) + 2, LEN(V)), CHARINDEX(',', SUBSTRING(V, CHARINDEX(',', V) + 1, LEN(V))), LEN(V)),
    Ax = LEFT(A, CHARINDEX(',', A) - 1),
    Ay = LEFT(SUBSTRING(A, CHARINDEX(',', A) + 1, LEN(A)), CHARINDEX(',', SUBSTRING(A, CHARINDEX(',', A) + 1, LEN(A))) - 1),
    Az = SUBSTRING(SUBSTRING(A, CHARINDEX(',', A) + 2, LEN(A)), CHARINDEX(',', SUBSTRING(A, CHARINDEX(',', A) + 1, LEN(A))), LEN(A))
FROM ##Particles

--SELECT *, ABS(Px) + ABS(Py) + ABS(Pz) FROM ##Particles

DECLARE @Counter INT = 0
DECLARE @ClosestPoint INT

DECLARE @SkipPart1 INT = 1

IF @SkipPart1 = 0
BEGIN

WHILE @Counter < 5000
BEGIN

    -- Update speeds
    UPDATE ##Particles
    SET Vx = Vx + Ax,
        Vy = Vy + Ay,
        Vz = Vz + Az

    -- Update positions
    UPDATE ##Particles
    SET Px = Vx + Px,
        Py = Vy + Py,
        Pz = Vz + Pz

    SELECT TOP 1 @ClosestPoint = ParticleNr FROM ##Particles ORDER BY ABS(Px) + ABS(Py) + ABS(Pz)

    PRINT 'Closest point currently is: ' + CAST(@ClosestPoint AS VARCHAR(4))

    SET @Counter = @Counter + 1

END

-- 170 is correct for part 1

END --SkipPart1

DECLARE @NrOfParticlesLeft INT

WHILE @Counter < 5000
BEGIN

    ;WITH cte_Collision AS 
    (
        SELECT P1.ParticleNr
        FROM ##Particles P1
        LEFT JOIN ##Particles P2 ON P1.Px = P2.Px
                                AND P1.Py = P2.Py
                                AND P1.Pz = P2.Pz
                                AND P1.ParticleNr <> P2.ParticleNr
        WHERE P2.ParticleNr IS NOT NULL
    )
    DELETE P 
    FROM ##Particles P
    INNER JOIN cte_Collision cC ON P.ParticleNr = cC.ParticleNr

    -- Update speeds
    UPDATE ##Particles
    SET Vx = Vx + Ax,
        Vy = Vy + Ay,
        Vz = Vz + Az

    -- Update positions
    UPDATE ##Particles
    SET Px = Vx + Px,
        Py = Vy + Py,
        Pz = Vz + Pz

    SELECT @NrOfParticlesLeft = COUNT(1) FROM ##Particles 

    PRINT 'Nr of particles left: ' + CAST(@NrOfParticlesLeft AS VARCHAR(4))

    SET @Counter = @Counter + 1

END

-- 571 is correct for part 2


/*

DROP TABLE ##Input
DROP TABLE ##Particles

*/