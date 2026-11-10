SuperStrict
Framework BRL.StandardIO

Type TReceiver
	Method Read:Int(value:Int)
		Return value
	End Method
End Type

Function MakeReceiver:TReceiver()
	Return New TReceiver
End Function

Function BindComputed<T>:Closure<Int(value:Int)>(unused:T)
	Return MakeReceiver().Read
End Function

Local callback:Closure<Int(value:Int)> = BindComputed<Int>(0)
Print callback(42)
