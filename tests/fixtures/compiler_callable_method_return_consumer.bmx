SuperStrict
Framework BRL.Blitz

Import acme.returnedmethodcallbacks

Local owner:TReturnedBase = CreateReturned()
Local iface:IReturnedChooser = CreateReturnedImplementation()
Local callback:Int(value:Int Var) = owner.Choose(True)
Local value:Int = 40
callback(value)
iface.Choose(True)(value)

Local typeCallback:Int(value:Int Var) = TReturnedFunctions.Choose(True)
Local typeValue:Int = 40
typeCallback(typeValue)
TReturnedFunctions.Choose(True)(typeValue)

If value = 42 And typeValue = 42
	WriteStdout("bcc2 public callable method return runtime ok~n")
End If
