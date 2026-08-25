SuperStrict

Framework BRL.StandardIO

Import "compiler_generic_composition_imported.bmx"

Global appendTransform:Closure<String(value:String)> = Function(value:String)
	Return value + "!"
End Function

Global arrayTransform:Closure<Int[](value:Int[])> = Function(value:Int[])
	Return value + [7]
End Function

Local stringPipeline:TImportedPipeline<String> = New TImportedPipeline<String>
Local deferredString:Closure<String()> = ImportedDeferred(stringPipeline, "quoted", appendTransform)
If deferredString() <> "quoted!" Then Throw "quoted String composition failed"

Local arrayPipeline:TImportedPipeline<Int[]> = New TImportedPipeline<Int[]>
Local deferredArray:Closure<Int[]()> = ImportedDeferred(arrayPipeline, [1, 2], arrayTransform)
Local arrayResult:Int[] = deferredArray()
If arrayResult.length <> 3 Or arrayResult[2] <> 7 Then Throw "quoted Array composition failed"

Print "generic-composition-import-ok"
