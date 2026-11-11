SuperStrict
Framework BRL.StandardIO
Import Embedded.System.Time
Import Embedded.Runtime.Memory

Global stage:Int
Global failures:Int

Function LeftLabel:String()
	If stage <> 0 Then failures :+ 1
	stage = 1
	Return "left"
End Function

Function RightLabel:String()
	If stage <> 1 Then failures :+ 1
	CollectObjects()
	stage = 2
	Return "right"
End Function

Function CollectedLabel:String()
	CollectObjects()
	Return "right"
End Function

Function CallPair<T>:String(value:T)
	Return LeftLabel() + RightLabel()
End Function

Function LiteralPair<T>:String(value:T)
	Return "left" + "right"
End Function

Function NumericPair<T>:String(value:T)
	Return "value" + 42
End Function

Function StablePair<T>:String(left:String, right:String, value:T)
	Return left + right
End Function

Struct SJoin<T>
	Method CallPair:String()
		Return LeftLabel() + RightLabel()
	End Method
	Method Nested:String()
		Return ("a" + "b") + ("c" + "d")
	End Method
End Struct

Type TJoin<T>
	Method Pair:String()
		Return "type" + CollectedLabel()
	End Method
End Type

Local join:SJoin<Int>
Local typeJoin:TJoin<Int> = New TJoin<Int>
Local collectionsBefore:UInt = CollectionCount()
For Local round:Int = 1 To 50
	stage = 0
	If CallPair<Int>(round) <> "leftright" Or stage <> 2 Then failures :+ 1
	stage = 0
	If join.CallPair() <> "leftright" Or stage <> 2 Then failures :+ 1
	If LiteralPair<Int>(round) <> "leftright" Then failures :+ 1
	If NumericPair<Int>(round) <> "value42" Then failures :+ 1
	If StablePair<Int>("a", "b", round) <> "ab" Then failures :+ 1
	If join.Nested() <> "abcd" Then failures :+ 1
	If typeJoin.Pair() <> "typeright" Then failures :+ 1
Next
If CollectionCount() < collectionsBefore + 150 Then failures :+ 1
If Not HeapIntegrityValid() Or InvalidReferenceCount() <> 0 Then failures :+ 1

While True
	If failures Then
		Print "GENERIC_CONCAT,format=1,rounds=50,failures=" + failures
	Else
		Print "GENERIC_CONCAT,format=1,rounds=50,failures=0,done=1"
	End If
	SleepMicroseconds(1000000)
Wend
