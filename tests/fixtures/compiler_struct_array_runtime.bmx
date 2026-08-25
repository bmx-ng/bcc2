SuperStrict

Struct SItem
	Field number:Int = 3
	Field text:String

	Method Add(delta:Int)
		number = number + delta
	End Method
End Struct

Function Mutate(value:SItem Var, delta:Int)
	value.number = value.number + delta
End Function

Local values:SItem[] = New SItem[2]
values[0].number = 20
values[0].Add(2)
values[1] = values[0]
Mutate(values[1], 3)
Local first:SItem = values[0]
Local literal:SItem[] = [values[0], values[1]]
Local joined:SItem[] = values + literal
Local total:Int = joined.length + first.number

For Local item:SItem = EachIn values
	total = total + item.number
Next
