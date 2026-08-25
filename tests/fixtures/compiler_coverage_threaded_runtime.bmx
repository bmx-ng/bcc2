SuperStrict

Framework BRL.StandardIO
Import BRL.Threads

Const WorkerCount:Int = 4
Const InvocationsPerWorker:Int = 250

Function GenericIdentity<T>:T(value:T)
	Return value
End Function

Function Worker:Object(data:Object)
	Local invoke:Closure<Int(value:Int)> = Function(value:Int)
		Return GenericIdentity<Int>(value) + 1
	End Function

	For Local index:Int = 0 Until InvocationsPerWorker
		If invoke(index) <> index + 1 Then Throw "threaded Closure mismatch"
	Next
	Return Null
End Function

Local workers:TThread[] = New TThread[WorkerCount]
For Local index:Int = 0 Until workers.length
	workers[index] = CreateThread(Worker, Null)
Next
For Local worker:TThread = EachIn workers
	WaitThread(worker)
Next

Try
	Throw "caught coverage exception"
Catch message:String
	If message <> "caught coverage exception" Then Throw message
End Try

Print "threaded-coverage-ok"
