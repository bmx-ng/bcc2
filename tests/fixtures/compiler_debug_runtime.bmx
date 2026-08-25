SuperStrict

Framework BRL.Blitz

Const debugAnswer:Int = 40
Const debugLabel:String = "bcc2"
Const debugEmpty:String = ""
Global debugConstructorCount:Int
Global debugText:String = debugLabel
Global assertionConditionCount:Int
Global assertionMessageCount:Int

Type TDebugValue
	Field value:Int

	Method Read:Int(delta:Int)
		Return value + delta
	End Method
End Type

Struct SDebugValue
	Field value:Int

	Method New()
		debugConstructorCount = debugConstructorCount + 1
	End Method

	Method Read:Int()
		Return value
	End Method
End Struct

Function Increment:Int(value:Int Var)
	value = value + 1
	Return value
End Function

Function NextIndex:Int(index:Int Var)
	Local result:Int = index
	index = index + 1
	Return result
End Function

Function AssertionCondition:Int(value:Int)
	assertionConditionCount = assertionConditionCount + 1
	Return value
End Function

Function AssertionMessage:String()
	assertionMessageCount = assertionMessageCount + 1
	Return "unexpected debug runtime result"
End Function

Function NoDebugContribution:Int() NoDebug
	Local hidden:Int
	Return hidden
End Function

Function ScopedFlow:Int()
	Local total:Int = 0
	#Outer
	For Local outer:Int = 0 Until 4
		Local current:Int = outer
		While current > 0
			Local nested:Int = current
			If nested = 99 Then Return total
			current = current - 1
			If nested = 3 Then Continue Outer
			If nested = 2 Then Exit
			total = total + nested
		Wend
	Next
	Return total
End Function

Local item:TDebugValue = New TDebugValue
item.value = debugAnswer / 2
Local cell:SDebugValue
cell.value = 1
Local values:Int[] = [20, 22]
Local dynamicIndex:Int
Local dynamicValue:Int = values[NextIndex(dynamicIndex)]
Local StaticArray fixed:Int[2]
fixed[0] = 2
Local fixedIndex:Int
Local fixedValue:Int = fixed[NextIndex(fixedIndex)]
Local result:Int = item.Read(Increment(item.value)) + cell.Read() + ScopedFlow() + NoDebugContribution() + debugConstructorCount + dynamicValue + fixedValue
Local raw:Byte Ptr = MemAlloc(2)
raw[0] = 20
raw[1] = 22
Local rawResult:Int = raw[0] + raw[1]
MemFree(raw)

Assert AssertionCondition(result = 67) Else AssertionMessage()
If result = 67 And rawResult = 42 And dynamicIndex = 1 And fixedIndex = 1 And assertionConditionCount = 1 And assertionMessageCount = 0 Then
	WriteStdout("bcc2 debug runtime ok~n")
End If
