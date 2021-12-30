USE Test_WME

SET NOCOUNT ON

DECLARE @year VARCHAR(4) = '2021'
DECLARE @day VARCHAR(2)  = '16'

IF EXISTS (SELECT * FROM tempdb.sys.tables WHERE name = '##Input') DROP TABLE ##Input
CREATE TABLE ##Input (Line NVARCHAR(MAX) NULL);

IF EXISTS (SELECT * FROM tempdb.sys.tables WHERE name = '##InputNumbered') DROP TABLE ##InputNumbered
CREATE TABLE ##InputNumbered (Ind INT NOT NULL, Line NVARCHAR(MAX) NULL);

IF EXISTS (SELECT * FROM tempdb.sys.tables WHERE name = '##InputGrid') DROP TABLE ##InputGrid
CREATE TABLE ##InputGrid (Ind INT IDENTITY(1,1), RowNr INT, ColNr INT, Val CHAR);

IF EXISTS (SELECT * FROM tempdb.sys.tables WHERE name = '##InputInts') DROP TABLE ##InputInts
CREATE TABLE ##InputInts (Ind INT NOT NULL, Val BIGINT);

IF EXISTS (SELECT * FROM tempdb.sys.tables WHERE name = '##InputSplit') DROP TABLE ##InputSplit
CREATE TABLE ##InputSplit (Ind INT IDENTITY(1,1), RowNr INT, PieceNr INT, Piece VARCHAR(MAX));

IF EXISTS (SELECT * FROM tempdb.sys.tables WHERE name = '##InputSplitCust') DROP TABLE ##InputSplitCust
CREATE TABLE ##InputSplitCust (Ind INT IDENTITY(1,1), RowNr INT, PieceNr INT, Piece VARCHAR(MAX));

EXEC dbo.GetInput @year = @year, @day = @day
EXEC dbo.ParseInput @year = @year, @day = @day

--SELECT TOP 10 * FROM ##InputNumbered
--SELECT TOP 10 * FROM ##InputGrid
--SELECT TOP 10 * FROM ##InputInts
--SELECT * FROM ##InputSplit
--SELECT TOP 10 * FROM ##InputSplitCust

DECLARE @Counter BIGINT = 0
DECLARE @BinaryString VARCHAR(MAX) = ''

