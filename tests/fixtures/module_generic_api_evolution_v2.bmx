SuperStrict

Module Bcc2ApiEvolutionTest.Owner

Interface IApiEvolutionValue
	Method EvolutionTag:Int()
End Interface

Type TApiEvolutionBox<T>
	Field value:T

	Method Apply:T(transform:Closure<T(value:T)>)
		Return EvolveValue<T>(value, transform)
	End Method
End Type

Function EvolveValue<T>:T(value:T, transform:Closure<T(value:T)>)
	Return transform(value)
End Function

Private Function PrivateMarker:Int()
	Return 20
End Function

Public Function ProviderMarker:Int()
	Return PrivateMarker()
End Function
