SuperStrict

Struct SParameterCell
	Field value:Int

	Method Add(delta:Int)
		value = value + delta
	End Method
End Struct

Function AddCell(value:SParameterCell Var, delta:Int)
	value.value = value.value + delta
End Function

Function Sum:Int(StaticArray values:Int[4])
	Local total:Int = values.length
	For Local value:Int = EachIn values
		total = total + value
	Next
	Return total
End Function

Function Touch(StaticArray cells:SParameterCell[2])
	cells[0].Add(2)
	AddCell(cells[1], 3)
End Function

Type TStaticParameterBase
	Method Size:Int(StaticArray values:Int[4])
		Return values.length
	End Method
End Type

Type TStaticParameterDerived Extends TStaticParameterBase
	Method Size:Int(StaticArray values:Int[4]) Override
		Return values.length + 1
	End Method
End Type

Local StaticArray numbers:Int[4]
Local StaticArray cells:SParameterCell[2]
Touch(cells)
Local owner:TStaticParameterBase = New TStaticParameterDerived
Local total:Int = Sum(numbers) + owner.Size(numbers)
