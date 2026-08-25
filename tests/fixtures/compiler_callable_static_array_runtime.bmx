SuperStrict

Function SumFixed:Int(StaticArray values:Int[4])
	Return values[0] + values.length
End Function

Function ApplyFixed:Int(callback:Int(StaticArray values:Int[4]), StaticArray values:Int[4])
	Return callback(values)
End Function

Local callback:Int(StaticArray values:Int[4]) = SumFixed
Local StaticArray values:Int[4]
values[0] = 38

If callback(values) = 42
	If ApplyFixed(callback, values) = 42
		WriteStdout("bcc2 callable StaticArray runtime ok~n")
	End If
End If
