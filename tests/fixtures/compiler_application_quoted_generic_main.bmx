SuperStrict

Framework BRL.Blitz
Import BRL.StandardIO
Import Math.Vector

Import "compiler_application_quoted_generic_types.bmx"

Function BuildQuotedList:TQuotedList<String>()
	Local result:TQuotedList<String> = New TQuotedList<String>
	result.AddLast("quoted-generic-ok")
	Return result
End Function

Local values:TQuotedList<String> = BuildQuotedList()
If values.Count() <> 1 Then Throw "quoted generic source ownership failed"

' A reconstructed nested generic argument must retain the application owner
' carried by its canonical companion rather than the quoted import token.
Local payload:TQuotedBox<Int> = New TQuotedBox<Int>
payload.value = 41
Local transform:IQuotedTransform<TQuotedBox<Int>> = New TQuotedTransform<TQuotedBox<Int>>
Local callback:Closure<TQuotedBox<Int>(value:TQuotedBox<Int>)> = transform.Transform
Local wrapped:Closure<Closure<TQuotedBox<Int>(value:TQuotedBox<Int>)>()> = WrapQuotedTransform<TQuotedBox<Int>>(callback)
Local result:TQuotedBox<Int> = wrapped()(payload)
If result = Null Or result.value <> 41 Then Throw "quoted nested generic Interface identity failed"

' An ordinary Struct declared by an imported source needs that source's
' generated header when it closes a separately emitted generic owner. The
' factory receiver and returned callback also exercise the bound-method path.
Local structPayload:SQuotedPayload
structPayload.number = 42
Local structCallback:Closure<SQuotedPayload(value:SQuotedPayload)> = MakeQuotedBoundOwner(structPayload).Transform
Local returnedStructCallback:Closure<SQuotedPayload(value:SQuotedPayload)> = ReturnQuotedCallback<SQuotedPayload>(structCallback)
Local structResult:SQuotedPayload = returnedStructCallback(structPayload)
If structResult.number <> 42 Then Throw "quoted Struct bound Method ownership failed"

' Generic Methods owned by an ordinary Type in the quoted source use that
' source's runtime header as the sole C layout authority.
Local entity:TQuotedEntity = New TQuotedEntity
entity.SetComponent<Int>(17)
If entity.GetComponent<Int>() <> 17 Then Throw "quoted scalar generic Method failed"
entity.SetComponent<String>("component")
If entity.GetComponent<String>() <> "component" Then Throw "quoted managed generic Method failed"
entity.SetComponent<SQuotedPayload>(structPayload)
Local component:SQuotedPayload = entity.GetComponent<SQuotedPayload>()
If component.number <> 42 Then Throw "quoted ordinary-owner generic Method failed"
Local vector:SVec2F = New SVec2F(20.4, 40.8)
entity.SetComponent<SVec2F>(vector)
Local returnedVector:SVec2F = entity.GetComponent<SVec2F>()
If returnedVector.x <> vector.x Or returnedVector.y <> vector.y Then Throw "quoted cross-module Struct generic Method failed"

Local structOwner:SQuotedGenericOwner
structOwner.marker = 1
If structOwner.Echo<Int>(23) <> 23 Then Throw "quoted Struct-owner scalar generic Method failed"
Local echoedPayload:SQuotedPayload = structOwner.Echo<SQuotedPayload>(structPayload)
If echoedPayload.number <> 42 Then Throw "quoted Struct-owner value generic Method failed"
Print "application-quoted-generic-ok"
