SuperStrict

Extern
	Function NativeStringLength:Int(value:String) = "bcc2_native_string_length"
	Global NativeString:String = "bcc2_native_string"
End Extern

Global Message:String = "native"
Global MessageLength:Int = NativeStringLength(Message)
NativeString = Message
