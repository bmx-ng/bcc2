SuperStrict

Framework BRL.StandardIO

Type TLocalRoutineBoundary<T>
	Field base:Int

	Method Compute:Int(value:Int)
		Local adjustment:Int = 1
		Function Add:Int(value:Int, adjustment:Int Var, base:Int, amount:Int = 1)
			adjustment :+ amount
			Return value + adjustment + base
		End Function
		Return Add(value, adjustment, base)
	End Method
End Type

Type TThreadedBoundary<T>
	ThreadedGlobal current:T

	Method Set(value:T)
		current = value
	End Method

	Method Get:T()
		Return current
	End Method
End Type

Type TAbstractBoundary Abstract
	Method Pick<T>:T(value:T) Abstract
End Type

Type TConcreteBoundary Extends TAbstractBoundary
	Method Pick<T>:T(value:T)
		Return value
	End Method
End Type

Local localRoutine:TLocalRoutineBoundary<String> = New TLocalRoutineBoundary<String>
localRoutine.base = 39
If localRoutine.Compute(1) <> 42 Then RuntimeError "local explicit-state/default parameter failed"

Local threadedInt:TThreadedBoundary<Int> = New TThreadedBoundary<Int>
Local threadedString:TThreadedBoundary<String> = New TThreadedBoundary<String>
threadedInt.Set(42)
threadedString.Set("tls")
If threadedInt.Get() <> 42 Or threadedString.Get() <> "tls" Then RuntimeError "canonical ThreadedGlobal specialization storage failed"

Local abstractValue:TAbstractBoundary = New TConcreteBoundary
If abstractValue.Pick<String>("abstract") <> "abstract" Then RuntimeError "abstract generic method dispatch failed"

Print "generic runtime boundary regression passed"
