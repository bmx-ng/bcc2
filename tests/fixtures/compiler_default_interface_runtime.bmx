SuperStrict

Framework BRL.Blitz

Interface INamed
	Method Name:String()
	Method Description:String() Default
		Return "Item: " + Name()
	End Method
End Interface

Interface IDecorated Extends INamed
	Method Description:String() Override Default
		Return Super<INamed>.Description() + "!"
	End Method
End Interface

Type TNamed Implements IDecorated
	Method Name:String()
		Return "box"
	End Method
End Type

Global named:TNamed = New TNamed
Global view:IDecorated = named
Global description:String = view.Description()
Assert description = "Item: box!"
