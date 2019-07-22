use Test_WME

SET NOCOUNT ON

CREATE TABLE ##Input (Line NVARCHAR(MAX));

BULK INSERT ##Input
FROM 'D:\Wilfred\AdventOfCode\2015\input7.txt'
WITH (ROWTERMINATOR = '0x0A');


CREATE TABLE ##Gates (ID INT IDENTITY(1,1), Gate VARCHAR(10), Input1 VARCHAR(5), Input2 VARCHAR(5), Output VARCHAR(5))

INSERT ##Gates(Gate, Input1, Output)
SELECT 'SET', LEFT(Line, CHARINDEX(' ', Line) - 1), SUBSTRING(Line, CHARINDEX('->', Line) + 3, LEN(Line)) FROM ##Input WHERE Line NOT LIKE '%AND%' AND Line NOT LIKE '%OR%' AND Line NOT LIKE '%NOT%' AND Line NOT LIKE '%LSHIFT%' AND Line NOT LIKE '%RSHIFT%' 

INSERT ##Gates(Gate, Input1, Input2, Output)
SELECT 'AND', LEFT(Line, CHARINDEX(' ', Line) - 1), SUBSTRING(Line, CHARINDEX('AND', Line) + 3, LEN(Line) - CHARINDEX('->', Line)), SUBSTRING(Line, CHARINDEX('->', Line) + 3, LEN(Line)) FROM ##Input WHERE Line LIKE '%AND%' 

INSERT ##Gates(Gate, Input1, Input2, Output)
SELECT 'OR', LEFT(Line, CHARINDEX(' ', Line) - 1), SUBSTRING(Line, CHARINDEX('OR', Line) + 2, LEN(Line) - CHARINDEX('->', Line)), SUBSTRING(Line, CHARINDEX('->', Line) + 3, LEN(Line)) FROM ##Input WHERE Line LIKE '%OR%' 

INSERT ##Gates(Gate, Input1, Input2, Output)
SELECT 'LSHIFT', LEFT(Line, CHARINDEX(' ', Line) - 1), SUBSTRING(Line, CHARINDEX('LSHIFT', Line) + 6, LEN(Line) - CHARINDEX('->', Line) - 1), SUBSTRING(Line, CHARINDEX('->', Line) + 3, LEN(Line)) FROM ##Input WHERE Line LIKE '%LSHIFT%' 
UNION 
SELECT 'RSHIFT', LEFT(Line, CHARINDEX(' ', Line) - 1), SUBSTRING(Line, CHARINDEX('RSHIFT', Line) + 6, LEN(Line) - CHARINDEX('->', Line) - 1), SUBSTRING(Line, CHARINDEX('->', Line) + 3, LEN(Line)) FROM ##Input WHERE Line LIKE '%RSHIFT%' 

INSERT ##Gates(Gate, Input1, Output)
SELECT 'NOT', SUBSTRING(Line, CHARINDEX('NOT', Line) + 3, LEN(Line) - CHARINDEX('->', Line)), SUBSTRING(Line, CHARINDEX('->', Line) + 3, LEN(Line)) FROM ##Input WHERE Line LIKE '%NOT%' 


UPDATE ##Gates
SET Input1 = LTRIM(RTRIM(Input1))
,   Input2 = LTRIM(RTRIM(Input2))
,   Output = LTRIM(RTRIM(Output))


CREATE TABLE ##Outputs (ID INT IDENTITY(1,1), Name VARCHAR(5), Value INT)

INSERT ##Outputs (Name) 
SELECT DISTINCT Output FROM ##Gates

UPDATE O 
SET Value = Input1
FROM ##Outputs O
INNER JOIN ##Gates G ON O.Name = G.Output
WHERE G.Gate = 'SET' AND G.Output <> 'a'

--For part 2
UPDATE ##Outputs SET Value = 3176 WHERE Name = 'b'


