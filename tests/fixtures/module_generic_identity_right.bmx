SuperStrict

Module Bcc2IdentityTest.Right

Private

Type TPrivateIdentityBox<T>
	Field value:T
End Type

Public

Function RightIdentity:String()
	Local box:TPrivateIdentityBox<String> = New TPrivateIdentityBox<String>
	box.value = "right-module"
	Return box.value
End Function
