SuperStrict

Framework BRL.StandardIO

Function Bind<T, R>:Closure<R()>(value:T, operation:Closure<R(value:T)>)
	Return Function()
		Return operation(value)
	End Function
End Function

Function BindAll<T, R>:Closure<R()>[](values:T[], operation:Closure<R(value:T)>)
	Local result:Closure<R()>[] = New Closure<R()>[values.length]
	For Local index:Int = 0 Until values.length
		result[index] = Bind<T, R>(values[index], operation)
	Next
	Return result
End Function

Type TPayload
	Field name:String

	Method New(name:String)
		Self.name = name
	End Method
End Type

Local render:Closure<String(value:TPayload)> = Function(value:TPayload)
	Return "bound:" + value.name
End Function
Local payloads:TPayload[] = [New TPayload("alpha"), New TPayload("beta"), New TPayload("gamma")]
Local actions:Closure<String()>[] = BindAll<TPayload, String>(payloads, render)
If actions.length <> 3 Or actions[0]() <> "bound:alpha" Or actions[1]() <> "bound:beta" Or actions[2]() <> "bound:gamma" Then Throw "generic Closure Array binding failed"
Print "closure-array-ok"
