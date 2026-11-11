SuperStrict

Interface IItem
	Method Read:Int()
End Interface

Type TItem Implements IItem
	Field value:Int
	Method Read:Int()
		Return value
	End Method
End Type

Function Keep<T>:T(value:T)
	Local retained:T = value
	Return retained
End Function

Function Exchange<T>(left:T Var, right:T Var)
	Local prior:T = left
	left = right
	right = prior
End Function

Function Expand<T>:T[](source:T[], item:T)
	Local values:T[] = New T[2]
	values[0] = source[0]
	values[1] = item
	Return values
End Function

Function AppendValue<T>:T(value:T Var, suffix:T)
	Local retained:T = value
	value = retained + suffix
	Return value
End Function

Local item:TItem = New TItem
Local retained:TItem = Keep<TItem>(item)
Local contract:IItem = item
Local retainedContract:IItem = Keep<IItem>(contract)
Local first:Object = item
Local second:Object = New TItem
Exchange<Object>(first, second)
Local source:Int[] = [1]
Local expanded:Int[] = Expand<Int>(source, 2)
Exchange<Int[]>(source, expanded)
Local words:String[] = ["one"]
Local expandedWords:String[] = Expand<String>(words, "two")
Local text:String = "first"
Local result:String = AppendValue<String>(text, " second")
