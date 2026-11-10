SuperStrict
Framework BRL.StandardIO

Function ReadAt<T>:T(pointer:T Ptr)
	Return pointer[0]
End Function

Local missing:Int Ptr
Print ReadAt<Int>(missing)
