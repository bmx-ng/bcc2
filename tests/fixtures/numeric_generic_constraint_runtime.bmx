SuperStrict

Import BRL.Math

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

Struct SLength<T> Where T Is Numeric
	Field x:T
	Field y:T

	Method New(x:T, y:T)
		Self.x = x
		Self.y = y
	End Method

	Method Length:T()
		Return T(Sqr(Double(x * x + y * y)))
	End Method
End Struct

Struct SFloatingLength<T> Where T Is Floating
	Field x:T
	Field y:T

	Method New(x:T, y:T)
		Self.x = x
		Self.y = y
	End Method

	Method LengthSquared:T()
		Return x * x + y * y
	End Method

	Method Length:T()
		Return Sqr(LengthSquared())
	End Method

	Method DoubleValue:Double()
		Return x
	End Method
End Struct

Struct SReflect<T> Where T Is Numeric
	Field x:T
	Field y:T

	Method New(x:T, y:T)
		Self.x = x
		Self.y = y
	End Method

	Method Operator*:SReflect<T>(scale:T)
		Return New SReflect<T>(x * scale, y * scale)
	End Method

	Method Operator-:SReflect<T>(other:SReflect<T>)
		Return New SReflect<T>(x - other.x, y - other.y)
	End Method

	Method Dot:T(other:SReflect<T>)
		Return x * other.x + y * other.y
	End Method

	Method Reflect:SReflect<T>(normal:SReflect<T>)
		Return normal * Dot(normal) * 2.0 - Self
	End Method

	Method ReflectCast:SReflect<T>(normal:SReflect<T>)
		Return normal * Dot(normal) * T(2.0) - Self
	End Method

	Method ToDouble:Double()
		Return Double(x)
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
Local vectorFloat:SReflect<Float> = New SReflect<Float>(1.0, 2.0)
Local normalFloat:SReflect<Float> = New SReflect<Float>(1.0, 0.0)
Local reflectedFloat:SReflect<Float> = vectorFloat.Reflect(normalFloat)
If reflectedFloat.x <> 1.0 Or reflectedFloat.y <> -2.0 Then Throw "numeric vector reflection"
Local castFloat:SReflect<Float> = vectorFloat.ReflectCast(normalFloat)
If castFloat.x <> reflectedFloat.x Or castFloat.y <> reflectedFloat.y Or vectorFloat.ToDouble() <> 1.0 Then Throw "numeric vector explicit casts"
Local vectorInt:SReflect<Int> = New SReflect<Int>(1, 2)
Local normalInt:SReflect<Int> = New SReflect<Int>(1, 0)
Local reflectedInt:SReflect<Int> = vectorInt.Reflect(normalInt)
If reflectedInt.x <> 1 Or reflectedInt.y <> -2 Then Throw "integral vector reflection"
Local lengthFloat:SLength<Float> = New SLength<Float>(3.0, 4.0)
Local lengthInt:SLength<Int> = New SLength<Int>(3, 4)
If lengthFloat.Length() <> 5.0 Or lengthInt.Length() <> 5 Then Throw "numeric vector length casts"
Local floatingLengthFloat:SFloatingLength<Float> = New SFloatingLength<Float>(3.0, 4.0)
Local floatingLengthDouble:SFloatingLength<Double> = New SFloatingLength<Double>(3.0, 4.0)
If floatingLengthFloat.Length() <> 5.0 Or floatingLengthDouble.Length() <> 5.0 Then Throw "floating vector length"
If floatingLengthFloat.DoubleValue() <> 3.0 Then Throw "floating vector widening"
Print "numeric-generic-constraint-runtime-ok"
