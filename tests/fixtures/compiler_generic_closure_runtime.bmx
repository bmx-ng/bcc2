SuperStrict

Framework BRL.StandardIO

Struct SGenericCapturedShape<T>
	Field value:T
	Field marker:String
End Struct

Struct SGenericClosureHistory<T>
	Field values:T[]
	Field cursor:Int
End Struct

Function RememberGenericStruct<T>:Closure<T()>(value:T)
	Local shape:SGenericCapturedShape<T>
	shape.value = value
	shape.marker = "managed"
	Return Function()
		If shape.marker <> "managed" Then Throw "generic Struct managed field was not retained"
		Return shape.value
	End Function
End Function

Function RememberGenericCatch<T>:Closure<String()>(value:String)
	Try
		Throw value
	Catch problem:String
		Return Function()
			Return problem
		End Function
	End Try
End Function

Function RememberGenericNestedCatch<T>:Closure<String()>()
	Try
		Throw "outer"
	Catch outerProblem:String
		Try
			Throw "inner"
		Catch innerProblem:String
			Return Function()
				Return outerProblem + "-" + innerProblem
			End Function
		End Try
	End Try
End Function

Function Apply<T, R>:R(value:T, operation:Closure<R(value:T)>)
	Return operation(value)
End Function

Function AppendOne<T>:T[](values:T[], value:T)
	values :+ [value]
	Return values
End Function

Function BindGenericClosure<T, R>:Closure<R()>(value:T, operation:Closure<R(value:T)>)
	Return Function()
		Return operation(value)
	End Function
End Function

Function BindAllGenericClosures<T, R>:Closure<R()>[](values:T[], operation:Closure<R(value:T)>)
	Local result:Closure<R()>[] = New Closure<R()>[values.length]
	For Local index:Int = 0 Until values.length
		result[index] = BindGenericClosure<T, R>(values[index], operation)
	Next
	Return result
End Function

Function MakeGenericClosureHistory<T>:Closure<T(value:T)>(initial:T)
	Local state:SGenericClosureHistory<T>
	state.values = [initial]
	Return Function(value:T)
		state.values :+ [value]
		state.cursor :+ 1
		Return state.values[state.cursor]
	End Function
End Function

Function Identity<T>:Closure<T(value:T)>()
	Return Function(value:T)
		Return value
	End Function
End Function

Function Update<T>(value:T Var, operation:Closure<(value:T Var)>)
	operation(value)
End Function

Function Thrower<T>:Closure<()>()
	Return Function()
		Throw "generic closure throw"
	End Function
End Function

Function Remember<T>:Closure<T()>(value:T)
	Return Function()
		Return value
	End Function
End Function

Function Replacer<T>:Closure<T(nextValue:T)>(initial:T)
	Local current:T = initial
	Return Function(nextValue:T)
		Local previous:T = current
		current = nextValue
		Return previous
	End Function
End Function

Global genericProducedNestedSelf:Closure<Int()>

Function MakeGenericNested<T>:Closure<Closure<Int()>()>(initial:Int)
	Local parentValue:Int = initial
	Return Function()
		Local childValue:Int = 10
		Return Function()
			parentValue :+ 1
			childValue :+ 2
			Return parentValue + childValue
		End Function
	End Function
End Function

Global genericIncrement:Closure<Int()>
Global genericCurrent:Closure<Int()>
Global genericOffset:Closure<Int(count:Int)>
Global genericLoopFirst:Closure<Int()>
Global genericLoopSecond:Closure<Int()>
Global genericLoopNested00:Closure<Int()>
Global genericLoopNested01:Closure<Int()>
Global genericLoopNested10:Closure<Int()>
Global genericLoopNested11:Closure<Int()>
Global genericWhileFirst:Closure<Int()>
Global genericWhileSecond:Closure<Int()>
Global genericRepeatFirst:Closure<Int()>
Global genericRepeatSecond:Closure<Int()>
Global genericLoopCatchFirst:Closure<String()>
Global genericLoopCatchSecond:Closure<String()>

