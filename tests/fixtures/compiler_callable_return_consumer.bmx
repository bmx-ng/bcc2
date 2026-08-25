SuperStrict
Framework BRL.Blitz

Import acme.returnedcallbacks

Local callback:Int(value:Int Var) = Choose(True)
Local value:Int = 40
callback(value)
Choose(True)(value)

If value = 42
	WriteStdout("bcc2 public callable return runtime ok~n")
End If
