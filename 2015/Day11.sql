use Test_WME

SET NOCOUNT ON

DECLARE @Input VARCHAR(MAX) = 'cqjxjnds'


CREATE TABLE ##Password (ID INT IDENTITY(1,1), Nr INT, Letter CHAR)

INSERT ##Password (Nr, Letter) VALUES (1, 'c')
INSERT ##Password (Nr, Letter) VALUES (2, 'q')
INSERT ##Password (Nr, Letter) VALUES (3, 'j')
INSERT ##Password (Nr, Letter) VALUES (4, 'x')
INSERT ##Password (Nr, Letter) VALUES (5, 'j')
INSERT ##Password (Nr, Letter) VALUES (6, 'n')
INSERT ##Password (Nr, Letter) VALUES (7, 'd')
INSERT ##Password (Nr, Letter) VALUES (8, 's')


DECLARE @PasswordValid INT = 0
DECLARE @Counter INT = 0

WHILE @PasswordValid < 1
BEGIN
    
    UPDATE ##Password
    SET Letter = CHAR(ASCII(Letter) + 1)
    WHERE Nr = 8

    WHILE (SELECT COUNT(1) FROM ##Password WHERE Letter = '{') > 0
    BEGIN

        UPDATE ##Password
        SET Letter = '*'
        WHERE Letter = '{'
        
        UPDATE ##Password
        SET Letter = CHAR(ASCII(Letter) + 1)
        WHERE Nr = (SELECT Nr - 1 FROM ##Password WHERE Letter = '*')

        UPDATE ##Password
        SET Letter = 'a'
        WHERE Letter = '*'

    END

    SET @PasswordValid = 1

    IF NOT EXISTS (
        SELECT 1
        FROM ##Password L1
        INNER JOIN ##Password L2 ON L1.Nr = L2.Nr - 1 AND ASCII(L1.Letter) = ASCII(L2.Letter) - 1
        INNER JOIN ##Password L3 ON L2.Nr = L3.Nr - 1 AND ASCII(L2.Letter) = ASCII(L3.Letter) - 1
        ) SET @PasswordValid = 0

    IF @PasswordValid = 1 AND (SELECT COUNT(1) FROM ##Password WHERE Letter IN ('i','o','l')) > 0
        SET @PasswordValid = 0

    IF @PasswordValid = 1 AND NOT EXISTS (SELECT 1 
                                          FROM ##Password L1
                                          INNER JOIN ##Password L2 ON L1.Nr = L2.Nr - 1 AND L1.Letter = L2.Letter
                                          INNER JOIN ##Password L3 ON L2.Nr < L3.Nr AND L2.Letter <> L3.Letter
                                          INNER JOIN ##Password L4 ON L3.Nr = L4.Nr - 1 AND L3.Letter = L4.Letter)
        SET @PasswordValid = 0

    SET @Counter = @Counter + 1

    IF (@Counter % 100000) = 0 PRINT CAST(@Counter AS VARCHAR(10)) + ' at time: ' + CAST(GETDATE() AS VARCHAR(50))
END

SELECT * FROM ##Password

/*

DROP TABLE ##Password

    Passwords must include one increasing straight of at least three letters, like abc, bcd, cde, and so on, up to xyz. They cannot skip letters; abd doesn't count.
    Passwords may not contain the letters i, o, or l, as these letters can be mistaken for other characters and are therefore confusing.
    Passwords must contain at least two different, non-overlapping pairs of letters, like aa, bb, or zz.

*/

-- cqjxxyzz is correct for part 1
-- cqkaabcc is correct for part 2 (without doing the whole calculation)