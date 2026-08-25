SuperStrict

Framework BRL.StandardIO
Import BRL.Threads

ThreadedGlobal current:Int

Type TThreadState
	ThreadedGlobal value:Int

	Function Set(value:Int)
		TThreadState.value = value
	End Function

	Function Read:Int()
		Return TThreadState.value
	End Function
End Type

Function Worker:Object(data:Object)
	current = 22
	TThreadState.Set(33)
	If current <> 22 Or TThreadState.Read() <> 33 Then Throw "worker TLS mismatch"
	Return Null
End Function

current = 11
TThreadState.Set(12)
Local worker:TThread = CreateThread(Worker, Null)
WaitThread(worker)
If current <> 11 Or TThreadState.Read() <> 12 Then Throw "main TLS mismatch"
Print "bcc2 debug ThreadedGlobal runtime ok"
