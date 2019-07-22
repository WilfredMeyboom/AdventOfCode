use Test_WME

CREATE TABLE #Input (Name NVARCHAR(MAX));

BULK INSERT #Input
FROM 'D:\Wilfred\AdventOfCode\input7.txt'
WITH (ROWTERMINATOR = '0x0A');

SELECT * FROM #Input


CREATE TABLE #Steps (ID INT IDENTITY(1,1), BeforeStep CHAR, AfterStep CHAR)

INSERT #Steps (BeforeStep, AfterStep)
SELECT SUBSTRING(Name, 6, 1), 
       SUBSTRING(Name, 37, 1)
FROM #Input

;WITH cte_Levels AS (
    SELECT DISTINCT 
           T1.BeforeStep AS Step
    ,      1 AS Level
    FROM #Steps T1
    LEFT JOIN #Steps T2 ON T1.BeforeStep = T2.AfterStep
    WHERE T2.ID IS NULL
    UNION ALL
    SELECT 
        T1.AfterStep
    ,   cL.Level + 1
    FROM cte_Levels cL
    INNER JOIN #Steps T1 ON cL.Step = T1.BeforeStep -- Based on the available steps. What would possible next?
    --INNER JOIN #Steps T2 ON T1.AfterStep = T2.AfterStep -- Are these steps possible? What other things are needed?
    --                    AND cL.Step = T2.BeforeStep
    
)
--SELECT Step, MAX(Level) AS Level FROM cte_Levels GROUP BY Step ORDER BY 2, 1
SELECT * FROM cte_Levels 

--ABLDFMNWCJRVHQITXEKUZOSYPG
--ABLDFMNWCJRVHQITXEKUZOSYPG

SELECT * FROM #Steps


CREATE TABLE #Solution (ID INT IDENTITY(1,1), Letter CHAR)

--INSERT #Solution (Letter) VALUES ('A')
--INSERT #Solution (Letter) VALUES ('B')
--INSERT #Solution (Letter) VALUES ('L')

WHILE ((SELECT COUNT(1) FROM #Solution) < 26)
BEGIN

    ;WITH cte_PossibleNext AS (
        SELECT DISTINCT T2.AfterStep AS Step
        FROM #Solution T1
        INNER JOIN #Steps T2 ON T1.Letter = T2.BeforeStep
        UNION SELECT ('A') 
        UNION SELECT ('B') 
        UNION SELECT ('L') 
    ), cte_AlreadyAddedRemoved AS (
        SELECT Step
        FROM cte_PossibleNext cPN
        LEFT JOIN #Solution S ON cPN.Step = S.Letter
        WHERE S.ID IS NULL
    ), cte_NotReady AS (
        SELECT DISTINCT cAAR.Step
        FROM cte_AlreadyAddedRemoved cAAR
        INNER JOIN #Steps S ON cAAR.Step = S.AfterStep
        LEFT JOIN #Solution So ON So.Letter = S.BeforeStep
        WHERE So.ID IS NULL
    )
    INSERT #Solution (Letter)
    SELECT TOP(1) C1.Step 
    FROM cte_AlreadyAddedRemoved C1
    LEFT JOIN cte_NotReady C2 ON C1.Step = C2.Step
    WHERE C2.Step IS NULL
    ORDER BY C1.Step

END

SELECT * FROM #Solution

DROP TABLE #Solution

--ABDCJLFMNVQWHIRKTEUXOZSYPG



CREATE TABLE #WorkSchedule (ID INT IDENTITY(1,1), WorkerID INT, Step CHAR, TimeReady INT)

DECLARE @Time INT = 0
DECLARE @AvailableWorkers INT = 5

WHILE ((SELECT COUNT(1) FROM #WorkSchedule) < 26)
BEGIN

    ;WITH cte_PossibleNext AS (
        SELECT DISTINCT T2.AfterStep AS Step
        FROM #WorkSchedule T1
        INNER JOIN #Steps T2 ON T1.Step = T2.BeforeStep
        UNION SELECT ('A') 
        UNION SELECT ('B') 
        UNION SELECT ('L') 
    ), cte_AlreadyAddedRemoved AS (
        SELECT cPN.Step
        FROM cte_PossibleNext cPN
        LEFT JOIN #WorkSchedule S ON cPN.Step = S.Step
        WHERE S.ID IS NULL
    ), cte_NotReady AS (
        SELECT DISTINCT cAAR.Step
        FROM cte_AlreadyAddedRemoved cAAR
        INNER JOIN #Steps S ON cAAR.Step = S.AfterStep
        LEFT JOIN #WorkSchedule So ON So.Step = S.BeforeStep AND So.TimeReady <= @Time
        WHERE So.ID IS NULL
    )
    INSERT #WorkSchedule (Step, TimeReady, WorkerID)
    SELECT TOP(1) C1.Step, @Time + ASCII(C1.Step) - 4, @AvailableWorkers
    FROM cte_AlreadyAddedRemoved C1
    LEFT JOIN cte_NotReady C2 ON C1.Step = C2.Step
    WHERE C2.Step IS NULL AND @AvailableWorkers > 0
    ORDER BY C1.Step

    IF (@@ROWCOUNT = 0) 
    BEGIN
        SELECT @Time = MIN(TimeReady) FROM #WorkSchedule WHERE TimeReady > @Time
        SET @AvailableWorkers = @AvailableWorkers + 1
    END
    ELSE
    BEGIN
        SET @AvailableWorkers = @AvailableWorkers - 1
    END

END

SELECT * FROM #WorkSchedule
