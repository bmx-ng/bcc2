SuperStrict

Framework BRL.StandardIO

Local add:Int(value:Int) = Function(value)
	Return value + 1
End Function

Local twice:Int(value:Int) = Function:Int(value:Int)
	Return value * 2
End Function

Print add(41) + twice(4)
