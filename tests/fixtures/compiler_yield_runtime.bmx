SuperStrict

Framework BRL.StandardIO
Import BRL.LinkedList

Global starts:Int
Global visits:Int
Global iteratorCloses:Int
Global iteratorCloseOrder:String
Global resourceCloses:Int
Global cleanupOrder:String
Global delegationStarts:Int

Function RecordCleanup(tag:String)
	If cleanupOrder.length Then cleanupOrder :+ ","
	cleanupOrder :+ tag
End Function

Struct TPair
	Field key:Int
	Field value:String
End Struct

Type TMarker
	Field value:Int
End Type

Interface IValue
	Method Value:Int()
End Interface

Type TValue Implements IValue
	Field value:Int
	Method Value:Int()
		Return value
	End Method
End Type

Type TTrackedIterator Implements ICloseableIterator<Int>
	Field value:Int
	Field last:Int
	Field throwAt:Int
	Field closeTag:String
	Field closed:Int

	Function Create:TTrackedIterator(last:Int, throwAt:Int = 0, closeTag:String = "")
		Local result:TTrackedIterator = New TTrackedIterator
		result.last = last
		result.throwAt = throwAt
		result.closeTag = closeTag
		Return result
	End Function

	Method MoveNext:Int() Override
		If closed Then Return False
		value :+ 1
		If throwAt And value = throwAt Then Throw "tracked iterator failure"
		Return value <= last
	End Method

	Method Current:Int() Override
		Return value
	End Method

	Method Close() Override
		If closed Then Return
		closed = True
		iteratorCloses :+ 1
		If closeTag.length Then
			If iteratorCloseOrder.length Then iteratorCloseOrder :+ ","
			iteratorCloseOrder :+ closeTag
			RecordCleanup(closeTag)
		End If
	End Method
End Type

Type TTrackedIterable Implements IIterable<Int>
	Field last:Int

	Function Create:TTrackedIterable(last:Int)
		Local result:TTrackedIterable = New TTrackedIterable
		result.last = last
		Return result
	End Function

	Method GetIterator:IIterator<Int>() Override
		Return TTrackedIterator.Create(last)
	End Method
End Type

Type TTrackedResource Implements ICloseable
	Field tag:String
	Field closed:Int
	Field throwOnClose:Int

	Method Close() Override
		If closed Then Throw "resource closed twice"
		closed = True
		resourceCloses :+ 1
		RecordCleanup(tag)
		If throwOnClose Then Throw "resource close failure"
	End Method
End Type

Function TrackedResource:TTrackedResource(tag:String, failCreation:Int = False, throwOnClose:Int = False)
	If failCreation Then Throw "resource creation failure"
	Local result:TTrackedResource = New TTrackedResource
	result.tag = tag
	result.throwOnClose = throwOnClose
	Return result
End Function

Function CountTo:ICloseableIterator<Int>(last:Int)
	starts :+ 1
	For Local value:Int = 1 To last
		visits :+ 1
		Yield value
	Next
End Function

Function Branches:ICloseableIterator<String>(selector:Int)
	If selector < 0 Then
		Yield "negative"
	Else If selector = 0 Then
		Yield "zero"
	Else
		Select selector
			Case 1
				Yield "one"
			Default
				Yield "many"
		End Select
	End If
	Yield "done"
End Function

Function WhileValues:ICloseableIterator<Int>(last:Int)
	Local value:Int
	While value < last
		value :+ 1
		Yield value
	Wend
End Function

Function ArrayValues:ICloseableIterator<Int>(values:Int[])
	For Local value:Int = EachIn values
		If value < 0 Then Continue
		Yield value * 2
		If value = 3 Then Exit
	Next
End Function

Function Characters:ICloseableIterator<Int>(value:String)
	For Local character:Int = EachIn value
		Yield character
	Next
End Function

Function ReturnEarly:ICloseableIterator<Int>()
	Yield 1
	Return
	Yield 2
End Function

Function Explodes:ICloseableIterator<Int>()
	Yield 1
	Throw "yield failure"
End Function

Function IteratorValues:ICloseableIterator<Int>(source:IIterator<Int>)
	For Local value:Int = EachIn source
		Yield value * 10
	Next
End Function

Function IterableValues:ICloseableIterator<Int>(source:IIterable<Int>)
	For Local value:Int = EachIn source
		Yield value
	Next
End Function

Function IteratorReturn:ICloseableIterator<Int>()
	For Local value:Int = EachIn TTrackedIterator.Create(3)
		Yield value
		Return
	Next
End Function

Function IteratorExit:ICloseableIterator<Int>()
	For Local value:Int = EachIn TTrackedIterator.Create(3)
		Yield value
		Exit
	Next
	Yield 99
End Function

Function IteratorFailure:ICloseableIterator<Int>()
	For Local value:Int = EachIn TTrackedIterator.Create(3, 2)
		Yield value
	Next
End Function

Function NestedIterators:ICloseableIterator<Int>()
	For Local outer:Int = EachIn TTrackedIterator.Create(2, 0, "outer")
		For Local inner:Int = EachIn TTrackedIterator.Create(2, 0, "inner")
			Yield outer * 10 + inner
		Next
	Next
End Function

Function NonSuspendingIteratorReturn:ICloseableIterator<Int>()
	Yield 0
	For Local value:Int = EachIn TTrackedIterator.Create(1)
		Return
	Next
End Function

Function UsingValues:ICloseableIterator<String>()
	Using
		Local resource:TTrackedResource = TrackedResource("using")
	Do
		Yield resource.tag + "-1"
		Yield resource.tag + "-2"
	End Using
End Function

Function UsingReturn:ICloseableIterator<Int>()
	Using
		Local resource:TTrackedResource = TrackedResource("return")
	Do
		Yield 1
		Return
	End Using
End Function

Function UsingExit:ICloseableIterator<Int>()
	For Local index:Int = 1 To 2
		Using
			Local resource:TTrackedResource = TrackedResource("exit")
		Do
			Yield index
			Exit
		End Using
	Next
	Yield 99
End Function

Function UsingFailure:ICloseableIterator<Int>()
	Using
		Local resource:TTrackedResource = TrackedResource("failure")
	Do
		Yield 1
		Throw "using body failure"
	End Using
End Function

Function UsingPartialInitialization:ICloseableIterator<Int>()
	Using
		Local first:TTrackedResource = TrackedResource("first")
		Local second:TTrackedResource = TrackedResource("second", True)
	Do
		Yield 1
	End Using
End Function

Function UsingMultiple:ICloseableIterator<Int>()
	Using
		Local first:TTrackedResource = TrackedResource("first")
		Local second:TTrackedResource = TrackedResource("second")
	Do
		Yield 1
	End Using
End Function

Function UsingCloseFailure:ICloseableIterator<Int>()
	Using
		Local resource:TTrackedResource = TrackedResource("close-failure", False, True)
	Do
		Yield 1
		Throw "primary using failure"
	End Using
End Function

