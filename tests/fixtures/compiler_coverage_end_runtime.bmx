SuperStrict

Framework BRL.StandardIO

Function BeforeEnd:Int()
	Return 42
End Function

If BeforeEnd() <> 42 Then Throw "explicit End coverage mismatch"
End

Throw "unreachable after End"
