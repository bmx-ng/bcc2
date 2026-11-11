SuperStrict
Framework BRL.StandardIO

Function ReadUnsupported<T>:T(pointer:T Ptr)
	Return pointer[0]
End Function

Local value:String
Local pointer:String Ptr = Varptr value
Print ReadUnsupported<String>(pointer)