Function NestedUsingIterator:ICloseableIterator<Int>()
	Using
		Local outer:TTrackedResource = TrackedResource("using-outer")
	Do
		For Local value:Int = EachIn TTrackedIterator.Create(2, 0, "using-iterator")
			Using
				Local inner:TTrackedResource = TrackedResource("using-inner")
			Do
				Yield value
			End Using
		Next
	End Using
End Function

Function NonSuspendingUsingReturn:ICloseableIterator<Int>()
	Yield 0
	Using
		Local resource:TTrackedResource = TrackedResource("non-suspending")
	Do
		Return
	End Using
End Function

Function TryCatchValues:ICloseableIterator<Int>()
	Try
		Yield 1
		Throw "caught"
	Catch message:String
		Yield message.length
	End Try
	Yield 9
End Function

Function TryFinallyValues:ICloseableIterator<Int>()
	Try
		Yield 2
	Finally
		RecordCleanup("finally")
	End Try
	Yield 8
End Function

Function TryCatchFinallyValues:ICloseableIterator<Int>()
	Try
		Yield 3
		Throw "caught"
	Catch message:String
		Yield message.length
	Finally
		RecordCleanup("catch-finally")
	End Try
	Yield 7
End Function

Function NestedFinallyClose:ICloseableIterator<Int>()
	Try
		Try
			Yield 4
		Finally
			RecordCleanup("inner-finally")
		End Try
	Finally
		RecordCleanup("outer-finally")
	End Try
End Function

Function ThrowingFinallyClose:ICloseableIterator<Int>()
	Try
		Try
			Yield 5
		Finally
			RecordCleanup("throwing-finally")
			Throw "finally close failure"
		End Try
	Finally
		RecordCleanup("outer-after-throw")
	End Try
End Function

Function CatchFinallyClose:ICloseableIterator<Int>()
	Try
		Yield 1
		Throw "caught while closing"
	Catch message:String
		Yield message.length
		Yield 99
	Finally
		RecordCleanup("catch-close-finally")
	End Try
End Function

Function ProtectedNestedOwnership:ICloseableIterator<Int>()
	Try
		Using
			Local outer:TTrackedResource = TrackedResource("protected-outer")
		Do
			For Local value:Int = EachIn TTrackedIterator.Create(2, 0, "protected-iterator")
				Using
					Local inner:TTrackedResource = TrackedResource("protected-inner")
				Do
					Yield value
				End Using
			Next
		End Using
	Finally
		RecordCleanup("protected-finally")
	End Try
End Function

Function Once<T>:ICloseableIterator<T>(value:T)
	Yield value
End Function

Function Many<T>:ICloseableIterator<T>(value:T, count:Int)
	Local first:Int = 1
	For Local index:Int = first To count
		Yield value
	Next
End Function

Function EachValue<T>:ICloseableIterator<T>(values:T[])
	For Local value:T = EachIn values
		Yield value
	Next
End Function

Function GenericCharacters<T>:ICloseableIterator<T>(value:String)
	For Local character:T = EachIn value
		Yield character
	Next
End Function

Function GenericNested<T>:ICloseableIterator<T>(value:T)
	For Local item:T = EachIn Once<T>(value)
		Yield item
	Next
End Function

Function GenericIteratorValues<T>:ICloseableIterator<T>(source:IIterator<T>)
	For Local item:T = EachIn source
		Yield item
	Next
End Function

Function GenericIteratorReturn<T>:ICloseableIterator<T>(source:IIterator<T>)
	For Local item:T = EachIn source
		Yield item
		Return
	Next
End Function

Function GenericNestedTracked<T>:ICloseableIterator<Int>()
	Local outerSource:IIterator<Int> = TTrackedIterator.Create(2, 0, "generic-outer")
	For Local outer:Int = EachIn outerSource
		Local innerSource:IIterator<Int> = TTrackedIterator.Create(2, 0, "generic-inner")
		For Local inner:Int = EachIn innerSource
			Yield outer * 10 + inner
		Next
	Next
End Function

Function GenericNonSuspendingIteratorReturn<T>:ICloseableIterator<Int>()
	Yield 0
	Local source:IIterator<Int> = TTrackedIterator.Create(1)
	For Local value:Int = EachIn source
		Return
	Next
End Function

Function GenericLegacyObjects<T>:ICloseableIterator<String>(values:TList)
	For Local value:String = EachIn values
		Yield value
	Next
End Function

Function GenericUsingValues<T>:ICloseableIterator<T>(value:T)
	Using
		Local resource:TTrackedResource = TrackedResource("generic-using")
	Do
		Yield value
	End Using
End Function

Function GenericUsingReturn<T>:ICloseableIterator<T>(value:T)
	Using
		Local first:TTrackedResource = TrackedResource("generic-first")
		Local second:TTrackedResource = TrackedResource("generic-second")
	Do
		Yield value
		Return
	End Using
End Function

Function GenericUsingFailure<T>:ICloseableIterator<T>(value:T)
	Using
		Local resource:TTrackedResource = TrackedResource("generic-failure")
	Do
		Yield value
		Throw "generic using failure"
	End Using
End Function

Function GenericNestedUsingIterator<T>:ICloseableIterator<Int>()
	Using
		Local outer:TTrackedResource = TrackedResource("generic-outer")
	Do
		Local source:IIterator<Int> = TTrackedIterator.Create(2, 0, "generic-iterator")
		For Local value:Int = EachIn source
			Using
				Local inner:TTrackedResource = TrackedResource("generic-inner")
			Do
				Yield value
			End Using
		Next
	End Using
End Function

Function GenericNonSuspendingUsingReturn<T>:ICloseableIterator<Int>()
	Yield 0
	Using
		Local resource:TTrackedResource = TrackedResource("generic-non-suspending")
	Do
		Return
	End Using
End Function

Function GenericTryCatchFinally<T>:ICloseableIterator<T>(value:T)
	Try
		Yield value
		Throw "generic caught"
	Catch message:String
		Yield value
	Finally
		RecordCleanup("generic-finally")
	End Try
	Yield value
End Function

Function GenericNestedFinallyClose<T>:ICloseableIterator<T>(value:T)
	Try
		Try
			Yield value
		Finally
			RecordCleanup("generic-inner-finally")
		End Try
	Finally
		RecordCleanup("generic-outer-finally")
	End Try
End Function

Function GenericThrowingFinallyClose<T>:ICloseableIterator<T>(value:T)
	Try
		Try
			Yield value
		Finally
			RecordCleanup("generic-throwing-finally")
			Throw "generic finally close failure"
		End Try
	Finally
		RecordCleanup("generic-outer-after-throw")
	End Try
End Function

Function GenericCatchFinallyClose<T>:ICloseableIterator<T>(value:T)
	Try
		Yield value
		Throw "generic caught while closing"
	Catch message:String
		Yield value
		Yield value
	Finally
		RecordCleanup("generic-catch-close-finally")
	End Try
End Function

Function GenericProtectedNestedOwnership<T>:ICloseableIterator<Int>()
	Try
		Using
			Local outer:TTrackedResource = TrackedResource("generic-protected-outer")
		Do
			Local source:IIterator<Int> = TTrackedIterator.Create(2, 0, "generic-protected-iterator")
			For Local value:Int = EachIn source
				Using
					Local inner:TTrackedResource = TrackedResource("generic-protected-inner")
				Do
					Yield value
				End Using
			Next
		End Using
	Finally
		RecordCleanup("generic-protected-finally")
	End Try
