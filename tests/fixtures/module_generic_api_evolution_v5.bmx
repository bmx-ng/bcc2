SuperStrict

Module Bcc2ApiEvolutionTest.Owner

Interface IApiEvolutionValue
	Method EvolutionTag:Int()
End Interface

Type TApiEvolutionBox<T> Where T Extends IApiEvolutionValue
	Field value:T

	Method Apply:T(transform:Closure<T(value:T)>)
		Return EvolveValue<T>(value, transform)
	End Method
End Type

Function EvolveValue<T>:T(value:T, transform:Closure<T(value:T)>, repeat:Int = 3) Where T Extends IApiEvolutionValue
	For Local index:Int = 0 Until repeat
		value = transform(value)
	Next
	Return value
End Function

Private Function PrivateMarker:Int()
	Return 20
End Function

Public Function ProviderMarker:Int()
	Return PrivateMarker()
End Function
