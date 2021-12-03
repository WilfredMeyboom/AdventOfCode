USE Test_WME

DECLARE @year VARCHAR(4) = '2021'
DECLARE @day VARCHAR(2)  = '3'

EXEC dbo.GetInput @year = @year, @day = @day
EXEC dbo.ParseInput @year = @year, @day = @day 

SELECT TOP 10 * FROM ##InputNumbered
SELECT TOP 10 * FROM ##InputGrid
SELECT TOP 10 * FROM ##InputInts
SELECT TOP 10 * FROM ##InputParsed


SELECT ColNr, Val, COUNT(1)  FROM ##InputGrid GROUP BY ColNr, Val
ORDER BY ColNr, 3

/*
ColNr	Val	(No column name)
0	1	511
1	0	502
2	0	510
3	1	520
4	0	530
5	0	517
6	1	503
7	0	513
8	1	524
9	0	509
10	1	504
11	0	508

100100101010
011011010101
--1173
*/

SELECT 2346 * 1749



SELECT *
FROM ##Input
WHERE Line LIKE '11010100011%'

SELECT SUBSTRING(Line, 12, 1), COUNT(1)
FROM ##Input
WHERE Line LIKE '11010100011%'
GROUP BY SUBSTRING(Line,12, 1)

--110101000111 -- 3399


SELECT *
FROM ##Input
WHERE Line LIKE '010011100%'

SELECT SUBSTRING(Line, 9, 1), COUNT(1)
FROM ##Input
WHERE Line LIKE '010011100%'
GROUP BY SUBSTRING(Line, 9, 1)

--010011100001 -- 1249

SELECT 3399 * 1249