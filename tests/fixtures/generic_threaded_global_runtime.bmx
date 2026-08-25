SuperStrict

Framework BRL.StandardIO
Import BRL.Reflection
Import BRL.Threads

Global SeedCalls:Int
Global RetryFailureBudget:Int
Global RetryFirstAttempts:Int
Global RetrySecondAttempts:Int
Global RetryDerivedAttempts:Int

Function NextThreadSeed:Int()
	Return AtomicAdd(SeedCalls, 1) + 1
End Function

Function InitializeRetryFirst:Int()
	AtomicAdd(RetryFirstAttempts, 1)
	Return 11
End Function

Function InitializeRetrySecond:Int()
	AtomicAdd(RetrySecondAttempts, 1)
	If AtomicSwap(RetryFailureBudget, 0) > 0 Then Throw "generic-tls-retry"
	Return 22
End Function

Function InitializeRetryDerived:Int()
	AtomicAdd(RetryDerivedAttempts, 1)
	Return 3
End Function

Type TThreadState<T> { reflect entity="generic-tls" }
	ThreadedGlobal Seed:Int = NextThreadSeed() { reflect category="tls" }
	ThreadedGlobal Value:T
	ThreadedGlobal Text:String
	ThreadedGlobal Values:Int[]
	ThreadedGlobal Reference:Object
	ThreadedGlobal Callback:Closure<Int()>

	Method ReadSeed:Int()
		Return Seed
	End Method

	Method Read:T()
		Return Value
	End Method

	Method Write(nextValue:T)
		Value = nextValue
	End Method

	Method ManagedDefaultsOkay:Int()
		Return Text = "" And Values.length = 0 And Reference = Null And Callback = Null
	End Method
End Type

Type TRetryThreadBase<T>
	ThreadedGlobal First:Int = InitializeRetryFirst()
	ThreadedGlobal Second:Int = InitializeRetrySecond()

	Method ReadBase:Int()
		Return First + Second
	End Method
End Type

Type TRetryThreadState<T> Extends TRetryThreadBase<T>
	ThreadedGlobal Third:Int = InitializeRetryDerived()

	Method Read:Int()
		Return ReadBase() + Third
	End Method
End Type

Type TThreadBase<T>
	ThreadedGlobal First:Int = 40
	ThreadedGlobal Second:Int = First + 1

	Method ReadBase:Int()
		Return Second
	End Method
End Type

Type TThreadDerived<T> Extends TThreadBase<T>
	ThreadedGlobal Derived:Int = Second + 1

	Method ReadDerived:Int()
		Return Derived
	End Method
End Type

Struct SThreadState<T>
	ThreadedGlobal Value:T

	Method Read:T()
		Return Value
	End Method

	Method Write(nextValue:T)
		Value = nextValue
	End Method
End Struct

Type TThreadResult
	Field seedInt:Int
	Field seedString:Int
	Field seedRepeated:Int
	Field intDefault:Int
	Field stringDefault:String
	Field managedDefaultsOkay:Int
	Field inheritedValue:Int
	Field structDefault:String
	Field intAfterWrite:Int
	Field stringAfterWrite:String
End Type

Type TRetryResult
	Field caught:Int
	Field value:Int
End Type

Function Worker:Object(data:Object)
	Local result:TThreadResult = TThreadResult(data)
	Local intState:TThreadState<Int> = New TThreadState<Int>
	Local stringState:TThreadState<String> = New TThreadState<String>
	Local derived:TThreadDerived<String> = New TThreadDerived<String>
	Local structState:SThreadState<String>

	result.seedInt = intState.ReadSeed()
	result.seedString = stringState.ReadSeed()
	result.seedRepeated = intState.ReadSeed()
	result.intDefault = intState.Read()
	result.stringDefault = stringState.Read()
	result.managedDefaultsOkay = stringState.ManagedDefaultsOkay()
	result.inheritedValue = derived.ReadDerived()
	result.structDefault = structState.Read()

	intState.Write(71)
	stringState.Write("worker")
	structState.Write("struct-worker")
	result.intAfterWrite = intState.Read()
	result.stringAfterWrite = stringState.Read()
	If structState.Read() <> "struct-worker" Then Throw "generic Struct TLS write failed"
	Return Null
End Function

