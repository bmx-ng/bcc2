SuperStrict

Framework BRL.StandardIO

Interface IValue
	Method Value:Int()
End Interface

Type TValue Implements IValue
	Field value:Int

	Method Value:Int()
		Return value
	End Method
End Type

Struct TIntPair
	Field left:Int
	Field right:Int
End Struct

Type TBox<T>
	Field value:T
End Type

Type TFunctions<T>
	Function Identity<U>:U(value:U)
		Return value
	End Function
End Type

Function Identity<T>:T(value:T)
	Return value
End Function

Function ApplyIdentity<T>:T(value:T)
	Local callback:T(value:T) = Identity<T>
	Return callback(value)
End Function

Local intIdentity:Int(value:Int) = Identity<Int>
If intIdentity(42) <> 42 Then Throw "Int generic routine reference failed"

Local stringIdentity:String(value:String) = Identity<String>
If stringIdentity("text") <> "text" Then Throw "String generic routine reference failed"

Local values:Int[] = [1, 2, 3]
Local arrayIdentity:Int[](value:Int[]) = Identity<Int[]>
If arrayIdentity(values) <> values Then Throw "Array generic routine reference failed"

Local objectValue:TValue = New TValue
objectValue.value = 7
Local objectIdentity:TValue(value:TValue) = Identity<TValue>
If objectIdentity(objectValue) <> objectValue Then Throw "Object generic routine reference failed"

Local interfaceValue:IValue = objectValue
Local interfaceIdentity:IValue(value:IValue) = Identity<IValue>
If interfaceIdentity(interfaceValue).Value() <> 7 Then Throw "Interface generic routine reference failed"

Local pair:TIntPair
pair.left = 20
pair.right = 22
Local structIdentity:TIntPair(value:TIntPair) = Identity<TIntPair>
Local samePair:TIntPair = structIdentity(pair)
If samePair.left + samePair.right <> 42 Then Throw "Struct generic routine reference failed"

Local box:TBox<String> = New TBox<String>
box.value = "nested"
Local boxIdentity:TBox<String>(value:TBox<String>) = Identity<TBox<String>>
If boxIdentity(box).value <> "nested" Then Throw "nested generic routine reference failed"

Local memberIdentity:String(value:String) = TFunctions<Int>.Identity<String>
If memberIdentity("member") <> "member" Then Throw "generic Type member routine reference failed"

If ApplyIdentity<Int>(42) <> 42 Then Throw "transitive generic routine reference failed"

Print "generic-routine-reference-ok"
