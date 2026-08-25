SuperStrict

Framework BRL.StandardIO
Import "compiler_managed_value_assertions_native.c"

Extern
	Function NativeNullObject:Object() = "bcc2_managed_null_object"
	Function NativeWrongArray:Int[]() = "bcc2_managed_wrong_array"
	Function NativeWrongString:String() = "bcc2_managed_wrong_string"
End Extern

Function CheckFailure(action:Void(), expected:String)
	Try
		action()
		Throw "managed assertion did not fail: " + expected
	Catch message:String
		If message.Find(expected) < 0 Then Throw "unexpected managed assertion: " + message
	End Try
End Function

CheckFailure(Function()
	Local value:Object = NativeNullObject()
	If value Then Throw "C NULL Object was truthy"
End Function, "managed Object contains C NULL")

CheckFailure(Function()
	Local values:Int[] = NativeWrongArray()
	Local count:Int = values.length
End Function, "managed Array contains an invalid sentinel")

CheckFailure(Function()
	Local value:String = NativeWrongString()
	If value Then Throw "wrong String sentinel was truthy"
End Function, "managed String contains an invalid sentinel")

Print "managed-value-assertions-ok"
