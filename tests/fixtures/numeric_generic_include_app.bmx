SuperStrict
Include "numeric_generic_include_declarations.bmx"
Local value:Float = 0.5
If IncludedClamp(value, 0, 1) <> value Then Throw "included numeric generic"
Print "numeric-generic-include-ok"
