SuperStrict
Module acme.returnedcallbacks

Function Increment:Int(value:Int Var)
	value = value + 1
	Return value
End Function

Function Choose:Int(value:Int Var)(enabled:Int)
	If enabled Then Return Increment
	Return Null
End Function
