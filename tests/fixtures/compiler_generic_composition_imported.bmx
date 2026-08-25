SuperStrict

Struct SImportedPair<T>
	Field value:T
	Field transform:Closure<T(value:T)>
End Struct

Type TImportedPipeline<T>
	Method Execute:T(value:T, transform:Closure<T(value:T)>)
		Local pair:SImportedPair<T>
		pair.value = value
		pair.transform = transform
		Local pairs:SImportedPair<T>[] = [pair]
		pairs :+ [pair]
		Local result:T
		For Local current:SImportedPair<T>=EachIn pairs
			result = current.transform(current.value)
		Next
		Return result
	End Method
End Type

Function ImportedDeferred<T>:Closure<T()>(pipeline:TImportedPipeline<T>, value:T, transform:Closure<T(value:T)>)
	Return Function()
		Return pipeline.Execute(value, transform)
	End Function
End Function
