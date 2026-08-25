SuperStrict

Framework BRL.StandardIO

Import BRL.Sequence

Global receiverFactoryCalls:Int

Interface IBoundTransform
	Method Apply:Int(value:Int)
End Interface

Type TBoundBase Implements IBoundTransform
	Field offset:Int

	Method New(offset:Int)
		Self.offset = offset
	End Method

	Method Apply:Int(value:Int)
		Return value + offset
	End Method

	Method MakeImplicit:Closure<Int(value:Int)>()
		Return Apply
	End Method

	Method AddTo(value:Int Var)
		value :+ offset
	End Method

	Method Wrap:Int[](value:Int)
		Return [value, value + offset]
	End Method

	Method Convert:Int(value:Int)
		Return value + offset
	End Method

	Method Convert:String(value:String)
		Return value + "-converted"
	End Method

	Method Fail:Int(value:Int)
		Throw "bound failure"
	End Method
End Type

Type TBoundDerived Extends TBoundBase
	Method Apply:Int(value:Int) Override
		Return value + offset + 1
	End Method
End Type

Type TBoundBox<T>
	Field suffix:T

	Method Join:T(value:T)
		Return value + suffix
	End Method

	Method BoundJoin:Closure<T(value:T)>()
		Return Join
	End Method
End Type

Function BindBox<T>:Closure<T(value:T)>(box:TBoundBox<T>)
	Return box.Join
End Function

Function MakeReceiver:TBoundBase()
	receiverFactoryCalls :+ 1
	Return New TBoundDerived(5)
End Function

Function InvokeObserved:Int(callback:Closure<Int(value:Int)>, observedFactoryCalls:Int)
	If observedFactoryCalls <> 1 Then Throw "bound Method receiver evaluation was not sequenced before the following argument"
	Return callback(36)
End Function

Local apply:Closure<Int(value:Int)> = MakeReceiver().Apply
If receiverFactoryCalls <> 1 Then Throw "bound Method receiver was evaluated more than once"
If apply(36) <> 42 Then Throw "bound Method lost virtual dispatch"
receiverFactoryCalls = 0
If InvokeObserved(MakeReceiver().Apply, receiverFactoryCalls) <> 42 Then Throw "bound Method call-argument evaluation failed"

Local concrete:TBoundBase = New TBoundBase(2)
Local throughInterface:IBoundTransform = concrete
Local interfaceApply:Closure<Int(value:Int)> = throughInterface.Apply
If interfaceApply(40) <> 42 Then Throw "bound Interface Method lost interface dispatch"

Local implicitApply:Closure<Int(value:Int)> = concrete.MakeImplicit()
If implicitApply(40) <> 42 Then Throw "implicit Self Method reference failed"

Local addTo:Closure<(value:Int Var)> = concrete.AddTo
Local changed:Int = 40
addTo(changed)
If changed <> 42 Then Throw "bound Method Var parameter ABI failed"

Local wrap:Closure<Int[](value:Int)> = concrete.Wrap
Local wrapped:Int[] = wrap(40)
If wrapped.length <> 2 Or wrapped[0] <> 40 Or wrapped[1] <> 42 Then Throw "bound Method managed return failed"

Local convert:Closure<String(value:String)> = concrete.Convert
If convert("bound") <> "bound-converted" Then Throw "target Closure did not select the bound Method overload"

Local retained:TBoundBase = New TBoundBase(2)
Local retainedApply:Closure<Int(value:Int)> = retained.Apply
retained = Null
GCCollect()
If retainedApply(40) <> 42 Then Throw "bound Method Closure did not retain its receiver"

?debug
Local missing:TBoundBase
Local missingApply:Closure<Int(value:Int)> = missing.Apply
Local caughtMissingReceiver:Int
Try
	missingApply(1)
Catch problem:Object
	caughtMissingReceiver = True
End Try
If Not caughtMissingReceiver Then Throw "bound Method invocation skipped the debug Null receiver check"
?

Local box:TBoundBox<String> = New TBoundBox<String>
box.suffix = "-bound"
Local join:Closure<String(value:String)> = box.Join
If join("generic") <> "generic-bound" Then Throw "constructed generic Type Method reference failed"
Local genericJoin:Closure<String(value:String)> = BindBox<String>(box)
If genericJoin("generic-routine") <> "generic-routine-bound" Then Throw "bound Method reference inside a generic routine failed"
Local genericSelfJoin:Closure<String(value:String)> = box.BoundJoin()
If genericSelfJoin("generic-self") <> "generic-self-bound" Then Throw "implicit Self bound Method reference inside a generic Type failed"

Local caught:String
Local fail:Closure<Int(value:Int)> = concrete.Fail
Try
	fail(1)
Catch message:String
	caught = message
End Try
If caught <> "bound failure" Then Throw "bound Method exception did not propagate unchanged"

Local selected:Int = Sequence<Int>.FromArray([1, 2, 3, 4]).Filter(concrete.Apply).Count()
If selected <> 4 Then Throw "bound Method reference did not compose with Sequence fusion"

Print "bound-method-reference-ok"
