SuperStrict
Module acme.varcallbacks

Function Increment:Int(value:Int Var)
	value = value + 1
	Return value
End Function

Global Active:Int(value:Int Var) = Increment

Type TVarCallbackHolder
	Field callback:Int(value:Int Var) = Increment

	Method Apply:Int(operation:Int(value:Int Var), value:Int Var)
		Return operation(value)
	End Method
End Type

Interface IVarCallback
	Method Apply:Int(operation:Int(value:Int Var), value:Int Var)
End Interface

Type TVarCallbackImplementation Implements IVarCallback
	Method Apply:Int(operation:Int(value:Int Var), value:Int Var)
		Return operation(value)
	End Method
End Type

Function CreateVarCallbackHolder:TVarCallbackHolder()
	Return New TVarCallbackHolder
End Function

Function CreateVarCallbackImplementation:TVarCallbackImplementation()
	Return New TVarCallbackImplementation
End Function
