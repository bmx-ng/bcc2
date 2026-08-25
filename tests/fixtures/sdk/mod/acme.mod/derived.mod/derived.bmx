SuperStrict

Module acme.derived

Import acme.base

Type TDerived Extends TBase
	Field DerivedValue:Int

	Method New(initialBaseValue:Int, initialDerivedValue:Int)
		BaseValue = initialBaseValue
		DerivedValue = initialDerivedValue
	End Method

	Method Sum:Int()
		Return BaseValue + DerivedValue
	End Method

	Method Score:Int(delta:Int) Override
		Return BaseValue + DerivedValue + delta
	End Method

	Method ToString:String() Override
		If DerivedValue Then Return "derived"
		Return "derived"
	End Method

	Method Compare:Int(other:Object) Override
		If other Then Return BaseValue + DerivedValue
		Return BaseValue + DerivedValue
	End Method

	Method Delete()
		DerivedValue = 0
	End Method
End Type
