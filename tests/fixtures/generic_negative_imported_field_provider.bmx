SuperStrict

Type TImportedOwner
	Method Read:Int(value:Int)
		Return value
	End Method
End Type

Type TImportedHolder
	Field owner:TImportedOwner
End Type

Function MakeHolder:TImportedHolder()
	Local holder:TImportedHolder = New TImportedHolder
	holder.owner = New TImportedOwner
	Return holder
End Function
