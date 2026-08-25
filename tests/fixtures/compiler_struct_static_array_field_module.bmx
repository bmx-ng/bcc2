SuperStrict

Module acme.fixedfields

Struct SFixedFieldGrid
	Field StaticArray cells:SFixedFieldCell[2]
	Field StaticArray counts:Int[3]
End Struct

Struct SFixedFieldCell
	Field number:Int = 7
	Field text:String
End Struct
