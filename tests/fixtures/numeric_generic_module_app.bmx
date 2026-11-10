SuperStrict
Import Bcc2NumericConstraintTest.Owner
Local value:Float = 0.5
If ModuleClamp(value, 0, 1) <> value Then Throw "imported Numeric routine"
Local box:SIntegralBox<Int>
box.value = 2
If box.value <> 2 Then Throw "imported Integral type"
Local floating:SFloatingBox<Float>
floating.value = 2.5
If floating.DoubleValue() <> 2.5 Then Throw "imported Floating type"
Print "numeric-generic-module-ok"
