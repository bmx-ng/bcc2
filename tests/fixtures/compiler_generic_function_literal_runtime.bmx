SuperStrict

Framework BRL.StandardIO

Function IdentityFunction<T>:T(value:T)()
	Return Function(value:T)
		Return value
	End Function
End Function

Function VarFunction<T>:T(value:T Var)()
	Return Function(value:T Var)
		value :+ 1
		Return value
	End Function
End Function

Function NestedFunction<T>:T(value:T)()
	Return Function(value:T)
		Local nested:T(item:T) = Function(item:T)
			Return item
		End Function
		Return nested(value)
	End Function
End Function

Function ThrowingFunction<T>:T(value:T)()
	Return Function(value:T)
		If value > 0 Then Throw "generic thin function throw"
		Return value
	End Function
End Function

Type TFunctionFactory<T>
	Method Identity:T(value:T)()
		Return Function(value:T)
			Return value
		End Function
	End Method
End Type

Local intIdentity:Int(value:Int) = IdentityFunction<Int>()
If intIdentity(42) <> 42 Then Throw "generic Int thin Function literal failed"

Local stringIdentity:String(value:String) = IdentityFunction<String>()
If stringIdentity("source-free") <> "source-free" Then Throw "generic String thin Function literal failed"

Local number:Int = 10
Local increment:Int(value:Int Var) = VarFunction<Int>()
If increment(number) <> 11 Or number <> 11 Then Throw "generic Var thin Function literal failed"

Local nested:Int(value:Int) = NestedFunction<Int>()
If nested(73) <> 73 Then Throw "nested generic thin Function literal failed"

Local factory:TFunctionFactory<String> = New TFunctionFactory<String>
Local methodIdentity:String(value:String) = factory.Identity()
If methodIdentity("method") <> "method" Then Throw "generic Method thin Function literal failed"

Local throwing:Int(value:Int) = ThrowingFunction<Int>()
Try
	throwing(1)
	Throw "generic thin Function literal did not throw"
Catch message:String
	If message <> "generic thin function throw" Then Throw message
End Try

Print "generic-function-literal-ok"
