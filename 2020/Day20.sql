use Test_WME

SET NOCOUNT ON

CREATE TABLE ##Input (Line NVARCHAR(MAX));

BULK INSERT ##Input
FROM 'C:\Source\AdventOfCode\2020\input20.txt'
WITH (ROWTERMINATOR = '0x0A');

SELECT ROW_NUMBER() OVER (ORDER BY (SELECT 0)) AS ID, * 
INTO ##NumberedInput
FROM ##Input

INSERT ##NumberedInput (ID, Line)
SELECT MAX(ID) + 1, NULL FROM ##NumberedInput

--SELECT * FROM ##NumberedInput ORDER BY ID

CREATE TABLE ##PhotoData (ID INT IDENTITY(1,1), PhotoID INT, TileNr INT, LineNr INT, LineData VARCHAR(10))

;WITH cte_BlankLines AS (
    SELECT ID
    , ROW_NUMBER() OVER (ORDER BY ID) AS PhotoID
    , ISNULL(LAG(ID) OVER (ORDER BY ID), 0) AS PrevID FROM ##NumberedInput WHERE Line IS NULL    
)
INSERT ##PhotoData (PhotoID, TileNr, LineNr, LineData)
SELECT PhotoID
,      CASE WHEN LEFT(Line, 1) = 'T' THEN REPLACE(REPLACE(Line, 'Tile', ''), ':', '') ELSE '' END
,      ROW_NUMBER() OVER (PARTITION BY PhotoID ORDER BY (SELECT 0)) - 1
,      CASE WHEN LEFT(Line,1) IN ('.','#') THEN Line ELSE '' END
FROM ##NumberedInput NI
INNER JOIN cte_BlankLines cBL ON NI.ID BETWEEN cBL.PrevID AND cBL.ID
WHERE Line IS NOT NULL

SELECT * FROM ##PhotoData

CREATE TABLE ##Edges (ID INT IDENTITY(1,1), PhotoID INT, EdgeLine CHAR(10), OriginalPlace VARCHAR(10))

INSERT ##Edges (PhotoID, EdgeLine, OriginalPlace)
SELECT PhotoID, LineData, 'Top' FROM ##PhotoData WHERE LineNr = 1

INSERT ##Edges (PhotoID, EdgeLine, OriginalPlace)
SELECT PhotoID, LineData, 'Bottom' FROM ##PhotoData WHERE LineNr = 10

INSERT ##Edges (PhotoID, EdgeLine, OriginalPlace)
SELECT T1.PhotoID, LEFT(T1.LineData,1) + LEFT(T2.LineData,1) + LEFT(T3.LineData,1) + LEFT(T4.LineData,1) + LEFT(T5.LineData,1)
                 + LEFT(T6.LineData,1) + LEFT(T7.LineData,1) + LEFT(T8.LineData,1) + LEFT(T9.LineData,1) + LEFT(T10.LineData,1) 
     , 'Left' 
FROM ##PhotoData T1
INNER JOIN ##PhotoData T2 ON T1.PhotoID = T2.PhotoID AND T1.LineNr = T2.LineNr - 1
INNER JOIN ##PhotoData T3 ON T1.PhotoID = T3.PhotoID AND T1.LineNr = T3.LineNr - 2
INNER JOIN ##PhotoData T4 ON T1.PhotoID = T4.PhotoID AND T1.LineNr = T4.LineNr - 3
INNER JOIN ##PhotoData T5 ON T1.PhotoID = T5.PhotoID AND T1.LineNr = T5.LineNr - 4
INNER JOIN ##PhotoData T6 ON T1.PhotoID = T6.PhotoID AND T1.LineNr = T6.LineNr - 5
INNER JOIN ##PhotoData T7 ON T1.PhotoID = T7.PhotoID AND T1.LineNr = T7.LineNr - 6
INNER JOIN ##PhotoData T8 ON T1.PhotoID = T8.PhotoID AND T1.LineNr = T8.LineNr - 7
INNER JOIN ##PhotoData T9 ON T1.PhotoID = T9.PhotoID AND T1.LineNr = T9.LineNr - 8
INNER JOIN ##PhotoData T10 ON T1.PhotoID = T10.PhotoID AND T1.LineNr = T10.LineNr - 9
WHERE T1.LineNr = 1

INSERT ##Edges (PhotoID, EdgeLine, OriginalPlace)
SELECT T1.PhotoID, RIGHT(T1.LineData,1) + RIGHT(T2.LineData,1) + RIGHT(T3.LineData,1) + RIGHT(T4.LineData,1) + RIGHT(T5.LineData,1)
                 + RIGHT(T6.LineData,1) + RIGHT(T7.LineData,1) + RIGHT(T8.LineData,1) + RIGHT(T9.LineData,1) + RIGHT(T10.LineData,1) 
     , 'Right' 
FROM ##PhotoData T1
INNER JOIN ##PhotoData T2 ON T1.PhotoID = T2.PhotoID AND T1.LineNr = T2.LineNr - 1
INNER JOIN ##PhotoData T3 ON T1.PhotoID = T3.PhotoID AND T1.LineNr = T3.LineNr - 2
INNER JOIN ##PhotoData T4 ON T1.PhotoID = T4.PhotoID AND T1.LineNr = T4.LineNr - 3
INNER JOIN ##PhotoData T5 ON T1.PhotoID = T5.PhotoID AND T1.LineNr = T5.LineNr - 4
INNER JOIN ##PhotoData T6 ON T1.PhotoID = T6.PhotoID AND T1.LineNr = T6.LineNr - 5
INNER JOIN ##PhotoData T7 ON T1.PhotoID = T7.PhotoID AND T1.LineNr = T7.LineNr - 6
INNER JOIN ##PhotoData T8 ON T1.PhotoID = T8.PhotoID AND T1.LineNr = T8.LineNr - 7
INNER JOIN ##PhotoData T9 ON T1.PhotoID = T9.PhotoID AND T1.LineNr = T9.LineNr - 8
INNER JOIN ##PhotoData T10 ON T1.PhotoID = T10.PhotoID AND T1.LineNr = T10.LineNr - 9
WHERE T1.LineNr = 1

INSERT ##Edges (PhotoID, EdgeLine, OriginalPlace)
SELECT PhotoId, REVERSE(EdgeLine), 'Rev' + OriginalPlace
FROM ##Edges

;WITH cte_CornerIDs AS (
    SELECT T1.PhotoID
    FROM ##Edges T1
    LEFT JOIN ##Edges T2 ON T1.EdgeLine = T2.EdgeLine AND T1.PhotoID <> T2.PhotoID
    WHERE T2.ID IS NULL
    GROUP BY T1.PhotoID
    HAVING COUNT(1) > 2 --2 is just one edge
    --ORDER BY T1.PhotoID
)
SELECT *
FROM ##PhotoData 
WHERE PhotoID IN (SELECT PhotoID FROM cte_CornerIDs)
AND TileNr <> 0

SELECT CAST(2551 AS BIGINT) * 1697 * 1129 * 3313

--16192267830719 is correct for part 1


CREATE TABLE ##TileGrid(ID INT IDENTITY(1,1), X INT , Y INT, PhotoID INT, NeedFlip INT, Rotation INT)

-- Create a tile grid and reserver 144 (12 x 12) spaces for it
;WITH cte_Nrs AS (
    SELECT TOP 12 ROW_NUMBER() OVER (ORDER BY (SELECT 0)) AS Nr FROM sys.messages
)
INSERT ##TileGrid (X, Y)
SELECT X.Nr, Y.Nr
FROM cte_Nrs X
CROSS APPLY cte_Nrs Y

-- Set the first tile, of which we know it is a corner and is upright
UPDATE ##TileGrid SET PhotoID = 87, NeedFlip = 0, Rotation = 0
WHERE X = 1 AND Y = 1

DECLARE @NrOfEmptyTiles INT = 143

-- Defintion: Flipping an image means flipping over the bottom-left to top-right diagonal

