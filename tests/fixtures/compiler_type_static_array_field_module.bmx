SuperStrict

Module acme.fixedobjects

Struct SFixedObjectCell
	Field number:Int = 11
	Field text:String
End Struct

Type TFixedObjectBase
	Field StaticArray cells:SFixedObjectCell[2]
	Field StaticArray counts:Int[3]
End Type

Type TFixedObjectChild Extends TFixedObjectBase
	Field marker:Int = 7
End Type

Function CreateFixedObjectChild:TFixedObjectChild()
	Return New TFixedObjectChild
End Function
