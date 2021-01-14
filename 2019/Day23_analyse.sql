SELECT TOP 5 * FROM ##Pointers ORDER BY Ticks, OpCodeCompNr
SELECT TOP 5 * FROM ##Pointers WHERE OpCodeCompNr = 32

--SELECT SendOut, COUNT(1) FROM ##Nat GROUP BY SendOut
SELECT TOP 10 * FROM ##Nat ORDER BY ID DESC

SELECT * FROM ##Packetqueue ORDER BY ID


SELECT * FROM ##Nat WHERE SendOut = 1
SELECT Y FROM ##Nat GROUP BY Y HAVING COUNT(1) > 1
SELECT * FROM ##Nat WHERE Y <= 17298

SELECT * FROM Test_WME.dbo.IntCompSave
SELECT * FROM Test_WME.dbo.PacketQueue
SELECT * FROM Test_WME.dbo.Nat
SELECT * FROM Test_WME.dbo.Pointers

SELECT * FROM Test_WME.dbo.OpCodes

--SELECT * FROM ##Logging