Function MakeGenericLoopCatch<T>()
	For Local index:Int = 0 Until 2
		Try
			Throw "caught"
		Catch problem:String
			Local action:Closure<String()> = Function()
				Return problem + "-" + index
			End Function
			If index = 0 Then genericLoopCatchFirst = action Else genericLoopCatchSecond = action
		End Try
	Next
End Function

Function MakeGenericLoop<T>(values:T[])
	Local ordinal:Int
	Local shared:Int = 100
	For Local value:T = EachIn values
		Local captured:Int = ordinal
		Local action:Closure<Int()> = Function()
			shared :+ 1
			captured :+ 1
			Return shared + captured
		End Function
		If ordinal = 0 Then genericLoopFirst = action Else genericLoopSecond = action
		ordinal :+ 1
	Next
End Function

Function RememberGenericLoopLast<T>:Closure<T()>(values:T[])
	Local result:Closure<T()>
	For Local value:T = EachIn values
		result = Function()
			Return value
		End Function
	Next
	Return result
End Function

Function MakeGenericNestedLoop<T>(marker:T)
	For Local outer:Int = 0 Until 2
		For Local inner:Int = 0 Until 2
			Local action:Closure<Int()> = Function()
				outer :+ 1
				inner :+ 1
				Return outer * 10 + inner
			End Function
			If outer = 0 Then
				If inner = 0 Then genericLoopNested00 = action Else genericLoopNested01 = action
			Else
				If inner = 0 Then genericLoopNested10 = action Else genericLoopNested11 = action
			End If
		Next
	Next
End Function

Function MakeGenericConditionalLoops<T>(marker:T)
	Local cursor:Int
	While cursor < 2
		Local value:Int = cursor
		Local action:Closure<Int()> = Function()
			value :+ 10
			Return value
		End Function
		If cursor = 0 Then genericWhileFirst = action Else genericWhileSecond = action
		cursor :+ 1
	Wend
	cursor = 0
	Repeat
		Local value:Int = cursor * 10
		Local action:Closure<Int()> = Function()
			value :+ 1
			Return value
		End Function
		If cursor = 0 Then genericRepeatFirst = action Else genericRepeatSecond = action
		cursor :+ 1
	Until cursor = 2
End Function

Function MakeGenericPair<T>(initial:Int)
	Local count:Int = initial
	Local offset:Int = 2
	genericIncrement = Function()
		count :+ 1
		Return count
	End Function
	genericCurrent = Function()
		Return count
	End Function
	genericOffset = Function(count:Int)
		Return count + offset
	End Function
End Function

Type TClosureFactory<T>
	Method Remember:Closure<T()>(value:T)
		Return Function()
			Return value
		End Function
	End Method
End Type

Type TGenericSelfFactory<T>
	Field value:T
	Field offset:Int

	Method New(value:T)
		Self.value = value
	End Method

	Method Read:T()
		Return value
	End Method

	Method RememberSelf:Closure<T()>()
		Return Function()
			Return Self.Read()
		End Function
	End Method

	Method RememberNestedSelf:Closure<()>()
		Return Function()
			Local childValue:Int = 1
			genericProducedNestedSelf = Function()
				Return Self.offset + childValue
			End Function
		End Function
	End Method
End Type

Type TGenericSuperBase<T>
	Field baseValue:T

	Method Read:T()
		Return baseValue
	End Method
End Type

Type TGenericSuperDerived<T> Extends TGenericSuperBase<T>
	Field derivedValue:T

	Method Read:T()
		Return derivedValue
	End Method

	Method RememberBase:Closure<T()>()
		Return Function()
			Return Super.Read()
		End Function
	End Method
End Type

Type TClosureBox<T>
	Field value:T

	Method New(value:T)
		Self.value = value
	End Method

	Method Get:T()
		Return value
	End Method
End Type

Global computedReceiverCalls:Int

Type TComputedReceiverTarget
	Method Read:Int()
		Return 42
	End Method
End Type

Function MakeComputedReceiver:TComputedReceiverTarget()
	computedReceiverCalls :+ 1
	Return New TComputedReceiverTarget
