SuperStrict

Module Bcc2ScaleTest.Graph

Type TScaleBox<T>
	Field value:T

	Method Read:T()
		Return value
	End Method
End Type

Function ScaleStage9<T>:T(value:T)
	Return value
End Function

Function ScaleStage8<T>:T(value:T)
	Return ScaleStage9<T>(value)
End Function

Function ScaleStage7<T>:T(value:T)
	Return ScaleStage8<T>(value)
End Function

Function ScaleStage6<T>:T(value:T)
	Return ScaleStage7<T>(value)
End Function

Function ScaleStage5<T>:T(value:T)
	Return ScaleStage6<T>(value)
End Function

Function ScaleStage4<T>:T(value:T)
	Return ScaleStage5<T>(value)
End Function

Function ScaleStage3<T>:T(value:T)
	Return ScaleStage4<T>(value)
End Function

Function ScaleStage2<T>:T(value:T)
	Return ScaleStage3<T>(value)
End Function

Function ScaleStage1<T>:T(value:T)
	Return ScaleStage2<T>(value)
End Function

Function ScaleStage0<T>:T(value:T)
	Return ScaleStage1<T>(value)
End Function
