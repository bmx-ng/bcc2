SuperStrict

Framework BRL.StandardIO

Function MakeFactorial:Closure<Long(value:Int)>()
	Local factorial:Closure<Long(value:Int)>
	factorial = Function(value:Int)
		If value <= 1 Then Return 1
		Return value * factorial(value - 1)
	End Function
	Return factorial
End Function

Function MakeEven:Closure<Int(value:Int)>()
	Local isEven:Closure<Int(value:Int)>
	Local isOdd:Closure<Int(value:Int)>
	isEven = Function(value:Int)
		If value = 0 Then Return True
		Return isOdd(value - 1)
	End Function
	isOdd = Function(value:Int)
		If value = 0 Then Return False
		Return isEven(value - 1)
	End Function
	Return isEven
End Function

Local factorial:Closure<Long(value:Int)> = MakeFactorial()
Local isEven:Closure<Int(value:Int)> = MakeEven()
If factorial(10) <> 3628800 Then Throw "recursive Closure failed"
If isEven(1001) Or Not isEven(1000) Then Throw "mutually recursive Closures failed"
Print "recursive-ok"
