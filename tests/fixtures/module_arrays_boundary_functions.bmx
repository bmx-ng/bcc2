SuperStrict

Module Bcc2ArraysBoundaryTest.Functions

Global ArraysBoundaryVisited:Int

Struct SArraysBoundaryValue
	Field value:Int
End Struct

Function ArraysBoundaryEven:Int(value:Int)
	Return (value & 1) = 0
End Function

Function ArraysBoundaryDouble:Int(value:Int)
	Return value * 2
End Function

Function ArraysBoundaryAdd:Int(total:Int, value:Int)
	Return total + value
End Function

Function ArraysBoundaryVisit(value:Int)
	ArraysBoundaryVisited :+ value
End Function

Function ArraysBoundaryVisitedTotal:Int()
	Return ArraysBoundaryVisited
End Function

Function ArraysBoundaryShift:SArraysBoundaryValue(value:SArraysBoundaryValue)
	value.value :+ 1
	Return value
End Function
