SuperStrict

Extern
	Function NativeAdd:Int(left:Int, right:Int) = "bcc2_native_add"
End Extern

Global NativeResult:Int = NativeAdd(20, 22)
