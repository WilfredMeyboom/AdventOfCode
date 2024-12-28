USE Test_WME

SET NOCOUNT ON

DECLARE @year VARCHAR(4) = '2024'
DECLARE @day VARCHAR(2)  = '24'

EXEC dbo.GetInput @year = @year, @day = @day
EXEC dbo.ParseInput @year = @year, @day = @day 

--SELECT TOP 10 * FROM ##Input
--SELECT TOP 10 * FROM ##InputInts
--SELECT TOP 10 * FROM ##InputNumbered
--SELECT TOP 10 * FROM ##InputGrid
--SELECT TOP 10 * FROM ##InputSplit
--SELECT TOP 10 * FROM ##InputSplitCust

CREATE TABLE ##Ports (ID INT IDENTITY(1,1), PortName VARCHAR(3), Val INT)

INSERT ##Ports (PortName, Val)
SELECT 
LEFT(Line, CHARINDEX(':', Line)-1)
, RIGHT(Line,1)
FROM ##InputNumbered WHERE Ind < 91

CREATE TABLE ##Ops (ID INT IDENTITY(1,1), Port1 VARCHAR(3), Port2 VARCHAR(3), Op VARCHAR(3), PortOut VARCHAR(3), Port1Val INT, Port2Val INT, PortOutVal INT)

INSERT ##Ops (Port1, Op, Port2, PortOut)
SELECT [1],[2],[3],[5]
FROM (
    SELECT RowNr, PieceNr, Piece
    FROM ##InputSplit
    WHERE RowNr > 91
    ) Src
PIVOT (
    MAX(Piece)
    FOR PieceNr IN ([1],[2],[3],[4],[5])
    ) pvt

UPDATE O
SET Port1Val = P1.Val
,   Port2Val = P2.Val
FROM ##Ops O
LEFT JOIN ##Ports P1 ON O.Port1 = P1.PortName
LEFT JOIN ##Ports P2 ON O.Port2 = P2.PortName

