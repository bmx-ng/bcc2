SuperStrict
Framework BRL.Blitz

Import acme.varcallbacks

Local value:Int = 38
Local holder:TVarCallbackHolder = CreateVarCallbackHolder()
Local callbackInterface:IVarCallback = CreateVarCallbackImplementation()

Active(value)
holder.callback(value)
holder.Apply(Increment, value)
callbackInterface.Apply(Increment, value)

If value = 42
	WriteStdout("bcc2 public callable Var runtime ok~n")
End If
