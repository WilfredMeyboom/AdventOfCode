use Test_WME

CREATE TABLE ##Input (Line NVARCHAR(MAX));

BULK INSERT ##Input
FROM 'C:\Source\AdventOfCode\2018\input8.txt'
WITH (ROWTERMINATOR = '0x0A');

--SELECT *, LEN(Line) FROM ##Input

CREATE TABLE ##Nrs (Ind INT, Val INT, NodeNr INT, typeVal VARCHAR(10), fkParentNode INT, Worth INT)

--typeVal: nrnodes, nrmetadata, metadata

;WITH cte_Nrs AS (
    SELECT 1 AS Ind
    ,      LTRIM(RTRIM(LEFT(Line, CHARINDEX(' ', Line)))) AS Nr
    ,      LTRIM(SUBSTRING(Line, CHARINDEX(' ', Line), LEN(Line))) + ' ' AS Remainder
    FROM ##Input
    UNION ALL
    SELECT Ind + 1
    ,      LTRIM(RTRIM(LEFT(Remainder, CHARINDEX(' ', Remainder))))
    ,      LTRIM(SUBSTRING(Remainder, CHARINDEX(' ', Remainder), LEN(Remainder)))
    FROM cte_Nrs
    WHERE LEN(Remainder) > 0
)
INSERT ##Nrs (Ind, Val)
SELECT Ind, Nr FROM cte_Nrs 
OPTION (MAXRECURSION 20000)

DECLARE @CurrentNode INT = 0
DECLARE @Ind INT = 1

EXEC dbo.AnalyseNode @Ind, @Currentnode, @Ind OUTPUT

SELECT SUM(Val)
FROM ##Nrs
WHERE typeVal = 'metadata'

--41028 is correct for part 1

-- Determine worth of empty nodes
;WITH cte_Emptynodes AS (
    SELECT NodeNr, SUM(Val) AS ValSum
    FROM ##Nrs
    WHERE typeVal = 'metadata'
      AND NodeNr IN (SELECT NodeNr FROM ##Nrs WHERE typeVal = 'nrnodes' AND Val = 0)
    GROUP BY NodeNr
)
UPDATE N
SET N.Worth = cE.ValSum
FROM ##Nrs N
INNER JOIN cte_Emptynodes cE ON N.NodeNr = cE.NodeNr AND typeVal = 'nrnodes'

DECLARE @nrOfRowsEdited INT = 1

--Keep going until we have a value for every node
WHILE @nrOfRowsEdited > 0
BEGIN

    ;WITH cte_Ordered AS (
        SELECT fkParentNode
        ,      NodeNr
        ,      ROW_NUMBER() OVER (PARTITION BY fkParentNode ORDER BY NodeNr) RowNrNode
        FROM ##Nrs
        WHERE typeVal = 'nrnodes'
    ), cte_Worths AS (
        SELECT N.Ind, SUM(Nd.Worth) AS NodeWorth
        FROM ##Nrs N
        INNER JOIN ##Nrs MD ON N.NodeNr = MD.NodeNr AND MD.typeVal = 'metadata'
        LEFT JOIN cte_Ordered cO ON MD.Val = cO.RowNrNode AND MD.NodeNr = cO.fkParentNode
        LEFT JOIN ##Nrs Nd ON cO.NodeNr = Nd.NodeNr AND Nd.typeVal = 'nrnodes'
        WHERE N.typeVal = 'nrnodes' 
          AND N.Worth IS NULL
        GROUP BY N.Ind
    )
    UPDATE N
    SET N.Worth = cW.NodeWorth
    FROM ##Nrs N
    INNER JOIN cte_Worths cW ON N.Ind = cW.Ind AND ISNULL(N.Worth, -1) <> cW.NodeWorth
    WHERE N.typeVal = 'nrnodes'

    SET @nrOfRowsEdited = @@ROWCOUNT

END

SELECT * FROM ##Nrs WHERE fkParentNode = 0 AND typeVal = 'nrnodes'

-- 20849 is correct for part 2

/*

DROP TABLE ##Nrs
DROP TABLE ##Input

*/


/*


CREATE OR ALTER PROCEDURE dbo.AnalyseNode 
(
	@Ind INT,
    @PrevNode INT,
    @Offset INT OUTPUT
)AS
BEGIN

	SET @Offset = @Ind
    DECLARE @NrOfNodes INT
    DECLARE @NrOfMetaData INT
    DECLARE @CurrentNode INT

    SELECT @CurrentNode = ISNULL(MAX(NodeNr), 0) + 1 FROM ##Nrs

    SELECT @NrOfNodes = Val
    FROM ##Nrs
    WHERE Ind = @Offset

    UPDATE ##Nrs
    SET typeVal = 'nrnodes'
    ,   NodeNr = @CurrentNode
    ,   fkParentNode = @PrevNode
    WHERE Ind = @Offset

    SET @Offset = @Offset + 1

    SELECT @NrOfMetaData = Val
    FROM ##Nrs
    WHERE Ind = @Offset

    UPDATE ##Nrs
    SET typeVal = 'nrmetadata'
    ,   NodeNr = @CurrentNode
    ,   fkParentNode = @PrevNode
    WHERE Ind = @Offset

    SET @Offset = @Offset + 1

    WHILE @NrOfNodes > 0
    BEGIN
        EXEC dbo.AnalyseNode @Offset, @CurrentNode, @Offset OUTPUT

        SET @NrOfNodes = @NrOfNodes - 1
    END

    WHILE @NrOfMetaData > 0
    BEGIN

        UPDATE ##Nrs
        SET typeVal = 'metadata'
        ,   NodeNr = @CurrentNode
        ,   fkParentNode = @PrevNode
        WHERE Ind = @Offset

        SET @Offset = @Offset + 1
        SET @NrOfMetaData = @NrOfMetaData - 1

    END

	RETURN @Offset

END


*/