End Function

Function GenericCapturedClosureValues<T>:ICloseableIterator<T>(first:T, second:T)
	Local current:T = first
	Local read:Closure<T()> = Function()
		Return current
	End Function
	Yield read()
	current = second
	Yield read()
End Function

Function GenericLoopCapturedClosureValues<T>:ICloseableIterator<Int>()
	For Local index:Int = 1 To 2
		Local read:Closure<Int()> = Function()
			Return index
		End Function
		Yield read()
		Require(read() = index, "generic loop Closure environment was not retained across Yield")
	Next
End Function

Function GenericYieldingClosureFactory<T>:Closure<ICloseableIterator<T>()>(value:T)
	Return Function()
		Yield value
	End Function
End Function

Function StaticStringValues:ICloseableIterator<String>()
	Local StaticArray values:String[3]
	values[0] = "alpha"
	values[1] = "beta"
	values[2] = "gamma"
	Yield values[0]
	values[1] = values[1] + "!"
	For Local value:String = EachIn values
		Yield value
	Next
End Function

Function StaticStructValues:ICloseableIterator<TPair>()
	Local StaticArray values:TPair[2]
	values[0].key = 1
	values[0].value = "one"
	Yield values[0]
	values[1].key = 2
	values[1].value = "two"
	Yield values[1]
End Function

Function GenericStaticValues<T>:ICloseableIterator<T>(first:T, second:T)
	Local StaticArray values:T[2]
	values[0] = first
	values[1] = second
	Yield values[0]
	For Local value:T = EachIn values
		Yield value
	Next
End Function

Function GenericStaticFailure<T>:ICloseableIterator<T>(value:T)
	Local StaticArray values:T[1]
	values[0] = value
	Yield values[0]
	Throw "static failure"
End Function

Function NewDelegatedSource:TTrackedIterator(last:Int, throwAt:Int = 0, closeTag:String = "")
	delegationStarts :+ 1
	Return TTrackedIterator.Create(last, throwAt, closeTag)
End Function

Function YieldFromValues:ICloseableIterator<Int>()
	Local first:Int[] = [1, 2]
	Local empty:Int[]
	Yield 0
	Yield From first
	Yield From empty
	Yield From NewDelegatedSource(2, 0, "yield-from-inner")
	Yield 99
End Function

Function YieldFromIterable:ICloseableIterator<Int>(source:IIterable<Int>)
	Yield From source
End Function

Function YieldFromLegacy:ICloseableIterator<String>(source:TList)
	Yield From source
End Function

Function YieldFromString:ICloseableIterator<Int>(source:String)
	Yield From source
End Function

Function YieldFromStaticArray:ICloseableIterator<String>()
	Local StaticArray values:String[2]
	values[0] = "fixed-left"
	values[1] = "fixed-right"
	Yield From values
End Function

Function GenericYieldFrom<T>:ICloseableIterator<T>(values:T[])
	Yield From values
End Function

Function GenericNestedYieldFrom<T>:ICloseableIterator<T>(values:T[])
	Yield From GenericYieldFrom<T>(values)
End Function

Function FailingYieldFrom:ICloseableIterator<Int>()
	Yield From NewDelegatedSource(3, 2, "yield-from-failure")
End Function

Function ProtectedYieldFrom:ICloseableIterator<Int>()
	Try
		Yield From NewDelegatedSource(2, 0, "yield-from-protected-inner")
	Finally
		RecordCleanup("yield-from-protected-finally")
	End Try
End Function

Type TBox<T>
	Field value:T

	Method Values:ICloseableIterator<T>(count:Int)
		For Local index:Int = 1 To count
			Yield value
		Next
	End Method
End Type

Function Require:Int(condition:Int, message:String)
	If Not condition Then Throw message
	Return condition
End Function

Function Join:String(iterator:IIterator<String>)
	Local result:String
	While iterator.MoveNext()
		If result.length Then result :+ ","
		result :+ iterator.Current()
	Wend
	Return result
End Function

Local iterator:ICloseableIterator<Int> = CountTo(3)
Require(starts = 0 And visits = 0, "generator was not lazy")
For Local expected:Int = 1 To 3
	Require(iterator.MoveNext(), "CountTo ended early")
	Require(iterator.Current() = expected, "CountTo yielded the wrong value")
Next
Require(Not iterator.MoveNext(), "CountTo did not end")
Require(Not iterator.MoveNext(), "completed generator restarted")
Require(starts = 1 And visits = 3, "generator invocation counts are wrong")

Local closed:ICloseableIterator<Int> = CountTo(5)
Require(closed.MoveNext() And closed.Current() = 1, "early-close setup failed")
closed.Close()
closed.Close()
Require(Not closed.MoveNext(), "closed generator resumed")

Local neverStarted:ICloseableIterator<Int> = CountTo(5)
neverStarted.Close()
neverStarted.Close()
Require(starts = 2 And visits = 4 And Not neverStarted.MoveNext(), "Close before first MoveNext executed or resumed the generator")

Require(Join(Branches(-1)) = "negative,done", "negative branch failed")
Require(Join(Branches(0)) = "zero,done", "zero branch failed")
Require(Join(Branches(1)) = "one,done", "Select branch failed")
Require(Join(Branches(9)) = "many,done", "Select default failed")

Local whileIterator:ICloseableIterator<Int> = WhileValues(3)
Local whileTotal:Int
While whileIterator.MoveNext()
	whileTotal :+ whileIterator.Current()
Wend
Require(whileTotal = 6, "While state was not retained")

Local arrayEach:ICloseableIterator<Int> = ArrayValues([1, -1, 2, 3, 4])
Local arrayEachValues:Int[]
While arrayEach.MoveNext()
	arrayEachValues :+ [arrayEach.Current()]
Wend
Require(arrayEachValues.length = 3 And arrayEachValues[0] = 2 And arrayEachValues[1] = 4 And arrayEachValues[2] = 6, "Array EachIn state was not retained")

Local characterEach:ICloseableIterator<Int> = Characters("Az")
Require(characterEach.MoveNext() And characterEach.Current() = 65, "String EachIn first value failed")
Require(characterEach.MoveNext() And characterEach.Current() = 122 And Not characterEach.MoveNext(), "String EachIn state was not retained")

Local early:ICloseableIterator<Int> = ReturnEarly()
Require(early.MoveNext() And early.Current() = 1 And Not early.MoveNext(), "bare Return did not complete generator")

Local failed:ICloseableIterator<Int> = Explodes()
Require(failed.MoveNext() And failed.Current() = 1, "exception generator setup failed")
Try
	failed.MoveNext()
	Throw "generator exception did not propagate"
Catch message:String
	Require(message = "yield failure", "wrong generator exception")
End Try
Require(Not failed.MoveNext(), "generator resumed after exception")

