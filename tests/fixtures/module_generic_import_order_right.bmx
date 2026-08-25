SuperStrict

Module Bcc2ImportOrderTest.Right

Import Bcc2ImportOrderTest.Core

Function RightPipeline<T>:T(value:T)
	Local invoke:Closure<T(deferred:Closure<T()>)> = Function:T(deferred:Closure<T()>)
		Return deferred()
	End Function
	Return OrderTransform<Closure<T()>, T>(OrderDeferred<T>(value), invoke)
End Function
