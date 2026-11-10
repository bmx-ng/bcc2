SuperStrict

Framework BRL.StandardIO

Struct SOperatorVector<T>
	Field x:T
	Field y:T

	Method Operator +:SOperatorVector<T>(other:SOperatorVector<T>)
		Local result:SOperatorVector<T>
		result.x = x + other.x
		result.y = y + other.y
		Return result
	End Method

	Method Operator -:SOperatorVector<T>(other:SOperatorVector<T>)
		Local result:SOperatorVector<T>
		result.x = x - other.x
		result.y = y - other.y
		Return result
	End Method

	Method Operator *:SOperatorVector<T>(scale:T)
		Local result:SOperatorVector<T>
		result.x = x * scale
		result.y = y * scale
		Return result
	End Method

	Method Dot:T(other:SOperatorVector<T>)
		Return x * other.x + y * other.y
	End Method

	Method Scaled:SOperatorVector<T>(scale:T)
		Return Self * scale
	End Method

	Method Reflect:SOperatorVector<T>(normal:SOperatorVector<T>)
		Local projection:T = Dot(normal)
		Return normal * (projection + projection) - Self
	End Method

	Method AddInPlace(other:SOperatorVector<T>)
		x :+ other.x
		y :+ other.y
	End Method
End Struct

Struct SManagedPair<T>
	Field first:T
	Field second:T

	Method Operator +:SManagedPair<T>(other:SManagedPair<T>)
		Local result:SManagedPair<T>
		result.first = first + other.first
		result.second = second + other.second
		Return result
	End Method
End Struct

Type TVectorHolder
	Field value:SOperatorVector<Int>
End Type

Type TOperatorBox<T>
	Field value:T

	Method Operator +:TOperatorBox<T>(other:TOperatorBox<T>)
		Local result:TOperatorBox<T> = New TOperatorBox<T>
		result.value = value + other.value
		Return result
	End Method
End Type

Local intA:SOperatorVector<Int>
intA.x = 1
intA.y = 2
Local intB:SOperatorVector<Int>
intB.x = 3
intB.y = 4

Local intSum:SOperatorVector<Int> = intA + intB
If intSum.x <> 4 Or intSum.y <> 6 Then RuntimeError "direct generic Struct operator failed"

Local intChain:SOperatorVector<Int> = intA + intB + intA
If intChain.x <> 5 Or intChain.y <> 8 Then RuntimeError "chained generic Struct operator failed"

Local methodChain:SOperatorVector<Int> = intA.Scaled(2).Scaled(3)
If methodChain.x <> 6 Or methodChain.y <> 12 Then RuntimeError "temporary generic Struct Method receiver failed"

If (intA + intB).Dot(intA) <> 16 Then RuntimeError "temporary generic Struct operator receiver failed"

Local normal:SOperatorVector<Int>
normal.x = 1
Local reflected:SOperatorVector<Int> = intA.Reflect(normal)
If reflected.x <> 1 Or reflected.y <> -2 Then RuntimeError "generic Struct Reflect expression failed"

Local mutated:SOperatorVector<Int> = intA
mutated.AddInPlace(intB)
If mutated.x <> 4 Or mutated.y <> 6 Then RuntimeError "addressable generic Struct receiver failed"

Local vectors:SOperatorVector<Int>[1]
vectors[0] = intA
vectors[0].AddInPlace(intB)
If vectors[0].x <> 4 Or vectors[0].y <> 6 Then RuntimeError "Array element generic Struct receiver failed"

Local holder:TVectorHolder = New TVectorHolder
holder.value = intA
holder.value.AddInPlace(intB)
If holder.value.x <> 4 Or holder.value.y <> 6 Then RuntimeError "field generic Struct receiver failed"

Local floatValue:SOperatorVector<Float>
floatValue.x = 1.5
floatValue.y = 2.5
Local floatScaled:SOperatorVector<Float> = floatValue.Scaled(0.5)
If floatScaled.x <> 0.75 Or floatScaled.y <> 1.25 Then RuntimeError "Float generic Struct specialization failed"

Local doubleValue:SOperatorVector<Double>
doubleValue.x = 2.0
doubleValue.y = 4.0
Local doubleScaled:SOperatorVector<Double> = doubleValue.Scaled(0.25)
If doubleScaled.x <> 0.5 Or doubleScaled.y <> 1.0 Then RuntimeError "Double generic Struct specialization failed"

Local longValue:SOperatorVector<Long>
longValue.x = 5
longValue.y = 7
Local longScaled:SOperatorVector<Long> = longValue.Scaled(3)
If longScaled.x <> 15 Or longScaled.y <> 21 Then RuntimeError "Long generic Struct specialization failed"

Local stringA:SManagedPair<String>
stringA.first = "a"
stringA.second = "b"
Local stringB:SManagedPair<String>
stringB.first = "c"
stringB.second = "d"
Local stringChain:SManagedPair<String> = stringA + stringB + stringA
If stringChain.first <> "aca" Or stringChain.second <> "bdb" Then RuntimeError "managed generic Struct specialization failed"

Local boxA:TOperatorBox<Int> = New TOperatorBox<Int>
Local boxB:TOperatorBox<Int> = New TOperatorBox<Int>
Local boxC:TOperatorBox<Int> = New TOperatorBox<Int>
boxA.value = 1
boxB.value = 2
boxC.value = 4
Local boxResult:TOperatorBox<Int> = boxA + boxB + boxC
If boxResult.value <> 7 Then RuntimeError "generic Type operator dispatch regressed"

Print "generic Struct operator runtime passed"