-- Let's go until the grid is filled
WHILE @NrOfEmptyTiles > 0
BEGIN

    -- Add tiles to the right of already placed tiles. Record how we need to rotate and / or flip them to make them fit
    ;WITH cte_NewTiles AS (
        SELECT E2.PhotoID AS NextPhotoID
        ,      TG2.X AS NextX
        ,      TG2.Y AS NextY
        ,      CASE WHEN E2.OriginalPlace IN ('Left', 'Bottom', 'RevTop', 'RevRight') THEN 0
                    WHEN E2.OriginalPlace IN ('Right', 'Top', 'RevBottom', 'RevLeft') THEN 1
                END AS NextNeedFlip
        ,      CASE WHEN E2.OriginalPlace IN ('Left', 'RevBottom') THEN 0
                    WHEN E2.OriginalPlace IN ('Bottom','RevLeft') THEN 90
                    WHEN E2.OriginalPlace IN ('Top','RevRight') THEN 180
                    WHEN E2.OriginalPlace IN ('Right','RevTop') THEN 270
                END AS NextRotation
        --,'||',      *
        FROM ##TileGrid TG
        INNER JOIN ##TileGrid TG2 ON TG.X = TG2.X - 1 AND TG.Y = TG2.Y
        INNER JOIN ##Edges E ON TG.PhotoID = E.PhotoID
                            AND ((TG.NeedFlip = 0 AND TG.Rotation = 0 AND E.OriginalPlace = 'Right')
                              OR (TG.NeedFlip = 1 AND TG.Rotation = 0 AND E.OriginalPlace = 'RevTop')
                              OR (TG.NeedFlip = 0 AND TG.Rotation = 90 AND E.OriginalPlace = 'Top')
                              OR (TG.NeedFlip = 1 AND TG.Rotation = 90 AND E.OriginalPlace = 'RevRight')
                              OR (TG.NeedFlip = 0 AND TG.Rotation = 180 AND E.OriginalPlace = 'RevLeft')
                              OR (TG.NeedFlip = 1 AND TG.Rotation = 180 AND E.OriginalPlace = 'Bottom')
                              OR (TG.NeedFlip = 0 AND TG.Rotation = 270 AND E.OriginalPlace = 'RevBottom')
                              OR (TG.NeedFlip = 1 AND TG.Rotation = 270 AND E.OriginalPlace = 'Left')
                              )
        INNER JOIN ##Edges E2 ON E.EdgeLine = E2.EdgeLine 
                            AND E.PhotoID <> E2.PhotoID
        WHERE TG.PhotoID IS NOT NULL AND TG2.PhotoID IS NULL
    )
    UPDATE TL
    SET PhotoID = cNT.NextPhotoID
    ,   NeedFlip = cNT.NextNeedFlip
    ,   Rotation = cNT.NextRotation
    FROM ##TileGrid TL
    INNER JOIN cte_NewTiles cNT ON TL.X = cNT.NextX AND TL.Y = cNT.NextY

    -- Add tiles above already placed tiles. Record how we need to rotate and / or flip them to make them fit
    ;WITH cte_NewTiles AS (
        SELECT E2.PhotoID AS NextPhotoID
        ,      TG2.X AS NextX
        ,      TG2.Y AS NextY
        ,      CASE WHEN E2.OriginalPlace IN ('Left', 'Bottom', 'RevTop', 'RevRight') THEN 0
                    WHEN E2.OriginalPlace IN ('Right', 'Top', 'RevBottom', 'RefLeft') THEN 1
                END AS NextNeedFlip
        ,      CASE WHEN E2.OriginalPlace IN ('Bottom', 'RevLeft') THEN 0
                    WHEN E2.OriginalPlace IN ('Top', 'RevRight') THEN 90
                    WHEN E2.OriginalPlace IN ('Right', 'RevTop') THEN 180
                    WHEN E2.OriginalPlace IN ('Left', 'RevBottom') THEN 270
                END AS NextRotation
        --,'||',      *
        FROM ##TileGrid TG
        INNER JOIN ##TileGrid TG2 ON TG.X = TG2.X AND TG.Y = TG2.Y - 1
        INNER JOIN ##Edges E ON TG.PhotoID = E.PhotoID
                            AND ((TG.NeedFlip = 0 AND TG.Rotation = 0 AND E.OriginalPlace = 'Top')
                              OR (TG.NeedFlip = 1 AND TG.Rotation = 0 AND E.OriginalPlace = 'RevRight')
                              OR (TG.NeedFlip = 0 AND TG.Rotation = 90 AND E.OriginalPlace = 'RevLeft')
                              OR (TG.NeedFlip = 1 AND TG.Rotation = 90 AND E.OriginalPlace = 'Bottom')
                              OR (TG.NeedFlip = 0 AND TG.Rotation = 180 AND E.OriginalPlace = 'RevBottom')
                              OR (TG.NeedFlip = 1 AND TG.Rotation = 180 AND E.OriginalPlace = 'Left')
                              OR (TG.NeedFlip = 0 AND TG.Rotation = 270 AND E.OriginalPlace = 'Right')
                              OR (TG.NeedFlip = 1 AND TG.Rotation = 270 AND E.OriginalPlace = 'RevTop')
                              )
        INNER JOIN ##Edges E2 ON E.EdgeLine = E2.EdgeLine 
                            AND E.PhotoID <> E2.PhotoID
        WHERE TG.PhotoID IS NOT NULL AND TG2.PhotoID IS NULL
    )
    UPDATE TL
    SET PhotoID = cNT.NextPhotoID
    ,   NeedFlip = cNT.NextNeedFlip
    ,   Rotation = cNT.NextRotation
    FROM ##TileGrid TL
    INNER JOIN cte_NewTiles cNT ON TL.X = cNT.NextX AND TL.Y = cNT.NextY
    
    SELECT @NrOfEmptyTiles = COUNT(1) FROM ##TileGrid WHERE PhotoID IS NULL

    PRINT @NrOfEmptyTiles
END

SELECT * FROM ##TileGrid

SELECT * FROM ##PhotoData

DECLARE @NrOfPhotos INT 
DECLARE @Counter INT = 1
DECLARE @Rotation INT
DECLARE @NeedFlip INT

SELECT @NrOfPhotos = MAX(ID) FROM ##PhotoData

CREATE TABLE ##ScrubbedPhotos (ID INT IDENTITY(1,1), PhotoID INT, X INT, Y INT, Val CHAR(1))

