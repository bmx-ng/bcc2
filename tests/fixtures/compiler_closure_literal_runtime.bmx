SuperStrict

Framework BRL.StandardIO

Local add:Closure<Int(value:Int)> = Function(value:Int)
	Return value + 2
End Function

Local notify:Closure<()> = Function()
	Print "managed closure"
End Function

If Not add Then Throw "managed closure should be truthy"
If notify = Null Then Throw "managed no-return closure should be truthy"

Print add(40)
notify()

Local fail:Closure<()> = Function()
	Throw "closure throw"
End Function

Try
	fail()
	Throw "closure exception did not propagate"
Catch message:String
	If message <> "closure throw" Then Throw message
End Try

Local missing:Closure<()> = Null
If missing Then Throw "null closure should be false"
Local sawNullClosureAsFalse:Int
If Not missing Then sawNullClosureAsFalse = True
If Not sawNullClosureAsFalse Then Throw "Not null closure should be true"
Try
	missing()
	Throw "null closure invocation did not throw"
Catch error:TNullFunctionException
	Print "null closure rejected"
End Try

Print "closure-ok"
