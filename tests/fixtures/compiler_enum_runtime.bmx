SuperStrict
Framework BRL.Blitz
Import "compiler_enum_registration_native.c"

Extern
	Function EnumRegistrationOk:Int() = "bcc2_enum_registration_ok"
End Extern

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

Function Advance:EState(value:EState)
	If value = EState.Unknown Then Return EState.Ready
	Return EState.Done
End Function

Local raw:Int = 5
Local current:EState = EState(raw)
Local nextState:EState = Advance(current)
Local numeric:Int = Int(nextState)
Local ordinal:Byte = nextState.Ordinal()
Local text:String = nextState.ToString()
Local coerced:String = nextState
Local values:EState[] = EState.Values()
Local converted:EState
Local convertedOk:Int = EState.TryConvert(9, converted)
Local parsed:EState = EState.FromString("ready")
Local access:EAccess = EAccess.Read | EAccess.Write
Local accessText:String = access.ToString()
Local parsedAccess:EAccess = EAccess.FromString("Read|Write")
Local created:EState[] = New EState[2]
created[0] = EState.Ready
Local literal:EState[] = [EState.Unknown, EState.Done]
Local joined:EState[] = values + literal

If current = EState.Unknown And nextState = EState.Ready And numeric = 6 And ordinal = 6 And text = "Ready" And coerced = "Ready" And values.length = 3 And values[0] = EState.Unknown And values[2] = EState.Done And convertedOk And converted = EState.Done And parsed = EState.Ready And accessText = "Read|Write" And parsedAccess = access And created[0] = EState.Ready And literal[1] = EState.Done And joined.length = 5 And joined[3] = EState.Unknown And joined[4] = EState.Done And EnumRegistrationOk()
	WriteStdout("bcc2 scalar Enum runtime ok~n")
End If
