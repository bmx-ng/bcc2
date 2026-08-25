SuperStrict

Framework BRL.StandardIO

Struct SHistory<T>
	Field values:T[]
	Field cursor:Int
End Struct

Function MakeHistory<T>:Closure<T(value:T)>(initial:T)
	Local state:SHistory<T>
	state.values = [initial]
	Return Function(value:T)
		state.values :+ [value]
		state.cursor :+ 1
		Return state.values[state.cursor]
	End Function
End Function

Local history:Closure<String(value:String)> = MakeHistory<String>("zero")
If history("one") <> "one" Or history("two") <> "two" Then Throw "captured generic Struct state failed"
Print "struct-state-ok"
