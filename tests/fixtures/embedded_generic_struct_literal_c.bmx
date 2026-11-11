SuperStrict

Function MakeLabel:String()
	Return "fresh"
End Function

Function WrapLabel:String(value:String)
	Return value
End Function

Function DoubleValue:Int(value:Int)
	Return value * 2
End Function

Function AddNumbers:Int(left:Int, right:Int)
	Return left + right
End Function

Function JoinLabels:String(left:String, right:String)
	Return left + right
End Function

Struct SLabel<T>
	Field value:T
	Field number:Int = DoubleValue(3)
	Field total:Int = AddNumbers(2, 3)
	Field label:String = "seed"
	Field called:String = MakeLabel()
	Field wrapped:String = WrapLabel("field")
	Method New()
		label = "made"
		called = MakeLabel()
		wrapped = WrapLabel(label)
		wrapped = JoinLabels(label, wrapped)
	End Method
	Method Label:String()
		Return label + "!"
	End Method
	Method Fresh:String()
		Return MakeLabel()
	End Method
	Method Wrapped:String()
		Return WrapLabel(wrapped)
	End Method
	Method Number:Int()
		Return DoubleValue(number)
	End Method
	Method Total:Int()
		Return AddNumbers(number, total)
	End Method
	Method Combined:String()
		Return JoinLabels(label, wrapped)
	End Method
End Struct

Local label:SLabel<String> = New SLabel<String>
Local value:String = label.Label()
Local fresh:String = label.Fresh()
Local wrapped:String = label.Wrapped()
Local number:Int = label.Number()
If number <> 12 Then value = "unexpected"
Local total:Int = label.Total()
If total <> 11 Then value = "unexpected"
Local combined:String = label.Combined()
