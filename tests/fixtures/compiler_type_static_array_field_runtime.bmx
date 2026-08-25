SuperStrict

Struct SObjectCell
	Field number:Int = 5
	Field text:String

	Method Add(delta:Int)
		number = number + delta
	End Method
End Struct

Type TFixedBase
	Field StaticArray cells:SObjectCell[2]
	Field StaticArray counts:Int[3]

	Method First:Int()
		Return cells[0].number
	End Method
End Type

Type TFixedDerived Extends TFixedBase
	Field marker:Int = 7
End Type

Function Mutate(value:SObjectCell Var, delta:Int)
	value.number = value.number + delta
End Function

Local base:TFixedBase = New TFixedBase
base.cells[0].number = 20
base.cells[0].Add(2)
Mutate(base.cells[1], 3)
base.counts[2] = base.First()

Local derived:TFixedDerived = New TFixedDerived
derived.cells[0] = base.cells[0]
derived.counts[1] = derived.cells.length + derived.counts.length + derived.marker

Local total:Int = derived.counts[1]
For Local item:SObjectCell = EachIn base.cells
	total = total + item.number
Next