WHILE @Counter <= (SELECT MAX(ColNR) FROM ##InputGrid IG)
BEGIN
    SELECT @BinaryString = @BinaryString + dbo.Hex2Binary(IG.Val) 
    FROM ##InputGrid IG
    WHERE ColNr = @Counter

    SET @Counter = @Counter + 1
END


CREATE TABLE ##Packets (ID BIGINT IDENTITY(1,1), Ver CHAR(3), TypeID CHAR(3), Val BIGINT, ParentID BIGINT)

DECLARE @Output INT 

EXEC dbo.ReadString_2021_16 @BinaryString, @ParentID = NULL, @CharsRead = @Output OUTPUT


SELECT SUM(dbo.Binary2Decimal(Ver)) AS Part1
FROM ##Packets


--Delete trailing zeros
DELETE FROM ##Packets WHERE LEN(Ver) < 3 OR LEN(TypeID) < 3

CREATE TABLE ##TempTable (ID INT, ParentID INT, Val BIGINT, Operation VARCHAR(10))

DECLARE @NotFinished INT = 1

WHILE @NotFinished > 0
BEGIN

    ;WITH cte_Base aS (
    SELECT ID 
    , ParentID
    , Val
    , CASE WHEN TypeID = '000' THEN 'SUM' 
           WHEN TypeID = '001' THEN 'MUL' 
           WHEN TypeID = '010' THEN 'MIN' 
           WHEN TypeID = '011' THEN 'MAX' 
           WHEN TypeID = '100' THEN 'VAL' 
           WHEN TypeID = '101' THEN '>' 
           WHEN TypeID = '110' THEN '<' 
           WHEN TypeID = '111' THEN '==' 
      END AS Operation
    FROM ##Packets 
    ), cte_Ready as (
    SELECT c.ID, COUNT(1) AS Subs, SUM(CASE WHEN c2.Operation = 'Val' THEN 1 ELSE 0 END) AS Nrs
    FROM cte_Base c
    INNER JOIN cte_Base c2 ON c.ID = c2.ParentID
    GROUP BY c.ID
    ), cte_IDs AS (
        SELECT ID
        FROM cte_Ready
        WHERE Subs = Nrs
    )
    INSERT ##TempTable (ID, ParentID, Val, Operation)    
    SELECT ID, ParentiD, Val, Operation
    FROM cte_Base
    WHERE ID IN (SELECT ID FROM cte_IDs) OR ParentID IN (SELECT ID FROM cte_IDs)

    --Sum values
    ;WITH cte_Sum AS (
    SELECT T1.ID, SUM(T2.Val) AS NewVal
    FROM ##TempTable T1
    INNER JOIN ##TempTable T2 ON T1.ID = T2.ParentID
    WHERE T1.Operation = 'SUM'
    GROUP BY T1.ID
    )
    UPDATE P 
    SET Val = s.NewVal, TypeID = '100'
    FROM ##Packets P
    INNER JOIN cte_Sum s ON P.ID = s.ID

    DELETE FROM ##Packets WHERE ParentID IN (SELECT ID FROM ##TempTable WHERE Operation = 'SUM')

    --Exception for multiply by zero because we use EXP / LOG for the regular multiplier 
    ;WITH cte_MulZero AS (
    SELECT T1.ID, 0 AS NewVal
    FROM ##TempTable T1
    INNER JOIN ##TempTable T2 ON T1.ID = T2.ParentID
    WHERE T1.Operation = 'MUL' AND T2.Val = 0
    GROUP BY T1.ID
    )
    UPDATE P 
    SET Val = s.NewVal, TypeID = '100'
    FROM ##Packets P
    INNER JOIN cte_MulZero s ON P.ID = s.ID

    ;WITH cte_MulZero AS (
    SELECT T1.ID, 0 AS NewVal
    FROM ##TempTable T1
    INNER JOIN ##TempTable T2 ON T1.ID = T2.ParentID
    WHERE T1.Operation = 'MUL' AND T2.Val = 0
    GROUP BY T1.ID
    )
    DELETE FROM ##TempTable WHERE ParentID IN (SELECT ID FROM cte_MulZero)

    -- Multiply values
    ;WITH cte_Mul AS (
    SELECT T1.ID, ROUND(EXP(SUM(LOG(T2.Val))), 0) AS NewVal
    FROM ##TempTable T1
    INNER JOIN ##TempTable T2 ON T1.ID = T2.ParentID
    WHERE T1.Operation = 'MUL'
    GROUP BY T1.ID
    )
    UPDATE P 
    SET Val = s.NewVal, TypeID = '100'
    FROM ##Packets P
    INNER JOIN cte_Mul s ON P.ID = s.ID

    DELETE FROM ##Packets WHERE ParentID IN (SELECT ID FROM ##TempTable WHERE Operation = 'MUL')

    -- Take MAX of two values
    ;WITH cte_Max AS (
    SELECT T1.ID, MAX(T2.Val) AS NewVal
    FROM ##TempTable T1
    INNER JOIN ##TempTable T2 ON T1.ID = T2.ParentID
    WHERE T1.Operation IN ('MAX')
    GROUP BY T1.ID
    )
    UPDATE P 
    SET Val = s.NewVal, TypeID = '100'
    FROM ##Packets P
    INNER JOIN cte_Max s ON P.ID = s.ID

    DELETE FROM ##Packets WHERE ParentID IN (SELECT ID FROM ##TempTable WHERE Operation = 'MAX')

    -- Greater than (set value to 1 if true else 0)
    ;WITH cte_GT AS (
    SELECT T1.ID, CASE WHEN T2.Val > T3.Val THEN 1 ELSE 0 END AS NewVal
    FROM ##TempTable T1
    INNER JOIN ##TempTable T2 ON T1.ID = T2.ParentID
    INNER JOIN ##TempTable T3 ON T1.ID = T3.ParentID AND T2.ID < T3.ID
    WHERE T1.Operation IN ('>')
    )
    UPDATE P 
    SET Val = s.NewVal, TypeID = '100'
    FROM ##Packets P
    INNER JOIN cte_GT s ON P.ID = s.ID

    DELETE FROM ##Packets WHERE ParentID IN (SELECT ID FROM ##TempTable WHERE Operation = '>')

    -- Take MIN of two values
    ;WITH cte_Min AS (
    SELECT T1.ID, MIN(T2.Val) AS NewVal
    FROM ##TempTable T1
    INNER JOIN ##TempTable T2 ON T1.ID = T2.ParentID
    WHERE T1.Operation IN ('MIN')
    GROUP BY T1.ID
    )
    UPDATE P 
    SET Val = s.NewVal, TypeID = '100'
    FROM ##Packets P
    INNER JOIN cte_Min s ON P.ID = s.ID

    DELETE FROM ##Packets WHERE ParentID IN (SELECT ID FROM ##TempTable WHERE Operation = 'MIN')

    -- Less than (set value to 1 if true else 0)
    ;WITH cte_LT AS (
    SELECT T1.ID, CASE WHEN T2.Val < T3.Val THEN 1 ELSE 0 END AS NewVal
    FROM ##TempTable T1
    INNER JOIN ##TempTable T2 ON T1.ID = T2.ParentID
    INNER JOIN ##TempTable T3 ON T1.ID = T3.ParentID AND T2.ID < T3.ID
    WHERE T1.Operation IN ('<')
    )
    UPDATE P 
    SET Val = s.NewVal, TypeID = '100'
    FROM ##Packets P
    INNER JOIN cte_LT s ON P.ID = s.ID

    DELETE FROM ##Packets WHERE ParentID IN (SELECT ID FROM ##TempTable WHERE Operation = '<')

    -- Equal to (set value to 1 if true else 0)
    ;WITH cte_EQ AS (
    SELECT T1.ID, CASE WHEN T2.Val = T3.Val THEN 1 ELSE 0 END AS NewVal
    FROM ##TempTable T1
    INNER JOIN ##TempTable T2 ON T1.ID = T2.ParentID
    INNER JOIN ##TempTable T3 ON T1.ID = T3.ParentID AND T2.ID < T3.ID
    WHERE T1.Operation IN ('==')
    )
    UPDATE P 
    SET Val = s.NewVal, TypeID = '100'
    FROM ##Packets P
    INNER JOIN cte_EQ s ON P.ID = s.ID

    DELETE FROM ##Packets WHERE ParentID IN (SELECT ID FROM ##TempTable WHERE Operation = '==')

    -- Check if there are operations left in the temp table
    SELECT @NotFinished = COUNT(1) FROM ##TempTable

    TRUNCATE TABLE ##TempTable

END

SELECT Val AS Part2 FROM ##Packets

--124921618408 is correct for part2

DROP TABLE ##TempTable
DROP TABLE ##Packets



/*


CREATE OR ALTER PROC ReadString_2021_16 @BinStr VARCHAR(MAX), @ParentID BIGINT, @CharsRead BIGINT OUTPUT
AS 
BEGIN

    DECLARE @Counter BIGINT = 1

    DECLARE @Ver CHAR(3)
    DECLARE @Typ CHAR(3)
    DECLARE @NotLastBit INT
    DECLARE @Bits VARCHAR(50)

    DECLARE @LenTypeID INT
    DECLARE @TempLen VARCHAR(1500)
    DECLARE @Len BIGINT
    DECLARE @Output BIGINT
    DECLARE @NewID INT
  
--PRINT 'String: ' + @BinStr + ' ParentID: ' + CAST(@ParentID AS VARCHAR(5))

    SET @Ver = SUBSTRING(@BinStr, @Counter, 3)
    SET @Counter = @Counter + 3
    SET @Typ = SUBSTRING(@BinStr, @Counter, 3)
    SET @Counter = @Counter + 3

    -- Not an operator
    IF @Typ = '100'
    BEGIN
    SET @NotLastBit = 1
    SET @Bits = ''

    WHILE @NotLastBit > 0
    BEGIN
        
        SET @NotLastBit = SUBSTRING(@BinStr, @Counter, 1)
        SET @Counter = @Counter + 1
        SET @Bits = @Bits + SUBSTRING(@BinStr, @Counter, 4)
        SET @Counter = @Counter + 4

    END

    IF LEN(@Bits) > 44 PRINT '!!!!PROBLEM!!!!'

    INSERT ##Packets
    (
        Ver,
        TypeID,
        Val,
        ParentID
    )
    SELECT @Ver, @Typ, dbo.Binary2Decimal(@Bits), @ParentID

    END --Not an operator

    ELSE

    BEGIN --It's an operator!
        
        SET @LenTypeID = SUBSTRING(@BinStr, @Counter, 1)
        SET @Counter = @Counter + 1

        IF @LenTypeID = 0
        BEGIN

            SET @TempLen = SUBSTRING(@BinStr, @Counter, 15)
            SET @Counter = @Counter + 15
                        
            SELECT @Len = dbo.Binary2Decimal(@TempLen)
            SET @TempLen = SUBSTRING(@BinStr, @Counter, @Len)
            SET @CharsRead = 0

            INSERT ##Packets
            (
                Ver,
                TypeID,
                Val,
                ParentID
            )
            SELECT @Ver, @Typ, @Len, @ParentID
 
            SET @NewID = @@IDENTITY
 
            WHILE @CharsRead < @Len --Keep reading until the desired length is reached
            BEGIN
                EXEC dbo.ReadString_2021_16 @BinStr = @TempLen, @ParentID = @NewID, @CharsRead = @Output OUTPUT

                --PRINT 'Type 0: ' + CAST(@Output AS VARCHAR(4))

                SET @Counter = @Counter + @Output
                SET @TempLen = SUBSTRING(@BinStr, @Counter, @Len)
                SET @CharsRead = @CharsRead + @Output

            END
           

        END
        ELSE
        BEGIN

            SET @TempLen = SUBSTRING(@BinStr, @Counter, 11)
            SET @Counter = @Counter + 11

            SELECT @Len = dbo.Binary2Decimal(@TempLen)
            SET @TempLen = SUBSTRING(@BinStr, @Counter, LEN(@BinStr))
            SET @CharsRead = 0

            INSERT ##Packets
            (
                Ver,
                TypeID,
                Val,
                ParentID
            )
            SELECT @Ver, @Typ, @Len, @ParentID

            SET @NewID = @@IDENTITY

            WHILE @CharsRead < @Len --Keep reading until the desired length is reached
            BEGIN
                EXEC dbo.ReadString_2021_16 @BinStr = @TempLen, @ParentID = @NewID, @CharsRead = @Output OUTPUT
 
                SET @Counter = @Counter + @Output
                SET @TempLen = SUBSTRING(@BinStr, @Counter, LEN(@BinStr))
                SET @CharsRead = @CharsRead + 1
            END


        END


    END

    SET @CharsRead = @Counter - 1

    RETURN
END


*/