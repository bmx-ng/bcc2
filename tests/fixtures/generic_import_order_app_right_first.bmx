SuperStrict

Framework BRL.StandardIO

Import Bcc2ImportOrderTest.Right
Import Bcc2ImportOrderTest.Left

Local left:Closure<Int()> = LeftPipeline<Int>(40)
Local right:String = RightPipeline<String>("ordered")

If left() + 2 = 42 And right = "ordered" Then
	Print "generic-import-order-ok"
Else
	Print "generic-import-order-failed"
End If
