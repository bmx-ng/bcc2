SuperStrict

Function Echo:String(value:String)
	Return value
End Function

Global Greeting:String = "bcc2 String runtime " + 42 + " ok~n"
Global Empty:String
Global RuntimeDirectory:String = AppDir
Global Parsed:Int = "42"

If Empty
	WriteStdout("invalid String truth~n")
Else If Greeting > ""
	If Not Empty
		If Parsed = 42
			WriteStdout(Echo(Greeting))
		End If
	End If
End If
