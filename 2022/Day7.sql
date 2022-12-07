USE Test_WME

SET NOCOUNT ON

DECLARE @year VARCHAR(4) = '2022'
DECLARE @day VARCHAR(2)  = '7'

EXEC dbo.GetInput @year = @year, @day = @day
EXEC dbo.ParseInput @year = @year, @day = @day 

--SELECT TOP 10 * FROM ##Input
--SELECT TOP 10 * FROM ##InputInts
--SELECT TOP 1000 * FROM ##InputNumbered
--SELECT TOP 10 * FROM ##InputGrid
--SELECT TOP 10 * FROM ##InputSplit
--SELECT TOP 10 * FROM ##InputSplitCust
  
  DECLARE @Counter INT = 1 
  DECLARE @CurrentPath VARCHAR(MAX)
  DECLARE @Instr VARCHAR(MAX)

  CREATE TABLE ##Disk (ID Int IDENTITY(1,1), Filepath VARCHAR(MAX), Fname VARchar(MAX), Size BIGINT)

  WHILE @Counter <= (SELECT MAX(Ind) FROM ##InputNumbered)
  BEGIN
    
    SELECT @Instr = Line FROM ##InputNumbered WHERE Ind = @Counter

    IF @Instr = '$ cd /' SET @CurrentPath = '.'
    ELSE 
        IF @Instr = '$ cd ..' 
        BEGIN
            SET @CurrentPath = REVERSE(SUBSTRING(REVERSE(@CurrentPath), CHARINDEX('|',REVERSE(@CurrentPath)) + 1, LEN(@CurrentPath))) -- Cut off the last part of the path
        END
        ELSE
            IF @Instr LIKE '$ cd %' SET @CurrentPath = @CurrentPath + '|' + REPLACE(@Instr, '$ cd ', '')
            ELSE
                IF TRY_CAST(LEFT(@Instr, 1) AS INT) IS NOT NULL
                BEGIN
                    --PRINT LEFT(@Instr, CHARINDEX(' ', @Instr))

                    INSERT ##Disk
                    (
                        Filepath,
                        Fname,
                        Size
                    )
                    SELECT @CurrentPath
                    ,      SUBSTRING(@Instr, CHARINDEX(' ', @Instr), LEN(@Instr))
                    ,      CAST(LEFT(@Instr, CHARINDEX(' ', @Instr)) AS BIGINT)
                END
                --ELSE
                --    IF @Instr LIKE 'dir %' INSERT ##Disk (Filepath, Fname, Size) SELECT @CurrentPath + '|' + REPLACE(@Instr, 'dir ', ''), REPLACE(@Instr, 'dir ', ''), 0
                --    ELSE
                --        PRINT @Instr

    SET @Counter = @Counter + 1

  END


--SELECT * FROM ##Disk ORDER BY FilePath

;WITH cte_Folders AS (
    SELECT FilePath
    ,      SUM(Size) AS Size
    ,      1 AS Lvl 
    FROM ##Disk GROuP BY FilePath

    UNION ALL

    SELECT REVERSE(SUBSTRING(REVERSE(Filepath), CHARINDEX('|',REVERSE(Filepath)) + 1, LEN(Filepath))) -- Cut off the last folder and add the "new" folder with the size of the "old" folder
    ,      Size
    ,      Lvl + 1
    FROM cte_Folders
    WHERE Filepath LIKE '%|%'
), cte_SizePerFolder AS (
    SELECT SUM(Size) AS Size
    FROM cte_Folders
    GROUP BY Filepath
)
SELECT SUM(Size) AS Part1
FROM cte_SizePerFolder
WHERE Size < 100000


DECLARE @Disksize BIGINT = 70000000
DECLARE @NeededSpace BIGINT = 30000000
DECLARE @UsedSpace BIGINT
DECLARE @MinimumFilesizeToDelete BIGINT

SELECT @UsedSpace = SUM(Size) FROM ##Disk
SET @MinimumFilesizeToDelete = @NeededSpace - (@Disksize - @UsedSpace)  -- What is needed - what is already available

;WITH cte_Folders AS (
    SELECT FilePath
    ,      SUM(Size) AS Size
    ,      1 AS Lvl 
    FROM ##Disk GROuP BY FilePath

    UNION ALL

    SELECT REVERSE(SUBSTRING(REVERSE(Filepath), CHARINDEX('|',REVERSE(Filepath)) + 1, LEN(Filepath)))  -- Cut off the last folder and add the "new" folder with the size of the "old" folder
    ,      Size
    ,      Lvl + 1
    FROM cte_Folders
    WHERE Filepath LIKE '%|%'
)
SELECT TOP(1) SUM(Size) AS Part2
FROM cte_Folders
GROUP BY Filepath
HAVING SUM(Size) >= @MinimumFilesizeToDelete

DROP TABLE ##Disk

