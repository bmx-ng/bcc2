SuperStrict

Framework BRL.StandardIO
Import BRL.Threads
Import "compiler_debugger_capture_stub.c"

Function RaiseFailure()
	Local marker:Int = 7
	Throw "boom"
End Function

Function CatchFailure()
	Local caught:Int
	DebugStop
	Try
		RaiseFailure()
	Catch message:String
		caught = True
	End Try
	Print "caught=" + caught
End Function

Function Outer()
	Local outerMarker:Int = 11
	CatchFailure()
End Function

Function RethrowFailure()
	Try
		RaiseFailure()
	Catch message:String
		Throw message
	End Try
End Function

Function CatchRethrow()
	Local rethrown:Int
	DebugStop
	Try
		RethrowFailure()
	Catch message:String
		rethrown = True
	End Try
	Print "rethrown=" + rethrown
End Function

Function Worker:Object(data:Object)
	Local workerValue:Int = 99
	DebugStop
	Print "worker=" + workerValue
	Return Null
End Function

Outer()
CatchRethrow()
Local workerThread:TThread = CreateThread(Worker, Null)
WaitThread(workerThread)