WHILE @Counter <= @NrOfPhotos
BEGIN

    SELECT @Rotation = Rotation, @NeedFlip = NeedFlip FROM ##TileGrid WHERE PhotoID = @Counter

    IF @Rotation = 0   AND @NeedFlip = 0
        WITH cte_Grid AS (
            SELECT 1 AS X
            ,      LineNr - 1 AS Y
            ,      LEFT(SUBSTRING(LineData, 2, 8) , 1) AS PhotoChar
            ,      SUBSTRING(LineData, 3, 7) AS LeftOver
            FROM ##PhotoData
            WHERE PhotoID = @Counter AND LineNr BETWEEN 2 AND 9

            UNION ALL

            SELECT X + 1
            ,      Y
            ,      LEFT(LeftOver, 1) AS PhotoChar
            ,      CASE WHEN LEN(LeftOver) = 1 THEN '' ELSE SUBSTRING(LeftOver, 2, LEN(LeftOver)) END AS LeftOver
            FROM cte_Grid
            WHERE LEN(LeftOver) > 0
        )
        INSERT ##ScrubbedPhotos (PhotoID, X, Y, Val)
        SELECT @Counter, X, Y, PhotoChar
        FROM cte_Grid

    IF @Rotation = 90  AND @NeedFlip = 0
        WITH cte_Grid AS (
            SELECT 10 - LineNr AS X
            ,      1 AS Y
            ,      LEFT(SUBSTRING(LineData, 2, 8) , 1) AS PhotoChar
            ,      SUBSTRING(LineData, 3, 7) AS LeftOver
            FROM ##PhotoData
            WHERE PhotoID = @Counter AND LineNr BETWEEN 2 AND 9

            UNION ALL

            SELECT X
            ,      Y + 1
            ,      LEFT(LeftOver, 1) AS PhotoChar
            ,      CASE WHEN LEN(LeftOver) = 1 THEN '' ELSE SUBSTRING(LeftOver, 2, LEN(LeftOver)) END AS LeftOver
            FROM cte_Grid
            WHERE LEN(LeftOver) > 0
        )
        INSERT ##ScrubbedPhotos (PhotoID, X, Y, Val)
        SELECT @Counter, X, Y, PhotoChar
        FROM cte_Grid

    IF @Rotation = 180 AND @NeedFlip = 0
        WITH cte_Grid AS (
            SELECT 8 AS X
            ,      10 - LineNr AS Y
            ,      LEFT(SUBSTRING(LineData, 2, 8) , 1) AS PhotoChar
            ,      SUBSTRING(LineData, 3, 7) AS LeftOver
            FROM ##PhotoData
            WHERE PhotoID = @Counter AND LineNr BETWEEN 2 AND 9

            UNION ALL

            SELECT X - 1
            ,      Y
            ,      LEFT(LeftOver, 1) AS PhotoChar
            ,      CASE WHEN LEN(LeftOver) = 1 THEN '' ELSE SUBSTRING(LeftOver, 2, LEN(LeftOver)) END AS LeftOver
            FROM cte_Grid
            WHERE LEN(LeftOver) > 0
        )
        INSERT ##ScrubbedPhotos (PhotoID, X, Y, Val)
        SELECT @Counter, X, Y, PhotoChar
        FROM cte_Grid

    IF @Rotation = 270 AND @NeedFlip = 0
        WITH cte_Grid AS (
            SELECT LineNr - 1 AS X
            ,      8 AS Y
            ,      LEFT(SUBSTRING(LineData, 2, 8) , 1) AS PhotoChar
            ,      SUBSTRING(LineData, 3, 7) AS LeftOver
            FROM ##PhotoData
            WHERE PhotoID = @Counter AND LineNr BETWEEN 2 AND 9

            UNION ALL

            SELECT X
            ,      Y - 1
            ,      LEFT(LeftOver, 1) AS PhotoChar
            ,      CASE WHEN LEN(LeftOver) = 1 THEN '' ELSE SUBSTRING(LeftOver, 2, LEN(LeftOver)) END AS LeftOver
            FROM cte_Grid
            WHERE LEN(LeftOver) > 0
        )
        INSERT ##ScrubbedPhotos (PhotoID, X, Y, Val)
        SELECT @Counter, X, Y, PhotoChar
        FROM cte_Grid

    IF @Rotation = 0   AND @NeedFlip = 1
        WITH cte_Grid AS (
            SELECT 10 - LineNr AS X
            ,      8 AS Y
            ,      LEFT(SUBSTRING(LineData, 2, 8) , 1) AS PhotoChar
            ,      SUBSTRING(LineData, 3, 7) AS LeftOver
            FROM ##PhotoData
            WHERE PhotoID = @Counter AND LineNr BETWEEN 2 AND 9

            UNION ALL

            SELECT X
            ,      Y - 1
            ,      LEFT(LeftOver, 1) AS PhotoChar
            ,      CASE WHEN LEN(LeftOver) = 1 THEN '' ELSE SUBSTRING(LeftOver, 2, LEN(LeftOver)) END AS LeftOver
            FROM cte_Grid
            WHERE LEN(LeftOver) > 0
        )
        INSERT ##ScrubbedPhotos (PhotoID, X, Y, Val)
        SELECT @Counter, X, Y, PhotoChar
        FROM cte_Grid

    IF @Rotation = 90  AND @NeedFlip = 1
        WITH cte_Grid AS (
            SELECT 1 AS X
            ,      10 - LineNr AS Y
            ,      LEFT(SUBSTRING(LineData, 2, 8) , 1) AS PhotoChar
            ,      SUBSTRING(LineData, 3, 7) AS LeftOver
            FROM ##PhotoData
            WHERE PhotoID = @Counter AND LineNr BETWEEN 2 AND 9

            UNION ALL

            SELECT X + 1
            ,      Y 
            ,      LEFT(LeftOver, 1) AS PhotoChar
            ,      CASE WHEN LEN(LeftOver) = 1 THEN '' ELSE SUBSTRING(LeftOver, 2, LEN(LeftOver)) END AS LeftOver
            FROM cte_Grid
            WHERE LEN(LeftOver) > 0
        )
        INSERT ##ScrubbedPhotos (PhotoID, X, Y, Val)
        SELECT @Counter, X, Y, PhotoChar
        FROM cte_Grid

    IF @Rotation = 180 AND @NeedFlip = 1
        WITH cte_Grid AS (
            SELECT LineNr - 1 AS X
            ,      1 AS Y
            ,      LEFT(SUBSTRING(LineData, 2, 8) , 1) AS PhotoChar
            ,      SUBSTRING(LineData, 3, 7) AS LeftOver
            FROM ##PhotoData
            WHERE PhotoID = @Counter AND LineNr BETWEEN 2 AND 9

            UNION ALL

            SELECT X
            ,      Y + 1 
            ,      LEFT(LeftOver, 1) AS PhotoChar
            ,      CASE WHEN LEN(LeftOver) = 1 THEN '' ELSE SUBSTRING(LeftOver, 2, LEN(LeftOver)) END AS LeftOver
            FROM cte_Grid
            WHERE LEN(LeftOver) > 0
        )
        INSERT ##ScrubbedPhotos (PhotoID, X, Y, Val)
        SELECT @Counter, X, Y, PhotoChar
        FROM cte_Grid

    IF @Rotation = 270 AND @NeedFlip = 1
        WITH cte_Grid AS (
            SELECT 8 AS X
            ,      LineNr - 1 AS Y
            ,      LEFT(SUBSTRING(LineData, 2, 8) , 1) AS PhotoChar
            ,      SUBSTRING(LineData, 3, 7) AS LeftOver
            FROM ##PhotoData
            WHERE PhotoID = @Counter AND LineNr BETWEEN 2 AND 9

            UNION ALL

            SELECT X - 1
            ,      Y  
            ,      LEFT(LeftOver, 1) AS PhotoChar
            ,      CASE WHEN LEN(LeftOver) = 1 THEN '' ELSE SUBSTRING(LeftOver, 2, LEN(LeftOver)) END AS LeftOver
            FROM cte_Grid
            WHERE LEN(LeftOver) > 0
        )
        INSERT ##ScrubbedPhotos (PhotoID, X, Y, Val)
        SELECT @Counter, X, Y, PhotoChar
        FROM cte_Grid


    SET @Counter = @Counter + 1

END

-- Synchronize coordinate systems
UPDATE ##TileGrid SET Y = 13 - Y



CREATE TABLE ##Grid (ID INT IDENTITY(1,1), X INT, Y INT, Val INT, PartOfSeaMonster INT DEFAULT(0), UNIQUE (X, Y)) 

INSERT ##Grid (X, Y, Val)
SELECT (TG.X - 1) * 8 + SP.X, (TG.Y - 1) * 8 + SP.Y, 1 AS Val
FROM ##TileGrid TG
INNER JOIN ##ScrubbedPhotos SP ON TG.PhotoID = SP.PhotoID
WHERE Val = '#'

--Upright Right
SELECT *
FROM ##Grid G1
INNER JOIN ##Grid G2  ON G1.X  = G2.X - 1  AND G1.Y  = G2.Y - 1
INNER JOIN ##Grid G3  ON G2.X  = G3.X - 3  AND G2.Y  = G3.Y
INNER JOIN ##Grid G4  ON G3.X  = G4.X - 1  AND G3.Y  = G4.Y + 1
INNER JOIN ##Grid G5  ON G4.X  = G5.X - 1  AND G4.Y  = G5.Y
INNER JOIN ##Grid G6  ON G5.X  = G6.X - 1  AND G5.Y  = G6.Y - 1
INNER JOIN ##Grid G7  ON G6.X  = G7.X - 3  AND G6.Y  = G7.Y
INNER JOIN ##Grid G8  ON G7.X  = G8.X - 1  AND G7.Y  = G8.Y + 1
INNER JOIN ##Grid G9  ON G8.X  = G9.X - 1  AND G8.Y  = G9.Y
INNER JOIN ##Grid G10 ON G9.X  = G10.X - 1 AND G9.Y  = G10.Y - 1
INNER JOIN ##Grid G11 ON G10.X = G11.X - 3 AND G10.Y = G11.Y
INNER JOIN ##Grid G12 ON G11.X = G12.X - 1 AND G11.Y = G12.Y + 1
INNER JOIN ##Grid G13 ON G12.X = G13.X - 1 AND G12.Y = G13.Y + 1
INNER JOIN ##Grid G14 ON G13.X = G14.X     AND G13.Y = G14.Y - 1
INNER JOIN ##Grid G15 ON G14.X = G15.X - 1 AND G14.Y = G15.Y

