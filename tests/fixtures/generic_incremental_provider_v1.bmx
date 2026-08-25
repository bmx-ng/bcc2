SuperStrict

Type TVersionBase<A, B>
	Field values:B

	Method Values:B()
		Return values
	End Method
End Type

Type TVersionPipeline<T> Extends TVersionBase<String, T[]>
	Method Apply:T(value:T, transform:Closure<T(value:T)>)
		values = [value]
		Return transform(value)
	End Method
End Type
