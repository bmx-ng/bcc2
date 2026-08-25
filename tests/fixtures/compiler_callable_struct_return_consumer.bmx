SuperStrict
Framework BRL.Blitz

Import acme.returnedstructcallbacks

Local owner:SReturnedCallbacks
Local methodCallback:Int(value:Int Var) = owner.Choose(True)
Local functionCallback:Int(value:Int Var) = SReturnedCallbacks.Pick(True)

Local methodValue:Int = 40
methodCallback(methodValue)
owner.Choose(True)(methodValue)

Local functionValue:Int = 40
functionCallback(functionValue)
SReturnedCallbacks.Pick(True)(functionValue)

If methodValue = 42 And functionValue = 42
	WriteStdout("bcc2 public callable Struct return runtime ok~n")
End If
