SuperStrict

Type TCompilerException
	Field value:Int
End Type

Local caught:Int

Try
	Local problem:TCompilerException = New TCompilerException
	problem.value = 40
	Throw problem
Catch problem:TCompilerException
	caught :+ problem.value
Catch message:String
	caught = -100
End Try

Try
	Throw "text"
Catch problem:TCompilerException
	caught = -200
Catch message:String
	caught :+ message.length Shr 2
End Try

Try
	Throw "combined"
Catch message:String
	caught :+ 1
Finally
	caught :+ 10
End Try

Global returnedCleanup:Int

Function ReturnThroughCatchFinally:Int()
	Try
		Return 5
	Catch problem:Object
		Return -1
	Finally
		returnedCleanup :+ 1
	End Try
End Function

If caught = 52 And ReturnThroughCatchFinally() = 5 And returnedCleanup = 1
	WriteStdout("bcc2 exception runtime ok~n")
End If
