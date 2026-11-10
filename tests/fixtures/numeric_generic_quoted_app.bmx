SuperStrict
Import "numeric_generic_quoted_provider.bmx"
Local value:Double = 0.5
If QuotedClamp(value, 0, 1) <> value Then Throw "quoted numeric generic"
Print "numeric-generic-quoted-ok"
