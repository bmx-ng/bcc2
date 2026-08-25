SuperStrict

Module Bcc2IdentityTest.Left

Private

Type TPrivateIdentityBox<T>
	Field value:T
End Type

Public

Function LeftIdentity:String()
	Local box:TPrivateIdentityBox<String> = New TPrivateIdentityBox<String>
	box.value = "left-module"
	Return box.value
End Function
