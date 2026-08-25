SuperStrict

Framework BRL.StandardIO

Type TLocalRoutineBox<T>
	Method Sum:Int(limit:Int)
		Function Accumulate:Int(value:Int)
			Local total:Int
			For Local index:Int = 1 To value
				total :+ index
			Next
			Return total
		End Function

		Return Accumulate(limit)
	End Method

	Method Factorial:Int(value:Int)
		Function Factor:Int(input:Int) Inline
			If input <= 1 Then Return 1
			Return input * Factor(input - 1)
		End Function

		Return Factor(value)
	End Method

	Method IsEven:Int(value:Int)
		Function Even:Int(input:Int)
			If input = 0 Then Return True
			Return Odd(input - 1)
		End Function

		Function Odd:Int(input:Int)
			If input = 0 Then Return False
			Return Even(input - 1)
		End Function

		Return Even(value)
	End Method
End Type

Local box:TLocalRoutineBox<String> = New TLocalRoutineBox<String>
If box.Sum(5) <> 15 Then RuntimeError "multi-statement local routine"
If box.Factorial(6) <> 720 Then RuntimeError "recursive local routine"
If Not box.IsEven(12) Or box.IsEven(9) Then RuntimeError "mutually recursive local routines"

Print "local-routines-ok"
