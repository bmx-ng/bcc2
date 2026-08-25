SuperStrict

Framework BRL.StandardIO

Function Identity<T>:Closure<T(value:T)>()
	Return Function(value:T)
		Return value
	End Function
End Function

Function Throwing<T>:Closure<()>(message:String)
	Return Function()
		Throw message
	End Function
End Function

Type TGenericCoverageFactory<T>
	Method Make:Closure<T(value:T)>()
		Return Function(value:T)
			Return value
		End Function
	End Method
End Type

Function LocalIdentity<T>:T(value:T)
	Function Inner:T(input:T)
		Return input
	End Function
	Return Inner(value)
End Function

Local intIdentity:Closure<Int(value:Int)> = Identity<Int>()
Local stringIdentity:Closure<String(value:String)> = Identity<String>()
Local factory:TGenericCoverageFactory<String> = New TGenericCoverageFactory<String>
Local factoryIdentity:Closure<String(value:String)> = factory.Make()

If intIdentity(41) <> 41 Then Throw "generic Int coverage mismatch"
If stringIdentity("source-free") <> "source-free" Then Throw "generic String coverage mismatch"
If factoryIdentity("method") <> "method" Then Throw "generic method coverage mismatch"
If LocalIdentity<Int>(42) <> 42 Then Throw "generic local routine coverage mismatch"

Try
	Throwing<Int>("generic coverage throw")()
Catch problem:String
	If problem <> "generic coverage throw" Then Throw problem
End Try

Print "generic-coverage-ok"
