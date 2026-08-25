SuperStrict

Module Bcc2PackageIntegrityTest.Owner

Type TIntegrityBox<T>
	Field value:T

	Method Read:T()
		Return value
	End Method
End Type

Function IntegrityIdentity<T>:T(value:T)
	Return value
End Function

Function IntegrityDeferred<T>:Closure<T()>(value:T)
	Return Function()
		Return value
	End Function
End Function

' Ensure that the provider also owns native canonical specialization outputs,
' so its build manifest covers both templates and generated C artifacts.
Function ProviderIntegrityValue:String()
	Local box:TIntegrityBox<String> = New TIntegrityBox<String>
	box.value = IntegrityIdentity<String>("provider")
	Return IntegrityDeferred<String>(box.Read())()
End Function
