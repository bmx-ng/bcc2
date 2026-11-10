SuperStrict

Struct SBoundaryVector<T>
	Field x:T
	Field y:T

	Method Operator +:SBoundaryVector<T>(other:SBoundaryVector<T>)
		Local result:SBoundaryVector<T>
		result.x = x + other.x
		result.y = y + other.y
		Return result
	End Method

	Method Operator *:SBoundaryVector<T>(scale:T)
		Local result:SBoundaryVector<T>
		result.x = x * scale
		result.y = y * scale
		Return result
	End Method

	Method AddTwice:SBoundaryVector<T>(other:SBoundaryVector<T>)
		Return Self + other + other
	End Method

	Method Scaled:SBoundaryVector<T>(scale:T)
		Return Self * scale
	End Method
End Struct
