SuperStrict

Module Bcc2ImportOrderTest.Left

Import Bcc2ImportOrderTest.Core

Function LeftPipeline<T>:Closure<T()>(value:T)
	Local identity:Closure<T(value:T)> = Function:T(current:T)
		Return current
	End Function
	Local normalized:T = OrderTransform<T, T>(value, identity)
	Return OrderDeferred<T>(normalized)
End Function
