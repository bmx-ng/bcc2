SuperStrict

Framework BRL.StandardIO

Import "bound_method_boundary_file_types.bmx"

Local base:TFileBoundBase = New TFileBoundDerived
base.offset = 1
Local direct:Closure<Int(value:Int)> = base.Apply
If direct(40) <> 42 Then Throw "file-bound virtual dispatch failed"

Local throughInterface:IFileBoundTransform = base
Local interfaceCall:Closure<Int(value:Int)> = throughInterface.Apply
If interfaceCall(40) <> 42 Then Throw "file-bound Interface dispatch failed"

Local returned:Closure<Int(value:Int)> = BindFileReceiver(base)
If returned(40) <> 42 Then Throw "file-bound returned Closure failed"

Local box:TFileBoundBox<String> = New TFileBoundBox<String>
box.suffix = "-file"
Local genericReturned:Closure<String(value:String)> = BindFileBox<String>(box)
If genericReturned("bound") <> "bound-file" Then Throw "file-bound generic returned Closure failed"

Print "bound-method-file-boundary-ok"
