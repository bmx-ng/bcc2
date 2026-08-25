SuperStrict

Extern
	Function NativeArraySum:Int(values:Int[]) = "bcc2_native_array_sum"
	Global NativeArray:Int[] = "bcc2_native_array"
End Extern

Local Values:Int[] = New Int[2]
Values[0] = 20
Values[1] = 22
Local Result:Int = NativeArraySum(Values)
If Result = 42
	NativeArray = Values
End If
