USE [Test_WME]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER PROC [dbo].[GetInput] (@year VARCHAR(4), @day VARCHAR(2))
AS
BEGIN
    DECLARE @sql NVARCHAR(100) = 'dir /b c:\source\adventofcode\' + @year + '\input' + @day + '.txt'
    DECLARE @result TABLE (Line NVARCHAR(512) NULL)
    INSERT INTO @result EXEC xp_cmdshell @sql=@sql

    IF EXISTS (SELECT 1 FROM @Result WHERE Line = 'File Not Found')
    BEGIN

        SET @sql = 'C:\Source\AdventOfCode\AOC_DL year ' + @year + ' day ' + @day + ' output C:\Source\AdventOfCode'
        INSERT INTO @result EXEC xp_cmdshell @sql=@sql

    END
END