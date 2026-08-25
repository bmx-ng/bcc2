SuperStrict

Framework BRL.StandardIO

Import Bcc2PackageIntegrityTest.Owner

Local box:TIntegrityBox<Int> = New TIntegrityBox<Int>
box.value = IntegrityIdentity<Int>(40)
Local deferred:Closure<Int()> = IntegrityDeferred<Int>(box.Read() + 2)

If ProviderIntegrityValue() = "provider" And deferred() = 42 Then
	Print "generic-package-integrity-ok"
Else
	Print "generic-package-integrity-failed"
End If
