Framework BRL.Blitz
Import BRL.StandardIO
Import BRL.LinkedList
Import "compiler_debugger_capture_stub.c"

Local arr:String[]

Type TFoo

End Type

Local list:TList = CreateList()
list.AddLast(New TFoo)

For Local foo:TFoo = EachIn list

	Print arr[1]

Next
