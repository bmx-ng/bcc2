SuperStrict

Module Bcc2ImportOrderTest.Core

Function OrderTransform<A, B>:B(value:A, transform:Closure<B(value:A)>)
	Return transform(value)
End Function

Function OrderDeferred<T>:Closure<T()>(value:T)
	Return Function()
		Return value
	End Function
End Function
