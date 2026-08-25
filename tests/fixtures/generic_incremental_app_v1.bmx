SuperStrict

Framework BRL.StandardIO

Import "provider.bmx"

Global appendTransform:Closure<String(value:String)> = Function(value:String)
	Return value + "!"
End Function

Local pipeline:TVersionPipeline<String> = New TVersionPipeline<String>
Local result:String = pipeline.Apply("seed", appendTransform)
Local base:TVersionBase<String, String[]> = pipeline
If base.Values().length <> 1 Or base.Values()[0] <> "seed" Then Throw "v1 inherited Array state failed"
Print result
