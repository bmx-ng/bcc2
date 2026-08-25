SuperStrict

Framework BRL.StandardIO

Function Covered:Int(value:Int)
	If value Then
		Return 41
	End If
	Return -1
End Function

Local actual:Int = Covered(True)
If actual <> 41 Then Throw "coverage result mismatch"
Print "coverage-ok"
