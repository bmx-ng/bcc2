SuperStrict

Function MakeLabel:String()
	Return "fresh"
End Function

Struct SLabel<T>
	Field value:T
	Field label:String = "seed"
	Field called:String = MakeLabel()
	Method New()
		label = "made"
		called = MakeLabel()
	End Method
	Method Label:String()
		Return label + "!"
	End Method
	Method Fresh:String()
		Return MakeLabel()
	End Method
End Struct

Local label:SLabel<String> = New SLabel<String>
Local value:String = label.Label()
Local fresh:String = label.Fresh()