Local objectEach:ICloseableIterator<Int> = IteratorValues(TTrackedIterator.Create(3))
Require(objectEach.MoveNext() And objectEach.Current() = 10, "iterator EachIn first value failed")
Require(iteratorCloses = 0, "iterator EachIn closed while suspended")
objectEach.Close()
objectEach.Close()
Require(iteratorCloses = 1 And Not objectEach.MoveNext(), "iterator EachIn early Close was not exact")

Local iterableEach:ICloseableIterator<Int> = IterableValues(TTrackedIterable.Create(2))
Require(iterableEach.MoveNext() And iterableEach.Current() = 1, "IIterable EachIn first value failed")
Require(iterableEach.MoveNext() And iterableEach.Current() = 2 And Not iterableEach.MoveNext(), "IIterable EachIn did not complete")
Require(iteratorCloses = 2, "IIterable-owned iterator was not closed")

Local returnedIterator:ICloseableIterator<Int> = IteratorReturn()
Require(returnedIterator.MoveNext() And returnedIterator.Current() = 1 And Not returnedIterator.MoveNext(), "Return inside iterator EachIn failed")
Require(iteratorCloses = 3, "Return did not close the active iterator")

Local exitedIterator:ICloseableIterator<Int> = IteratorExit()
Require(exitedIterator.MoveNext() And exitedIterator.Current() = 1, "Exit iterator setup failed")
Require(exitedIterator.MoveNext() And exitedIterator.Current() = 99 And Not exitedIterator.MoveNext(), "Exit did not continue after iterator EachIn")
Require(iteratorCloses = 4, "Exit did not close the active iterator")

Local failingIterator:ICloseableIterator<Int> = IteratorFailure()
Require(failingIterator.MoveNext() And failingIterator.Current() = 1, "iterator exception setup failed")
Try
	failingIterator.MoveNext()
	Throw "iterator exception did not propagate"
Catch message:String
	Require(message = "tracked iterator failure", "wrong iterator exception")
End Try
Require(iteratorCloses = 5 And Not failingIterator.MoveNext(), "iterator exception did not close and complete the generator")

Local nestedIterators:ICloseableIterator<Int> = NestedIterators()
Require(nestedIterators.MoveNext() And nestedIterators.Current() = 11, "nested iterator setup failed")
nestedIterators.Close()
Require(iteratorCloses = 7 And iteratorCloseOrder = "inner,outer", "nested iterators did not close inside-out")

Local nonSuspendingReturn:ICloseableIterator<Int> = NonSuspendingIteratorReturn()
Require(nonSuspendingReturn.MoveNext() And nonSuspendingReturn.Current() = 0 And Not nonSuspendingReturn.MoveNext(), "non-suspending iterator Return failed")
Require(iteratorCloses = 8, "non-suspending iterator Return did not balance its cleanup frame")

Local eachTotal:Int
For Local value:Int = EachIn CountTo(4)
	eachTotal :+ value
Next
Require(eachTotal = 10, "generated iterator did not work with EachIn")

Local text:ICloseableIterator<String> = Once<String>("generic")
Require(text.Current() = "", "generic iterator Current was not initialized to the String sentinel")
Require(text.MoveNext() And text.Current() = "generic" And Not text.MoveNext(), "generic String generator failed")

Local arrayValue:Int[] = [2, 4, 6]
Local arrays:ICloseableIterator<Int[]> = Once<Int[]>(arrayValue)
Require(arrays.MoveNext() And arrays.Current()[1] = 4, "generic Array generator failed")

Local marker:TMarker = New TMarker
marker.value = 17
Local objects:ICloseableIterator<TMarker> = Once<TMarker>(marker)
Require(objects.MoveNext() And objects.Current().value = 17, "generic Object generator failed")

Local implementation:TValue = New TValue
implementation.value = 23
Local interfaceValue:IValue = implementation
Local interfaces:ICloseableIterator<IValue> = Once<IValue>(interfaceValue)
Require(interfaces.MoveNext() And interfaces.Current().Value() = 23, "generic Interface generator failed")

Local pair:TPair
pair.key = 5
pair.value = "five"
Local structs:ICloseableIterator<TPair> = Once<TPair>(pair)
Require(structs.MoveNext() And structs.Current().key = 5 And structs.Current().value = "five", "generic Struct generator failed")

Local many:ICloseableIterator<Int> = Many<Int>(7, 3)
Local manyTotal:Int
While many.MoveNext()
	manyTotal :+ many.Current()
Wend
Require(manyTotal = 21, "generic routine loop generator failed")

Local genericEach:ICloseableIterator<String> = EachValue<String>(["left", "right"])
Require(genericEach.MoveNext() And genericEach.Current() = "left", "generic Array EachIn first value failed")
Require(genericEach.MoveNext() And genericEach.Current() = "right" And Not genericEach.MoveNext(), "generic Array EachIn state was not retained")

Local genericCharacters:ICloseableIterator<Long> = GenericCharacters<Long>("AZ")
Require(genericCharacters.MoveNext() And genericCharacters.Current() = 65:Long, "generic String EachIn first value failed")
Require(genericCharacters.MoveNext() And genericCharacters.Current() = 90:Long And Not genericCharacters.MoveNext(), "generic String EachIn state was not retained")

Local genericNested:ICloseableIterator<String> = GenericNested<String>("nested")
Require(genericNested.MoveNext() And genericNested.Current() = "nested" And Not genericNested.MoveNext(), "generic iterator EachIn state was not retained")

Local genericTracked:ICloseableIterator<Int> = GenericIteratorValues<Int>(TTrackedIterator.Create(3))
Require(genericTracked.MoveNext() And genericTracked.Current() = 1, "generic retained iterator setup failed")
genericTracked.Close()
Require(iteratorCloses = 9 And Not genericTracked.MoveNext(), "generic early Close did not close the retained iterator")

Local genericReturned:ICloseableIterator<Int> = GenericIteratorReturn<Int>(TTrackedIterator.Create(3))
Require(genericReturned.MoveNext() And genericReturned.Current() = 1 And Not genericReturned.MoveNext(), "generic Return inside iterator EachIn failed")
Require(iteratorCloses = 10, "generic Return did not close the retained iterator")

Local genericFailed:ICloseableIterator<Int> = GenericIteratorValues<Int>(TTrackedIterator.Create(3, 2))
Require(genericFailed.MoveNext() And genericFailed.Current() = 1, "generic iterator exception setup failed")
Try
	genericFailed.MoveNext()
	Throw "generic iterator exception did not propagate"
Catch message:String
	Require(message = "tracked iterator failure", "wrong generic iterator exception")
End Try
Require(iteratorCloses = 11 And Not genericFailed.MoveNext(), "generic iterator exception did not close and complete the generator")

iteratorCloseOrder = ""
Local genericNestedTracked:ICloseableIterator<Int> = GenericNestedTracked<String>()
Require(genericNestedTracked.MoveNext() And genericNestedTracked.Current() = 11, "generic nested iterator setup failed")
genericNestedTracked.Close()
Require(iteratorCloses = 13 And iteratorCloseOrder = "generic-inner,generic-outer", "generic nested iterators did not close inside-out")

