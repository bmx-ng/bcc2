SuperStrict

Framework BRL.StandardIO

Enum EFixedValue:Byte
	First = 5
	Second = 9
End Enum

Global StaticArray GlobalStrings:String[2]

Struct SFixedStrings
	Field StaticArray values:String[2]
End Struct

Type TReferenceCell
	Field value:Int
End Type

Type TReferenceHolder
	Field StaticArray cells:TReferenceCell[8]
End Type

Local holder:TReferenceHolder = New TReferenceHolder
If holder.cells[0] Then Throw "reference StaticArray default was not Null"
holder.cells[0] = New TReferenceCell
holder.cells[0].value = 42
Local cell:TReferenceCell = holder.cells[0]
If cell.value <> 42 Then Throw "reference StaticArray cell did not retain its value"

Local raw:Byte
Local StaticArray pointers:Byte Ptr[2]
pointers[1] = Varptr raw
Local pointerCount:Int
For Local pointer:Byte Ptr = EachIn pointers
	If pointer Then pointerCount :+ 1
Next
If pointerCount <> 1 Then Throw "Pointer StaticArray storage or EachIn failed"

Local StaticArray states:EFixedValue[2]
states[0] = EFixedValue.First
states[1] = EFixedValue.Second
Local stateTotal:Int
For Local state:EFixedValue = EachIn states
	stateTotal :+ state.Ordinal()
Next
If stateTotal <> 14 Then Throw "Enum StaticArray storage or EachIn failed"

Local StaticArray words:String[2]
If words[0].length <> 0 Or GlobalStrings[0].length <> 0 Then Throw "String StaticArray default was raw Null"
words[0] = "first"
words[1] = "second"
Local text:String
For Local word:String = EachIn words
	text :+ word
Next
If text <> "firstsecond" Then Throw "String StaticArray EachIn failed"

Local fixedStrings:SFixedStrings
If fixedStrings.values[0].length <> 0 Then Throw "Struct String StaticArray default was raw Null"

Print "reference StaticArray runtime ok"
