SuperStrict

Framework BRL.Blitz

Function ScopedValue<T>:T(value:T)
	Local copy:T = value
	Try
		Local nested:T = copy
		If True Then Return nested
	Finally
		copy = value
	End Try
End Function

Global scopedResult:Int = ScopedValue(7)