--Upsidedown Right
SELECT *
FROM ##Grid G1
INNER JOIN ##Grid G2  ON G1.X  = G2.X - 1  AND G1.Y  = G2.Y + 1
INNER JOIN ##Grid G3  ON G2.X  = G3.X - 3  AND G2.Y  = G3.Y
INNER JOIN ##Grid G4  ON G3.X  = G4.X - 1  AND G3.Y  = G4.Y - 1
INNER JOIN ##Grid G5  ON G4.X  = G5.X - 1  AND G4.Y  = G5.Y
INNER JOIN ##Grid G6  ON G5.X  = G6.X - 1  AND G5.Y  = G6.Y + 1
INNER JOIN ##Grid G7  ON G6.X  = G7.X - 3  AND G6.Y  = G7.Y
INNER JOIN ##Grid G8  ON G7.X  = G8.X - 1  AND G7.Y  = G8.Y - 1
INNER JOIN ##Grid G9  ON G8.X  = G9.X - 1  AND G8.Y  = G9.Y
INNER JOIN ##Grid G10 ON G9.X  = G10.X - 1 AND G9.Y  = G10.Y + 1
INNER JOIN ##Grid G11 ON G10.X = G11.X - 3 AND G10.Y = G11.Y
INNER JOIN ##Grid G12 ON G11.X = G12.X - 1 AND G11.Y = G12.Y - 1
INNER JOIN ##Grid G13 ON G12.X = G13.X - 1 AND G12.Y = G13.Y - 1
INNER JOIN ##Grid G14 ON G13.X = G14.X     AND G13.Y = G14.Y + 1
INNER JOIN ##Grid G15 ON G14.X = G15.X - 1 AND G14.Y = G15.Y


--Upright Left
SELECT *
FROM ##Grid G1
INNER JOIN ##Grid G2  ON G1.X  = G2.X + 1  AND G1.Y  = G2.Y - 1
INNER JOIN ##Grid G3  ON G2.X  = G3.X + 3  AND G2.Y  = G3.Y
INNER JOIN ##Grid G4  ON G3.X  = G4.X + 1  AND G3.Y  = G4.Y + 1
INNER JOIN ##Grid G5  ON G4.X  = G5.X + 1  AND G4.Y  = G5.Y
INNER JOIN ##Grid G6  ON G5.X  = G6.X + 1  AND G5.Y  = G6.Y - 1
INNER JOIN ##Grid G7  ON G6.X  = G7.X + 3  AND G6.Y  = G7.Y
INNER JOIN ##Grid G8  ON G7.X  = G8.X + 1  AND G7.Y  = G8.Y + 1
INNER JOIN ##Grid G9  ON G8.X  = G9.X + 1  AND G8.Y  = G9.Y
INNER JOIN ##Grid G10 ON G9.X  = G10.X + 1 AND G9.Y  = G10.Y - 1
INNER JOIN ##Grid G11 ON G10.X = G11.X + 3 AND G10.Y = G11.Y
INNER JOIN ##Grid G12 ON G11.X = G12.X + 1 AND G11.Y = G12.Y + 1
INNER JOIN ##Grid G13 ON G12.X = G13.X + 1 AND G12.Y = G13.Y + 1
INNER JOIN ##Grid G14 ON G13.X = G14.X     AND G13.Y = G14.Y - 1
INNER JOIN ##Grid G15 ON G14.X = G15.X + 1 AND G14.Y = G15.Y

--Upsidedown Left
SELECT *
FROM ##Grid G1
INNER JOIN ##Grid G2  ON G1.X  = G2.X + 1  AND G1.Y  = G2.Y + 1
INNER JOIN ##Grid G3  ON G2.X  = G3.X + 3  AND G2.Y  = G3.Y
INNER JOIN ##Grid G4  ON G3.X  = G4.X + 1  AND G3.Y  = G4.Y - 1
INNER JOIN ##Grid G5  ON G4.X  = G5.X + 1  AND G4.Y  = G5.Y
INNER JOIN ##Grid G6  ON G5.X  = G6.X + 1  AND G5.Y  = G6.Y + 1
INNER JOIN ##Grid G7  ON G6.X  = G7.X + 3  AND G6.Y  = G7.Y
INNER JOIN ##Grid G8  ON G7.X  = G8.X + 1  AND G7.Y  = G8.Y - 1
INNER JOIN ##Grid G9  ON G8.X  = G9.X + 1  AND G8.Y  = G9.Y
INNER JOIN ##Grid G10 ON G9.X  = G10.X + 1 AND G9.Y  = G10.Y + 1
INNER JOIN ##Grid G11 ON G10.X = G11.X + 3 AND G10.Y = G11.Y
INNER JOIN ##Grid G12 ON G11.X = G12.X + 1 AND G11.Y = G12.Y - 1
INNER JOIN ##Grid G13 ON G12.X = G13.X + 1 AND G12.Y = G13.Y - 1
INNER JOIN ##Grid G14 ON G13.X = G14.X     AND G13.Y = G14.Y + 1
INNER JOIN ##Grid G15 ON G14.X = G15.X + 1 AND G14.Y = G15.Y

--Bottom Left
SELECT *
FROM ##Grid G1
INNER JOIN ##Grid G2  ON G1.X  = G2.X - 1  AND G1.Y  = G2.Y - 1
INNER JOIN ##Grid G3  ON G2.X  = G3.X      AND G2.Y  = G3.Y - 3
INNER JOIN ##Grid G4  ON G3.X  = G4.X + 1  AND G3.Y  = G4.Y - 1
INNER JOIN ##Grid G5  ON G4.X  = G5.X      AND G4.Y  = G5.Y - 1
INNER JOIN ##Grid G6  ON G5.X  = G6.X - 1  AND G5.Y  = G6.Y - 1
INNER JOIN ##Grid G7  ON G6.X  = G7.X      AND G6.Y  = G7.Y - 3
INNER JOIN ##Grid G8  ON G7.X  = G8.X + 1  AND G7.Y  = G8.Y - 1
INNER JOIN ##Grid G9  ON G8.X  = G9.X      AND G8.Y  = G9.Y - 1
INNER JOIN ##Grid G10 ON G9.X  = G10.X - 1 AND G9.Y  = G10.Y - 1
INNER JOIN ##Grid G11 ON G10.X = G11.X     AND G10.Y = G11.Y - 3
INNER JOIN ##Grid G12 ON G11.X = G12.X + 1 AND G11.Y = G12.Y - 1
INNER JOIN ##Grid G13 ON G12.X = G13.X + 1 AND G12.Y = G13.Y - 1
INNER JOIN ##Grid G14 ON G13.X = G14.X - 1 AND G13.Y = G14.Y
INNER JOIN ##Grid G15 ON G14.X = G15.X     AND G14.Y = G15.Y - 1

