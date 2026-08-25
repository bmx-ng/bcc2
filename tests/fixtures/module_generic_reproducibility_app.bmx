SuperStrict

Framework BRL.StandardIO

Import Bcc2ReproducibilityTest.Owner

Function ApplicationIdentity<T>:T(value:T)
	Return value
End Function

Local integerBox:TReproducibleBox<Int> = New TReproducibleBox<Int>
integerBox.value = ApplicationIdentity<Int>(ReproducibleIdentity<Int>(41))
If integerBox.Read() <> 41 Then Throw "application-owned Int specialization failed"

Local seed:Closure<Int()> = Function()
	Return 42
End Function
Local closureBox:TReproducibleBox<Closure<Int()>> = New TReproducibleBox<Closure<Int()>>
closureBox.value = ReproducibleIdentity<Closure<Int()>>(seed)
closureBox.value = ApplicationIdentity<Closure<Int()>>(closureBox.value)
If closureBox.Read()() <> 42 Then Throw "application-owned Closure specialization failed"

If ModuleReproducibleValue() <> "module" Then Throw "module-owned specialization failed"

Print "generic-reproducibility-ok"