Function RetryWorker:Object(data:Object)
	Local result:TRetryResult = TRetryResult(data)
	Local state:TRetryThreadState<String>
	Try
		state = New TRetryThreadState<String>
		state.Read()
	Catch message:String
		If message = "generic-tls-retry" Then result.caught = True
	End Try
	state = New TRetryThreadState<String>
	result.value = state.Read()
	Return Null
End Function

Local intState:TThreadState<Int> = New TThreadState<Int>
Local stringState:TThreadState<String> = New TThreadState<String>
Local derived:TThreadDerived<String> = New TThreadDerived<String>
Local structState:SThreadState<String>
Local retryState:TRetryThreadState<String> = New TRetryThreadState<String>

If intState.ReadSeed() <= 0 Or stringState.ReadSeed() <= 0 Then Throw "main generic TLS initializer did not run"
If intState.ReadSeed() = stringState.ReadSeed() Then Throw "closed generic TLS initializers shared state"
If Not stringState.ManagedDefaultsOkay() Or stringState.Read() <> "" Then Throw "main managed generic TLS defaults were invalid"
If derived.ReadBase() <> 41 Or derived.ReadDerived() <> 42 Then Throw "main inherited generic TLS order failed"
If structState.Read() <> "" Then Throw "main generic Struct TLS default was invalid"
If retryState.Read() <> 36 Then Throw "main retry specialization initialization failed"

intState.Write(31)
stringState.Write("main")
structState.Write("struct-main")

For Local index:Int = 0 Until 2
	Local result:TThreadResult = New TThreadResult
	Local thread:TThread = CreateThread(Worker, result)
	WaitThread(thread)
	If result.seedInt <= 0 Or result.seedString <= 0 Or result.seedInt = result.seedString Then Throw "worker generic TLS initializer did not run independently"
	If result.seedRepeated <> result.seedInt Then Throw "worker generic TLS initializer ran more than once"
	If result.intDefault <> 0 Or result.stringDefault <> "" Or Not result.managedDefaultsOkay Then Throw "worker generic TLS defaults were invalid"
	If result.inheritedValue <> 42 Then Throw "worker inherited generic TLS order failed"
	If result.structDefault <> "" Then Throw "worker generic Struct TLS default was invalid"
	If result.intAfterWrite <> 71 Or result.stringAfterWrite <> "worker" Then Throw "worker generic TLS mutation failed"
Next

' Canonical registration precedes the ordinary application initializer, which
' establishes SeedCalls as zero after the main-thread specialization pass. The
' two worker threads must therefore contribute exactly two closed values each.
If SeedCalls <> 4 Then Throw "generic TLS dynamic initializer count failed: " + SeedCalls
If intState.Read() <> 31 Or stringState.Read() <> "main" Or structState.Read() <> "struct-main" Then Throw "worker generic TLS mutation leaked into main"

' A failed worker-thread initializer resets only that closed specialization's
' per-thread guard. The next access reruns the complete declaration sequence.
RetryFailureBudget = 1
RetryFirstAttempts = 0
RetrySecondAttempts = 0
RetryDerivedAttempts = 0
Local retryResult:TRetryResult = New TRetryResult
Local retryThread:TThread = CreateThread(RetryWorker, retryResult)
WaitThread(retryThread)
If Not retryResult.caught Or retryResult.value <> 36 Then Throw "generic TLS initializer failure was not caught and retried"
If RetryFirstAttempts <> 2 Or RetrySecondAttempts <> 2 Then Throw "generic TLS retry did not repeat the complete declaration sequence"
If RetryDerivedAttempts <> 1 Then Throw "derived generic TLS initialized before its failed base or repeated after success"
If retryState.Read() <> 36 Then Throw "worker retry changed the main-thread specialization state"

' A method access refreshes the reflected TLS address for the executing thread.
intState.ReadSeed()
Local typeId:TTypeId = TTypeId.ForName("TThreadState<int>")
Local reflectedSeed:TGlobal = typeId.FindGlobal("Seed")
If Not reflectedSeed Or reflectedSeed.GetInt() <> intState.ReadSeed() Or reflectedSeed.MetaData("category") <> "tls" Then Throw "generic TLS reflection did not resolve the current thread"

Print "bcc2 generic ThreadedGlobal runtime ok"
