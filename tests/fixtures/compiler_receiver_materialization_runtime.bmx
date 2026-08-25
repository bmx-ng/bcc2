SuperStrict

Global ReceiverCount:Int

Type TReceiver
	Field value:Int

	Method Read:Int()
		Return value
	End Method
End Type

Function MakeReceiver:TReceiver(value:Int)
	ReceiverCount = ReceiverCount + 1
	Local receiver:TReceiver = New TReceiver
	receiver.value = value
	Return receiver
End Function

Local methodValue:Int = MakeReceiver(20).Read()
Local fieldValue:Int = MakeReceiver(22).value
MakeReceiver(1).value = 7
Local newValue:Int = (New TReceiver).Read()

If ReceiverCount = 3 And methodValue = 20 And fieldValue = 22 And newValue = 0
	WriteStdout("bcc2 receiver materialization runtime ok~n")
End If
