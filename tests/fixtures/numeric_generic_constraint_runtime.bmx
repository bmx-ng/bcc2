SuperStrict

Function Clamp<T>:T(value:T, low:T, high:T) Where T Is Numeric
	If value < low Then Return low
	If value > high Then Return high
	Return value
End Function

Function IntegralProbe<T>:T(a:T, b:T, shift:T) Where T Is Integral
	Return ((a Mod b) Shl shift) & a
End Function

Struct SClamp<T> Where T Is Numeric
	Method Apply:T(value:T, low:T, high:T)
		If value < low Then Return low
		If value > high Then Return high
		Return value
	End Method
End Struct

Local b:Byte = 1
Local s:Short = 1
Local i:Int = 1
Local ui:UInt = 1
Local l:Long = 1
Local ul:ULong = 1
Local li:LongInt = 1
Local uli:ULongInt = 1
Local z:Size_T = 1
Local f:Float = 0.5
Local d:Double = 0.5
If Clamp(b, 0, 1) <> b Or Clamp(s, 0, 1) <> s Or Clamp(i, 0, 1) <> i Then Throw "small integral clamp"
If Clamp(ui, 0, 1) <> ui Or Clamp(l, 0, 1) <> l Or Clamp(ul, 0, 1) <> ul Then Throw "wide integral clamp"
If Clamp(li, 0, 1) <> li Or Clamp(uli, 0, 1) <> uli Or Clamp(z, 0, 1) <> z Then Throw "special integral clamp"
If Clamp(f, 0, 1) <> f Or Clamp(d, 0, 1) <> d Then Throw "floating clamp"
If IntegralProbe<Byte>(3, 2, 1) <> 2 Or IntegralProbe<Short>(3, 2, 1) <> 2 Or IntegralProbe<Int>(3, 2, 1) <> 2 Then Throw "small integral operators"
If IntegralProbe<UInt>(3, 2, 1) <> 2 Or IntegralProbe<Long>(3, 2, 1) <> 2 Or IntegralProbe<ULong>(3, 2, 1) <> 2 Then Throw "wide integral operators"
If IntegralProbe<LongInt>(3, 2, 1) <> 2 Or IntegralProbe<ULongInt>(3, 2, 1) <> 2 Or IntegralProbe<Size_T>(3, 2, 1) <> 2 Then Throw "special integral operators"
Local calculator:SClamp<Double>
If calculator.Apply(d, 0, 1) <> d Then Throw "constrained method"
Print "numeric-generic-constraint-runtime-ok"