--Bottom Right
SELECT *
FROM ##Grid G1
INNER JOIN ##Grid G2  ON G1.X  = G2.X - 1  AND G1.Y  = G2.Y + 1
INNER JOIN ##Grid G3  ON G2.X  = G3.X      AND G2.Y  = G3.Y + 3
INNER JOIN ##Grid G4  ON G3.X  = G4.X + 1  AND G3.Y  = G4.Y + 1
INNER JOIN ##Grid G5  ON G4.X  = G5.X      AND G4.Y  = G5.Y + 1
INNER JOIN ##Grid G6  ON G5.X  = G6.X - 1  AND G5.Y  = G6.Y + 1
INNER JOIN ##Grid G7  ON G6.X  = G7.X      AND G6.Y  = G7.Y + 3
INNER JOIN ##Grid G8  ON G7.X  = G8.X + 1  AND G7.Y  = G8.Y + 1
INNER JOIN ##Grid G9  ON G8.X  = G9.X      AND G8.Y  = G9.Y + 1
INNER JOIN ##Grid G10 ON G9.X  = G10.X - 1 AND G9.Y  = G10.Y + 1
INNER JOIN ##Grid G11 ON G10.X = G11.X     AND G10.Y = G11.Y + 3
INNER JOIN ##Grid G12 ON G11.X = G12.X + 1 AND G11.Y = G12.Y + 1
INNER JOIN ##Grid G13 ON G12.X = G13.X + 1 AND G12.Y = G13.Y + 1
INNER JOIN ##Grid G14 ON G13.X = G14.X - 1 AND G13.Y = G14.Y
INNER JOIN ##Grid G15 ON G14.X = G15.X     AND G14.Y = G15.Y + 1


--Top Left
SELECT *
FROM ##Grid G1
INNER JOIN ##Grid G2  ON G1.X  = G2.X + 1  AND G1.Y  = G2.Y - 1
INNER JOIN ##Grid G3  ON G2.X  = G3.X      AND G2.Y  = G3.Y - 3
INNER JOIN ##Grid G4  ON G3.X  = G4.X - 1  AND G3.Y  = G4.Y - 1
INNER JOIN ##Grid G5  ON G4.X  = G5.X      AND G4.Y  = G5.Y - 1
INNER JOIN ##Grid G6  ON G5.X  = G6.X + 1  AND G5.Y  = G6.Y - 1
INNER JOIN ##Grid G7  ON G6.X  = G7.X      AND G6.Y  = G7.Y - 3
INNER JOIN ##Grid G8  ON G7.X  = G8.X - 1  AND G7.Y  = G8.Y - 1
INNER JOIN ##Grid G9  ON G8.X  = G9.X      AND G8.Y  = G9.Y - 1
INNER JOIN ##Grid G10 ON G9.X  = G10.X + 1 AND G9.Y  = G10.Y - 1
INNER JOIN ##Grid G11 ON G10.X = G11.X     AND G10.Y = G11.Y - 3
INNER JOIN ##Grid G12 ON G11.X = G12.X - 1 AND G11.Y = G12.Y - 1
INNER JOIN ##Grid G13 ON G12.X = G13.X - 1 AND G12.Y = G13.Y - 1
INNER JOIN ##Grid G14 ON G13.X = G14.X + 1 AND G13.Y = G14.Y
INNER JOIN ##Grid G15 ON G14.X = G15.X     AND G14.Y = G15.Y - 1

--Top Right
SELECT *
FROM ##Grid G1
INNER JOIN ##Grid G2  ON G1.X  = G2.X + 1  AND G1.Y  = G2.Y + 1
INNER JOIN ##Grid G3  ON G2.X  = G3.X      AND G2.Y  = G3.Y + 3
INNER JOIN ##Grid G4  ON G3.X  = G4.X - 1  AND G3.Y  = G4.Y + 1
INNER JOIN ##Grid G5  ON G4.X  = G5.X      AND G4.Y  = G5.Y + 1
INNER JOIN ##Grid G6  ON G5.X  = G6.X + 1  AND G5.Y  = G6.Y + 1
INNER JOIN ##Grid G7  ON G6.X  = G7.X      AND G6.Y  = G7.Y + 3
INNER JOIN ##Grid G8  ON G7.X  = G8.X - 1  AND G7.Y  = G8.Y + 1
INNER JOIN ##Grid G9  ON G8.X  = G9.X      AND G8.Y  = G9.Y + 1
INNER JOIN ##Grid G10 ON G9.X  = G10.X + 1 AND G9.Y  = G10.Y + 1
INNER JOIN ##Grid G11 ON G10.X = G11.X     AND G10.Y = G11.Y + 3
INNER JOIN ##Grid G12 ON G11.X = G12.X - 1 AND G11.Y = G12.Y + 1
INNER JOIN ##Grid G13 ON G12.X = G13.X - 1 AND G12.Y = G13.Y + 1
INNER JOIN ##Grid G14 ON G13.X = G14.X + 1 AND G13.Y = G14.Y
INNER JOIN ##Grid G15 ON G14.X = G15.X     AND G14.Y = G15.Y + 1

