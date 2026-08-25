SuperStrict
Module acme.fixedparams

Struct SFixedParameterCell
	Field value:Int

	Method Add(delta:Int)
		value = value + delta
	End Method
End Struct

Function SumFixed:Int(StaticArray values:Int[4])
	Local total:Int = values.length
	For Local value:Int = EachIn values
		total = total + value
	Next
	Return total
End Function

Function TouchFixed(StaticArray cells:SFixedParameterCell[2])
	cells[0].Add(1)
End Function

Type TFixedParameterBase
	Method Size:Int(StaticArray values:Int[4])
		Return values.length
	End Method
End Type

Type TFixedParameterDerived Extends TFixedParameterBase
	Method Size:Int(StaticArray values:Int[4]) Override
		Return values.length + 1
	End Method
End Type

Function CreateFixedParameterBase:TFixedParameterBase()
	Return New TFixedParameterDerived
End Function
