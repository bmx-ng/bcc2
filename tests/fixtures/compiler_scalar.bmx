SuperStrict

Global Seed:Int = 40

Function Twice:Int(value:Int)
	Local result:Int = value * 2
	Return result
End Function

Function SumTo:Int(limit:Int)
	Local total:Int = 0
	Local index:Int = 0
	While index < limit
		total = total + index
		index = index + 1
	Wend
	If total > 10
		Return total
	Else
		Return 10
	End If
End Function

Local answer:Int = Twice(21)
Local sum:Int = SumTo(6)
answer = answer + Seed + sum
