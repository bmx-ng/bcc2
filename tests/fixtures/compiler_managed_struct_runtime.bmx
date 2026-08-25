SuperStrict

Struct SManagedValue
	Field text:String
	Field items:Int[]
	Field owner:Object
End Struct

Struct SManagedOuter
	Field value:SManagedValue
End Struct

Type TManagedHolder
	Field value:SManagedOuter
End Type

Global Direct:SManagedValue
Global Holder:TManagedHolder = New TManagedHolder
