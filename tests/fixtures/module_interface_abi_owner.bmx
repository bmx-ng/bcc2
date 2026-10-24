SuperStrict

Module Bcc2InterfaceAbi.Owner

Import Bcc2InterfaceAbi.Box

Interface IProvider
	Method Value:Int()
End Interface

Type TRegistry
	Field provider:TBox<IProvider>
End Type
