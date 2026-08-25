SuperStrict

Framework BRL.StandardIO

Import Bcc2CompositionTest.Owner

Global appendTransform:Closure<String(value:String)> = Function(value:String)
	Return value + "!"
End Function

Global closureTransform:Closure<Closure<Int()>(value:Closure<Int()>)> = Function(value:Closure<Int()>)
	Return Function()
		Return value() + 1
	End Function
End Function

Local stringPipeline:TModulePipeline<String> = New TModulePipeline<String>
Local deferredString:Closure<String()> = ModuleDeferred(stringPipeline, "module", appendTransform)
If deferredString() <> "module!" Then Throw "source-free module String composition failed"
Local stringBase:TModuleBase<String, String[]> = stringPipeline
If stringBase.Values().length <> 1 Or stringBase.Values()[0] <> "module" Then Throw "source-free module inherited String storage failed"

Local seed:Closure<Int()> = Function()
	Return 41
End Function
Local closurePipeline:TModulePipeline<Closure<Int()>> = New TModulePipeline<Closure<Int()>>
Local deferredClosure:Closure<Closure<Int()>()> = ModuleDeferred(closurePipeline, seed, closureTransform)
If deferredClosure()() <> 42 Then Throw "source-free module nested Closure composition failed"
Local closureBase:TModuleBase<String, Closure<Int()>[]> = closurePipeline
If closureBase.Values().length <> 1 Or closureBase.Values()[0]() <> 41 Then Throw "source-free module inherited Closure storage failed"

Print "generic-composition-module-ok"
