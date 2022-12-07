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
            SET @CurrentPath = REVERSE(SUBSTRING(REVERSE(@CurrentPath), CHARINDEX('|',REVERSE(@CurrentPath)) + 1, LEN(@CurrentPath)))
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
                ELSE
                    IF @Instr LIKE 'dir %' INSERT ##Disk (Filepath, Fname, Size) SELECT @CurrentPath + '|' + REPLACE(@Instr, 'dir ', ''), REPLACE(@Instr, 'dir ', ''), 0
                    ELSE
                        PRINT @Instr

    SET @Counter = @Counter + 1

  END


SELECT * FROM ##Disk ORDER BY FilePath

;WITH cte_Folders AS (
    SELECT FilePath
    ,      SUM(Size) AS Size
    ,      1 AS Lvl 
    FROM ##Disk GROuP BY FilePath

    UNION ALL

    SELECT REVERSE(SUBSTRING(REVERSE(Filepath), CHARINDEX('|',REVERSE(Filepath)) + 1, LEN(Filepath)))
    ,      Size
    ,      Lvl + 1
    FROM cte_Folders
    WHERE Filepath LIKE '%|%'
)
SELECT Filepath, SUM(Size) AS TotalSize
FROM cte_Folders
GROUP BY Filepath
HAVING SUM(Size) < 100000
ORDER BY 2


;WITH cte_Folders AS (
    SELECT FilePath
    ,      SUM(Size) AS Size
    ,      1 AS Lvl 
    FROM ##Disk GROuP BY FilePath

    UNION ALL

    SELECT REVERSE(SUBSTRING(REVERSE(Filepath), CHARINDEX('|',REVERSE(Filepath)) + 1, LEN(Filepath)))
    ,      Size
    ,      Lvl + 1
    FROM cte_Folders
    WHERE Filepath LIKE '%|%'
)
SELECT Filepath, SUM(Size) AS TotalSize
FROM cte_Folders
GROUP BY Filepath
HAVING SUM(Size) >= 30000000 + 48044502 - 70000000
ORDER BY 2

 --DROP TABLE ##Disk


  /*

  DECLARE @Folders TABLE (ID INT IDENTITY(1,1), Folder VARCHAR(MAX), Size bigint)

  /* declare variables */
  DECLARE @Path VARCHAR(MAX)
  DECLARE @Size BIGiNt
  
  DECLARE folderCursor CURSOR FAST_FORWARD READ_ONLY FOR SELECT D.Filepath, D.Size FROM @Disk D
  
  OPEN folderCursor
  
  FETCH NEXT FROM folderCursor INTO @Path,@Size
  
  WHILE @@FETCH_STATUS = 0
  BEGIN
      
      INSERT @Folders(Folder, Size)
      SELECT value, @Size FROM STRING_SPLIT(@Path,'|') SS
  
      FETCH NEXT FROM folderCursor INTO @Path,@Size
  END
  
  CLOSE folderCursor
  DEALLOCATE folderCursor

  SELECT * FROM @Folders F
   
  SELECT Folder, SUM(Size) AS Size FROM @Folders F GROUP BY F.Folder ORDER BY 2
  SELECT Folder, SUM(Size) AS Size FROM @Folders F GROUP BY F.Folder ORDER BY 1
  --Too Low

  --SELECT 15229 + 18543 + 25094 + 34310 + 36358 + 43395 + 48696 + 58678 + 59244 + 66475 + 73557 + 85871 + 90049 + 94716 + 98744 + 98803

  -- Too Low
  --SELECT 12772 + 12772 + 15229 + 18543 + 25094 + 34310 + 34417 + 36358 + 43395 + 48696 + 58678 + 59244 + 66475 + 73557 + 85871 + 85871 + 90049 + 98744 + 98744 + 98803



SELECT * FROM @Disk D 
INNer JOIN @Disk D2 ON D.FName = D2.Fname AND D.Filepath <> D2.Filepath

*/