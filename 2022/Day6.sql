USE Test_WME

DECLARE @year VARCHAR(4) = '2022'
DECLARE @day VARCHAR(2)  = '6'

EXEC dbo.GetInput @year = @year, @day = @day
EXEC dbo.ParseInput @year = @year, @day = @day 

--SELECT TOP 10 * FROM ##Input
--SELECT TOP 10 * FROM ##InputInts
--SELECT TOP 10 * FROM ##InputNumbered
SELECT TOP 10 * FROM ##InputGrid
--SELECT TOP 10 * FROM ##InputSplit
--SELECT TOP 10 * FROM ##InputSplitCust
  

SELECT i1.colnr, i2.colnr,i3.colnr,i4.colnr,i1.val,i2.val,i3.val,i4.val FROM ##InputGrid i1
INNER JOIN ##InputGrid i2 ON i1.ColNr = i2.ColNr - 1 AND i1.Val <> i2.Val
INNER JOIN ##InputGrid i3 ON i2.ColNr = i3.ColNr - 1 AND i1.Val <> i3.Val AND i2.val <> i3.val
INNER JOIN ##InputGrid i4 ON i3.ColNr = i4.ColNr - 1 AND i1.Val <> i4.Val AND i2.val <> i4.val AND i3.val <> i4.val
ORDER BY i1.ColNr


SELECT i1.colnr, i2.colnr,i3.colnr,i4.colnr,i5.colnr,i6.colnr,i7.colnr,i8.colnr,i9.colnr,i10.colnr,i11.colnr,i12.colnr,i13.colnr,i14.colnr
,i1.val,i2.val,i3.val,i4.val,i5.val,i6.val,i7.val,i8.val,i9.val,i10.val,i11.val,i12.val,i13.val,i14.val 
FROM ##InputGrid i1
INNER JOIN ##InputGrid i2 ON i1.ColNr = i2.ColNr - 1 AND i1.Val <> i2.Val
INNER JOIN ##InputGrid i3 ON i2.ColNr = i3.ColNr - 1 AND i1.Val <> i3.Val AND i2.val <> i3.val
INNER JOIN ##InputGrid i4 ON i3.ColNr = i4.ColNr - 1 AND i1.Val <> i4.Val AND i2.val <> i4.val AND i3.val <> i4.val
INNER JOIN ##InputGrid i5 ON i4.ColNr = i5.ColNr - 1 AND i1.Val <> i5.Val AND i2.val <> i5.val AND i3.val <> i5.val AND i4.val <> i5.val
INNER JOIN ##InputGrid i6 ON i5.ColNr = i6.ColNr - 1 AND i1.Val <> i6.Val AND i2.val <> i6.val AND i3.val <> i6.val AND i4.val <> i6.val AND i5.val <> i6.val
INNER JOIN ##InputGrid i7 ON i6.ColNr = i7.ColNr - 1 AND i1.Val <> i7.Val AND i2.val <> i7.val AND i3.val <> i7.val AND i4.val <> i7.val AND i5.val <> i7.val AND i6.val <> i7.val
INNER JOIN ##InputGrid i8 ON i7.ColNr = i8.ColNr - 1 AND i1.Val <> i8.Val AND i2.val <> i8.val AND i3.val <> i8.val AND i4.val <> i8.val AND i5.val <> i8.val AND i6.val <> i8.val AND i7.val <> i8.val
INNER JOIN ##InputGrid i9 ON i8.ColNr = i9.ColNr - 1 AND i1.Val <> i9.Val AND i2.val <> i9.val AND i3.val <> i9.val AND i4.val <> i9.val AND i5.val <> i9.val AND i6.val <> i9.val AND i7.val <> i9.val AND i8.val <> i9.val
INNER JOIN ##InputGrid i10 ON i9.ColNr = i10.ColNr - 1 AND i1.Val <> i10.Val AND i2.val <> i10.val AND i3.val <> i10.val AND i4.val <> i10.val AND i5.val <> i10.val AND i6.val <> i10.val AND i7.val <> i10.val AND i8.val <> i10.val AND i9.val <> i10.val
INNER JOIN ##InputGrid i11 ON i10.ColNr = i11.ColNr - 1 AND i1.Val <> i11.Val AND i2.val <> i11.val AND i3.val <> i11.val AND i4.val <> i11.val AND i5.val <> i11.val AND i6.val <> i11.val AND i7.val <> i11.val AND i8.val <> i11.val AND i9.val <> i11.val AND i10.val <> i11.val
INNER JOIN ##InputGrid i12 ON i11.ColNr = i12.ColNr - 1 AND i1.Val <> i12.Val AND i2.val <> i12.val AND i3.val <> i12.val AND i4.val <> i12.val AND i5.val <> i12.val AND i6.val <> i12.val AND i7.val <> i12.val AND i8.val <> i12.val AND i9.val <> i12.val AND i10.val <> i12.val AND i11.val <> i12.val
INNER JOIN ##InputGrid i13 ON i12.ColNr = i13.ColNr - 1 AND i1.Val <> i13.Val AND i2.val <> i13.val AND i3.val <> i13.val AND i4.val <> i13.val AND i5.val <> i13.val AND i6.val <> i13.val AND i7.val <> i13.val AND i8.val <> i13.val AND i9.val <> i13.val AND i10.val <> i13.val AND i11.val <> i13.val AND i12.val <> i13.val
INNER JOIN ##InputGrid i14 ON i13.ColNr = i14.ColNr - 1 AND i1.Val <> i14.Val AND i2.val <> i14.val AND i3.val <> i14.val AND i4.val <> i14.val AND i5.val <> i14.val AND i6.val <> i14.val AND i7.val <> i14.val AND i8.val <> i14.val AND i9.val <> i14.val AND i10.val <> i14.val AND i11.val <> i14.val AND i12.val <> i14.val AND i13.val <> i14.val


ORDER BY i1.ColNr

