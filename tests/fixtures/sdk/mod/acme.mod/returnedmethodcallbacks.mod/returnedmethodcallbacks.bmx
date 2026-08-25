SuperStrict
Module acme.returnedmethodcallbacks

Function Increment:Int(value:Int Var)
	value = value + 1
	Return value
End Function

Type TReturnedBase
	Method Choose:Int(value:Int Var)(enabled:Int)
		If enabled Then Return Increment
		Return Null
	End Method
End Type

Type TReturnedDerived Extends TReturnedBase
	Method Choose:Int(value:Int Var)(enabled:Int) Override
		Return Super.Choose(enabled)
	End Method
End Type

Interface IReturnedChooser
	Method Choose:Int(value:Int Var)(enabled:Int)
End Interface

Type TReturnedImplementation Implements IReturnedChooser
	Method Choose:Int(value:Int Var)(enabled:Int)
		If enabled Then Return Increment
		Return Null
	End Method
End Type

Type TReturnedFunctions
	Function Choose:Int(value:Int Var)(enabled:Int)
		If enabled Then Return Increment
		Return Null
	End Function
End Type

Function CreateReturned:TReturnedBase()
	Return New TReturnedDerived
End Function

Function CreateReturnedImplementation:TReturnedImplementation()
	Return New TReturnedImplementation
End Function
