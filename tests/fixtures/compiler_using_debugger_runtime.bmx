SuperStrict

Framework BRL.StandardIO

Global closeCount:Int

Type TUsingDebugResource Implements ICloseable
	Field throwOnClose:Int

	Method Close()
		closeCount :+ 1
		If throwOnClose Then Throw "close"
	End Method
End Type

Function ReturnFromUsing:Int()
	Using
		Local resource:TUsingDebugResource = New TUsingDebugResource
	Do
		Return 7
	End Using
End Function

Function CompleteUsing:Int()
	Local result:Int
	Using
		Local resource:TUsingDebugResource = New TUsingDebugResource
	Do
		result = 11
	End Using
	Return result
End Function

Function SuppressCloseFailure:Int()
	Using
		Local resource:TUsingDebugResource = New TUsingDebugResource
	Do
		resource.throwOnClose = True
		Return 13
	End Using
End Function

Function PropagateBodyFailure:Int()
	Try
		Using
			Local resource:TUsingDebugResource = New TUsingDebugResource
		Do
			Throw "body"
		End Using
	Catch message:String
		Return message = "body"
	End Try
End Function

Function ReturnFromNestedUsing:Int()
	Using
		Local outer:TUsingDebugResource = New TUsingDebugResource
	Do
		Using
			Local inner:TUsingDebugResource = New TUsingDebugResource
		Do
			Return 17
		End Using
	End Using
End Function

Local resultA:Int = ReturnFromUsing()
Local resultB:Int = CompleteUsing()
Local resultC:Int = SuppressCloseFailure()
Local resultD:Int = PropagateBodyFailure()
Local resultE:Int = ReturnFromNestedUsing()
Print resultA + ":" + resultB + ":" + resultC + ":" + resultD + ":" + resultE + ":" + closeCount
