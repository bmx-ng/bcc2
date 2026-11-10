SuperStrict

Framework BRL.StandardIO

Import "compiler_generic_struct_operator_boundary_provider.bmx"

Local a:SBoundaryVector<Int>
a.x = 1
a.y = 2
Local b:SBoundaryVector<Int>
b.x = 3
b.y = 4
Local added:SBoundaryVector<Int> = a.AddTwice(b)
If added.x <> 7 Or added.y <> 10 Then RuntimeError "quoted Import generic Struct operator failed"
Local scaled:SBoundaryVector<Int> = a.Scaled(2).Scaled(3)
If scaled.x <> 6 Or scaled.y <> 12 Then RuntimeError "quoted Import temporary Struct receiver failed"

Print "generic Struct operator quoted Import passed"
