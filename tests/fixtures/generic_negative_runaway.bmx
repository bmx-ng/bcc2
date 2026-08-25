SuperStrict

Framework BRL.Blitz

Type TGrowingValue<T>
End Type

Function ExpandForever<T>:Int(value:T)
	Return ExpandForever<TGrowingValue<T>>(New TGrowingValue<T>)
End Function

Global InvalidExpansion:Int = ExpandForever<Int>(0)
