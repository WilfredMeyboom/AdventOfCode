USE Test_WME

SET NOCOUNT ON

DECLARE @year VARCHAR(4) = '2016'
DECLARE @day VARCHAR(2)  = '10'

EXEC dbo.GetInput @year = @year, @day = @day
EXEC dbo.ParseInput @year = @year, @day = @day

--SELECT TOP 10 * FROM ##InputNumbered
--SELECT TOP 10 * FROM ##InputGrid
--SELECT TOP 10 * FROM ##InputInts
--SELECT TOP 100 * FROM ##InputSplit
--SELECT * FROM ##Input


CREATE TABLE ##Bots (ID INT IDENTITY(1,1), BotNr INT, LowType VARCHAR(10), LowToNr INT, HighType VARCHAR(10), HighToNr INT, FirstValue INT, SecondValue INT)

INSERT ##Bots(BotNr, LowType, LowToNr, HighType, HighToNr)
SELECT [2] AS Bot, [6] AS LowDestType, [7] AS LowDest, [11] AS HighDestType, [12] AS HighDest FROM (
    SELECT RowNr, PieceNr, Piece
    FROM ##InputSplit
    WHERE PieceNr IN (2, 6, 7, 11, 12) AND RowNr IN (SELECT RowNr FROM ##InputSplit WHERE PieceNr = 1 AND Piece = 'bot')
) T
PIVOT (
    MAX(Piece) FOR PieceNr IN ([2],[6],[7],[11],[12])
) PVT

;WITH cte_StartingValues AS (
    SELECT [2] AS Val, [6] AS ToBot
    FROM (
        SELECT RowNr, PieceNr, Piece
        FROM ##InputSplit
        WHERE RowNr IN (SELECT RowNr FROM ##InputSplit WHERE PieceNr = 1 AND Piece = 'value')
    ) T
    PIVOT (
        MAX(Piece) FOR PieceNr IN ([2],[6])
    ) PVT
)
UPDATE B
SET FirstValue = c1.Val
,   SecondValue = c2.Val
FROM ##Bots B
INNER JOIN cte_StartingValues c1 ON B.BotNr = c1.ToBot
LEFT JOIN cte_StartingValues c2 ON B.BotNr = c2.ToBot AND c1.Val <> c2.Val
WHERE c2.Val IS NULL OR c1.Val < c2.Val

WHILE (SELECT COUNT(1) FROM ##Bots WHERE FirstValue IS NULL OR SecondValue IS NULL) > 0
BEGIN
    
    ;WITH cte_NewValues AS (
        SELECT LowToNr AS DestBot
        ,      CASE WHEN FirstValue < SecondValue THEN FirstValue ELSE SecondValue END AS ValueForBot
        FROM ##Bots 
        WHERE FirstValue IS NOT NULL AND SecondValue IS NOT NULL AND LowType = 'bot'
        UNION
        SELECT HighToNr AS DestBot
        ,      CASE WHEN FirstValue > SecondValue THEN FirstValue ELSE SecondValue END AS ValueForBot
        FROM ##Bots 
        WHERE FirstValue IS NOT NULL AND SecondValue IS NOT NULL AND HighType = 'bot'
        UNION
        SELECT BotNr AS DestBot, FirstValue AS ValueForBot
        FROM ##Bots
        WHERE FirstValue IS NOT NULL 
    )
    UPDATE B
    SET FirstValue = cN.ValueForBot
    ,   SecondValue = cN2.ValueForBot
    FROM ##Bots B
    INNER JOIN cte_NewValues cN ON B.BotNr = cN.DestBot
    INNER JOIN cte_NewValues cN2 ON B.BotNr = cN2.DestBot AND cN.ValueForBot < cN2.ValueForBot

END

SELECT BotNr AS Part1 FROM ##Bots WHERE FirstValue IN (17,61) AND SecondValue IN (17,61)

SELECT [0] * [1] * [2] AS Part2
FROM (
    SELECT CASE WHEN LowType = 'output' THEN LowToNr ELSE HighToNr END AS OutputNr
    ,      CASE WHEN LowType = 'output' AND FirstValue < SecondValue 
                  OR HighType = 'output' AND FirstValue > SecondValue 
                THEN FirstValue ELSE SecondValue END AS Val
    FROM ##Bots
    WHERE (LowType = 'output' AND LowToNr IN (0,1,2)) 
       OR (HighType = 'output' AND HighToNr IN (0,1,2)) 
) T
PIVOT (
    MAX(Val) FOR OutputNr IN ([0],[1],[2])
) PVT

DROP TABLE ##Bots

