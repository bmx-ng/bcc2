SuperStrict
Framework BRL.StandardIO

Interface IValue
	Method Value:Int()
End Interface

Type TBox<T> Implements IValue
	Field value:T
	Method Value:Int()
		Return 42
	End Method
End Type

Local box:TBox<String> = New TBox<String>
Local value:IValue = box
Print value.Value()
