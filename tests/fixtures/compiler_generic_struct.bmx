SuperStrict

Struct TValueBox<T>
	Field value:T

	Method Read:T()
		Return value
	End Method
End Struct

Global first:TValueBox<String>
Global second:TValueBox<String>
Global observed:String

first.value = "canonical struct"
second = first
observed = second.Read()
