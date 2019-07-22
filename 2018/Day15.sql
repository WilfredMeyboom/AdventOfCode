use Test_WME

SET NOCOUNT ON

CREATE TABLE ##Input (Name NVARCHAR(MAX));

BULK INSERT ##Input
FROM 'D:\Wilfred\AdventOfCode\input15.txt'
WITH (ROWTERMINATOR = '0x0A');


--SELECT * FROM ##Input

CREATE TABLE ##Cave (ID INT IDENTITY(1,1), X INT, Y INT, CaveSpace CHAR(1))

;WITH cte_Cave AS (
    SELECT LEFT(Name, 1) AS CaveSpace
    ,      SUBSTRING(Name, 2, LEN(Name)) AS Remainder
    ,      ROW_NUMBER() OVER (ORDER BY (SELECT 0)) - 1 AS Y
    ,      0 AS X
    FROM ##Input
    UNION ALL
    SELECT LEFT(Remainder, 1)
    ,      SUBSTRING(Remainder, 2, LEN(Remainder))
    ,      Y
    ,      X + 1
    FROM cte_Cave
    WHERE LEN(Remainder) > 0
)
INSERT ##Cave (X, Y, CaveSpace)
SELECT X 
,      Y
,      CaveSpace
FROM cte_Cave
--OPTION (MAXRECURSION 25000)

--SELECT * FROM ##Cave

CREATE TABLE ##Creatures (ID INT IDENTITY(1,1) PRIMARY KEY, Creature CHAR(1), X INT, Y INT, Health INT)

INSERT ##Creatures (Creature, X, Y, Health)
SELECT CaveSpace, x, y, 200
FROM ##Cave
WHERE CaveSpace IN ('G', 'E')

UPDATE ##Cave
SET CaveSpace = '.'
WHERE CaveSpace IN ('G','E')


DELETE FROM ##Cave WHERE CaveSpace = '#'

--SELECT * FROM ##Creatures
-----------------------------------------------------------

CREATE TABLE ##Distances (X INT, Y INT, Distance INT, MoveX INT, MoveY INT)
CREATE TABLE ##TargetSpaces (X INT, Y INT)

DECLARE @FightOver INT = 2
DECLARE @CurrentCreature INT
DECLARE @CurrentX INT
DECLARE @CurrentY INT
DECLARE @CurrentType CHAR(1)
DECLARE @MoveX INT
DECLARE @MoveY INT
DECLARE @TargetID INT
DECLARE @Distance INT
DECLARE @Health INT
DECLARE @RoundCounter INT = 0
DECLARE @PowerElf INT = 25
-- Power 12 Round 28 Elf Dies
-- Power 50 Round 20 Elfs Win
-- Power 31 Round 31 Elfs Win
-- Power 21 Round 30 Elf Dies
-- Power 26 Round 35 Elfs Win
-- Power 24 Round 31 Elf Dies
-- Power 25 Round 35 Elfs Win
--DECLARE @LastAttack BIT = 0
DECLARE @StartingNrOfElfs INT

SELECT @StartingNrOfElfs = COUNT(1) FROM ##Creatures WHERE Creature = 'E'

WHILE (@FightOver > 1 AND @RoundCounter < 500)
BEGIN
    
--    PRINT 'Start round: ' + CAST(DATEDIFF(MILLISECOND, '20181220', GETDATE()) AS VARCHAR(20))

    DECLARE CreatureCursor CURSOR FOR
    SELECT ID FROM ##Creatures ORDER BY Y, X

    OPEN CreatureCursor
    FETCH NEXT FROM CreatureCursor INTO @CurrentCreature

    SET @RoundCounter = @RoundCounter + 1

    WHILE @@FETCH_STATUS = 0
    BEGIN

--        PRINT 'Start creature turn: ' + CAST(DATEDIFF(MILLISECOND, '20181220', GETDATE()) AS VARCHAR(20))

        SET @MoveX = NULL
        SET @MoveY = NULL
        SET @Distance = NULL

        SELECT @CurrentType = Creature
        ,      @CurrentX = X
        ,      @CurrentY = Y
        ,      @Health = Health
        FROM ##Creatures
        WHERE ID = @CurrentCreature

        --PRINT @CurrentCreature

