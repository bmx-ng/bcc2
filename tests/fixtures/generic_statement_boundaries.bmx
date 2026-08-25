SuperStrict

Framework BRL.StandardIO

Private
Global loopIndex:Int
Public

Global markOrder:Int
Global catchCleanup:Int

Function MarkValue:Int(value:Int) { nomangle }
	markOrder = markOrder * 10 + value
	Return value
End Function

Function IncrementValue:Int(value:Int) { nomangle }
	Return value + 1
End Function

Function ExerciseStatements<T>:Int(cleanup:Int Var)
	Local values:Int[] = [MarkValue(2), MarkValue(3)]
	Local result:Int
	Select values[0] + values[1]
		Case 5
			result = 5
		Default
			result = -1
	End Select
	For loopIndex = 0 Until 2
		values[loopIndex] :+ 1
	Next
	For values[0] = 0 Until 2
	Next
	#Outer
	While True
		Try
			Exit Outer
		Finally
			cleanup :+ 1
		End Try
	Wend
	Return result
End Function

Function ExerciseUsing<T>:Int(stream:TStream)
	#Outer
	While True
		Using
			Local owned:TStream = stream
		Do
			Exit Outer
		End Using
	Wend
	Return 1
End Function

Function InvokeCallable<T>:Int(callback:Int(value:Int), value:Int)
	Return callback(value)
End Function

Function ExerciseCatch<T>:Int(shouldThrow:Int)
	Try
		If shouldThrow Then Throw "problem"
		Return 0
	Catch message:String
		Return 40
	Finally
		catchCleanup :+ 1
	End Try
End Function

Function ReturnThroughFinally<T>:T(value:T, cleanup:Int Var)
	Try
		Return value
	Finally
		cleanup :+ 10
	End Try
End Function

Function ContinueThroughFinally<T>:Int(cleanup:Int Var)
	Local cursor:Int
	While cursor < 3
		cursor :+ 1
		Try
			If cursor < 3
				Continue
			End If
		Finally
			cleanup :+ 1
		End Try
	Wend
	Return cursor
End Function

Function NestedExceptionCleanup<T>:Int(cleanup:Int Var)
	Try
		Try
			Throw "nested"
		Finally
			cleanup = cleanup * 10 + 1
		End Try
	Catch message:String
		If message <> "nested" Then Throw message
		cleanup = cleanup * 10 + 2
	Finally
		cleanup = cleanup * 10 + 3
	End Try
	Return 1
End Function

Function ExerciseData<T>:Int()
	#values
	DefData 42, "answer"
	Local value:Int
	Local text:String
	RestoreData values
	ReadData value, text
	If text <> "answer" Then Return -1
	Return value
End Function

Local cleanup:Int
Local result:Int = ExerciseStatements<String>(cleanup)
result :+ ExerciseUsing<String>(Null)
result :+ InvokeCallable<String>(IncrementValue, 41)
result :+ ExerciseCatch<String>(True)
result :+ ExerciseCatch<String>(False)
result :+ ExerciseData<String>()
result :+ ReturnThroughFinally<Int>(7, cleanup)
If ReturnThroughFinally<String>("returned", cleanup) <> "returned" Then Throw "generic Return value was not retained across Finally"
result :+ ContinueThroughFinally<Float>(cleanup)
Local nestedCleanup:Int
result :+ NestedExceptionCleanup<Double>(nestedCleanup)
If result <> 141 Or cleanup <> 24 Or nestedCleanup <> 123 Or markOrder <> 23 Or loopIndex <> 2 Or catchCleanup <> 2 Then Throw "generic statement boundary regression"
Print "bcc2 generic statement boundaries ok"
