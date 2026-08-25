SuperStrict

Extern
	Function CheckObjectSlots:Int() = "bcc2_check_object_slots"
End Extern

Type TBase
	Field value:Int

	Method ToString:String() Override
		Return "base"
	End Method

	Method Compare:Int(other:Object) Override
		Return value
	End Method

	Method SendMessage:Object(message:Object, sender:Object) Override
		Return message
	End Method

	Method HashCode:UInt() Override
		Return UInt(value)
	End Method

	Method Equals:Int(other:Object) Override
		Return Self = other
	End Method
End Type

Type TDerived Extends TBase
	Method ToString:String() Override
		Return "derived"
	End Method

	Method Compare:Int(other:Object) Override
		Return value + 1
	End Method
End Type

Local item:TDerived = New TDerived
item.value = 41
If item.ToString() = "derived"
	If item.Compare(item) = 42
		If item.HashCode() = 41
			If item.Equals(item)
				If CheckObjectSlots()
					WriteStdout("bcc2 Object slots runtime ok~n")
				End If
			End If
		End If
	End If
End If
