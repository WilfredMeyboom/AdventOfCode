USE Test_WME

SET NOCOUNT ON

DECLARE @year VARCHAR(4) = '2023'
DECLARE @day VARCHAR(2)  = '7'

EXEC dbo.GetInput @year = @year, @day = @day
EXEC dbo.ParseInput @year = @year, @day = @day 

--SELECT TOP 10 * FROM ##Input
--SELECT TOP 10 * FROM ##InputInts
--SELECT TOP 10 * FROM ##InputNumbered
--SELECT TOP 10 * FROM ##InputGrid
--SELECT TOP 10 * FROM ##InputSplit
--SELECT TOP 10 * FROM ##InputSplitCust
  

CREATE TABLE ##Hands (ID INT IDENTITY(1,1), RowNr INT, Hand VARCHAR(5), Bid INT, HandType VARCHAR(20), HandType2 VARCHAR(20))

-- We'll be determining the type of the hands in steps. So create a table we can update
INSERT ##Hands (RowNr, Hand, Bid)
SELECT I1.RowNr, I1.Piece, I2.Piece
FROM ##InputSplit I1
INNER JOIN ##InputSplit I2 ON I1.RowNr = I2.RowNr AND I2.PieceNr = 2
WHERE I1.PieceNr = 1


CREATE TABLE ##MatchingCards (ID INT IDENTITY(1,1), RowNr INT, Val CHAR, MatchingCards INT)

-- For every hand, look at the number of matching cards there are 
INSERT ##MatchingCards
(
    RowNr,
    Val,
    MatchingCards
)
SELECT I1.RowNr + 1, I1.Val, COUNT(1) AS MatchingCards -- InputGrid and InputSplit differ in the starting index. Adjust the grid results so they are usable with the split results
FROM ##InputGrid I1
INNER JOIN ##InputGrid I2 ON I1.RowNr = I2.RowNr AND I1.ColNr <> I2.ColNr AND I1.Val = I2.Val AND I2.ColNr BETWEEN 0 AND 4
WHERE I1.ColNr BETWEEN 0 AND 4
GROUP BY I1.RowNr, I1.Val
ORDER BY 3 DESC

