SuperStrict

Framework BRL.Blitz

Interface IDynamicGeneric
	Method Pick<T>:T(value:T)
End Interface

Type TDynamicGeneric Implements IDynamicGeneric
	Method Pick<T>:T(value:T)
		Return value
	End Method
End Type

Global dynamicValue:IDynamicGeneric = New TDynamicGeneric
Global dynamicResult:String = dynamicValue.Pick("linked")