Local genericNonSuspendingReturn:ICloseableIterator<Int> = GenericNonSuspendingIteratorReturn<String>()
Require(genericNonSuspendingReturn.MoveNext() And genericNonSuspendingReturn.Current() = 0 And Not genericNonSuspendingReturn.MoveNext(), "generic non-suspending iterator Return failed")
Require(iteratorCloses = 14, "generic non-suspending iterator Return did not balance its cleanup frame")

Local legacyValues:TList = New TList
legacyValues.AddLast("legacy")
Local genericLegacy:ICloseableIterator<String> = GenericLegacyObjects<Int>(legacyValues)
Require(genericLegacy.MoveNext() And genericLegacy.Current() = "legacy" And Not genericLegacy.MoveNext(), "generic ObjectEnumerator EachIn state was not retained")

Local box:TBox<String> = New TBox<String>
box.value = "box"
Local boxed:ICloseableIterator<String> = box.Values(2)
Require(boxed.MoveNext() And boxed.Current() = "box", "generic method first value failed")
Require(boxed.MoveNext() And boxed.Current() = "box" And Not boxed.MoveNext(), "generic method retained Self failed")

resourceCloses = 0
cleanupOrder = ""
Local usingValues:ICloseableIterator<String> = UsingValues()
Require(usingValues.MoveNext() And usingValues.Current() = "using-1", "Using generator first value failed")
Require(resourceCloses = 0, "Using resource closed while suspended")
Require(usingValues.MoveNext() And usingValues.Current() = "using-2" And Not usingValues.MoveNext(), "Using generator did not resume through its resource")
Require(resourceCloses = 1 And cleanupOrder = "using", "Using resource was not closed on exhaustion")

resourceCloses = 0
cleanupOrder = ""
Local usingEarly:ICloseableIterator<String> = UsingValues()
Require(usingEarly.MoveNext(), "Using early-Close setup failed")
usingEarly.Close()
usingEarly.Close()
Require(resourceCloses = 1 And cleanupOrder = "using" And Not usingEarly.MoveNext(), "Using early Close was not exact")

resourceCloses = 0
cleanupOrder = ""
Local usingReturn:ICloseableIterator<Int> = UsingReturn()
Require(usingReturn.MoveNext() And usingReturn.Current() = 1 And Not usingReturn.MoveNext(), "Return inside resumable Using failed")
Require(resourceCloses = 1 And cleanupOrder = "return", "Return did not close the retained Using resource")

resourceCloses = 0
cleanupOrder = ""
Local usingExit:ICloseableIterator<Int> = UsingExit()
Require(usingExit.MoveNext() And usingExit.Current() = 1, "Exit from resumable Using setup failed")
Require(usingExit.MoveNext() And usingExit.Current() = 99 And Not usingExit.MoveNext(), "Exit from resumable Using did not continue after its loop")
Require(resourceCloses = 1 And cleanupOrder = "exit", "Exit did not close the retained Using resource")

resourceCloses = 0
cleanupOrder = ""
Local usingFailure:ICloseableIterator<Int> = UsingFailure()
Require(usingFailure.MoveNext(), "Using exception setup failed")
Try
	usingFailure.MoveNext()
	Throw "Using exception did not propagate"
Catch message:String
	Require(message = "using body failure", "wrong Using body exception")
End Try
Require(resourceCloses = 1 And cleanupOrder = "failure" And Not usingFailure.MoveNext(), "Using exception did not close and complete the generator")

resourceCloses = 0
cleanupOrder = ""
Local partialUsing:ICloseableIterator<Int> = UsingPartialInitialization()
Try
	partialUsing.MoveNext()
	Throw "Using initializer exception did not propagate"
Catch message:String
	Require(message = "resource creation failure", "wrong Using initializer exception")
End Try
Require(resourceCloses = 1 And cleanupOrder = "first", "partially initialized Using resources were not cleaned safely")

resourceCloses = 0
cleanupOrder = ""
Local multipleUsing:ICloseableIterator<Int> = UsingMultiple()
Require(multipleUsing.MoveNext(), "multiple Using resource setup failed")
multipleUsing.Close()
Require(resourceCloses = 2 And cleanupOrder = "second,first", "multiple Using resources did not close in reverse order")

resourceCloses = 0
cleanupOrder = ""
Local closeFailure:ICloseableIterator<Int> = UsingCloseFailure()
Require(closeFailure.MoveNext(), "Using close-failure setup failed")
Try
	closeFailure.MoveNext()
	Throw "primary Using exception did not propagate"
Catch message:String
	Require(message = "primary using failure", "Using cleanup hid the primary exception")
End Try
Require(resourceCloses = 1 And cleanupOrder = "close-failure", "throwing Using Close was not invoked exactly once")

resourceCloses = 0
cleanupOrder = ""
Local nestedUsing:ICloseableIterator<Int> = NestedUsingIterator()
Require(nestedUsing.MoveNext() And nestedUsing.Current() = 1, "nested Using/iterator setup failed")
nestedUsing.Close()
Require(resourceCloses = 2 And cleanupOrder = "using-inner,using-iterator,using-outer", "mixed retained resources did not close inside-out")

resourceCloses = 0
cleanupOrder = ""
Local nonSuspendingUsing:ICloseableIterator<Int> = NonSuspendingUsingReturn()
Require(nonSuspendingUsing.MoveNext() And nonSuspendingUsing.Current() = 0 And Not nonSuspendingUsing.MoveNext(), "non-suspending Using Return failed")
Require(resourceCloses = 1 And cleanupOrder = "non-suspending", "non-suspending Using did not balance its cleanup frame")

resourceCloses = 0
cleanupOrder = ""
Local genericUsing:ICloseableIterator<String> = GenericUsingValues<String>("generic")
Require(genericUsing.MoveNext() And genericUsing.Current() = "generic" And Not genericUsing.MoveNext(), "generic resumable Using failed")
Require(resourceCloses = 1 And cleanupOrder = "generic-using", "generic Using resource was not closed on exhaustion")

resourceCloses = 0
cleanupOrder = ""
Local genericUsingReturn:ICloseableIterator<String> = GenericUsingReturn<String>("return")
Require(genericUsingReturn.MoveNext() And genericUsingReturn.Current() = "return" And Not genericUsingReturn.MoveNext(), "generic Return inside resumable Using failed")
Require(resourceCloses = 2 And cleanupOrder = "generic-second,generic-first", "generic Return did not close multiple Using resources in reverse order")

resourceCloses = 0
cleanupOrder = ""
Local genericUsingFailure:ICloseableIterator<String> = GenericUsingFailure<String>("failure")
Require(genericUsingFailure.MoveNext(), "generic Using exception setup failed")
Try
	genericUsingFailure.MoveNext()
	Throw "generic Using exception did not propagate"
Catch message:String
	Require(message = "generic using failure", "wrong generic Using exception")
End Try
Require(resourceCloses = 1 And cleanupOrder = "generic-failure" And Not genericUsingFailure.MoveNext(), "generic Using exception did not close and complete the generator")

