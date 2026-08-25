SuperStrict

Framework BRL.StandardIO

Type TConfigurationState<T>
	Field current:T

	Method Store(value:T)
		current = value
	End Method

	Method Load:T()
		Return current
	End Method
End Type

Function ConfigurationDeferred<T>:Closure<T()>(value:T)
	Local state:TConfigurationState<T> = New TConfigurationState<T>
	state.Store(value)
	Return Function()
		Return state.Load()
	End Function
End Function

Local number:Closure<Int()> = ConfigurationDeferred<Int>(42)
Local text:Closure<String()> = ConfigurationDeferred<String>("mode")

If number() = 42 And text() = "mode" Then
	Print "generic-configuration-cache-ok"
Else
	Print "generic-configuration-cache-failed"
End If
