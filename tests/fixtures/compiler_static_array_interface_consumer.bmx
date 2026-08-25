SuperStrict
Framework BRL.Blitz

Import acme.fixedinterfaces

Local StaticArray values:Int[4]
values[0] = 36

Local published:TFixedPublishedReader = CreateFixedPublishedReader()
Local child:IFixedInterfaceChild = published
Local base:IFixedInterfaceBase = child
Local extra:IFixedInterfaceExtra = child
Local result:Int = base.Read(values) + extra.Extra() + child.Offset()

If result = 42
	WriteStdout("bcc2 public StaticArray Interface runtime ok~n")
End If
