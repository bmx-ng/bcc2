SuperStrict

Extern
	Global NativeCounter:Int = "bcc2_native_counter"
	Global NativeBuffer:Byte Ptr = "bcc2_native_buffer"
	Global NativeCallback:Int(left:Int, right:Int) = "bcc2_native_callback"
End Extern

Function NativeReplacement:Int(left:Int, right:Int)
	Return left - right
End Function

Global NativeResult:Int = NativeCounter
Global NativeCallbackResult:Int = NativeCallback(20, 22)
NativeCounter = NativeResult + 1
NativeBuffer = 0
NativeCallback = NativeReplacement
NativeCallbackResult = NativeCallback(44, 2)
