SuperStrict

Framework BRL.StandardIO

Global range0:Closure<Int()>
Global range1:Closure<Int()>
Global range2:Closure<Int()>
Global while0:Closure<Int()>
Global while1:Closure<Int()>
Global repeat0:Closure<Int()>
Global repeat1:Closure<Int()>
Global each0:Closure<Int()>
Global each1:Closure<Int()>
Global nested00:Closure<Int()>
Global nested01:Closure<Int()>
Global nested10:Closure<Int()>
Global nested11:Closure<Int()>
Global rangeControlLast:Closure<Int()>
Global outside0:Closure<Int()>
Global outside1:Closure<Int()>

Function BuildRangeClosures()
	Local shared:Int = 100
	For Local index:Int = 0 Until 3
		Local offset:Int = index * 10
		Local action:Closure<Int()> = Function()
			shared :+ 1
			index :+ 1
			offset :+ 2
			Return shared + index + offset
		End Function
		Select index
			Case 0
				range0 = action
			Case 1
				range1 = action
			Case 2
				range2 = action
		End Select
		If index = 1 Then Continue
	Next
End Function

Function BuildRangeControlClosures:Int()
	Local visits:Int
	For Local index:Int = 0 Until 10
		visits :+ 1
		rangeControlLast = Function()
			Return index
		End Function
		index :+ 4
		Continue
	Next
	Return visits
End Function

Function BuildOutsideLoopClosures()
	Local index:Int
	For index = 0 Until 2
		Local action:Closure<Int()> = Function()
			Return index
		End Function
		If index = 0 Then outside0 = action Else outside1 = action
	Next
End Function

Function BuildWhileClosures()
	Local cursor:Int
	While cursor < 2
		Local value:Int = cursor
		Local action:Closure<Int()> = Function()
			value :+ 10
			Return value
		End Function
		If cursor = 0 Then while0 = action Else while1 = action
		cursor :+ 1
	Wend
End Function

Function BuildRepeatClosures()
	Local cursor:Int
	Repeat
		Local value:Int = cursor * 10
		Local action:Closure<Int()> = Function()
			value :+ 1
			Return value
		End Function
		If cursor = 0 Then repeat0 = action Else repeat1 = action
		cursor :+ 1
	Until cursor = 2
End Function

Function BuildEachInClosures()
	Local values:Int[] = [3, 7]
	Local ordinal:Int
	For Local value:Int = EachIn values
		Local action:Closure<Int()> = Function()
			value :+ 1
			Return value
		End Function
		If ordinal = 0 Then each0 = action Else each1 = action
		ordinal :+ 1
	Next
End Function

Function BuildNestedClosures()
	For Local outer:Int = 0 Until 2
		For Local inner:Int = 0 Until 2
			Local action:Closure<Int()> = Function()
				outer :+ 1
				inner :+ 1
				Return outer * 10 + inner
			End Function
			If outer = 0 Then
				If inner = 0 Then nested00 = action Else nested01 = action
			Else
				If inner = 0 Then nested10 = action Else nested11 = action
			End If
		Next
	Next
End Function

BuildRangeClosures()
GCCollect()
If range0() <> 104 Then Throw "first range iteration did not retain its own cells"
If range1() <> 116 Then Throw "second range iteration did not retain its own cells"
If range2() <> 128 Then Throw "third range iteration did not retain its own cells"
If range0() <> 110 Then Throw "closures from one range iteration did not share their mutable iteration cells"
If BuildRangeControlClosures() <> 2 Or rangeControlLast() <> 9 Then Throw "captured range mutation was not copied back through Continue before the normal step"
BuildOutsideLoopClosures()
If outside0() <> 2 Or outside1() <> 2 Then Throw "a variable declared outside its loop did not remain one deliberately shared capture cell"

BuildWhileClosures()
GCCollect()
If while0() <> 10 Or while1() <> 11 Then Throw "While body locals were not fresh per iteration"
If while0() <> 20 Or while1() <> 21 Then Throw "While iteration cells did not retain independent mutation"

BuildRepeatClosures()
GCCollect()
If repeat0() <> 1 Or repeat1() <> 11 Then Throw "Repeat body locals were not fresh per iteration"

BuildEachInClosures()
GCCollect()
If each0() <> 4 Or each1() <> 8 Then Throw "EachIn header values were not fresh per iteration"
If each0() <> 5 Or each1() <> 9 Then Throw "EachIn iteration cells did not retain independent mutation"

BuildNestedClosures()
GCCollect()
If nested00() <> 11 Or nested01() <> 22 Or nested10() <> 21 Or nested11() <> 32 Then Throw "nested loops did not retain their distinct environment chains"

Print "loop-closure-capture-ok"
