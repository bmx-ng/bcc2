SuperStrict

Import BRL.Event

Function EachValues:Int[]()
	Return [1, 2, 3, 4]
End Function

Function EachText:String()
	Return "ABC"
End Function

Type TEachBase
End Type

Type TEachChild Extends TEachBase
End Type

Type TLegacyRuntimeIterator
	Field index:Int

	Method HasNext:Int()
		index = index + 1
		Return index <= 4
	End Method

	Method NextObject:Object()
		Return Self
	End Method
End Type

Type TLegacyRuntimeValues
	Field enumerations:Int

	Method ObjectEnumerator:TLegacyRuntimeIterator()
		enumerations = enumerations + 1
		Return New TLegacyRuntimeIterator
	End Method
End Type

Local event:TEvent = CreateEvent(1)
event.id = event.id + 1
event.source = event
event.extra = event
Local events:TEvent[] = New TEvent[2]
Local empty:TEvent = events[0]
events[0] = event
events[1] = CreateEvent(2)
Local first:TEvent = events[0]
Local joined:TEvent[] = events + events
Local literal:TEvent[] = [event, CreateEvent(3)]
Local loopTotal:Int
Local outer:Int
#Outer
Repeat
	outer = outer + 1
	Local inner:Int
	Repeat
		inner = inner + 1
		If inner = 2 Then Continue
		If outer = 2 Then Continue Outer
		If inner = 4 Then Exit
		loopTotal = loopTotal + 1
	Forever
	If outer = 3 Then Exit Outer
Until outer = 10
Local rangeTotal:Int
For Local value:Int = 1 To 5 Step 2
	rangeTotal = rangeTotal + value
Next
For Local value:Int = 5 To 1 Step -2
	rangeTotal = rangeTotal + value
Next
For Local value:Int = 0 Until 3
	rangeTotal = rangeTotal + value
Next
Local rangeValue:Int
#RangeOuter
For rangeValue = 1 To 3
	If rangeValue = 2 Then Continue RangeOuter
	If rangeValue = 3 Then Exit RangeOuter
	rangeTotal = rangeTotal + rangeValue
Next
Local eachTotal:Int
For Local item:Int = EachIn EachValues()
	If item = 2 Then Continue
	If item = 4 Then Exit
	eachTotal = eachTotal + item
Next
Local eachWords:String[] = ["one", "two"]
For Local word:String = EachIn eachWords
	If word Then eachTotal = eachTotal + 1
Next
Local eachRows:Int[][] = [[1], [2, 3]]
For Local row:Int[] = EachIn eachRows
	eachTotal = eachTotal + row.length
Next
Local eachExisting:Int
Local eachValues:Int[] = [5, 6]
For eachExisting = EachIn eachValues
	eachTotal = eachTotal + eachExisting
Next
Local stringEachTotal:Int
For Local code:Int = EachIn EachText()
	If code = 66 Then Continue
	stringEachTotal = stringEachTotal + code
Next
Local stringEachExisting:Short
For stringEachExisting = EachIn "D"
	stringEachTotal = stringEachTotal + stringEachExisting
Next
Local StaticArray staticValues:Int[4]
staticValues[0] = 1
staticValues[1] = 2
staticValues[2] = 3
staticValues[3] = 4
Local staticEachTotal:Int = staticValues.length
For Local staticValue:Short = EachIn staticValues
	If staticValue = 2 Then Continue
	staticEachTotal = staticEachTotal + staticValue
Next
Local legacyEachCount:Int
Local legacyEachTotal:Int
For Local legacyValue:Object = EachIn New TLegacyRuntimeValues
	legacyEachCount = legacyEachCount + 1
	If legacyEachCount = 2 Then Continue
	If legacyEachCount = 4 Then Exit
	If legacyValue Then legacyEachTotal = legacyEachTotal + 1
Next
Local emptyObject:Object
Local eachObjects:Object[] = [event, emptyObject, CreateEvent(4)]
Local objectEachTotal:Int
For Local filtered:TEvent = EachIn eachObjects
	objectEachTotal = objectEachTotal + 1
Next
For Local filtered:Object = EachIn eachObjects
	objectEachTotal = objectEachTotal + 1
Next
Local sourceEachObjects:Object[] = [New TEachBase, New TEachChild, emptyObject]
Local sourceObjectEachTotal:Int
For Local filtered:TEachChild = EachIn sourceEachObjects
	sourceObjectEachTotal = sourceObjectEachTotal + 1
Next
If Not empty
	If first
		If joined.length = 4 And literal.length = 2 And literal[0] = event And loopTotal = 4 And rangeTotal = 22 And eachTotal = 20 And stringEachTotal = 200 And staticEachTotal = 12 And legacyEachCount = 4 And legacyEachTotal = 2 And objectEachTotal = 4 And sourceObjectEachTotal = 1 Then WriteStdout("imported defaults runtime ok~n")
	End If
End If