End Function

Function ReadComputedReceiver<T>:Int()
	Return MakeComputedReceiver().Read()
End Function

Type TApplicationPayload
	Field value:Int

	Method New(value:Int)
		Self.value = value
	End Method
End Type

Local increment:Closure<Int(value:Int)> = Function(value:Int)
	Return value + 1
End Function
If ReadComputedReceiver<String>() <> 42 Or computedReceiverCalls <> 1 Then Throw "generic computed method receiver was evaluated more than once"
If Apply<Int, Int>(41, increment) <> 42 Then Throw "generic Closure argument failed"
Local box:TClosureBox<Closure<Int(value:Int)> > = New TClosureBox<Closure<Int(value:Int)> >
box.value = increment
Local boxed:Closure<Int(value:Int)> = box.Get()
If boxed(41) <> 42 Then Throw "Closure generic type argument failed"

Local applicationPayload:TApplicationPayload = New TApplicationPayload(41)
Local readApplicationPayload:Closure<Int(value:TApplicationPayload)> = Function(value:TApplicationPayload)
	Return value.value + 1
End Function
If Apply<TApplicationPayload, Int>(applicationPayload, readApplicationPayload) <> 42 Then Throw "application-local nominal generic Closure argument failed"
Local applicationPayloads:TApplicationPayload[] = AppendOne<TApplicationPayload>(New TApplicationPayload[0], applicationPayload)
If applicationPayloads.length <> 1 Or applicationPayloads[0] <> applicationPayload Then Throw "application-local nominal generic Array append failed"
Local boundApplicationPayloads:TApplicationPayload[] = [New TApplicationPayload(40), New TApplicationPayload(41), New TApplicationPayload(42)]
Local boundApplicationReaders:Closure<Int()>[] = BindAllGenericClosures<TApplicationPayload, Int>(boundApplicationPayloads, readApplicationPayload)
If boundApplicationReaders.length <> 3 Or boundApplicationReaders[0]() <> 41 Or boundApplicationReaders[1]() <> 42 Or boundApplicationReaders[2]() <> 43 Then Throw "generic Array of captured Closures failed"
Local genericClosureHistory:Closure<String(value:String)> = MakeGenericClosureHistory<String>("zero")
If genericClosureHistory("one") <> "one" Or genericClosureHistory("two") <> "two" Then Throw "captured generic Struct Array field mutation failed"

Local identityClosure:Closure<String(value:String)> = Identity<String>()
If identityClosure("source-free") <> "source-free" Then Throw "generic Closure literal failed"

Local rememberedText:Closure<String()> = Remember<String>("retained")
Local rememberedStruct:Closure<String()> = RememberGenericStruct<String>("struct-retained")
Local rememberedCatch:Closure<String()> = RememberGenericCatch<Int>("catch-retained")
Local rememberedNestedCatch:Closure<String()> = RememberGenericNestedCatch<Int>()
For Local allocationIndex:Int = 0 Until 1000
	Local pressure:String = "generic-allocation-" + allocationIndex
Next
GCCollect()
If rememberedText() <> "retained" Then Throw "generic captured parameter was not retained"
If rememberedStruct() <> "struct-retained" Then Throw "generic captured Struct value was not retained"
If rememberedCatch() <> "catch-retained" Then Throw "generic captured Catch value was not retained"
If rememberedNestedCatch() <> "outer-inner" Then Throw "generic nested Catch activation chain was not retained"

Local replaceValue:Closure<Int(nextValue:Int)> = Replacer<Int>(10)
If replaceValue(20) <> 10 Or replaceValue(30) <> 20 Then Throw "generic captured Local mutation failed"

Local genericNestedFactory:Closure<Closure<Int()>()> = MakeGenericNested<String>(10)
Local genericNestedFirst:Closure<Int()> = genericNestedFactory()
Local genericNestedSecond:Closure<Int()> = genericNestedFactory()
genericNestedFactory = Null
GCCollect()
If genericNestedFirst() <> 23 Then Throw "generic nested Closure did not retain parent and owned cells"
If genericNestedSecond() <> 24 Then Throw "generic nested Closure did not share its inherited parent cell"
If genericNestedFirst() <> 27 Then Throw "generic nested Closure child cells were copied or shared incorrectly"

