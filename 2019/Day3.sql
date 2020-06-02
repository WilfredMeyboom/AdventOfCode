use Test_WME

SET NOCOUNT ON

CREATE TABLE #Input (Nr NVARCHAR(MAX));

BULK INSERT #Input
FROM 'C:\Source\AdventOfCode\2019\input3.txt'
WITH (ROWTERMINATOR = '0x0A');

UPDATE #Input
SET nr = LEFT(nr, LEN(nr)-1)

SELECT * FROM #Input

--DELETE FROM #Input
--INSERT #Input (Nr) VALUES ('1,9,10,3,2,3,11,0,99,30,40,50')

CREATE TABLE #Wires (Ind INT, WireNr INT, Dir VARCHAR(10))

;WITH cte_Values AS (
    SELECT 0 AS Ind
    ,      ROW_NUMBER() OVER (ORDER BY (SELECT 0)) As WireNr
    ,      SUBSTRING(Nr, 1, CHARINDEX(',', Nr) - 1) AS Val
    ,      SUBSTRING(Nr, CHARINDEX(',', Nr) + 1, LEN(Nr)) + ',' AS Rest
    FROM #Input
    UNION ALL
    SELECT Ind + 1
    ,      WireNr
    ,      SUBSTRING(Rest, 1, CHARINDEX(',', Rest) - 1) AS Val
    ,      SUBSTRING(Rest, CHARINDEX(',', Rest) + 1, LEN(Rest)) AS Rest
    FROM cte_Values
    WHERE LEN(Rest) > 0
)
INSERT #Wires (Ind, WireNr, Dir)
SELECT Ind, WireNr, Val
FROM cte_Values OPTION (MAXRECURSION 10000)

--SELECT * FROM #Wires

CREATE TABLE #Points (WireNr INT, X INT, Y INT, Dist INT)

DECLARE @WireNr INT = 1
DECLARE @WireNrOld INT = 0
DECLARE @Ind INT
DECLARE @Dir VARCHAR(10)
DECLARE @X INT
DECLARE @Y INT
DECLARE @Instr VARCHAR(10)
DECLARE @Length INT
DECLARE @Counter INT = 0
DECLARE @DistCounter INT = 0

DECLARE Instr CURSOR FOR SELECT WireNr, Ind, Dir FROM #Wires ORDER BY WireNr, Ind, Dir 

OPEN Instr

FETCH NEXT FROM Instr INTO @WireNr, @Ind, @Dir

WHILE @@FETCH_STATUS = 0
BEGIN

    IF @WireNr <> @WireNrOld 
    BEGIN
        SET @WireNrOld = @WireNr
        SET @X = 0
        SET @Y = 0
        SET @DistCounter = 0
    END

    SELECT @Instr = SUBSTRING(@Dir, 1, 1)
    ,      @Length = SUBSTRING(@Dir, 2, LEN(@Dir))

    SET @Counter = 0

    WHILE @Counter < @Length
    BEGIN

        SET @DistCounter = @DistCounter + 1

        IF @Instr = 'U' SET @Y = @Y + 1
        IF @Instr = 'D' SET @Y = @Y - 1
        IF @Instr = 'L' SET @X = @X - 1
        IF @Instr = 'R' SET @X = @X + 1

        INSERT #Points (WireNr, X, Y, Dist)
        SELECT @WireNr, @X, @Y, @DistCounter

        SET @Counter = @Counter + 1
    END


    FETCH NEXT FROM Instr INTO @WireNr, @Ind, @Dir

END

CLOSE Instr
DEALLOCATE Instr

--SELECT * FROM #Points

SELECT P1.X, P1.Y, ABS(P1.X) + ABS(P1.Y) AS ManhattanDist 
FROM #Points P1
INNER JOIN #Points P2 ON P1.X = P2.X
                     AND P1.Y = P2.Y
                     AND P1.WireNr < P2.WireNr
ORDER BY 3

-- 2180 is correct for part 1

;WITH cte_crossRoads AS (
    SELECT P1.X, P1.Y, ABS(P1.X) + ABS(P1.Y) AS ManhattanDist 
    FROM #Points P1
    INNER JOIN #Points P2 ON P1.X = P2.X
                         AND P1.Y = P2.Y
                         AND P1.WireNr < P2.WireNr
)
SELECT cR.*, P1.Dist, P2.Dist, P1.Dist + P2.Dist AS Dist
FROM cte_crossRoads cR
INNER JOIN #Points P1 ON P1.WireNr = 1
                     AND cR.X = P1.X
                     AND cR.Y = P1.Y
INNER JOIN #Points P2 ON P2.WireNr = 2
                     AND cR.X = P2.X
                     AND cR.Y = P2.Y
ORDER BY P1.Dist + P2.Dist

DROP TABLE #Input
DROP TABLE #Wires
DROP TABLE #Points

--2180 is correct for part 1

--112316 is correct for part 2