SuperStrict

Framework BRL.StandardIO
Import "compiler_debugger_capture_stub.c"

Function MakeOrdinary:Closure<Int()>(initial:Int)
	Local count:Int = initial
	Return Function()
		count :+ 1
		DebugStop
		Throw "ordinary failure"
	End Function
End Function

Function MakeNested:Closure<Int()>(initial:Int)
	Local parentValue:Int = initial
	Local factory:Closure<Closure<Int()>()> = Function()
		Local childValue:Int = 2
		Return Function()
			parentValue :+ 1
			childValue :+ 2
			DebugStop
			Throw "nested failure"
		End Function
	End Function
	Return factory()
End Function

Function MakeGeneric<T>:Closure<Int()>(initial:Int)
	Local genericValue:Int = initial
	Return Function()
		genericValue :+ 1
		DebugStop
		Throw "generic failure"
	End Function
End Function

Local ordinaryCaught:Int
Try
	MakeOrdinary(40)()
Catch message:String
	ordinaryCaught = message = "ordinary failure"
End Try
Print "ordinary-caught=" + ordinaryCaught

Local nestedCaught:Int
Try
	MakeNested(10)()
Catch message:String
	nestedCaught = message = "nested failure"
End Try
Print "nested-caught=" + nestedCaught

Local genericCaught:Int
Try
	MakeGeneric<String>(90)()
Catch message:String
	genericCaught = message = "generic failure"
End Try
Print "generic-caught=" + genericCaught