----> Top Right gives sea monsters (40 of them :D)
;WITH cte_Points AS (
    SELECT G1.X, G1.Y FROM ##Grid G1 INNER JOIN ##Grid G2  ON G1.X  = G2.X + 1  AND G1.Y  = G2.Y + 1 INNER JOIN ##Grid G3  ON G2.X  = G3.X      AND G2.Y  = G3.Y + 3 INNER JOIN ##Grid G4  ON G3.X  = G4.X - 1  AND G3.Y  = G4.Y + 1 INNER JOIN ##Grid G5  ON G4.X  = G5.X      AND G4.Y  = G5.Y + 1 INNER JOIN ##Grid G6  ON G5.X  = G6.X + 1  AND G5.Y  = G6.Y + 1 INNER JOIN ##Grid G7  ON G6.X  = G7.X      AND G6.Y  = G7.Y + 3 INNER JOIN ##Grid G8  ON G7.X  = G8.X - 1  AND G7.Y  = G8.Y + 1 INNER JOIN ##Grid G9  ON G8.X  = G9.X      AND G8.Y  = G9.Y + 1 INNER JOIN ##Grid G10 ON G9.X  = G10.X + 1 AND G9.Y  = G10.Y + 1INNER JOIN ##Grid G11 ON G10.X = G11.X     AND G10.Y = G11.Y + 3 INNER JOIN ##Grid G12 ON G11.X = G12.X - 1 AND G11.Y = G12.Y + 1 INNER JOIN ##Grid G13 ON G12.X = G13.X - 1 AND G12.Y = G13.Y + 1 INNER JOIN ##Grid G14 ON G13.X = G14.X + 1 AND G13.Y = G14.Y INNER JOIN ##Grid G15 ON G14.X = G15.X     AND G14.Y = G15.Y + 1
    UNION
    SELECT G2.X, G2.Y FROM ##Grid G1 INNER JOIN ##Grid G2  ON G1.X  = G2.X + 1  AND G1.Y  = G2.Y + 1 INNER JOIN ##Grid G3  ON G2.X  = G3.X      AND G2.Y  = G3.Y + 3 INNER JOIN ##Grid G4  ON G3.X  = G4.X - 1  AND G3.Y  = G4.Y + 1 INNER JOIN ##Grid G5  ON G4.X  = G5.X      AND G4.Y  = G5.Y + 1 INNER JOIN ##Grid G6  ON G5.X  = G6.X + 1  AND G5.Y  = G6.Y + 1 INNER JOIN ##Grid G7  ON G6.X  = G7.X      AND G6.Y  = G7.Y + 3 INNER JOIN ##Grid G8  ON G7.X  = G8.X - 1  AND G7.Y  = G8.Y + 1 INNER JOIN ##Grid G9  ON G8.X  = G9.X      AND G8.Y  = G9.Y + 1 INNER JOIN ##Grid G10 ON G9.X  = G10.X + 1 AND G9.Y  = G10.Y + 1INNER JOIN ##Grid G11 ON G10.X = G11.X     AND G10.Y = G11.Y + 3 INNER JOIN ##Grid G12 ON G11.X = G12.X - 1 AND G11.Y = G12.Y + 1 INNER JOIN ##Grid G13 ON G12.X = G13.X - 1 AND G12.Y = G13.Y + 1 INNER JOIN ##Grid G14 ON G13.X = G14.X + 1 AND G13.Y = G14.Y INNER JOIN ##Grid G15 ON G14.X = G15.X     AND G14.Y = G15.Y + 1
    UNION
    SELECT G3.X, G3.Y FROM ##Grid G1 INNER JOIN ##Grid G2  ON G1.X  = G2.X + 1  AND G1.Y  = G2.Y + 1 INNER JOIN ##Grid G3  ON G2.X  = G3.X      AND G2.Y  = G3.Y + 3 INNER JOIN ##Grid G4  ON G3.X  = G4.X - 1  AND G3.Y  = G4.Y + 1 INNER JOIN ##Grid G5  ON G4.X  = G5.X      AND G4.Y  = G5.Y + 1 INNER JOIN ##Grid G6  ON G5.X  = G6.X + 1  AND G5.Y  = G6.Y + 1 INNER JOIN ##Grid G7  ON G6.X  = G7.X      AND G6.Y  = G7.Y + 3 INNER JOIN ##Grid G8  ON G7.X  = G8.X - 1  AND G7.Y  = G8.Y + 1 INNER JOIN ##Grid G9  ON G8.X  = G9.X      AND G8.Y  = G9.Y + 1 INNER JOIN ##Grid G10 ON G9.X  = G10.X + 1 AND G9.Y  = G10.Y + 1INNER JOIN ##Grid G11 ON G10.X = G11.X     AND G10.Y = G11.Y + 3 INNER JOIN ##Grid G12 ON G11.X = G12.X - 1 AND G11.Y = G12.Y + 1 INNER JOIN ##Grid G13 ON G12.X = G13.X - 1 AND G12.Y = G13.Y + 1 INNER JOIN ##Grid G14 ON G13.X = G14.X + 1 AND G13.Y = G14.Y INNER JOIN ##Grid G15 ON G14.X = G15.X     AND G14.Y = G15.Y + 1
    UNION
    SELECT G4.X, G4.Y FROM ##Grid G1 INNER JOIN ##Grid G2  ON G1.X  = G2.X + 1  AND G1.Y  = G2.Y + 1 INNER JOIN ##Grid G3  ON G2.X  = G3.X      AND G2.Y  = G3.Y + 3 INNER JOIN ##Grid G4  ON G3.X  = G4.X - 1  AND G3.Y  = G4.Y + 1 INNER JOIN ##Grid G5  ON G4.X  = G5.X      AND G4.Y  = G5.Y + 1 INNER JOIN ##Grid G6  ON G5.X  = G6.X + 1  AND G5.Y  = G6.Y + 1 INNER JOIN ##Grid G7  ON G6.X  = G7.X      AND G6.Y  = G7.Y + 3 INNER JOIN ##Grid G8  ON G7.X  = G8.X - 1  AND G7.Y  = G8.Y + 1 INNER JOIN ##Grid G9  ON G8.X  = G9.X      AND G8.Y  = G9.Y + 1 INNER JOIN ##Grid G10 ON G9.X  = G10.X + 1 AND G9.Y  = G10.Y + 1INNER JOIN ##Grid G11 ON G10.X = G11.X     AND G10.Y = G11.Y + 3 INNER JOIN ##Grid G12 ON G11.X = G12.X - 1 AND G11.Y = G12.Y + 1 INNER JOIN ##Grid G13 ON G12.X = G13.X - 1 AND G12.Y = G13.Y + 1 INNER JOIN ##Grid G14 ON G13.X = G14.X + 1 AND G13.Y = G14.Y INNER JOIN ##Grid G15 ON G14.X = G15.X     AND G14.Y = G15.Y + 1
    UNION
    SELECT G5.X, G5.Y FROM ##Grid G1 INNER JOIN ##Grid G2  ON G1.X  = G2.X + 1  AND G1.Y  = G2.Y + 1 INNER JOIN ##Grid G3  ON G2.X  = G3.X      AND G2.Y  = G3.Y + 3 INNER JOIN ##Grid G4  ON G3.X  = G4.X - 1  AND G3.Y  = G4.Y + 1 INNER JOIN ##Grid G5  ON G4.X  = G5.X      AND G4.Y  = G5.Y + 1 INNER JOIN ##Grid G6  ON G5.X  = G6.X + 1  AND G5.Y  = G6.Y + 1 INNER JOIN ##Grid G7  ON G6.X  = G7.X      AND G6.Y  = G7.Y + 3 INNER JOIN ##Grid G8  ON G7.X  = G8.X - 1  AND G7.Y  = G8.Y + 1 INNER JOIN ##Grid G9  ON G8.X  = G9.X      AND G8.Y  = G9.Y + 1 INNER JOIN ##Grid G10 ON G9.X  = G10.X + 1 AND G9.Y  = G10.Y + 1INNER JOIN ##Grid G11 ON G10.X = G11.X     AND G10.Y = G11.Y + 3 INNER JOIN ##Grid G12 ON G11.X = G12.X - 1 AND G11.Y = G12.Y + 1 INNER JOIN ##Grid G13 ON G12.X = G13.X - 1 AND G12.Y = G13.Y + 1 INNER JOIN ##Grid G14 ON G13.X = G14.X + 1 AND G13.Y = G14.Y INNER JOIN ##Grid G15 ON G14.X = G15.X     AND G14.Y = G15.Y + 1
    UNION
    SELECT G6.X, G6.Y FROM ##Grid G1 INNER JOIN ##Grid G2  ON G1.X  = G2.X + 1  AND G1.Y  = G2.Y + 1 INNER JOIN ##Grid G3  ON G2.X  = G3.X      AND G2.Y  = G3.Y + 3 INNER JOIN ##Grid G4  ON G3.X  = G4.X - 1  AND G3.Y  = G4.Y + 1 INNER JOIN ##Grid G5  ON G4.X  = G5.X      AND G4.Y  = G5.Y + 1 INNER JOIN ##Grid G6  ON G5.X  = G6.X + 1  AND G5.Y  = G6.Y + 1 INNER JOIN ##Grid G7  ON G6.X  = G7.X      AND G6.Y  = G7.Y + 3 INNER JOIN ##Grid G8  ON G7.X  = G8.X - 1  AND G7.Y  = G8.Y + 1 INNER JOIN ##Grid G9  ON G8.X  = G9.X      AND G8.Y  = G9.Y + 1 INNER JOIN ##Grid G10 ON G9.X  = G10.X + 1 AND G9.Y  = G10.Y + 1INNER JOIN ##Grid G11 ON G10.X = G11.X     AND G10.Y = G11.Y + 3 INNER JOIN ##Grid G12 ON G11.X = G12.X - 1 AND G11.Y = G12.Y + 1 INNER JOIN ##Grid G13 ON G12.X = G13.X - 1 AND G12.Y = G13.Y + 1 INNER JOIN ##Grid G14 ON G13.X = G14.X + 1 AND G13.Y = G14.Y INNER JOIN ##Grid G15 ON G14.X = G15.X     AND G14.Y = G15.Y + 1
    UNION
    SELECT G7.X, G7.Y FROM ##Grid G1 INNER JOIN ##Grid G2  ON G1.X  = G2.X + 1  AND G1.Y  = G2.Y + 1 INNER JOIN ##Grid G3  ON G2.X  = G3.X      AND G2.Y  = G3.Y + 3 INNER JOIN ##Grid G4  ON G3.X  = G4.X - 1  AND G3.Y  = G4.Y + 1 INNER JOIN ##Grid G5  ON G4.X  = G5.X      AND G4.Y  = G5.Y + 1 INNER JOIN ##Grid G6  ON G5.X  = G6.X + 1  AND G5.Y  = G6.Y + 1 INNER JOIN ##Grid G7  ON G6.X  = G7.X      AND G6.Y  = G7.Y + 3 INNER JOIN ##Grid G8  ON G7.X  = G8.X - 1  AND G7.Y  = G8.Y + 1 INNER JOIN ##Grid G9  ON G8.X  = G9.X      AND G8.Y  = G9.Y + 1 INNER JOIN ##Grid G10 ON G9.X  = G10.X + 1 AND G9.Y  = G10.Y + 1INNER JOIN ##Grid G11 ON G10.X = G11.X     AND G10.Y = G11.Y + 3 INNER JOIN ##Grid G12 ON G11.X = G12.X - 1 AND G11.Y = G12.Y + 1 INNER JOIN ##Grid G13 ON G12.X = G13.X - 1 AND G12.Y = G13.Y + 1 INNER JOIN ##Grid G14 ON G13.X = G14.X + 1 AND G13.Y = G14.Y INNER JOIN ##Grid G15 ON G14.X = G15.X     AND G14.Y = G15.Y + 1
    UNION
    SELECT G8.X, G8.Y FROM ##Grid G1 INNER JOIN ##Grid G2  ON G1.X  = G2.X + 1  AND G1.Y  = G2.Y + 1 INNER JOIN ##Grid G3  ON G2.X  = G3.X      AND G2.Y  = G3.Y + 3 INNER JOIN ##Grid G4  ON G3.X  = G4.X - 1  AND G3.Y  = G4.Y + 1 INNER JOIN ##Grid G5  ON G4.X  = G5.X      AND G4.Y  = G5.Y + 1 INNER JOIN ##Grid G6  ON G5.X  = G6.X + 1  AND G5.Y  = G6.Y + 1 INNER JOIN ##Grid G7  ON G6.X  = G7.X      AND G6.Y  = G7.Y + 3 INNER JOIN ##Grid G8  ON G7.X  = G8.X - 1  AND G7.Y  = G8.Y + 1 INNER JOIN ##Grid G9  ON G8.X  = G9.X      AND G8.Y  = G9.Y + 1 INNER JOIN ##Grid G10 ON G9.X  = G10.X + 1 AND G9.Y  = G10.Y + 1INNER JOIN ##Grid G11 ON G10.X = G11.X     AND G10.Y = G11.Y + 3 INNER JOIN ##Grid G12 ON G11.X = G12.X - 1 AND G11.Y = G12.Y + 1 INNER JOIN ##Grid G13 ON G12.X = G13.X - 1 AND G12.Y = G13.Y + 1 INNER JOIN ##Grid G14 ON G13.X = G14.X + 1 AND G13.Y = G14.Y INNER JOIN ##Grid G15 ON G14.X = G15.X     AND G14.Y = G15.Y + 1
    UNION
    SELECT G9.X, G9.Y FROM ##Grid G1 INNER JOIN ##Grid G2  ON G1.X  = G2.X + 1  AND G1.Y  = G2.Y + 1 INNER JOIN ##Grid G3  ON G2.X  = G3.X      AND G2.Y  = G3.Y + 3 INNER JOIN ##Grid G4  ON G3.X  = G4.X - 1  AND G3.Y  = G4.Y + 1 INNER JOIN ##Grid G5  ON G4.X  = G5.X      AND G4.Y  = G5.Y + 1 INNER JOIN ##Grid G6  ON G5.X  = G6.X + 1  AND G5.Y  = G6.Y + 1 INNER JOIN ##Grid G7  ON G6.X  = G7.X      AND G6.Y  = G7.Y + 3 INNER JOIN ##Grid G8  ON G7.X  = G8.X - 1  AND G7.Y  = G8.Y + 1 INNER JOIN ##Grid G9  ON G8.X  = G9.X      AND G8.Y  = G9.Y + 1 INNER JOIN ##Grid G10 ON G9.X  = G10.X + 1 AND G9.Y  = G10.Y + 1INNER JOIN ##Grid G11 ON G10.X = G11.X     AND G10.Y = G11.Y + 3 INNER JOIN ##Grid G12 ON G11.X = G12.X - 1 AND G11.Y = G12.Y + 1 INNER JOIN ##Grid G13 ON G12.X = G13.X - 1 AND G12.Y = G13.Y + 1 INNER JOIN ##Grid G14 ON G13.X = G14.X + 1 AND G13.Y = G14.Y INNER JOIN ##Grid G15 ON G14.X = G15.X     AND G14.Y = G15.Y + 1
    UNION
    SELECT G10.X, G10.Y FROM ##Grid G1 INNER JOIN ##Grid G2  ON G1.X  = G2.X + 1  AND G1.Y  = G2.Y + 1 INNER JOIN ##Grid G3  ON G2.X  = G3.X      AND G2.Y  = G3.Y + 3 INNER JOIN ##Grid G4  ON G3.X  = G4.X - 1  AND G3.Y  = G4.Y + 1 INNER JOIN ##Grid G5  ON G4.X  = G5.X      AND G4.Y  = G5.Y + 1 INNER JOIN ##Grid G6  ON G5.X  = G6.X + 1  AND G5.Y  = G6.Y + 1 INNER JOIN ##Grid G7  ON G6.X  = G7.X      AND G6.Y  = G7.Y + 3 INNER JOIN ##Grid G8  ON G7.X  = G8.X - 1  AND G7.Y  = G8.Y + 1 INNER JOIN ##Grid G9  ON G8.X  = G9.X      AND G8.Y  = G9.Y + 1 INNER JOIN ##Grid G10 ON G9.X  = G10.X + 1 AND G9.Y  = G10.Y + 1INNER JOIN ##Grid G11 ON G10.X = G11.X     AND G10.Y = G11.Y + 3 INNER JOIN ##Grid G12 ON G11.X = G12.X - 1 AND G11.Y = G12.Y + 1 INNER JOIN ##Grid G13 ON G12.X = G13.X - 1 AND G12.Y = G13.Y + 1 INNER JOIN ##Grid G14 ON G13.X = G14.X + 1 AND G13.Y = G14.Y INNER JOIN ##Grid G15 ON G14.X = G15.X     AND G14.Y = G15.Y + 1
    UNION
    SELECT G11.X, G11.Y FROM ##Grid G1 INNER JOIN ##Grid G2  ON G1.X  = G2.X + 1  AND G1.Y  = G2.Y + 1 INNER JOIN ##Grid G3  ON G2.X  = G3.X      AND G2.Y  = G3.Y + 3 INNER JOIN ##Grid G4  ON G3.X  = G4.X - 1  AND G3.Y  = G4.Y + 1 INNER JOIN ##Grid G5  ON G4.X  = G5.X      AND G4.Y  = G5.Y + 1 INNER JOIN ##Grid G6  ON G5.X  = G6.X + 1  AND G5.Y  = G6.Y + 1 INNER JOIN ##Grid G7  ON G6.X  = G7.X      AND G6.Y  = G7.Y + 3 INNER JOIN ##Grid G8  ON G7.X  = G8.X - 1  AND G7.Y  = G8.Y + 1 INNER JOIN ##Grid G9  ON G8.X  = G9.X      AND G8.Y  = G9.Y + 1 INNER JOIN ##Grid G10 ON G9.X  = G10.X + 1 AND G9.Y  = G10.Y + 1INNER JOIN ##Grid G11 ON G10.X = G11.X     AND G10.Y = G11.Y + 3 INNER JOIN ##Grid G12 ON G11.X = G12.X - 1 AND G11.Y = G12.Y + 1 INNER JOIN ##Grid G13 ON G12.X = G13.X - 1 AND G12.Y = G13.Y + 1 INNER JOIN ##Grid G14 ON G13.X = G14.X + 1 AND G13.Y = G14.Y INNER JOIN ##Grid G15 ON G14.X = G15.X     AND G14.Y = G15.Y + 1
    UNION
    SELECT G12.X, G12.Y FROM ##Grid G1 INNER JOIN ##Grid G2  ON G1.X  = G2.X + 1  AND G1.Y  = G2.Y + 1 INNER JOIN ##Grid G3  ON G2.X  = G3.X      AND G2.Y  = G3.Y + 3 INNER JOIN ##Grid G4  ON G3.X  = G4.X - 1  AND G3.Y  = G4.Y + 1 INNER JOIN ##Grid G5  ON G4.X  = G5.X      AND G4.Y  = G5.Y + 1 INNER JOIN ##Grid G6  ON G5.X  = G6.X + 1  AND G5.Y  = G6.Y + 1 INNER JOIN ##Grid G7  ON G6.X  = G7.X      AND G6.Y  = G7.Y + 3 INNER JOIN ##Grid G8  ON G7.X  = G8.X - 1  AND G7.Y  = G8.Y + 1 INNER JOIN ##Grid G9  ON G8.X  = G9.X      AND G8.Y  = G9.Y + 1 INNER JOIN ##Grid G10 ON G9.X  = G10.X + 1 AND G9.Y  = G10.Y + 1INNER JOIN ##Grid G11 ON G10.X = G11.X     AND G10.Y = G11.Y + 3 INNER JOIN ##Grid G12 ON G11.X = G12.X - 1 AND G11.Y = G12.Y + 1 INNER JOIN ##Grid G13 ON G12.X = G13.X - 1 AND G12.Y = G13.Y + 1 INNER JOIN ##Grid G14 ON G13.X = G14.X + 1 AND G13.Y = G14.Y INNER JOIN ##Grid G15 ON G14.X = G15.X     AND G14.Y = G15.Y + 1
    UNION
    SELECT G13.X, G13.Y FROM ##Grid G1 INNER JOIN ##Grid G2  ON G1.X  = G2.X + 1  AND G1.Y  = G2.Y + 1 INNER JOIN ##Grid G3  ON G2.X  = G3.X      AND G2.Y  = G3.Y + 3 INNER JOIN ##Grid G4  ON G3.X  = G4.X - 1  AND G3.Y  = G4.Y + 1 INNER JOIN ##Grid G5  ON G4.X  = G5.X      AND G4.Y  = G5.Y + 1 INNER JOIN ##Grid G6  ON G5.X  = G6.X + 1  AND G5.Y  = G6.Y + 1 INNER JOIN ##Grid G7  ON G6.X  = G7.X      AND G6.Y  = G7.Y + 3 INNER JOIN ##Grid G8  ON G7.X  = G8.X - 1  AND G7.Y  = G8.Y + 1 INNER JOIN ##Grid G9  ON G8.X  = G9.X      AND G8.Y  = G9.Y + 1 INNER JOIN ##Grid G10 ON G9.X  = G10.X + 1 AND G9.Y  = G10.Y + 1INNER JOIN ##Grid G11 ON G10.X = G11.X     AND G10.Y = G11.Y + 3 INNER JOIN ##Grid G12 ON G11.X = G12.X - 1 AND G11.Y = G12.Y + 1 INNER JOIN ##Grid G13 ON G12.X = G13.X - 1 AND G12.Y = G13.Y + 1 INNER JOIN ##Grid G14 ON G13.X = G14.X + 1 AND G13.Y = G14.Y INNER JOIN ##Grid G15 ON G14.X = G15.X     AND G14.Y = G15.Y + 1
    UNION
    SELECT G14.X, G14.Y FROM ##Grid G1 INNER JOIN ##Grid G2  ON G1.X  = G2.X + 1  AND G1.Y  = G2.Y + 1 INNER JOIN ##Grid G3  ON G2.X  = G3.X      AND G2.Y  = G3.Y + 3 INNER JOIN ##Grid G4  ON G3.X  = G4.X - 1  AND G3.Y  = G4.Y + 1 INNER JOIN ##Grid G5  ON G4.X  = G5.X      AND G4.Y  = G5.Y + 1 INNER JOIN ##Grid G6  ON G5.X  = G6.X + 1  AND G5.Y  = G6.Y + 1 INNER JOIN ##Grid G7  ON G6.X  = G7.X      AND G6.Y  = G7.Y + 3 INNER JOIN ##Grid G8  ON G7.X  = G8.X - 1  AND G7.Y  = G8.Y + 1 INNER JOIN ##Grid G9  ON G8.X  = G9.X      AND G8.Y  = G9.Y + 1 INNER JOIN ##Grid G10 ON G9.X  = G10.X + 1 AND G9.Y  = G10.Y + 1INNER JOIN ##Grid G11 ON G10.X = G11.X     AND G10.Y = G11.Y + 3 INNER JOIN ##Grid G12 ON G11.X = G12.X - 1 AND G11.Y = G12.Y + 1 INNER JOIN ##Grid G13 ON G12.X = G13.X - 1 AND G12.Y = G13.Y + 1 INNER JOIN ##Grid G14 ON G13.X = G14.X + 1 AND G13.Y = G14.Y INNER JOIN ##Grid G15 ON G14.X = G15.X     AND G14.Y = G15.Y + 1
    UNION
    SELECT G15.X, G15.Y FROM ##Grid G1 INNER JOIN ##Grid G2  ON G1.X  = G2.X + 1  AND G1.Y  = G2.Y + 1 INNER JOIN ##Grid G3  ON G2.X  = G3.X      AND G2.Y  = G3.Y + 3 INNER JOIN ##Grid G4  ON G3.X  = G4.X - 1  AND G3.Y  = G4.Y + 1 INNER JOIN ##Grid G5  ON G4.X  = G5.X      AND G4.Y  = G5.Y + 1 INNER JOIN ##Grid G6  ON G5.X  = G6.X + 1  AND G5.Y  = G6.Y + 1 INNER JOIN ##Grid G7  ON G6.X  = G7.X      AND G6.Y  = G7.Y + 3 INNER JOIN ##Grid G8  ON G7.X  = G8.X - 1  AND G7.Y  = G8.Y + 1 INNER JOIN ##Grid G9  ON G8.X  = G9.X      AND G8.Y  = G9.Y + 1 INNER JOIN ##Grid G10 ON G9.X  = G10.X + 1 AND G9.Y  = G10.Y + 1INNER JOIN ##Grid G11 ON G10.X = G11.X     AND G10.Y = G11.Y + 3 INNER JOIN ##Grid G12 ON G11.X = G12.X - 1 AND G11.Y = G12.Y + 1 INNER JOIN ##Grid G13 ON G12.X = G13.X - 1 AND G12.Y = G13.Y + 1 INNER JOIN ##Grid G14 ON G13.X = G14.X + 1 AND G13.Y = G14.Y INNER JOIN ##Grid G15 ON G14.X = G15.X     AND G14.Y = G15.Y + 1
)
SELECT COUNT(1) - c.UsedPoints
FROM ##Grid G
CROSS APPLY (SELECT COUNT(1) AS UsedPoints FROM cte_Points) c
GROUP BY c.UsedPoints


