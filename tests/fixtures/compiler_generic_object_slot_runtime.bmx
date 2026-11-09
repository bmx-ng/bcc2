SuperStrict

Framework BRL.StandardIO

Type TObjectSlotBase
	Method ToString:String() Override
		Return "base"
	End Method

	Method Compare:Int(other:Object) Override
		Return 1
	End Method

	Method SendMessage:Object(message:Object, source:Object) Override
		Return source
	End Method

	Method HashCode:UInt() Override
		Return 2
	End Method

	Method Equals:Int(other:Object) Override
		Return False
	End Method
End Type

Type TObjectSlotDerived Extends TObjectSlotBase
	Method ToString:String() Override
		Return "derived"
	End Method

	Method Compare:Int(other:Object) Override
		Return 11
	End Method

	Method SendMessage:Object(message:Object, source:Object) Override
		Return message
	End Method

	Method HashCode:UInt() Override
		Return 12
	End Method

	Method Equals:Int(other:Object) Override
		Return Self = other
	End Method
End Type

Function ExerciseObjectSlots<T>:Int(value:TObjectSlotBase, other:Object)
	If value.ToString() <> "derived" Then Return 1
	If value.Compare(other) <> 11 Then Return 2
	If value.SendMessage(other, Null) <> other Then Return 3
	If value.HashCode() <> 12 Then Return 4
	If Not value.Equals(other) Then Return 5
	Return 0
End Function

Local value:TObjectSlotBase = New TObjectSlotDerived
Local result:Int = ExerciseObjectSlots<String>(value, value)
If result Then RuntimeError "generic Object-slot dispatch failed: " + result

Print "generic Object-slot dispatch passed"