resourceCloses = 0
cleanupOrder = ""
Local genericNestedUsing:ICloseableIterator<Int> = GenericNestedUsingIterator<String>()
Require(genericNestedUsing.MoveNext() And genericNestedUsing.Current() = 1, "generic nested Using/iterator setup failed")
genericNestedUsing.Close()
Require(resourceCloses = 2 And cleanupOrder = "generic-inner,generic-iterator,generic-outer", "generic mixed retained resources did not close inside-out")

resourceCloses = 0
cleanupOrder = ""
Local genericNonSuspendingUsing:ICloseableIterator<Int> = GenericNonSuspendingUsingReturn<String>()
Require(genericNonSuspendingUsing.MoveNext() And genericNonSuspendingUsing.Current() = 0 And Not genericNonSuspendingUsing.MoveNext(), "generic non-suspending Using Return failed")
Require(resourceCloses = 1 And cleanupOrder = "generic-non-suspending", "generic non-suspending Using did not balance its cleanup frame")

cleanupOrder = ""
Local caughtValues:ICloseableIterator<Int> = TryCatchValues()
Require(caughtValues.MoveNext() And caughtValues.Current() = 1, "Yield in protected Try failed")
Require(caughtValues.MoveNext() And caughtValues.Current() = 6, "exception after protected Yield did not reach Catch")
Require(caughtValues.MoveNext() And caughtValues.Current() = 9 And Not caughtValues.MoveNext(), "Yield in Catch did not resume to the trailing body")

cleanupOrder = ""
Local finallyValues:ICloseableIterator<Int> = TryFinallyValues()
Require(finallyValues.MoveNext() And finallyValues.Current() = 2 And cleanupOrder = "", "Try/Finally ran eagerly before suspension")
Require(finallyValues.MoveNext() And finallyValues.Current() = 8 And cleanupOrder = "finally" And Not finallyValues.MoveNext(), "Try/Finally did not resume and finish exactly once")

cleanupOrder = ""
Local combinedValues:ICloseableIterator<Int> = TryCatchFinallyValues()
Require(combinedValues.MoveNext() And combinedValues.Current() = 3, "combined Try/Catch/Finally protected Yield failed")
Require(combinedValues.MoveNext() And combinedValues.Current() = 6 And cleanupOrder = "", "combined Catch Yield failed")
Require(combinedValues.MoveNext() And combinedValues.Current() = 7 And cleanupOrder = "catch-finally" And Not combinedValues.MoveNext(), "combined Finally did not run before the trailing Yield")

cleanupOrder = ""
Local nestedFinally:ICloseableIterator<Int> = NestedFinallyClose()
Require(nestedFinally.MoveNext() And nestedFinally.Current() = 4, "nested Finally close setup failed")
nestedFinally.Close()
Require(cleanupOrder = "inner-finally,outer-finally" And Not nestedFinally.MoveNext(), "manual Close did not unwind Finally blocks inside-out")

cleanupOrder = ""
Local throwingFinally:ICloseableIterator<Int> = ThrowingFinallyClose()
Require(throwingFinally.MoveNext(), "throwing Finally close setup failed")
Try
	throwingFinally.Close()
	Throw "manual Close did not propagate Finally exception"
Catch message:String
	Require(message = "finally close failure", "manual Close propagated the wrong Finally exception")
End Try
Require(cleanupOrder = "throwing-finally,outer-after-throw" And Not throwingFinally.MoveNext(), "outer Finally did not run after an inner Close failure")
throwingFinally.Close()
Require(cleanupOrder = "throwing-finally,outer-after-throw", "repeated Close reran a throwing Finally")

cleanupOrder = ""
Local catchFinallyClose:ICloseableIterator<Int> = CatchFinallyClose()
Require(catchFinallyClose.MoveNext() And catchFinallyClose.Current() = 1, "Catch early-Close protected setup failed")
Require(catchFinallyClose.MoveNext() And catchFinallyClose.Current() = 20 And cleanupOrder = "", "Catch early-Close handler setup failed")
catchFinallyClose.Close()
catchFinallyClose.Close()
Require(cleanupOrder = "catch-close-finally" And Not catchFinallyClose.MoveNext(), "Close while suspended in Catch did not run Finally exactly once")

resourceCloses = 0
cleanupOrder = ""
Local protectedNested:ICloseableIterator<Int> = ProtectedNestedOwnership()
Require(protectedNested.MoveNext() And protectedNested.Current() = 1, "protected nested ownership setup failed")
protectedNested.Close()
protectedNested.Close()
Require(resourceCloses = 2 And cleanupOrder = "protected-inner,protected-iterator,protected-outer,protected-finally" And Not protectedNested.MoveNext(), "protected nested ownership did not unwind inside-out exactly once")

cleanupOrder = ""
Local genericTry:ICloseableIterator<String> = GenericTryCatchFinally<String>("generic")
Require(genericTry.MoveNext() And genericTry.Current() = "generic", "generic protected Try Yield failed")
Require(genericTry.MoveNext() And genericTry.Current() = "generic" And cleanupOrder = "", "generic Catch Yield failed")
Require(genericTry.MoveNext() And genericTry.Current() = "generic" And cleanupOrder = "generic-finally" And Not genericTry.MoveNext(), "generic Finally resumption failed")

cleanupOrder = ""
Local genericNestedFinally:ICloseableIterator<String> = GenericNestedFinallyClose<String>("generic-close")
Require(genericNestedFinally.MoveNext() And genericNestedFinally.Current() = "generic-close", "generic nested Finally close setup failed")
genericNestedFinally.Close()
Require(cleanupOrder = "generic-inner-finally,generic-outer-finally" And Not genericNestedFinally.MoveNext(), "generic Close did not unwind Finally blocks inside-out")

cleanupOrder = ""
Local genericThrowingFinally:ICloseableIterator<String> = GenericThrowingFinallyClose<String>("generic-failure")
Require(genericThrowingFinally.MoveNext(), "generic throwing Finally close setup failed")
Try
	genericThrowingFinally.Close()
	Throw "generic manual Close did not propagate Finally exception"
Catch message:String
	Require(message = "generic finally close failure", "generic manual Close propagated the wrong Finally exception")
End Try
Require(cleanupOrder = "generic-throwing-finally,generic-outer-after-throw" And Not genericThrowingFinally.MoveNext(), "generic outer Finally did not run after an inner Close failure")
genericThrowingFinally.Close()
Require(cleanupOrder = "generic-throwing-finally,generic-outer-after-throw", "generic repeated Close reran a throwing Finally")

cleanupOrder = ""
Local genericCatchFinallyClose:ICloseableIterator<String> = GenericCatchFinallyClose<String>("generic-close")
Require(genericCatchFinallyClose.MoveNext() And genericCatchFinallyClose.Current() = "generic-close", "generic Catch early-Close protected setup failed")
Require(genericCatchFinallyClose.MoveNext() And genericCatchFinallyClose.Current() = "generic-close" And cleanupOrder = "", "generic Catch early-Close handler setup failed")
genericCatchFinallyClose.Close()
genericCatchFinallyClose.Close()
Require(cleanupOrder = "generic-catch-close-finally" And Not genericCatchFinallyClose.MoveNext(), "generic Close while suspended in Catch did not run Finally exactly once")

