SuperStrict

Framework BRL.StandardIO

Function MappedValue:Int(value:Int)
	Local adjusted:Int = value + 1
	Return adjusted
End Function

Function GenericMapped<T>:T(value:T)
	Local copied:T = value
	Return copied
End Function

Print GenericMapped<Int>(MappedValue(41))

Function ClosureMapped:Closure<Int()>(value:Int)
	Return Function()
		value :+ 1
		Return value
	End Function
End Function

Function GenericClosureMapped<T>:Closure<Int()>(value:Int)
	Return Function()
		value :+ 1
		Return value
	End Function
End Function

Local closureMappedValue:Int = ClosureMapped(40)()
Local genericClosureMappedValue:Int = GenericClosureMapped<String>(40)()
