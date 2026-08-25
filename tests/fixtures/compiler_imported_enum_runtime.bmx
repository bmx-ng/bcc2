SuperStrict

Framework BRL.Blitz
Import acme.states
Import "compiler_enum_registration_native.c"

Extern
	Function EnumRegistrationOk:Int() = "bcc2_enum_registration_ok"
End Extern

Local raw:Int = 5
Local state:EState = EState(raw)
Local nextState:EState = Advance(state)
Local numeric:Int = Int(nextState)
Local text:String = nextState.ToString()
Local coerced:String = nextState
Local values:EState[] = EState.Values()
Local converted:EState
Local convertedOk:Int = EState.TryConvert(9, converted)
Local parsed:EState = EState.FromString("ready")
Local access:EAccess = EAccess.Read | EAccess.Write
Local accessText:String = access.ToString()
Local parsedAccess:EAccess = EAccess.FromString("Read|Write")
Local literal:EState[] = [EState.Unknown, EState.Done]
Local joined:EState[] = values + literal

If state = EState.Unknown And nextState = EState.Ready And numeric = 6 And text = "Ready" And coerced = "Ready" And values.length = 3 And values[2] = EState.Done And convertedOk And converted = EState.Done And parsed = EState.Ready And accessText = "Read|Write" And parsedAccess = access And joined.length = 5 And joined[4] = EState.Done And EnumRegistrationOk() Then
	WriteStdout("bcc2 imported Enum runtime ok~n")
End If