resourceCloses = 0
cleanupOrder = ""
Local genericProtectedNested:ICloseableIterator<Int> = GenericProtectedNestedOwnership<String>()
Require(genericProtectedNested.MoveNext() And genericProtectedNested.Current() = 1, "generic protected nested ownership setup failed")
genericProtectedNested.Close()
genericProtectedNested.Close()
Require(resourceCloses = 2 And cleanupOrder = "generic-protected-inner,generic-protected-iterator,generic-protected-outer,generic-protected-finally" And Not genericProtectedNested.MoveNext(), "generic protected nested ownership did not unwind inside-out exactly once")

Local genericCapturedClosure:ICloseableIterator<String> = GenericCapturedClosureValues<String>("first", "second")
Require(genericCapturedClosure.MoveNext() And genericCapturedClosure.Current() = "first", "generic generator capturing Closure first value failed")
Require(genericCapturedClosure.MoveNext() And genericCapturedClosure.Current() = "second" And Not genericCapturedClosure.MoveNext(), "generic generator capturing Closure did not retain its environment")

Local genericLoopCapturedClosure:ICloseableIterator<Int> = GenericLoopCapturedClosureValues<String>()
Require(genericLoopCapturedClosure.MoveNext() And genericLoopCapturedClosure.Current() = 1, "generic loop Closure first activation failed")
Require(genericLoopCapturedClosure.MoveNext() And genericLoopCapturedClosure.Current() = 2 And Not genericLoopCapturedClosure.MoveNext(), "generic loop Closure activation did not survive suspension or refresh per iteration")

Local genericYieldingFactory:Closure<ICloseableIterator<String>()> = GenericYieldingClosureFactory<String>("closure-yield")
Local genericYieldingClosure:ICloseableIterator<String> = genericYieldingFactory()
Require(genericYieldingClosure.MoveNext() And genericYieldingClosure.Current() = "closure-yield" And Not genericYieldingClosure.MoveNext(), "capturing generic Closure body did not yield through its retained environment")
Local genericYieldingClosed:ICloseableIterator<String> = genericYieldingFactory()
genericYieldingClosed.Close()
Require(Not genericYieldingClosed.MoveNext(), "capturing generic yielding Closure resumed after early Close")

Local staticStrings:ICloseableIterator<String> = StaticStringValues()
Require(staticStrings.MoveNext() And staticStrings.Current() = "alpha", "retained String StaticArray did not yield its indexed value")
GCCollect()
Require(staticStrings.MoveNext() And staticStrings.Current() = "alpha", "retained String StaticArray did not survive collection or enter EachIn")
Require(staticStrings.MoveNext() And staticStrings.Current() = "beta!", "retained StaticArray EachIn did not resume at its second element")
Require(staticStrings.MoveNext() And staticStrings.Current() = "gamma" And Not staticStrings.MoveNext(), "retained StaticArray EachIn did not complete in order")

Local staticStructs:ICloseableIterator<TPair> = StaticStructValues()
Require(staticStructs.MoveNext() And staticStructs.Current().key = 1 And staticStructs.Current().value = "one", "retained Struct StaticArray first value failed")
Require(staticStructs.MoveNext() And staticStructs.Current().key = 2 And staticStructs.Current().value = "two" And Not staticStructs.MoveNext(), "retained Struct StaticArray second value failed")

Local genericFirstPair:TPair
genericFirstPair.key = 11
genericFirstPair.value = "eleven"
Local genericSecondPair:TPair
genericSecondPair.key = 12
genericSecondPair.value = "twelve"
Local genericStaticStructs:ICloseableIterator<TPair> = GenericStaticValues<TPair>(genericFirstPair, genericSecondPair)
Require(genericStaticStructs.MoveNext() And genericStaticStructs.Current().key = 11, "generic Struct StaticArray first value failed")
Require(genericStaticStructs.MoveNext() And genericStaticStructs.Current().value = "eleven", "generic Struct StaticArray EachIn first value failed")
Require(genericStaticStructs.MoveNext() And genericStaticStructs.Current().key = 12 And Not genericStaticStructs.MoveNext(), "generic Struct StaticArray EachIn resumption failed")

Local genericStaticStrings:ICloseableIterator<String> = GenericStaticValues<String>("left", "right")
Require(genericStaticStrings.MoveNext() And genericStaticStrings.Current() = "left", "generic retained StaticArray indexed value failed")
Require(genericStaticStrings.MoveNext() And genericStaticStrings.Current() = "left", "generic retained StaticArray EachIn first value failed")
Require(genericStaticStrings.MoveNext() And genericStaticStrings.Current() = "right" And Not genericStaticStrings.MoveNext(), "generic retained StaticArray EachIn resumption failed")

Local firstMarker:TMarker = New TMarker
firstMarker.value = 31
Local secondMarker:TMarker = New TMarker
secondMarker.value = 32
Local genericStaticObjects:ICloseableIterator<TMarker> = GenericStaticValues<TMarker>(firstMarker, secondMarker)
firstMarker = Null
secondMarker = Null
Require(genericStaticObjects.MoveNext() And genericStaticObjects.Current().value = 31, "generic Object StaticArray first value failed")
GCCollect()
Require(genericStaticObjects.MoveNext() And genericStaticObjects.Current().value = 31, "generic Object StaticArray did not retain managed values across collection")
Require(genericStaticObjects.MoveNext() And genericStaticObjects.Current().value = 32 And Not genericStaticObjects.MoveNext(), "generic Object StaticArray EachIn resumption failed")

Local firstInterfaceValue:TValue = New TValue
firstInterfaceValue.value = 41
Local secondInterfaceValue:TValue = New TValue
secondInterfaceValue.value = 42
Local genericStaticInterfaces:ICloseableIterator<IValue> = GenericStaticValues<IValue>(firstInterfaceValue, secondInterfaceValue)
Require(genericStaticInterfaces.MoveNext() And genericStaticInterfaces.Current().Value() = 41, "generic Interface StaticArray first value failed")
Require(genericStaticInterfaces.MoveNext() And genericStaticInterfaces.Current().Value() = 41, "generic Interface StaticArray EachIn first value failed")
Require(genericStaticInterfaces.MoveNext() And genericStaticInterfaces.Current().Value() = 42 And Not genericStaticInterfaces.MoveNext(), "generic Interface StaticArray EachIn resumption failed")

Local firstArray:Int[] = [4, 5]
Local secondArray:Int[] = [6]
Local genericStaticArrays:ICloseableIterator<Int[]> = GenericStaticValues<Int[]>(firstArray, secondArray)
Require(genericStaticArrays.MoveNext() And genericStaticArrays.Current()[1] = 5, "generic heap-Array StaticArray first value failed")
Require(genericStaticArrays.MoveNext() And genericStaticArrays.Current()[0] = 4, "generic heap-Array StaticArray EachIn first value failed")
Require(genericStaticArrays.MoveNext() And genericStaticArrays.Current()[0] = 6 And Not genericStaticArrays.MoveNext(), "generic heap-Array StaticArray EachIn resumption failed")