-- Determine the type of hand; top to bottom, and only adjust hands that don't have a type yet
UPDATE H
SET H.HandType = '1 Five of a kind'
FROM ##Hands H
INNER JOIN ##MatchingCards MC ON H.RowNr = MC.RowNr
WHERE MC.MatchingCards = 20 -- Because every card matches to every other card, we get a lot more matches (than the expected 4 or 5; it's actually 4*5)

UPDATE H
SET H.HandType = '2 Four of a kind'
FROM ##Hands H
INNER JOIN ##MatchingCards MC ON H.RowNr = MC.RowNr
WHERE MC.MatchingCards = 12 AND H.HandType IS NULL -- Idem (4 * 3 for four of a kind)

UPDATE H
SET H.HandType = '3 Full House'
FROM ##Hands H
INNER JOIN ##MatchingCards MC ON H.RowNr = MC.RowNr AND MC.MatchingCards = 6
INNER JOIN ##MatchingCards MC2 ON H.RowNr = MC2.RowNr AND MC2.MatchingCards = 2
WHERE H.HandType IS NULL

UPDATE H
SET H.HandType = '4 Three of a kind'
FROM ##Hands H
INNER JOIN ##MatchingCards MC ON H.RowNr = MC.RowNr AND MC.MatchingCards = 6
WHERE H.HandType IS NULL

UPDATE H
SET H.HandType = '5 Two pair'
FROM ##Hands H
INNER JOIN ##MatchingCards MC ON H.RowNr = MC.RowNr AND MC.MatchingCards = 2
INNER JOIN ##MatchingCards MC2 ON H.RowNr = MC2.RowNr AND MC.MatchingCards = 2 AND MC.Val <> MC2.Val
WHERE H.HandType IS NULL

UPDATE H
SET H.HandType = '6 One pair'
FROM ##Hands H
INNER JOIN ##MatchingCards MC ON H.RowNr = MC.RowNr AND MC.MatchingCards = 2
WHERE H.HandType IS NULL

UPDATE H
SET H.HandType = '7 High card'
FROM ##Hands H
WHERE H.HandType IS NULL

-- Change the name of some cards to help the sorting algorithm
UPDATE H
SET Hand = REPLACE(REPLACE(REPLACE(Hand,'T','B'),'K','R'),'A','S')
FROM ##Hands H

-- Determine the rank and calculate the answer
;WITH cte_Ranked AS (
    SELECT ROW_NUMBER() OVER (ORDER BY HandType DESC, Hand ASC) AS Rn
    ,      Bid
    FROM ##Hands H
)
SELECT SUM(Rn * Bid) AS Part1
FROM cte_Ranked

-- For part 2 the Jacks are wild but valued as a 1
-- So basically hands get upgraded in type (which we will record in the handtype2 column)
-- And at the sort, we'll replace the Jacks with ones

-- Without Jacks everything stays the same
UPDATE ##Hands
SET HandType2 = HandType
WHERE Hand NOT LIKE '%J%'

-- Nothing changes for Five of a kind
UPDATE ##Hands
SET HandType2 = HandType
WHERE HandType LIKE '1%'

-- Upgrade four of a kinds to five of kind
UPDATE H
SET H.HandType2 = '1 Five of a kind'
FROM ##Hands H
INNER JOIN ##MatchingCards MC ON MC.RowNr = H.RowNr AND MC.MatchingCards = 12
WHERE H.HandType LIKE '2%' AND (MC.Val = 'J' OR (MC.Val <> 'J' AND Hand LIKE '%J%'))

--Upgrade full houses to five of kind
UPDATE H
SET H.HandType2 = '1 Five of a kind'
FROM ##Hands H
INNER JOIN ##MatchingCards MC ON MC.RowNr = H.RowNr 
WHERE H.HandType LIKE '3%' AND Hand LIKE '%J%'
AND MC.Val <> 'J' 

-- Upgrade three of a kind with a Jack and two pairs with a pair of Jacks to four of a kind
UPDATE H
SET H.HandType2 = '2 Four of a kind'
FROM ##Hands H
INNER JOIN ##MatchingCards MC ON MC.RowNr = H.RowNr 
WHERE (H.HandType LIKE '4%' AND Hand LIKE '%J%')
    OR (H.HandType LIKE '5%' AND MC.Val = 'J')

-- Upgrade two pairs with a single Jack to a full House
UPDATE H
SET H.HandType2 = '3 Full House'
FROM ##Hands H
INNER JOIN ##MatchingCards MC ON MC.RowNr = H.RowNr 
WHERE H.HandType LIKE '5%' AND H.HandType2 IS NULL

-- Upgrade a single pair to three of kind (it doesn't matter if it is a pair of jacks or a single jack)
UPDATE H
SET H.HandType2 = '4 Three of a kind'
FROM ##Hands H
INNER JOIN ##MatchingCards MC ON MC.RowNr = H.RowNr 
WHERE H.HandType LIKE '6%' AND H.HandType2 IS NULL

-- Upgrade anything else (which should be high cards) to one pair
UPDATE H
SET H.HandType2 = '6 One pair'
FROM ##Hands H
WHERE H.HandType2 IS NULL



--Change the name of the Jacks to help the sorting algorithm
UPDATE H
SET Hand = REPLACE(Hand,'J','1')
FROM ##Hands H

-- Determine the rank and calculate the answer
;WITH cte_Ranked AS (
    SELECT ROW_NUMBER() OVER (ORDER BY HandType2 DESC, Hand ASC) AS Rn
    ,      Bid
    FROM ##Hands H
)
SELECT SUM(Rn * Bid) AS Part2
FROM cte_Ranked


/*

DROP TABLE ##Hands
DROP TABLE ##MatchingCards

*/