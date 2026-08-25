SuperStrict

Framework BRL.StandardIO

Import BRL.Arrays
Import Bcc2ArraysBoundaryTest.Functions

Local values:Int[] = [1, 2, 3, 4]
Local mapped:Int[] = Map<Int, Int>(values, ArraysBoundaryDouble)
If mapped.Length <> 4 Or mapped[0] <> 2 Or mapped[3] <> 8 Then Throw "module Map failed"

Local filtered:Int[] = Filter<Int>(values, ArraysBoundaryEven)
If filtered.Length <> 2 Or filtered[0] <> 2 Or filtered[1] <> 4 Then Throw "module Filter failed"
If Fold<Int, Int>(values, 0, ArraysBoundaryAdd) <> 10 Then Throw "module Fold failed"
If Count<Int>(values, ArraysBoundaryEven) <> 2 Then Throw "module Count failed"
If Not Any<Int>(values, ArraysBoundaryEven) Then Throw "module Any failed"
If All<Int>(values, ArraysBoundaryEven) Then Throw "module All failed"
If FirstOrNone<Int>(values, ArraysBoundaryEven).Value() <> 2 Then Throw "module FirstOrNone failed"
If LastOrNone<Int>(values).Value() <> 4 Then Throw "module LastOrNone failed"

ForEach<Int>(values, ArraysBoundaryVisit)
If ArraysBoundaryVisitedTotal() <> 10 Then Throw "module ForEach failed"

Local original:SArraysBoundaryValue
original.value = 41
Local shifted:SArraysBoundaryValue[] = Map<SArraysBoundaryValue, SArraysBoundaryValue>([original], ArraysBoundaryShift)
If shifted[0].value <> 42 Then Throw "module Struct Map failed"

Local offset:Int = 10
Local closure:Closure<Int(value:Int)> = Function:Int(value:Int)
	Return value + offset
End Function
If Map<Int, Int>([32], closure)[0] <> 42 Then Throw "capturing Closure Map failed"

Print "arrays-module-boundary-ok"
