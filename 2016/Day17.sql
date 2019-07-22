SET NOCOUNT ON

--DECLARE @Input VARCHAR(10) = 'ihgpwlah' --DDRRRD  --> Max 370 steps
--DECLARE @Input VARCHAR(10) = 'kglvqrro' --DDUDRLRRUDRD --> Max 492 steps
--DECLARE @Input VARCHAR(10) = 'ulqzkmiv' --DRURDRUDDLLDLUURRDULRLDUUDDDRR  --> 830 steps
DECLARE @Input VARCHAR(10) = 'vkjiggvb'

--SELECT LEFT(CONVERT(VARCHAR(32), HASHBYTES('MD5', 'abc22728'), 2), 4)


CREATE TABLE ##Routes (ID INT IDENTITY(1,1), LocationX INT, LocationY INT, Hash4 VARCHAR(4), CurrentRoute VARCHAR(MAX))
CREATE TABLE ##NewRoutes (ID INT IDENTITY(1,1), LocationX INT, LocationY INT, Hash4 VARCHAR(4), CurrentRoute VARCHAR(MAX))

INSERT ##Routes (LocationX, LocationY, Hash4, CurrentRoute) SELECT 1, 1, LEFT(CONVERT(VARCHAR(32), HASHBYTES('MD5', @Input), 2), 4), ''

CREATE TABLE ##LongestRoute (CurrentRoute VARCHAR(MAX))

--WHILE NOT EXISTS (SELECT 1 FROM ##Routes WHERE LocationX = 4 AND LocationY = 4)
WHILE (SELECT COUNT(1) FROM ##Routes) > (SELECT COUNT(1) FROM ##Routes WHERE LocationX = 4 AND LocationY = 4)
BEGIN

    IF EXISTS (SELECT 1 FROM ##Routes WHERE LocationX = 4 AND LocationY = 4) --New for part 2
    BEGIN
        
        DELETE FROM ##LongestRoute

        INSERT ##LongestRoute SELECT CurrentRoute FROM ##Routes WHERE LocationX = 4 AND LocationY = 4

        DELETE FROM ##Routes WHERE LocationX = 4 AND LocationY = 4 

    END


    INSERT ##NewRoutes (LocationX, LocationY, Hash4, CurrentRoute)
    SELECT R.LocationX + M.X
    ,      R.LocationY + M.Y
    ,      LEFT(CONVERT(VARCHAR(32), HASHBYTES('MD5', @Input + R.CurrentRoute + CASE WHEN M.X =  1 THEN 'R'
                                                                                     WHEN M.X = -1 THEN 'L'
                                                                                     WHEN M.Y =  1 THEN 'D'
                                                                                     WHEN M.Y = -1 THEN 'U'
                                                                                 END )
                       , 2) --Convert
               , 4) --Left
    ,      R.CurrentRoute + CASE WHEN M.X =  1 THEN 'R'
                                 WHEN M.X = -1 THEN 'L'
                                 WHEN M.Y =  1 THEN 'D'
                                 WHEN M.Y = -1 THEN 'U'
                             END 
    FROM ##Routes R
    CROSS APPLY (SELECT 1 AS X, 0 AS Y UNION SELECT 0, 1 UNION SELECT -1, 0 UNION SELECT 0, -1) M
    WHERE R.LocationX + M.X BETWEEN 1 AND 4
      AND R.LocationY + M.Y BETWEEN 1 AND 4 -- Stay inside the grid

      AND (
          (M.Y = -1 AND LEFT(R.Hash4, 1)         IN ('b','c','d','e','f')) OR
          (M.Y =  1 AND SUBSTRING(R.Hash4, 2, 1) IN ('b','c','d','e','f')) OR
          (M.X = -1 AND SUBSTRING(R.Hash4, 3, 1) IN ('b','c','d','e','f')) OR
          (M.X =  1 AND RIGHT(R.Hash4, 1)        IN ('b','c','d','e','f')) 
          )

    DELETE FROM ##Routes

    INSERT ##Routes (LocationX, LocationY, Hash4, CurrentRoute)
    SELECT LocationX, LocationY, Hash4, CurrentRoute FROM ##NewRoutes

    DELETE FROM ##NewRoutes

END


--SELECT * FROM ##NewRoutes

SELECT * FROM ##Routes --WHERE LocationX = 4 AND LocationY = 4
SELECT LEN(CurrentRoute), * FROM ##LongestRoute
/*

DROP TABLE ##Routes
DROP TABLE ##NewRoutes
DROP TABLE ##LongestRoute

*/



