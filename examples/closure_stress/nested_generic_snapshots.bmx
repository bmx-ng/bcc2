SuperStrict

Framework BRL.StandardIO

Function MakeSnapshots<T>:Closure<Closure<T()>(nextValue:T)>(initial:T)
	Local current:T = initial
	Return Function(nextValue:T)
		current = nextValue
		Local snapshot:T = current
		Return Function()
			Return snapshot
		End Function
	End Function
End Function

Type TPayload
	Field text:String

	Method New(text:String)
		Self.text = text
	End Method
End Type

Local strings:Closure<Closure<String()>(nextValue:String)> = MakeSnapshots<String>("initial")
Local firstString:Closure<String()> = strings("first")
Local secondString:Closure<String()> = strings("second")
If firstString() <> "first" Or secondString() <> "second" Then Throw "generic String snapshots shared the wrong child environment"

Local payloads:Closure<Closure<TPayload()>(nextValue:TPayload)> = MakeSnapshots<TPayload>(New TPayload("initial"))
Local firstPayload:Closure<TPayload()> = payloads(New TPayload("first"))
Local secondPayload:Closure<TPayload()> = payloads(New TPayload("second"))
If firstPayload().text <> "first" Or secondPayload().text <> "second" Then Throw "application-local generic snapshots failed"
Print "snapshots-ok"
