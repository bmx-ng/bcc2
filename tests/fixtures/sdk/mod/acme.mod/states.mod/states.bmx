SuperStrict

Module acme.states

Import BRL.Blitz

Enum EState:Byte
	Unknown = 5
	Ready
	Done = 9
End Enum

Enum EAccess:UInt Flags
	None = 0
	Read
	Write
	Execute
End Enum

Function Advance:EState(value:EState = EState.Unknown)
	If value = EState.Unknown Then Return EState.Ready
	Return EState.Done
End Function
