SuperStrict
Module acme.structcallbacks

Struct SBoundaryCell
	Field value:Int
End Struct

Function SumCells:Int(StaticArray cells:SBoundaryCell[2])
	Return cells[0].value + cells[1].value
End Function

Function OffsetCells:Int(StaticArray cells:SBoundaryCell[2])
	Return SumCells(cells) + 1
End Function

Global ActiveCells:Int(StaticArray cells:SBoundaryCell[2]) = SumCells

Type TBoundaryBase
	Field callback:Int(StaticArray cells:SBoundaryCell[2]) = SumCells

	Method Apply:Int(operation:Int(StaticArray cells:SBoundaryCell[2]), StaticArray cells:SBoundaryCell[2])
		Return operation(cells) + callback(cells)
	End Method
End Type

Type TBoundaryDerived Extends TBoundaryBase
	Method Apply:Int(operation:Int(StaticArray cells:SBoundaryCell[2]), StaticArray cells:SBoundaryCell[2]) Override
		Return Super.Apply(operation, cells) + 1
	End Method
End Type

Interface IBoundaryCallback
	Method Apply:Int(operation:Int(StaticArray cells:SBoundaryCell[2]), StaticArray cells:SBoundaryCell[2])
End Interface

Type TBoundaryImplementation Implements IBoundaryCallback
	Method Apply:Int(operation:Int(StaticArray cells:SBoundaryCell[2]), StaticArray cells:SBoundaryCell[2])
		Return operation(cells)
	End Method
End Type

Function CreateBoundary:TBoundaryBase()
	Return New TBoundaryDerived
End Function

Function CreateBoundaryImplementation:TBoundaryImplementation()
	Return New TBoundaryImplementation
End Function
