SuperStrict

Module Bcc2GenericStructOperatorTest.Provider

Struct SModuleVector<T>
	Field x:T
	Field y:T

	Method Operator +:SModuleVector<T>(other:SModuleVector<T>)
		Local result:SModuleVector<T>
		result.x = x + other.x
		result.y = y + other.y
		Return result
	End Method

	Method Operator *:SModuleVector<T>(scale:T)
		Local result:SModuleVector<T>
		result.x = x * scale
		result.y = y * scale
		Return result
	End Method

	Method AddTwice:SModuleVector<T>(other:SModuleVector<T>)
		Return Self + other + other
	End Method

	Method Scaled:SModuleVector<T>(scale:T)
		Return Self * scale
	End Method
End Struct
