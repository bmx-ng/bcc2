SuperStrict

Module Bcc2CompositionTest.Owner

Struct SModulePair<T>
	Field value:T
	Field transform:Closure<T(value:T)>
End Struct

Type TModuleBase<A, B>
	Field values:B

	Method Values:B()
		Return values
	End Method
End Type

Type TModuleMiddle<X> Extends TModuleBase<String, X[]>
End Type

Type TModulePipeline<T> Extends TModuleMiddle<T>
	Method Execute:T(value:T, transform:Closure<T(value:T)>)
		Local pair:SModulePair<T>
		pair.value = value
		pair.transform = transform
		Local pairs:SModulePair<T>[] = [pair]
		pairs :+ [pair]
		Local result:T
		For Local current:SModulePair<T>=EachIn pairs
			result = current.transform(current.value)
		Next
		values = [value]
		Return result
	End Method
End Type

Function ModuleDeferred<T>:Closure<T()>(pipeline:TModulePipeline<T>, value:T, transform:Closure<T(value:T)>)
	Return Function()
		Return pipeline.Execute(value, transform)
	End Function
End Function
