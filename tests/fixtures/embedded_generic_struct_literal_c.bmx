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

Struct SLabel<T>
	Field value:T
	Field number:Int = DoubleValue(3)
	Field label:String = "seed"
	Field called:String = MakeLabel()
	Field wrapped:String = WrapLabel("field")
	Method New()
		label = "made"
		called = MakeLabel()
		wrapped = WrapLabel(label)
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
End Struct

Local label:SLabel<String> = New SLabel<String>
Local value:String = label.Label()
Local fresh:String = label.Fresh()
Local wrapped:String = label.Wrapped()
Local number:Int = label.Number()
If number <> 12 Then value = "unexpected"
