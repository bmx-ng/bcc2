SuperStrict

Framework BRL.StandardIO
Import Bcc2GenericStructOperatorTest.Provider

Local a:SModuleVector<Double>
a.x = 1.25
a.y = 2.5
Local b:SModuleVector<Double>
b.x = 0.5
b.y = 1.0
Local added:SModuleVector<Double> = a.AddTwice(b)
If added.x <> 2.25 Or added.y <> 4.5 Then RuntimeError "module generic Struct operator failed"
Local scaled:SModuleVector<Double> = a.Scaled(4.0).Scaled(0.25)
If scaled.x <> 1.25 Or scaled.y <> 2.5 Then RuntimeError "module temporary Struct receiver failed"

Print "generic Struct operator module passed"