Local neverStartedStatic:ICloseableIterator<String> = GenericStaticValues<String>("unused", "unused")
neverStartedStatic.Close()
neverStartedStatic.Close()
Require(Not neverStartedStatic.MoveNext(), "never-started retained StaticArray resumed after Close")

Local earlyClosedStatic:ICloseableIterator<String> = GenericStaticValues<String>("first", "second")
Require(earlyClosedStatic.MoveNext() And earlyClosedStatic.Current() = "first", "retained StaticArray early-Close setup failed")
earlyClosedStatic.Close()
earlyClosedStatic.Close()
Require(Not earlyClosedStatic.MoveNext(), "retained StaticArray resumed after early Close")

Local failingStatic:ICloseableIterator<String> = GenericStaticFailure<String>("before-failure")
Require(failingStatic.MoveNext() And failingStatic.Current() = "before-failure", "retained StaticArray exception setup failed")
Try
	failingStatic.MoveNext()
	Throw "retained StaticArray exception was not propagated"
Catch message:String
	Require(message = "static failure", "retained StaticArray propagated the wrong exception")
End Try
Require(Not failingStatic.MoveNext(), "retained StaticArray iterator resumed after an exception")

delegationStarts = 0
iteratorCloses = 0
iteratorCloseOrder = ""
Local delegated:ICloseableIterator<Int> = YieldFromValues()
Require(delegationStarts = 0, "Yield From evaluated its source before the first MoveNext")
Local delegatedExpected:Int[] = [0, 1, 2, 1, 2, 99]
For Local delegatedIndex:Int = 0 Until delegatedExpected.length
	Require(delegated.MoveNext(), "Yield From ended before all composed sources were consumed")
	Require(delegated.Current() = delegatedExpected[delegatedIndex], "Yield From produced an out-of-order value")
	If delegatedIndex < 2 Then Require(delegationStarts = 0, "Yield From evaluated a later source too early")
	If delegatedExpected[delegatedIndex] = 99 Then Require(iteratorCloses = 1, "Yield From did not close its exhausted iterator before continuing the outer generator")
Next
Require(Not delegated.MoveNext(), "Yield From did not exhaust after its final value")
Require(delegationStarts = 1 And iteratorCloses = 1 And iteratorCloseOrder = "yield-from-inner", "Yield From did not acquire and close its nested iterator exactly once")

delegationStarts = 0
iteratorCloses = 0
Local delegatedNeverStarted:ICloseableIterator<Int> = YieldFromValues()
delegatedNeverStarted.Close()
delegatedNeverStarted.Close()
Require(delegationStarts = 0 And iteratorCloses = 0 And Not delegatedNeverStarted.MoveNext(), "closing an unstarted Yield From generator evaluated or acquired its source")

delegationStarts = 0
iteratorCloses = 0
Local delegatedEarly:ICloseableIterator<Int> = YieldFromValues()
For Local delegatedIndex:Int = 0 Until 4
	Require(delegatedEarly.MoveNext(), "Yield From early-close setup ended unexpectedly")
Next
Require(delegationStarts = 1, "Yield From early-close setup did not acquire its nested iterator")
delegatedEarly.Close()
delegatedEarly.Close()
Require(iteratorCloses = 1 And Not delegatedEarly.MoveNext(), "Yield From did not propagate idempotent early Close")

iteratorCloses = 0
Local delegatedIterable:ICloseableIterator<Int> = YieldFromIterable(TTrackedIterable.Create(2))
Require(delegatedIterable.MoveNext() And delegatedIterable.Current() = 1, "Yield From IIterable first value failed")
Require(delegatedIterable.MoveNext() And delegatedIterable.Current() = 2 And Not delegatedIterable.MoveNext(), "Yield From IIterable completion failed")
Require(iteratorCloses = 1, "Yield From did not close the runtime-closeable iterator returned by IIterable")

Local yieldFromLegacyValues:TList = New TList
yieldFromLegacyValues.AddLast("legacy-left")
yieldFromLegacyValues.AddLast("legacy-right")
Local delegatedLegacy:ICloseableIterator<String> = YieldFromLegacy(yieldFromLegacyValues)
Require(delegatedLegacy.MoveNext() And delegatedLegacy.Current() = "legacy-left", "Yield From legacy ObjectEnumerator first value failed")
Require(delegatedLegacy.MoveNext() And delegatedLegacy.Current() = "legacy-right" And Not delegatedLegacy.MoveNext(), "Yield From legacy ObjectEnumerator completion failed")

Local delegatedCharacters:ICloseableIterator<Int> = YieldFromString("AZ")
Require(delegatedCharacters.MoveNext() And delegatedCharacters.Current() = 65, "Yield From String first code unit failed")
Require(delegatedCharacters.MoveNext() And delegatedCharacters.Current() = 90 And Not delegatedCharacters.MoveNext(), "Yield From String completion failed")

Local delegatedStatic:ICloseableIterator<String> = YieldFromStaticArray()
Require(delegatedStatic.MoveNext() And delegatedStatic.Current() = "fixed-left", "Yield From StaticArray first value failed")
Require(delegatedStatic.MoveNext() And delegatedStatic.Current() = "fixed-right" And Not delegatedStatic.MoveNext(), "Yield From StaticArray completion failed")

Local delegatedGeneric:ICloseableIterator<String> = GenericNestedYieldFrom<String>(["generic-left", "generic-right"])
Require(delegatedGeneric.MoveNext() And delegatedGeneric.Current() = "generic-left", "generic nested Yield From first value failed")
Require(delegatedGeneric.MoveNext() And delegatedGeneric.Current() = "generic-right" And Not delegatedGeneric.MoveNext(), "generic nested Yield From completion failed")

delegationStarts = 0
iteratorCloses = 0
iteratorCloseOrder = ""
Local delegatedFailure:ICloseableIterator<Int> = FailingYieldFrom()
Require(delegatedFailure.MoveNext() And delegatedFailure.Current() = 1, "Yield From exception setup failed")
Try
	delegatedFailure.MoveNext()
	Throw "Yield From nested exception was not propagated"
Catch message:String
	Require(message = "tracked iterator failure", "Yield From propagated the wrong nested exception")
End Try
Require(iteratorCloses = 1 And iteratorCloseOrder = "yield-from-failure", "Yield From did not close a failing nested iterator")
Require(Not delegatedFailure.MoveNext(), "Yield From resumed after a nested iterator exception")

delegationStarts = 0
iteratorCloses = 0
cleanupOrder = ""
Local delegatedProtected:ICloseableIterator<Int> = ProtectedYieldFrom()
Require(delegatedProtected.MoveNext() And delegatedProtected.Current() = 1, "protected Yield From early-close setup failed")
delegatedProtected.Close()
Require(iteratorCloses = 1 And cleanupOrder = "yield-from-protected-inner,yield-from-protected-finally", "protected Yield From did not unwind its iterator before Finally")
Require(Not delegatedProtected.MoveNext(), "protected Yield From resumed after early Close")

Print "yield-runtime-ok"
