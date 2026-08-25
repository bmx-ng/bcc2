SuperStrict

Framework BRL.StandardIO

Import Collections.HashMap

Type TPair<K, V> Implements IDeconstruct2<K, V>
	Field key:K
	Field value:V

	Method New(key:K, value:V)
		Self.key = key
		Self.value = value
	End Method

	Method Deconstruct(first:K Var, second:V Var)
		first = key
		second = value
	End Method
End Type

Type TPairCounter<K, V>
	Method Count:Int(values:TPair<K, V>[])
		Local count:Int
		For Local key:K, value:V = EachIn values
			count :+ 1
		Next
		Return count
	End Method
End Type

Function GeneratedPairs:ICloseableIterator<TPair<String, Int>>()
	Yield New TPair<String, Int>("one", 1)
	Yield New TPair<String, Int>("two", 2)
End Function

Local generatedKey0:Closure<String()>
Local generatedKey1:Closure<String()>
Local generatedTotal:Int
Local generatedOrdinal:Int
For Local key, value = EachIn GeneratedPairs()
	Local readKey:Closure<String()> = Function()
		Return key
	End Function
	If generatedOrdinal = 0 Then generatedKey0 = readKey Else generatedKey1 = readKey
	generatedTotal :+ value
	generatedOrdinal :+ 1
Next

Local map:THashMap<String, Int> = New THashMap<String, Int>
map["one"] = 1
map["two"] = 2
Local mapTotal:Int
Local mapNameLength:Int
For Local key:String, value:Int = EachIn map
	mapTotal :+ value
	mapNameLength :+ key.length
Next

Local pairs:TPair<String, Int>[] = [New TPair<String, Int>("one", 1), New TPair<String, Int>("two", 2)]
Local pairCount:Int = New TPairCounter<String, Int>.Count(pairs)

GCCollect()
If generatedTotal <> 3 Or generatedKey0() <> "one" Or generatedKey1() <> "two" Then Throw "generated sequence deconstruction or Closure capture failed"
If mapTotal <> 3 Or mapNameLength <> 6 Then Throw "map deconstruction failed"
If pairCount <> 2 Then Throw "generic-owner deconstruction failed"

Print "bcc2 EachIn deconstruction runtime ok"
