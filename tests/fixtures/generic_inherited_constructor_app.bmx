SuperStrict

Framework BRL.Blitz
Import BRL.StandardIO
Import "generic_inherited_constructor_provider.bmx"

Local deepDefault:TInheritedDeep<String> = New TInheritedDeep<String>("hello")
If deepDefault.value <> "hello" Or deepDefault.note <> "!" Or deepDefault.RuntimeKind() <> "deep" Then Throw "deep inherited constructor lost its default or runtime identity"

Local deepExplicit:TInheritedDeep<String> = New TInheritedDeep<String>("hello", "?")
If deepExplicit.value <> "hello" Or deepExplicit.note <> "?" Then Throw "deep inherited constructor lost its explicit optional argument"

Local implicitDefault:TInheritedDeep<String> = New TInheritedDeep<String>()
If implicitDefault.note <> "" Or implicitDefault.RuntimeKind() <> "deep" Then Throw "inherited optional constructor replaced implicit New()"

Local shadowDirect:TInheritedShadow<String> = New TInheritedShadow<String>(7)
If shadowDirect.note <> "direct-7" Or shadowDirect.RuntimeKind() <> "shadow" Then Throw "derived constructor did not shadow its matching inherited overload"

Local shadowInherited:TInheritedShadow<String> = New TInheritedShadow<String>("base")
If shadowInherited.value <> "base" Or shadowInherited.note <> "!" Or shadowInherited.RuntimeKind() <> "shadow" Then Throw "unshadowed inherited overload was not retained"

Local source:Int = 41
Local varForwarded:TVarConstructorDerived<Int> = New TVarConstructorDerived<Int>(source)
If varForwarded.value <> 41 Then Throw "inherited Var constructor argument was not forwarded"

Local zeroForwarded:TZeroConstructorDerived<String> = New TZeroConstructorDerived<String>()
If zeroForwarded.initialized <> 41 Then Throw "inherited zero-argument constructor was not invoked"

Local zeroShadowed:TZeroConstructorShadow<String> = New TZeroConstructorShadow<String>()
If zeroShadowed.initialized <> 7 Then Throw "derived zero-argument constructor did not shadow its base overload"

Print "generic-inherited-constructor-ok"
