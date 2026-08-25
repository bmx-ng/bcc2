SuperStrict

Struct TInnerValue<T>
	Field value:T

	Method Read:T()
		Return value
	End Method
End Struct

Struct TOuterValue<T>
	Field inner:TInnerValue<T>
End Struct

Global first:TOuterValue<String>
Global second:TOuterValue<String>
Global observed:String

first.inner.value = "nested canonical struct"
second = first
observed = second.inner.Read()
