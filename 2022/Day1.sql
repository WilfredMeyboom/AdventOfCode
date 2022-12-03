USE Test_WME

DECLARE @year VARCHAR(4) = '2022'
DECLARE @day VARCHAR(2)  = '1'

EXEC dbo.GetInput @year = @year, @day = @day
EXEC dbo.ParseInput @year = @year, @day = @day 


-- Add a column which has a 0 for integers and a 1 for NULLs. If we keep a running total of this new column we can treat it as the number of the Elf
;WITH cte_ElfNrs AS (
    SELECT SUM(CASE WHEN Line IS NULL THEN 1 ELSE 0 END) OVER (ORDER BY Ind) AS ElfNr, CAST(Line AS INT) AS Cal
    FROM ##InputNumbered
)
SELECT TOP 1 ElfNr, SUM(Cal) AS Part1
FROM cte_ElfNrs
GROUP BY ElfNr
ORDER BY Part1 DESC

-- Since we need the top 3 instead of the top 1 we add a column with a row number (starting with 1 for the highest calorie value and going down). This allows us to filter the highest 3

;WITH cte_ElfNrs AS (
    SELECT SUM(CASE WHEN Line IS NULL THEN 1 ELSE 0 END) OVER (ORDER BY Ind) AS ElfNr, CAST(Line AS INT) AS Cal
    FROM ##InputNumbered
), cte_perElf AS (
    SELECT ElfNr, SUM(Cal) AS TotalCal, ROW_NUMBER() OVER (ORDER BY (SUM(Cal)) DESC) AS RN
    FROM cte_ElfNrs
    GROUP BY ElfNr
)
SELECT SUM(TotalCal) AS Part2
FROM cte_perElf
WHERE RN <= 3