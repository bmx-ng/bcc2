SuperStrict
Module acme.fixedinterfaces

Interface IFixedInterfaceBase
	Method Read:Int(StaticArray values:Int[4])
End Interface

Interface IFixedInterfaceExtra
	Method Extra:Int()
End Interface

Interface IFixedInterfaceChild Extends IFixedInterfaceBase, IFixedInterfaceExtra
	Method Offset:Int()
End Interface

Type TFixedPublishedReader Implements IFixedInterfaceChild
	Method Read:Int(StaticArray values:Int[4])
		Return values[0] + values.length
	End Method

	Method Extra:Int()
		Return 1
	End Method

	Method Offset:Int()
		Return 1
	End Method
End Type

Function CreateFixedPublishedReader:TFixedPublishedReader()
	Return New TFixedPublishedReader
End Function
