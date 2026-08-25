SuperStrict

Import "types.bmx"

Type TVersionPipeline<T> Extends TVersionBase<String, T[,]>
	Method Apply:T(value:T, transform:Closure<T(value:T)>)
		values = New T[1, 1]
		values[0, 0] = value
		Return transform(transform(transform(value)))
	End Method
End Type
