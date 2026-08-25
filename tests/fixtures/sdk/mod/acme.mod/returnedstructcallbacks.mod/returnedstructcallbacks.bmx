SuperStrict
Module acme.returnedstructcallbacks

Function Increment:Int(value:Int Var)
	value = value + 1
	Return value
End Function

Struct SReturnedCallbacks
	Method Choose:Int(value:Int Var)(enabled:Int)
		If enabled Then Return Increment
		Return Null
	End Method

	Function Pick:Int(value:Int Var)(enabled:Int)
		If enabled Then Return Increment
		Return Null
	End Function
End Struct