--1909 is correct for part 2

/*
------------------------------------
Upright Right
 12345678901234567890
1                  # 
2#    ##    ##    ###
3 #  #  #  #  #  #   
------------------------------------
Upright Left
 #                  
###    ##    ##    #
   #  #  #  #  #  # 
------------------------------------
Upsidedown Right
 #  #  #  #  #  #   
#    ##    ##    ###
                  # 
------------------------------------
Upsidedown Left
   #  #  #  #  #  # 
###    ##    ##    #
 #                  
------------------------------------

SELECT REVERSE ('                  # ')
UNION
SELECT REVERSE ('#    ##    ##    ###')
UNION
SELECT REVERSE (' #  #  #  #  #  #   ')

------------------------------------
Top Left
 123
1 # 
2## 
3 #
4  #
5
6
7  #
8 #
9 #
0  #
1
2
3  #
4 #
5 #
6  #
7
8
9  #
0 #
------------------------------------
Top Right
 # 
 ##
 # 
#  
   
   
#  
 # 
 # 
#  
   
   
#  
 # 
 # 
#  
   
   
#  
 # 
------------------------------------
Bottom Left



------------------------------------
Bottom Right


*/

--2494 is too high for part 2


/*

DROP TABLE ##Grid
DROP TABLE ##ScrubbedPhotos
DROP TABLE ##TileGrid
DROP TABLE ##Edges
DROP TABLE ##PhotoData
DROP TABLE ##Input
DROP TABLE ##NumberedInput

*/





DECLARE @X INT
DECLARE @Y INT
DECLARE @MinX INT
DECLARE @MaxX INT
DECLARE @MaxY INT
DECLARE @Str NVARCHAR(MAX) = ''
DECLARE @Chr CHAR

SELECT @X = MIN(X), @Y = MIN(Y), @MaxX = MAX(X), @MaxY = MAX(Y) FROM ##Grid
SET @MinX = @X

WHILE (@Y <= @MaxY)
BEGIN

    SET @Str = ''

    WHILE (@X <= @MaxX)
    BEGIN
    
        SET @Chr = ' '

        SELECT @Chr = (CASE WHEN G.ID IS NOT NULL THEN '#' ELSE ' ' END)
        FROM ##Grid G
        WHERE G.X = @X AND G.Y = @Y
        
        SET @Str = @Str + @Chr

        SET @X = @X + 1

    END

    PRINT @Str

    SET @Y = @Y + 1
    SET @X = @MinX
END
