SuperStrict

Struct SFixedItem
	Field number:Int = 3
	Field text:String

	Method Add(delta:Int)
		number = number + delta
	End Method
End Struct

Function Mutate(value:SFixedItem Var, delta:Int)
	value.number = value.number + delta
End Function

Global StaticArray shared:SFixedItem[2]
Local StaticArray values:SFixedItem[2]
values[0].number = 20
values[0].Add(2)
Mutate(values[1], 3)
shared[0] = values[0]
Local first:SFixedItem = values[0]
Local total:Int = first.number + shared.length

For Local item:SFixedItem = EachIn values
	total = total + item.number
Next