MakeGenericLoop<String>(["first", "second"])
GCCollect()
If genericLoopFirst() <> 102 Or genericLoopSecond() <> 104 Then Throw "generic loop-scoped Closure captures were not fresh per iteration or did not retain shared outer state"
If genericLoopFirst() <> 105 Or genericLoopSecond() <> 107 Then Throw "generic loop-scoped Closure cells did not retain independent mutation"
Local genericLoopLast:Closure<String()> = RememberGenericLoopLast<String>(["first", "second"])
GCCollect()
If genericLoopLast() <> "second" Then Throw "generic EachIn header capture did not retain its managed value"
MakeGenericNestedLoop<String>("marker")
GCCollect()
If genericLoopNested00() <> 11 Or genericLoopNested01() <> 22 Or genericLoopNested10() <> 21 Or genericLoopNested11() <> 32 Then Throw "generic nested loops did not retain distinct managed environment chains"
MakeGenericConditionalLoops<String>("marker")
GCCollect()
If genericWhileFirst() <> 10 Or genericWhileSecond() <> 11 Then Throw "generic While captures were not fresh per iteration"
If genericRepeatFirst() <> 1 Or genericRepeatSecond() <> 11 Then Throw "generic Repeat captures were not fresh per iteration"
MakeGenericLoopCatch<String>()
GCCollect()
If genericLoopCatchFirst() <> "caught-0" Or genericLoopCatchSecond() <> "caught-1" Then Throw "generic Catch environments did not retain their per-iteration parent chain"

MakeGenericPair<String>(40)
If genericCurrent() <> 40 Or genericIncrement() <> 41 Or genericCurrent() <> 41 Then Throw "generic sibling Closures did not share their environment"
If genericOffset(10) <> 12 Then Throw "generic Closure parameter was confused with a sibling capture"

Local factory:TClosureFactory<String> = New TClosureFactory<String>
Local rememberedByMethod:Closure<String()> = factory.Remember("method-capture")
If rememberedByMethod() <> "method-capture" Then Throw "generic method Closure capture failed"

Local selfFactory:TGenericSelfFactory<String> = New TGenericSelfFactory<String>("generic-self")
Local rememberedSelf:Closure<String()> = selfFactory.RememberSelf()
selfFactory = Null
GCCollect()
If rememberedSelf() <> "generic-self" Then Throw "generic Closure did not retain captured Self"

Local nestedSelfFactory:TGenericSelfFactory<String> = New TGenericSelfFactory<String>("generic-self")
nestedSelfFactory.offset = 41
Local nestedSelfOuter:Closure<()> = nestedSelfFactory.RememberNestedSelf()
nestedSelfOuter()
Local nestedRememberedSelf:Closure<Int()> = genericProducedNestedSelf
nestedSelfFactory = Null
nestedSelfOuter = Null
GCCollect()
If nestedRememberedSelf() <> 42 Then Throw "generic nested Closure did not retain inherited Self"

Local superFactory:TGenericSuperDerived<String> = New TGenericSuperDerived<String>
superFactory.baseValue = "generic-base"
superFactory.derivedValue = "generic-derived"
Local rememberedBase:Closure<String()> = superFactory.RememberBase()
superFactory = Null
GCCollect()
If rememberedBase() <> "generic-base" Then Throw "generic Closure did not preserve captured Super dispatch"

Local replace:Closure<(value:Int Var)> = Function(value:Int Var)
	value = 42
End Function
Local changed:Int
Update<Int>(changed, replace)
If changed <> 42 Then Throw "generic Var Closure invocation failed"

Local fail:Closure<()> = Thrower<String>()
Try
	fail()
	Throw "generic Closure exception did not propagate"
Catch message:String
	If message <> "generic closure throw" Then Throw message
End Try

Print "generic-closure-ok"
