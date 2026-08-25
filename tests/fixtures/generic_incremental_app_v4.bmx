SuperStrict

Framework BRL.StandardIO

Import "pipeline.bmx"

Global appendTransform:Closure<String(value:String)> = Function(value:String)
	Return value + "!"
End Function

Local pipeline:TVersionPipeline<String> = New TVersionPipeline<String>
Local result:String = pipeline.Apply("seed", appendTransform)
Local base:TVersionBase<String, String[,]> = pipeline
If base.Values().length <> 1 Or base.Values()[0, 0] <> "seed" Then Throw "v4 split inherited state failed"
If result <> "seed!!!" Then Throw "v4 split generic body failed"
Print "topology-ok"
