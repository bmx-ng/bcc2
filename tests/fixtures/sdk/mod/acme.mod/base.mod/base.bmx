SuperStrict

Module acme.base

Type TBase
	Field BaseValue:Int

	Method Score:Int(delta:Int)
		Return BaseValue + delta
	End Method

	Method ToString:String() Override
		If BaseValue Then Return "base"
		Return "base"
	End Method

	Method Compare:Int(other:Object) Override
		If other Then Return BaseValue
		Return BaseValue
	End Method

	Method SendMessage:Object(message:Object, sender:Object) Override
		If Self = sender Then Return message
		Return message
	End Method

	Method HashCode:UInt() Override
		Return UInt(BaseValue)
	End Method

	Method Equals:Int(other:Object) Override
		Return Self = other
	End Method

	Method Delete()
		BaseValue = 0
	End Method

	Function Double:Int(value:Int)
		Return value * 2
	End Function
End Type
