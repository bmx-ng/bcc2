SuperStrict

Framework BRL.StandardIO

Function CellReader<T>:Closure<T()>(grid:T[,], x:Int, y:Int)
	Return Function()
		Return grid[x, y]
	End Function
End Function

Function CellWriter<T>:Closure<(value:T)>(grid:T[,], x:Int, y:Int)
	Return Function(value:T)
		grid[x, y] = value
	End Function
End Function

Local grid:String[,] = New String[2, 3]
grid[1, 2] = "before"
Local read:Closure<String()> = CellReader<String>(grid, 1, 2)
Local write:Closure<(value:String)> = CellWriter<String>(grid, 1, 2)
If read() <> "before" Then Throw "generic ranked Array capture read failed"
write("after")
If read() <> "after" Then Throw "generic ranked Array capture mutation failed"
Print "ranked-array-ok"