WHILE EXISTS (SELECT 1 FROM ##Ops WHERE PortOutVal IS NULL)
BEGIN

    UPDATE O
    SET PortOutVal = CASE WHEN Op = 'AND' THEN 
                          CASE WHEN Port1Val = 1 AND Port2Val = 1 THEN 1 ELSE 0 END
                          WHEN Op = 'OR'  THEN 
                          CASE WHEN Port1Val = 0 AND Port2Val = 0 THEN 0 ELSE 1 END
                          ELSE --XOR
                          CASE WHEN Port1Val + Port2Val = 1 THEN 1 ELSE 0 END
                     END
    FROM ##Ops O
    WHERE PortOutVal IS NULL
    AND Port1Val IS NOT NULL
    AND Port2Val IS NOT NULL

    UPDATE O_In
    SET Port1Val = O1.PortOutVal
    FROM ##Ops O_In
    INNER JOIN ##Ops O1 ON O1.PortOut = O_In.Port1 AND O_In.Port1Val IS NULL

    UPDATE O_In
    SET Port2Val = O2.PortOutVal
    FROM ##Ops O_In
    INNER JOIN ##Ops O2 ON O2.PortOut = O_In.Port2 AND O_In.Port2Val IS NULL

END

--SELECT PortOut ,PortOutVal FROM ##Ops WHERE PortOut LIKE 'z%' ORDER BY PortOut DESC
DECLARE @Part1 VARCHAR(100)
SELECT @Part1 = STRING_AGG(PortOutVal, '') WITHIN GROUP (ORDER BY PortOut DESC) FROM ##Ops WHERE PortOut LIKE 'z%' 

SELECT dbo.Binary2Decimal(@Part1) AS Part1

-- 43942008931358 is correct


UPDATE ##Ports SET Val = 0
UPDATE ##Ports SET Val = 1 WHERE PortName LIKE 'x%' -- IN ('x10')
--UPDATE ##Ports SET Val = 1 WHERE PortName IN ('y10')

EXEC BinaryAdd

SELECT STRING_AGG(Val, '') WITHIN GROUP (ORDER BY PortName DESC) FROM ##Ports WHERE PortName LIKE 'x%' 
SELECT STRING_AGG(Val, '') WITHIN GROUP (ORDER BY PortName DESC) FROM ##Ports WHERE PortName LIKE 'y%' 
SELECT STRING_AGG(PortOutVal, '') WITHIN GROUP (ORDER BY PortOut DESC) FROM ##Ops WHERE PortOut LIKE 'z%' 

SELECT * FROM ##Ops WHERE Port1 IN ('x10', 'y10','x11', 'y11','x12', 'y12','x13', 'y13','x14', 'y14','x15', 'y15','x16', 'y16') OR Port2 IN ('x10', 'y10','x11', 'y11','x12', 'y12','x13', 'y13','x14', 'y14','x15', 'y15','x16', 'y16') ORDER BY Port1

SELECT * FROM ##Ops WHERE PortOut IN ('skm','kwg','fwc')

DECLARE @Port VARCHAR(3) = 'tnc'
SELECT * FROM ##Ops WHERE Port1 = @Port OR Port2 = @Port OR PortOut = @Port

SELECT * FROM ##Ops ORDER BY Port1

--UPDATE ##Ops SET PortOut = 'z10' WHERE ID = 215
--UPDATE ##Ops SET PortOut = 'vcf' WHERE ID = 92
--UPDATE ##Ops SET PortOut = 'z17' WHERE ID = 190
--UPDATE ##Ops SET PortOut = 'fhg' WHERE ID = 24
--UPDATE ##Ops SET PortOut = 'dvb' WHERE ID = 16
--UPDATE ##Ops SET PortOut = 'fsq' WHERE ID = 54
--UPDATE ##Ops SET PortOut = 'z39' WHERE ID = 91
--UPDATE ##Ops SET PortOut = 'tnc' WHERE ID = 11

--dvb,fhg,fsq,tnc,vcf,z10,z17,z39
/*

 111111111111111111111111111111111111111111111
 000000000000000000000000000000000000000000000
0111111000011111111111111111100000001111111111

 000000000000000000000000000000000000000000000
 111111111111111111111111111111111111111111111
0111111000011111111111111111100000001111111111

 000000000000000000000000000000000111000000000
 000000000000000000000000000000000000000000000
0000000000000000000000000000000001001000000000

0111111001011111111111111111111111111111111111


*/




/*

DROP TABLE ##Ops
DROP TABLE ##Ports


*/


/*

GO
CREATE PROCEDURE BinaryAdd 
AS
BEGIN

    UPDATE ##Ops 
    SET Port1Val = NULL
    ,   Port2Val = NULL
    ,   PortOutVal = NULL

    UPDATE O
    SET Port1Val = P1.Val
    ,   Port2Val = P2.Val
    FROM ##Ops O
    LEFT JOIN ##Ports P1 ON O.Port1 = P1.PortName
    LEFT JOIN ##Ports P2 ON O.Port2 = P2.PortName

    WHILE EXISTS (SELECT 1 FROM ##Ops WHERE PortOutVal IS NULL)
    BEGIN

        UPDATE O
        SET PortOutVal = CASE WHEN Op = 'AND' THEN 
                              CASE WHEN Port1Val = 1 AND Port2Val = 1 THEN 1 ELSE 0 END
                              WHEN Op = 'OR'  THEN 
                              CASE WHEN Port1Val = 0 AND Port2Val = 0 THEN 0 ELSE 1 END
                              ELSE --XOR
                              CASE WHEN Port1Val + Port2Val = 1 THEN 1 ELSE 0 END
                         END
        FROM ##Ops O
        WHERE PortOutVal IS NULL
        AND Port1Val IS NOT NULL
        AND Port2Val IS NOT NULL

        UPDATE O_In
        SET Port1Val = O1.PortOutVal
        FROM ##Ops O_In
        INNER JOIN ##Ops O1 ON O1.PortOut = O_In.Port1 AND O_In.Port1Val IS NULL

        UPDATE O_In
        SET Port2Val = O2.PortOutVal
        FROM ##Ops O_In
        INNER JOIN ##Ops O2 ON O2.PortOut = O_In.Port2 AND O_In.Port2Val IS NULL

    END

END


*/