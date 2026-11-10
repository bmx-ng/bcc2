SuperStrict

Framework BRL.StandardIO

Include "compiler_generic_struct_operator_boundary_provider.bmx"

Local a:SBoundaryVector<Float>
a.x = 1.5
a.y = 2.5
Local b:SBoundaryVector<Float>
b.x = 0.5
b.y = 1.5
Local added:SBoundaryVector<Float> = a.AddTwice(b)
If added.x <> 2.5 Or added.y <> 5.5 Then RuntimeError "Include generic Struct operator failed"
Local scaled:SBoundaryVector<Float> = a.Scaled(2.0).Scaled(0.5)
If scaled.x <> 1.5 Or scaled.y <> 2.5 Then RuntimeError "Include temporary Struct receiver failed"

Print "generic Struct operator Include passed"