--        PRINT 'Get creature details: ' + CAST(DATEDIFF(MILLISECOND, '20181220', GETDATE()) AS VARCHAR(20))

        IF @Health > 0
        BEGIN

--            PRINT 'Build distances table: ' + CAST(DATEDIFF(MILLISECOND, '20181220', GETDATE()) AS VARCHAR(20))

            TRUNCATE TABLE ##TargetSpaces

            INSERT ##TargetSpaces (X, Y)
            SELECT C.X, C.Y
            FROM ##Cave C
            INNER JOIN ##Creatures Cr ON Cr.Creature <> @CurrentType
                                     AND ((ABS(Cr.X - C.X) = 1 AND Cr.Y = C.Y) OR (Cr.X = C.X AND ABS(Cr.Y - C.Y) = 1)) 
                                     AND Cr.Health > 0

            TRUNCATE TABLE ##Distances

            INSERT ##Distances VALUES (@CurrentX, @CurrentY, 0, NULL, NULL)

            WHILE (NOT EXISTS (SELECT 1 FROM ##Distances D INNER JOIN ##TargetSpaces TS ON D.X = TS.X AND D.Y = TS.Y)) AND @@ROWCOUNT > 0
            BEGIN

                INSERT ##Distances (X, Y, Distance, MoveX, MoveY)
                SELECT DISTINCT C.X, C.Y, D.Distance + 1, ISNULL(D.MoveX, C.X), ISNULL(D.MoveY, C.Y)
                FROM ##Distances D
                INNER JOIN ##Cave C ON (D.X = C.X AND ABS(D.Y - C.Y) = 1) OR (ABS(D.X - C.X) = 1 AND D.Y = C.Y)
                LEFT JOIN ##Distances D_Done ON D_Done.X = C.X AND D_Done.Y = C.Y
                LEFT JOIN ##Creatures Cr ON Cr.X = C.X AND Cr.Y = C.Y AND Cr.ID <> @CurrentCreature AND Cr.Health > 0
                WHERE D_Done.Distance IS NULL AND Cr.Creature IS NULL

            END

--            PRINT 'Choose closest target: ' + CAST(DATEDIFF(MILLISECOND, '20181220', GETDATE()) AS VARCHAR(20))

            SELECT TOP (1) 
                   @MoveX = D.MoveX
            ,      @MoveY = D.MoveY
            ,      @Distance = D.Distance
            FROM ##Distances D
            INNER JOIN ##Creatures Cr ON Cr.ID <> @CurrentCreature
                                    AND Cr.Creature <> @CurrentType
                                    AND ((ABS(Cr.X - D.X) = 1 AND Cr.Y = D.Y) OR (Cr.X = D.X AND ABS(Cr.Y - D.Y) = 1)) 
                                    AND Cr.Health > 0
            ORDER BY Distance, D.Y, D.X, D.MoveY, D.MoveX

--            PRINT 'Move: ' + CAST(DATEDIFF(MILLISECOND, '20181220', GETDATE()) AS VARCHAR(20))

            IF @Distance >= 1
            BEGIN
                UPDATE ##Creatures
                SET X = ISNULL(@MoveX, X)
                ,   Y = ISNULL(@MoveY, Y)
                ,   @Distance = @Distance - 1
                WHERE ID = @CurrentCreature

                --PRINT 'Creature: ' + CAST(@CurrentCreature AS VARCHAR(2)) + ISNULL(' moved from ' + CAST(@CurrentX AS VARCHAR(2)) + ',' + CAST(@CurrentY AS VARCHAR(2)) + ' moved to ' + CAST(@MoveX AS VARCHAR(2)) + ',' + CAST(@MoveY AS VARCHAR(2)), ' did not move')
            END

--            PRINT 'Attack: ' + CAST(DATEDIFF(MILLISECOND, '20181220', GETDATE()) AS VARCHAR(20))

            IF @Distance < 1
            BEGIN
                SET @TargetID = NULL

--                PRINT 'Choose target: ' + CAST(DATEDIFF(MILLISECOND, '20181220', GETDATE()) AS VARCHAR(20))

                SELECT TOP(1)
                       @TargetID = tar.ID
                FROM ##Creatures cur
                INNER JOIN ##Creatures tar ON tar.ID <> @CurrentCreature
                                    AND tar.Creature <> @CurrentType
                                    AND ((ABS(cur.X - tar.X) = 1 AND cur.Y = tar.Y) OR (cur.X = tar.X AND ABS(cur.Y - tar.Y) = 1))
                                    AND tar.Health > 0
                WHERE cur.ID = @CurrentCreature
                ORDER BY tar.Health, tar.Y, tar.X

                --PRINT 'Creature ' + CAST(@CurrentCreature AS VARCHAR(2)) + ' hit creature ' + CAST(@TargetID AS VARCHAR(2))

--                PRINT 'Hit target: ' + CAST(DATEDIFF(MILLISECOND, '20181220', GETDATE()) AS VARCHAR(20))

                UPDATE ##Creatures
                SET Health = Health - CASE WHEN @CurrentType = 'E' THEN @PowerElf ELSE 3 END
                WHERE ID = @TargetID

                --SELECT * FROM ##Creatures WHERE ID = @TargetID

--                SET @LastAttack = 1
            END


--            PRINT 'End of creature turn: ' + CAST(DATEDIFF(MILLISECOND, '20181220', GETDATE()) AS VARCHAR(20))
--            IF (@TargetID IS NULL) SET @LastAttack = 0

        END

        FETCH NEXT FROM CreatureCursor INTO @CurrentCreature
    END

    CLOSE CreatureCursor
    DEALLOCATE CreatureCursor

--    PRINT 'End of round: ' + CAST(DATEDIFF(MILLISECOND, '20181220', GETDATE()) AS VARCHAR(20))

    PRINT 'End of round ' + CAST(@RoundCounter AS VARCHAR(10)) + '. Time is ' + CAST(GETDATE() AS VARCHAR(20))

    --SELECT * FROM ##Creatures

--    PRINT 'Check for deaths: ' + CAST(DATEDIFF(MILLISECOND, '20181220', GETDATE()) AS VARCHAR(20))

    IF (SELECT COUNT(1) FROM ##Creatures WHERE Health <= 0) > 0
    BEGIN

        DELETE FROM ##Creatures
        WHERE Health <= 0

--        PRINT CAST(@@ROWCOUNT AS NVARCHAR(2)) + ' creature(s) dies'
    END

--    PRINT 'Check for survivors: ' + CAST(DATEDIFF(MILLISECOND, '20181220', GETDATE()) AS VARCHAR(20))

    ;WITH cte_CreatureCount AS (
        SELECT Creature
        FROM ##Creatures
        GROUP BY Creature
    )
    SELECT @FightOver = COUNT(1) FROM cte_CreatureCount

--    PRINT 'Check for elf death: ' + CAST(DATEDIFF(MILLISECOND, '20181220', GETDATE()) AS VARCHAR(20))

    IF (SELECT COUNT(1) FROM ##Creatures WHERE Creature = 'E') < @StartingNrOfElfs
    BEGIN

        PRINT 'AN ELF HAS DIED!'

        SET @FightOver = 1

    END

--    PRINT 'Real end of round: ' + CAST(DATEDIFF(MILLISECOND, '20181220', GETDATE()) AS VARCHAR(20))

END



--SELECT CASE WHEN @LastAttack = 1 THEN (@RoundCounter) 
--                                 ELSE (@RoundCounter -1) 
--                                 END
--            * SUM(Health) 
--    ,   @LastAttack
--    ,   @RoundCounter
--    ,   SUM(Health)
--    FROM ##Creatures
--SELECT 80*SUM(Health) FROM ##Creatures

--217013 Too low
--219760 Too low
--239670 Too low (239670	0	91	2663) Eigenlijk 90
--242333 Ook fout en nou zegt die niet meer of het te hoog of te laag is

--SELECT * FROM ##Creatures
--SELECT * FROM ##Distances


/*


DROP TABLE ##Distances
DROP TABLE ##TargetSpaces
DROP TABLE ##Cave
DROP TABLE ##Creatures
DROP TABLE ##Input


*/


PRINT ''



/*

End of round 1. Time is Dec 19 2018  1:31PM
End of round 2. Time is Dec 19 2018  1:33PM
End of round 3. Time is Dec 19 2018  1:34PM
End of round 4. Time is Dec 19 2018  1:34PM
End of round 5. Time is Dec 19 2018  1:36PM
End of round 6. Time is Dec 19 2018  1:39PM
End of round 7. Time is Dec 19 2018  1:41PM
End of round 8. Time is Dec 19 2018  1:43PM
End of round 9. Time is Dec 19 2018  1:45PM
End of round 10. Time is Dec 19 2018  1:47PM
End of round 11. Time is Dec 19 2018  1:50PM
End of round 12. Time is Dec 19 2018  1:52PM
End of round 13. Time is Dec 19 2018  1:54PM
End of round 14. Time is Dec 19 2018  1:56PM
End of round 15. Time is Dec 19 2018  1:58PM
End of round 16. Time is Dec 19 2018  2:00PM
End of round 17. Time is Dec 19 2018  2:03PM
End of round 18. Time is Dec 19 2018  2:04PM
End of round 19. Time is Dec 19 2018  2:06PM
End of round 20. Time is Dec 19 2018  2:08PM
End of round 21. Time is Dec 19 2018  2:11PM
End of round 22. Time is Dec 19 2018  2:12PM
End of round 23. Time is Dec 19 2018  2:14PM
End of round 24. Time is Dec 19 2018  2:17PM
End of round 25. Time is Dec 19 2018  2:19PM
2 creature(s) die
End of round 26. Time is Dec 19 2018  2:21PM
End of round 27. Time is Dec 19 2018  2:22PM
End of round 28. Time is Dec 19 2018  2:23PM
1 creature(s) die
End of round 29. Time is Dec 19 2018  2:23PM
2 creature(s) die
End of round 30. Time is Dec 19 2018  2:23PM
End of round 31. Time is Dec 19 2018  2:24PM
End of round 32. Time is Dec 19 2018  2:24PM
End of round 33. Time is Dec 19 2018  2:25PM
End of round 34. Time is Dec 19 2018  2:25PM
End of round 35. Time is Dec 19 2018  2:26PM
End of round 36. Time is Dec 19 2018  2:26PM
End of round 37. Time is Dec 19 2018  2:26PM
End of round 38. Time is Dec 19 2018  2:28PM
End of round 39. Time is Dec 19 2018  2:29PM
End of round 40. Time is Dec 19 2018  2:30PM
End of round 41. Time is Dec 19 2018  2:32PM
End of round 42. Time is Dec 19 2018  2:33PM
1 creature(s) die
End of round 43. Time is Dec 19 2018  2:34PM
End of round 44. Time is Dec 19 2018  2:36PM
End of round 45. Time is Dec 19 2018  2:37PM
End of round 46. Time is Dec 19 2018  2:37PM
End of round 47. Time is Dec 19 2018  2:37PM
End of round 48. Time is Dec 19 2018  2:38PM
1 creature(s) die
End of round 49. Time is Dec 19 2018  2:39PM
End of round 50. Time is Dec 19 2018  2:39PM
End of round 51. Time is Dec 19 2018  2:40PM
End of round 52. Time is Dec 19 2018  2:41PM
End of round 53. Time is Dec 19 2018  2:43PM
End of round 54. Time is Dec 19 2018  2:44PM
End of round 55. Time is Dec 19 2018  2:45PM
End of round 56. Time is Dec 19 2018  2:46PM
End of round 57. Time is Dec 19 2018  2:47PM
End of round 58. Time is Dec 19 2018  2:48PM
1 creature(s) die
End of round 59. Time is Dec 19 2018  2:49PM
End of round 60. Time is Dec 19 2018  2:50PM
End of round 61. Time is Dec 19 2018  2:51PM
End of round 62. Time is Dec 19 2018  2:52PM
End of round 63. Time is Dec 19 2018  2:53PM
1 creature(s) die
End of round 64. Time is Dec 19 2018  2:54PM
1 creature(s) die
End of round 65. Time is Dec 19 2018  2:56PM
End of round 66. Time is Dec 19 2018  2:57PM
End of round 67. Time is Dec 19 2018  2:58PM
End of round 68. Time is Dec 19 2018  2:58PM
End of round 69. Time is Dec 19 2018  2:58PM
End of round 70. Time is Dec 19 2018  2:59PM
End of round 71. Time is Dec 19 2018  2:59PM
End of round 72. Time is Dec 19 2018  3:00PM
1 creature(s) die
End of round 73. Time is Dec 19 2018  3:00PM
End of round 74. Time is Dec 19 2018  3:00PM
End of round 75. Time is Dec 19 2018  3:01PM
End of round 76. Time is Dec 19 2018  3:01PM
End of round 77. Time is Dec 19 2018  3:01PM
End of round 78. Time is Dec 19 2018  3:01PM
End of round 79. Time is Dec 19 2018  3:02PM
1 creature(s) die
End of round 80. Time is Dec 19 2018  3:03PM
End of round 81. Time is Dec 19 2018  3:04PM
End of round 82. Time is Dec 19 2018  3:06PM
End of round 83. Time is Dec 19 2018  3:06PM
1 creature(s) die
End of round 84. Time is Dec 19 2018  3:06PM
End of round 85. Time is Dec 19 2018  3:07PM
End of round 86. Time is Dec 19 2018  3:08PM
End of round 87. Time is Dec 19 2018  3:09PM
End of round 88. Time is Dec 19 2018  3:10PM
End of round 89. Time is Dec 19 2018  3:11PM
End of round 90. Time is Dec 19 2018  3:11PM
End of round 91. Time is Dec 19 2018  3:12PM
1 creature(s) die


*/


/*

End of round 1. Time is Dec 20 2018 12:14PM
End of round 2. Time is Dec 20 2018 12:14PM
End of round 3. Time is Dec 20 2018 12:14PM
End of round 4. Time is Dec 20 2018 12:14PM
End of round 5. Time is Dec 20 2018 12:14PM
End of round 6. Time is Dec 20 2018 12:14PM
End of round 7. Time is Dec 20 2018 12:14PM
End of round 8. Time is Dec 20 2018 12:14PM
End of round 9. Time is Dec 20 2018 12:14PM
End of round 10. Time is Dec 20 2018 12:14PM
End of round 11. Time is Dec 20 2018 12:14PM
End of round 12. Time is Dec 20 2018 12:14PM
End of round 13. Time is Dec 20 2018 12:14PM
End of round 14. Time is Dec 20 2018 12:14PM
End of round 15. Time is Dec 20 2018 12:14PM
End of round 16. Time is Dec 20 2018 12:14PM
End of round 17. Time is Dec 20 2018 12:14PM
End of round 18. Time is Dec 20 2018 12:14PM
End of round 19. Time is Dec 20 2018 12:14PM
End of round 20. Time is Dec 20 2018 12:14PM
End of round 21. Time is Dec 20 2018 12:14PM
End of round 22. Time is Dec 20 2018 12:14PM
End of round 23. Time is Dec 20 2018 12:14PM
End of round 24. Time is Dec 20 2018 12:14PM
End of round 25. Time is Dec 20 2018 12:15PM
End of round 26. Time is Dec 20 2018 12:15PM
End of round 27. Time is Dec 20 2018 12:15PM
End of round 28. Time is Dec 20 2018 12:15PM
End of round 29. Time is Dec 20 2018 12:15PM
End of round 30. Time is Dec 20 2018 12:15PM
End of round 31. Time is Dec 20 2018 12:15PM
End of round 32. Time is Dec 20 2018 12:15PM
End of round 33. Time is Dec 20 2018 12:15PM
End of round 34. Time is Dec 20 2018 12:16PM
End of round 35. Time is Dec 20 2018 12:16PM
 



##Creatures
4	E	6	25	20
8	E	12	20	44
24	E	22	13	101
9	E	11	21	104
15	E	16	11	143
12	E	16	9	164
13	E	11	12	200
1	E	12	21	200
2	E	20	19	200
3	E	20	9	200

SELECT 1376 * 34
== 46784

*/