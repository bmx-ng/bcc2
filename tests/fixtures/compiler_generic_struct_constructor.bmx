SuperStrict

Struct TInnerValue<T>
	Field value:T
End Struct

Struct TConstructedValue<T>
	Field inner:TInnerValue<T>
	Field stored:T
	Field count:Int

	Method New()
	End Method

	Method New(value:T)
		stored = value
	End Method

	Method New(amount:Int)
		count = amount
	End Method

	Method New(value:T, amount:Int)
		New(value)
		count = amount
	End Method

	Method Read:T()
		Return stored
	End Method
End Struct

Global defaultConstructed:TConstructedValue<String> = New TConstructedValue<String>
Global constructed:TConstructedValue<String> = New TConstructedValue<String>("canonical constructor")
Global counted:TConstructedValue<String> = New TConstructedValue<String>(7)
Global delegated:TConstructedValue<String> = New TConstructedValue<String>("delegated constructor", 9)
Global copied:TConstructedValue<String> = constructed
Global observed:String = copied.Read()
