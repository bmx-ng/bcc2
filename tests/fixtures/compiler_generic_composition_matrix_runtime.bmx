SuperStrict

Framework BRL.StandardIO

Type TMatrixPayload
	Field value:Int

	Method New(value:Int)
		Self.value = value
	End Method
End Type

Type TMatrixOrdered<T>
	Field value:T

	Method New(value:T)
		Self.value = value
	End Method

	Method Operator <:Int(other:TMatrixOrdered<T>)
		Return value < other.value
	End Method

	Method Operator >:Int(other:TMatrixOrdered<T>)
		Return value > other.value
	End Method

	Method Before:Int(other:TMatrixOrdered<T>)
		Return value < other.value
	End Method

	Method After:Int(other:TMatrixOrdered<T>)
		Return value > other.value
	End Method

	Method AtMost:Int(other:TMatrixOrdered<T>)
		Return value <= other.value
	End Method

	Method AtLeast:Int(other:TMatrixOrdered<T>)
		Return value >= other.value
	End Method
End Type

Struct SMatrixPair<T>
	Field value:T
	Field transform:Closure<T(value:T)>
End Struct

Type TMatrixTypeOwner<T>
	Method Apply:T(value:T, transform:Closure<T(value:T)>)
		Local pair:SMatrixPair<T>
		pair.value = value
		pair.transform = transform
		Local pairs:SMatrixPair<T>[] = [pair]
		pairs = pairs + [pair]
		Local matrix:T[,] = New T[1, 2]
		For Local current:SMatrixPair<T>=EachIn pairs
			matrix[0, 1] = current.transform(current.value)
		Next
		Return matrix[0, 1]
	End Method
End Type

Struct SMatrixStructOwner<T>
	Method Apply:T(value:T, transform:Closure<T(value:T)>)
		Local pair:SMatrixPair<T>
		pair.value = value
		pair.transform = transform
		Local pairs:SMatrixPair<T>[] = [pair]
		pairs = pairs + [pair]
		Local matrix:T[,] = New T[1, 2]
		For Local current:SMatrixPair<T>=EachIn pairs
			matrix[0, 1] = current.transform(current.value)
		Next
		Return matrix[0, 1]
	End Method
End Struct

Type TMatrixMethodOwner
	Method Apply<T>:T(value:T, transform:Closure<T(value:T)>)
		Local pair:SMatrixPair<T>
		pair.value = value
		pair.transform = transform
		Local pairs:SMatrixPair<T>[] = [pair]
		pairs = pairs + [pair]
		Local matrix:T[,] = New T[1, 2]
		For Local current:SMatrixPair<T>=EachIn pairs
			matrix[0, 1] = current.transform(current.value)
		Next
		Return matrix[0, 1]
	End Method
End Type

Type TMatrixBase<A, B>
	Field values:B

	Method Values:B()
		Return values
	End Method
End Type

Type TMatrixMiddle<X> Extends TMatrixBase<String, X[]>
End Type

Type TMatrixInheritedOwner<T> Extends TMatrixMiddle<T>
	Method Apply:T(value:T, transform:Closure<T(value:T)>)
		Local pair:SMatrixPair<T>
		pair.value = value
		pair.transform = transform
		Local pairs:SMatrixPair<T>[] = [pair]
		pairs = pairs + [pair]
		Local matrix:T[,] = New T[1, 2]
		For Local current:SMatrixPair<T>=EachIn pairs
			matrix[0, 1] = current.transform(current.value)
		Next
		values = [value]
		Return matrix[0, 1]
	End Method
End Type

Global stringTransform:Closure<String(value:String)> = Function(value:String)
	Return value + "!"
End Function

Global objectTransform:Closure<TMatrixPayload(value:TMatrixPayload)> = Function(value:TMatrixPayload)
	Return New TMatrixPayload(value.value + 1)
End Function

Global arrayTransform:Closure<Int[](value:Int[])> = Function(value:Int[])
	Return value + [99]
End Function

Global closureTransform:Closure<Closure<Int()>(value:Closure<Int()>)> = Function(value:Closure<Int()>)
	Return Function()
		Return value() + 1
	End Function
End Function

Function SeedClosure:Closure<Int()>()
	Return Function()
		Return 42
	End Function
End Function

Function CheckString(value:String, label:String)
	If value <> "seed!" Then Throw label + ": expected seed!, received " + value
End Function

Function CheckObject(value:TMatrixPayload, label:String)
	If Not value Or value.value <> 6 Then Throw label + ": object result was not retained"
End Function

Function CheckArray(value:Int[], label:String)
	If Not value Or value.length <> 3 Or value[0] <> 1 Or value[1] <> 2 Or value[2] <> 99 Then Throw label + ": Array result was not retained"
End Function

Function CheckClosure(value:Closure<Int()>, label:String)
	If Not value Or value() <> 43 Then Throw label + ": nested Closure result was not retained"