WHILE NOT EXISTS (SELECT Value FROM ##Outputs WHERE Name = 'lx' AND Value IS NOT NULL)
BEGIN

  --SELECT * FROM ##Gates
  --SELECT * FROM ##Outputs ORDER BY Value

    ;WITH cte_Update AS (
        SELECT G.Gate, ISNULL(CAST(O1.Value AS VARCHAR(15)), G.Input1) AS I1, ISNULL(CAST(O2.Value AS VARCHAR(15)), G.Input2) AS I2, G.Output 
        FROM ##Gates G
            LEFT JOIN ##Outputs O1 ON G.Input1 = O1.Name
            LEFT JOIN ##Outputs O2 ON G.Input2 = O2.Name
            INNER JOIN ##Outputs O3 ON G.Output = O3.Name
        WHERE O3.Value IS NULL
            AND TRY_CAST(ISNULL(CAST(O1.Value AS VARCHAR(15)), G.Input1) AS INT) IS NOT NULL
            AND (TRY_CAST(ISNULL(CAST(O2.Value AS VARCHAR(15)), G.Input2) AS INT) IS NOT NULL OR Gate = 'NOT')
    )
    UPDATE O
    SET O.Value = CASE WHEN T.Gate = 'AND' THEN CAST(T.I1 AS INT) & CAST(T.I2 AS INT)
                       WHEN T.Gate = 'OR' THEN CAST(T.I1 AS INT) | CAST(T.I2 AS INT)
                       WHEN T.Gate = 'NOT' THEN ~CAST(T.I1 AS INT)
                       WHEN T.Gate = 'LSHIFT' THEN dbo.BinaryStringToInt(SUBSTRING(dbo.ToBinaryString(CAST(T.I1 AS INT)), CAST(T.I2 AS INT) + 1, 32) + LEFT(dbo.ToBinaryString(CAST(T.I1 AS INT)), CAST(T.I2 AS INT)))
                       WHEN T.Gate = 'RSHIFT' THEN dbo.BinaryStringToInt(SUBSTRING(dbo.ToBinaryString(CAST(T.I1 AS INT)), 32 - CAST(T.I2 AS INT) + 1, 32) + LEFT(dbo.ToBinaryString(CAST(T.I1 AS INT)), 32 - CAST(T.I2 AS INT)))
           END
    FROM ##Outputs O
    INNER JOIN cte_Update T ON O.Name = T.Output


--00000000000000001010110110001110
--00000000000000000101011011000111
--00000000000000010101101100011100
END

UPDATE O 
SET Value = O2.Value
FROM ##Outputs O
INNER JOIN ##Gates G ON O.Name = G.Output
INNER JOIN ##Outputs O2 ON G.Input1 = O2.Name
WHERE G.Gate = 'SET' AND G.Output = 'a'

SELECT * FROM ##Outputs

/*

DROP TABLE ##Outputs
DROP TABLE ##Gates
DROP TABLE ##Input

*/


--3176 is correct for part 1
--14710 is correct for part 2


/*


CREATE FUNCTION ToBinaryString
      /**
summary:  >
 Converts any type of integer that can be implicitly 
 converted to a bigint into a binary string (e.g. 3 = 11)
Author: Phil Factor
Revision: 1.0
date: 20 May 2013
example:
code: |
  Select dbo.ToBinaryString (CAST(0xFF AS tinyint))--11111111
  Select dbo.ToBinaryString (8045)--1111101101101
  Select dbo.ToBinaryString (0xFFFF)
  Select dbo.ToBinaryString (0xAFDC1111)
returns:  >
 The number as a binary string
**/
  (
    @InputInteger VARBINARY(8)
  )
RETURNS VARCHAR(70)
      AS
  BEGIN
  DECLARE @representation VARCHAR(70);
  SELECT @Representation=
        REPLACE(
          REPLACE(
            CONVERT(VARCHAR(64), @InputInteger, 2), --convert to HEX
        '0','0000'),
      '1','0001'); --you need to do 0 and 1 first, and separately. 
    --before 2008, one had to use this to get the hex conversion...
    --select cast('' as xml).value('xs:hexBinary(sql:variable("@InputInteger") )', 'varchar(64)');
  SELECT @Representation=
        REPLACE(@Representation,HexDigit,BinaryDigits)
    FROM (
      VALUES('2','0010'), ('3','0011'),('4','0100'),('5','0101'),('6','0110'),
      ('7','0111'),('8','1000'), ('9','1001'),('A','1010'),('B','1011'),
      ('C','1100'),('D','1101'),('E','1110'),('F','1111'))f(HexDigit,BinaryDigits);
        /* this simply replaces the ASCII HEX notation with its ASCII binary equivalent. I haven't performance-tested it to see if it is quicker or slower than the maths technique, but it is more like SQL! */
  RETURN @Representation;
  END


*/

/*


CREATE FUNCTION BinaryStringToInt
      /**
summary:  >
 Converts a string that is a binary number into a bigint (e.g. 3 = '11')
Author: Phil Factor
Revision: 1.0
date: 24 May 2013
example:
code: |
  Select dbo.BinaryStringToInt('10101010') 
  Select dbo.BinaryStringToInt('1110'+'1111') 
returns:  >
 the binary string as an integer
**/
  (
    @InputBinaryString VARCHAR(2000)
  )
RETURNS bigint
      AS
  BEGIN
  DECLARE @ii INT, @len INT,@Output Bigint,
    @length INT, @Negative bit,@CurrentBit INT;
  SELECT @InputBinaryString=REPLACE(@InputBinaryString,' ','');
    --remove any extra spaces
  SELECT @Len=LEN(@InputBinaryString), @Output=0,@ii=1
    --determine what sort of value it is
  SELECT @length=CASE
          WHEN @len=1 THEN 2000 --no two's complement
          WHEN @len<=8 THEN 2000 --no two's complement
          WHEN @len<=16 THEN 16 -- -2^15 (-32,768) to 2^15-1 (32,767)
          WHEN @len<=32 THEN 32 -- -2^31 (-2,147,483,648) to 2^31-1 (2,147,483,647)
          WHEN @len<=64 THEN 64 -- -2^63 (-9,223,372,036,854,775,808) to 2^63-1 
    ELSE 2000 END; --no two's complement
    --checkk to see if we have to do twos complement maths on it.
  IF (@Len=@Length 
        AND @length IN (16,32,64))
    IF SUBSTRING(@InputBinaryString,@ii,1)='1'
    SELECT @Negative=1; --flag that we need to 'twos complement' 
  IF (@InputBinaryString NOT LIKE '%[^01]%')--check for errors
    BEGIN --doing repeated multiplication to do the conversion
    WHILE(@ii <= @len 
          AND @@Error=0) 
      BEGIN
      SELECT @currentBit=CAST(SUBSTRING(@InputBinaryString,@ii,1) AS INT);
      IF @negative<>0 
        SELECT @CurrentBit= CASE @CurrentBit WHEN 0 THEN 1 
        ELSE 0 END;
      SELECT @Output = (@output*2)+@CurrentBit;
      SELECT @ii = @ii + 1;
      END
    IF @negative<>0 
      SELECT @Output = -(@Output+1); --twos complement 
    END
  ELSE
  SELECT @Output=NULL; --unknown or error
  RETURN @output;
  END


*/