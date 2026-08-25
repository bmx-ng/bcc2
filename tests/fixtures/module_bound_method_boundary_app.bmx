SuperStrict

Framework BRL.StandardIO

Import Bcc2BoundMethodBoundary.Types

Local base:TModuleBoundBase = New TModuleBoundDerived
base.offset = 1
Local direct:Closure<Int(value:Int)> = base.Apply
If direct(40) <> 42 Then Throw "module-bound virtual dispatch failed"

Local throughInterface:IModuleBoundTransform = base
Local interfaceCall:Closure<Int(value:Int)> = throughInterface.Apply
If interfaceCall(40) <> 42 Then Throw "module-bound Interface dispatch failed"

Local returned:Closure<Int(value:Int)> = BindModuleReceiver(base)
If returned(40) <> 42 Then Throw "module-bound returned Closure failed"

Local box:TModuleBoundBox<String> = New TModuleBoundBox<String>
box.suffix = "-module"
Local genericReturned:Closure<String(value:String)> = BindModuleBox<String>(box)
If genericReturned("bound") <> "bound-module" Then Throw "module-bound generic returned Closure failed"

Print "bound-method-module-boundary-ok"
