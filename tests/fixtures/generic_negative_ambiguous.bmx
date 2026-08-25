SuperStrict

Framework BRL.Blitz

Function Choose<T>:Int(value:T, left:Int, right:Float)
	Return 1
End Function

Function Choose<T>:Int(value:T, left:Float, right:Int)
	Return 2
End Function

Global InvalidChoice:Int = Choose<Int>(1, 1, 1)
