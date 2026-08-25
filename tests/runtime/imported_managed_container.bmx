SuperStrict

Framework BRL.StandardIO

Import Collections.StringMap

For Local iteration:Int = 0 Until 256
	Local values:TStringMap = New TStringMap
	values.Insert("answer", String(42))
	GCCollect()
	If String(values.ValueForKey("answer")) <> "42" Then
		Throw "imported TStringMap lost its constructed generic field"
	End If
Next

Print "imported managed container runtime regression passed"
