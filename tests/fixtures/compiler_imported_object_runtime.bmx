SuperStrict

Framework BRL.Blitz
Import BRL.Map

Local map:TMap = New TMap
Local problem:TRuntimeException = New TRuntimeException("constructed")
If map Then
	If map.IsEmpty() Then
		If map.ToString() Then
			If problem Then WriteStdout("imported object runtime ok~n")
		End If
	End If
End If
