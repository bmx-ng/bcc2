SuperStrict

Framework BRL.StandardIO

Local thin:Int(value:Int) = Function(value:Int)
	Return value + 1
End Function

Local offset:Int = 40
Local managed:Closure<Int(value:Int)> = Function(value:Int)
	Return value + offset
End Function

Function MakeNested:Closure<Closure<Int(value:Int)>()>()
	Return Function()
		Return Function(value:Int)
			Return value + 2
		End Function
	End Function
End Function

Function InvokeLoop:Int()
	Local total:Int
	For Local index:Int = 0 Until 3
		Local action:Closure<Int()> = Function()
			Return index
		End Function
		total :+ action()
	Next
	Return total
End Function

Local fail:Closure<()> = Function()
	Throw "coverage throw"
End Function

Local caught:Int
Try
	fail()
Catch message:String
	If message = "coverage throw" Then caught = True
End Try

Local factory:Closure<Closure<Int(value:Int)>()> = MakeNested()
Local nested:Closure<Int(value:Int)> = factory()
If thin(41) <> 42 Or managed(2) <> 42 Or nested(40) <> 42 Or InvokeLoop() <> 3 Or Not caught Then Throw "callable coverage mismatch"

Print "callable-coverage-ok"