End Function

Function RunTypeOwner()
	Local ownerString:TMatrixTypeOwner<String> = New TMatrixTypeOwner<String>
	CheckString(ownerString.Apply("seed", stringTransform), "type-string")
	Local ownerObject:TMatrixTypeOwner<TMatrixPayload> = New TMatrixTypeOwner<TMatrixPayload>
	CheckObject(ownerObject.Apply(New TMatrixPayload(5), objectTransform), "type-object")
	Local ownerArray:TMatrixTypeOwner<Int[]> = New TMatrixTypeOwner<Int[]>
	CheckArray(ownerArray.Apply([1, 2], arrayTransform), "type-array")
	Local ownerClosure:TMatrixTypeOwner<Closure<Int()>> = New TMatrixTypeOwner<Closure<Int()>>
	CheckClosure(ownerClosure.Apply(SeedClosure(), closureTransform), "type-closure")
End Function

Function RunStructOwner()
	Local ownerString:SMatrixStructOwner<String>
	CheckString(ownerString.Apply("seed", stringTransform), "struct-string")
	Local ownerObject:SMatrixStructOwner<TMatrixPayload>
	CheckObject(ownerObject.Apply(New TMatrixPayload(5), objectTransform), "struct-object")
	Local ownerArray:SMatrixStructOwner<Int[]>
	CheckArray(ownerArray.Apply([1, 2], arrayTransform), "struct-array")
	Local ownerClosure:SMatrixStructOwner<Closure<Int()>>
	CheckClosure(ownerClosure.Apply(SeedClosure(), closureTransform), "struct-closure")
End Function

Function RunMethodOwner()
	Local owner:TMatrixMethodOwner = New TMatrixMethodOwner
	CheckString(owner.Apply<String>("seed", stringTransform), "method-string")
	CheckObject(owner.Apply<TMatrixPayload>(New TMatrixPayload(5), objectTransform), "method-object")
	CheckArray(owner.Apply<Int[]>([1, 2], arrayTransform), "method-array")
	CheckClosure(owner.Apply<Closure<Int()>>(SeedClosure(), closureTransform), "method-closure")
End Function

Function RunInheritedOwner()
	Local ownerString:TMatrixInheritedOwner<String> = New TMatrixInheritedOwner<String>
	CheckString(ownerString.Apply("seed", stringTransform), "inheritance-string")
	Local baseString:TMatrixBase<String, String[]> = ownerString
	If baseString.Values().length <> 1 Or baseString.Values()[0] <> "seed" Then Throw "inheritance-string: inherited field"

	Local ownerObject:TMatrixInheritedOwner<TMatrixPayload> = New TMatrixInheritedOwner<TMatrixPayload>
	Local objectValue:TMatrixPayload = New TMatrixPayload(5)
	CheckObject(ownerObject.Apply(objectValue, objectTransform), "inheritance-object")
	Local baseObject:TMatrixBase<String, TMatrixPayload[]> = ownerObject
	If baseObject.Values().length <> 1 Or baseObject.Values()[0] <> objectValue Then Throw "inheritance-object: inherited field"

	Local ownerArray:TMatrixInheritedOwner<Int[]> = New TMatrixInheritedOwner<Int[]>
	Local arrayValue:Int[] = [1, 2]
	CheckArray(ownerArray.Apply(arrayValue, arrayTransform), "inheritance-array")
	Local baseArray:TMatrixBase<String, Int[][]> = ownerArray
	If baseArray.Values().length <> 1 Or baseArray.Values()[0] <> arrayValue Then Throw "inheritance-array: inherited field"

	Local ownerClosure:TMatrixInheritedOwner<Closure<Int()>> = New TMatrixInheritedOwner<Closure<Int()>>
	Local closureValue:Closure<Int()> = SeedClosure()
	CheckClosure(ownerClosure.Apply(closureValue, closureTransform), "inheritance-closure")
	Local baseClosure:TMatrixBase<String, Closure<Int()>[]> = ownerClosure
	If baseClosure.Values().length <> 1 Or baseClosure.Values()[0]() <> 42 Then Throw "inheritance-closure: inherited field"
End Function

Function RunStringOrdering()
	Local first:TMatrixOrdered<String> = New TMatrixOrdered<String>("alpha")
	Local second:TMatrixOrdered<String> = New TMatrixOrdered<String>("beta")
	If Not first.Before(second) Then Throw "generic String <: ordering was lost"
	If Not second.After(first) Then Throw "generic String >: ordering was lost"
	If Not first.AtMost(first) Then Throw "generic String <= ordering was lost"
	If Not second.AtLeast(first) Then Throw "generic String >= ordering was lost"
End Function

RunTypeOwner()
RunStructOwner()
RunMethodOwner()
RunInheritedOwner()
RunStringOrdering()

Print "generic-composition-matrix-runtime-ok"
