SuperStrict

Framework BRL.Blitz

Type TInitializationCycleA<T>
	Global Value:Int = (New TInitializationCycleB<T>).Read() + 1

	Method Read:Int()
		Return Value
	End Method
End Type

Type TInitializationCycleB<T>
	Global Value:Int = (New TInitializationCycleA<T>).Read() + 1

	Method Read:Int()
		Return Value
	End Method
End Type

Global Cycle:TInitializationCycleA<String> = New TInitializationCycleA<String>
