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

Function ExchangeLabels:String(left:String Var, right:String Var)
	Local prior:String = left
	left = right
	right = prior
	Return left
End Function

Function PrefixNumber:String(number:Int, text:String)
	If number <= 0 Then Return ""
	Return text
End Function

Function ConsumeLabels(left:String, right:String)
	Local combined:String = left + right
End Function

Struct SLabel<T>
	Field value:T
	Field number:Int = DoubleValue(3)
	Field total:Int = AddNumbers(2, 3)
	Field label:String = "seed"
	Field called:String = MakeLabel()
	Field wrapped:String = WrapLabel("field")
	Field paired:String = JoinLabels("first", "second")
	Method New()
		label = "made"
		called = MakeLabel()
		wrapped = WrapLabel(label)
		wrapped = JoinLabels(label, wrapped)
		paired = JoinLabels(MakeLabel(), paired)
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
	Method Sequenced:String()
		Return JoinLabels(paired, "!")
	End Method
	Method Nested:String()
		Return JoinLabels(JoinLabels("a", "b"), JoinLabels("c", "d"))
	End Method
	Method Exchange:String()
		Return ExchangeLabels(label, wrapped)
	End Method
	Method Mixed:String()
		Return PrefixNumber(DoubleValue(3), "mixed")
	End Method
	Method Touch()
		ConsumeLabels("touch", "!")
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
Local sequenced:String = label.Sequenced()
Local nested:String = label.Nested()
Local exchanged:String = label.Exchange()
Local mixed:String = label.Mixed()
label.Touch()
