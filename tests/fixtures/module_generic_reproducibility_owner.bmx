SuperStrict

Module Bcc2ReproducibilityTest.Owner

Type TReproducibleBox<T>
	Field value:T

	Method Read:T()
		Return value
	End Method
End Type

Function ReproducibleIdentity<T>:T(value:T)
	Return value
End Function

Function ModuleReproducibleValue:String()
	Local box:TReproducibleBox<String> = New TReproducibleBox<String>
	box.value = ReproducibleIdentity<String>("module")
	Return box.Read()
End Function
