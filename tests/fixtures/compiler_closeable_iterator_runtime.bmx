SuperStrict

Framework BRL.StandardIO

Type TCloseableCounter Implements ICloseableIterator<Int>
	Field value:Int
	Field closed:Int
	Field tracker:TCloseTracker
	Field throwAt:Int
	Field throwOnClose:Int

	Method Current:Int()
		Return value
	End Method

	Method MoveNext:Int()
		value :+ 1
		If throwAt And value = throwAt Then Throw "iterator failure"
		Return value <= 2
	End Method

	Method Close()
		closed :+ 1
		If tracker Then tracker.closed :+ 1
		If throwOnClose Then Throw "close failure"
	End Method
End Type

Type TCloseTracker
	Field closed:Int
End Type

Type TCloseableValues Implements IIterable<Int>
	Field tracker:TCloseTracker
	Field throwAt:Int
	Field throwOnClose:Int

	Method GetIterator:IIterator<Int>()
		Local iterator:TCloseableCounter = New TCloseableCounter
		iterator.tracker = tracker
		iterator.throwAt = throwAt
		iterator.throwOnClose = throwOnClose
		Return iterator
	End Method
End Type

Function Values:TCloseableValues(tracker:TCloseTracker, throwAt:Int = 0, throwOnClose:Int = False)
	Local values:TCloseableValues = New TCloseableValues
	values.tracker = tracker
	values.throwAt = throwAt
	values.throwOnClose = throwOnClose
	Return values
End Function

Function ReturnFromEach:Int(tracker:TCloseTracker)
	For Local value:Int = EachIn Values(tracker)
		Return value
	Next
	Return 0
End Function

Local counter:TCloseableCounter = New TCloseableCounter
Local iterator:IIterator<Int> = counter
Local closeable:ICloseable = counter
Local combined:ICloseableIterator<Int> = ICloseableIterator<Int>(iterator)
If Not combined Or Not iterator.MoveNext() Or iterator.Current() <> 1 Then Throw "iterator contract failed"
combined.Close()
If counter.closed <> 1 Or ICloseable(combined) <> closeable Then Throw "closeable contract failed"

Local normal:TCloseTracker = New TCloseTracker
Local sum:Int
For Local value:Int = EachIn Values(normal)
	sum :+ value
Next
If sum <> 3 Or normal.closed <> 1 Then Throw "normal EachIn cleanup failed"

Local exited:TCloseTracker = New TCloseTracker
For Local value:Int = EachIn Values(exited)
	Exit
Next
If exited.closed <> 1 Then Throw "Exit cleanup failed"

Local continued:TCloseTracker = New TCloseTracker
For Local value:Int = EachIn Values(continued)
	Continue
Next
If continued.closed <> 1 Then Throw "Continue closed early or more than once"

Local returned:TCloseTracker = New TCloseTracker
If ReturnFromEach(returned) <> 1 Or returned.closed <> 1 Then Throw "Return cleanup failed"

Local bodyFailure:TCloseTracker = New TCloseTracker
Try
	For Local value:Int = EachIn Values(bodyFailure)
		Throw "body failure"
	Next
Catch message:String
	If message <> "body failure" Then Throw message
End Try
If bodyFailure.closed <> 1 Then Throw "body exception cleanup failed"

Local iteratorFailure:TCloseTracker = New TCloseTracker
Try
	For Local value:Int = EachIn Values(iteratorFailure, 2)
	Next
Catch message:String
	If message <> "iterator failure" Then Throw message
End Try
If iteratorFailure.closed <> 1 Then Throw "iterator exception cleanup failed"

Local primaryFailure:TCloseTracker = New TCloseTracker
Try
	For Local value:Int = EachIn Values(primaryFailure, 0, True)
		Throw "primary failure"
	Next
Catch message:String
	If message <> "primary failure" Then Throw message
End Try
If primaryFailure.closed <> 1 Then Throw "cleanup failure suppression failed"

Local cleanupOnlyFailure:TCloseTracker = New TCloseTracker
For Local value:Int = EachIn Values(cleanupOnlyFailure, 0, True)
Next
If cleanupOnlyFailure.closed <> 1 Then Throw "normal cleanup failure suppression failed"

Local outer:TCloseTracker = New TCloseTracker
Local inner:TCloseTracker = New TCloseTracker
For Local outerValue:Int = EachIn Values(outer)
	For Local innerValue:Int = EachIn Values(inner)
		If innerValue = 1 Then Continue
		Exit
	Next
	Exit
Next
If outer.closed <> 1 Or inner.closed <> 1 Then Throw "nested cleanup failed"

Local nonLocalOuter:TCloseTracker = New TCloseTracker
Local nonLocalInner:TCloseTracker = New TCloseTracker
#OuterCloseable
For Local outerValue:Int = EachIn Values(nonLocalOuter)
	For Local innerValue:Int = EachIn Values(nonLocalInner)
		Exit OuterCloseable
	Next
Next
If nonLocalOuter.closed <> 1 Or nonLocalInner.closed <> 1 Then Throw "non-local Exit cleanup failed"

Local direct:TCloseableCounter = New TCloseableCounter
For Local value:Int = EachIn direct
	Exit
Next
If direct.closed <> 1 Then Throw "direct iterator cleanup failed"
Print "closeable-iterator-ok"
