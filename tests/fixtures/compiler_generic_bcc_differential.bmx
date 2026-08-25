SuperStrict

Framework BRL.StandardIO

Interface IValue<T>
	Method Read:T()
End Interface

Type TBox<T> Implements IValue<T>
	Field value:T

	Method New(value:T)
		Self.value = value
	End Method

	Method Read:T()
		Return value
	End Method
End Type

Local first:TBox<String> = New TBox<String>("canonical")
Local second:TBox<String> = first
Local abstractValue:IValue<String> = second
Local numbers:Int[] = [1, 2, 3, 4]
Local total:Int
For Local value:Int = EachIn numbers
	total :+ value
Next

Print abstractValue.Read() + ":" + total
