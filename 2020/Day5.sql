use Test_WME

SET NOCOUNT ON

CREATE TABLE ##Input (Line NVARCHAR(MAX));

BULK INSERT ##Input
FROM 'C:\Source\AdventOfCode\2020\input5.txt'
WITH (ROWTERMINATOR = '0x0A');

SELECT REPLACE(REPLACE(LEFT(Line, 7), 'B', 1), 'F', 0) R
,      REPLACE(REPLACE(RIGHT(Line, 3), 'R', 1), 'L', 0) C
,      dbo.BinaryToDecimal(REPLACE(REPLACE(LEFT(Line, 7), 'B', 1), 'F', 0)) R_D
,      dbo.BinaryToDecimal(REPLACE(REPLACE(RIGHT(Line, 3), 'R', 1), 'L', 0)) C_D
,      dbo.BinaryToDecimal(REPLACE(REPLACE(LEFT(Line, 7), 'B', 1), 'F', 0)) * 8 +
            dbo.BinaryToDecimal(REPLACE(REPLACE(RIGHT(Line, 3), 'R', 1), 'L', 0)) ID
,* 
INTO ##IDList
FROM ##Input
ORDER BY 5


SELECT * 
FROM ##IDList T1
LEFT JOIN ##IDList T2 ON T1.ID = T2.ID - 1
WHERE T2.ID IS NULL

SELECT * FROM ##IDList WHERE ID = 610

--928 is correct for part 1
--610 is correct for part 2

/*
DROP TABLE ##Input
*/



/*

CREATE FUNCTION [dbo].[BinaryToDecimal]
(
	@Input varchar(255)
)
RETURNS bigint
AS
BEGIN

	DECLARE @Cnt tinyint = 1
	DECLARE @Len tinyint = LEN(@Input)
	DECLARE @Output bigint = CAST(SUBSTRING(@Input, @Len, 1) AS bigint)

	WHILE(@Cnt < @Len) BEGIN
		SET @Output = @Output + POWER(CAST(SUBSTRING(@Input, @Len - @Cnt, 1) * 2 AS bigint), @Cnt)

		SET @Cnt = @Cnt + 1
	END

	RETURN @Output	

END

*/