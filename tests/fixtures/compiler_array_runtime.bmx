SuperStrict

Function Sum:Int(values:Int[])
	Local total:Int
	Local index:Int
	While index < values.length
		total = total + values[index]
		index = index + 1
	Wend
	Return total
End Function

Global Arguments:String[] = AppArgs
Global ArgumentCount:Int = Arguments.length

Local Empty:Int[]
Local Values:Int[] = New Int[2]
Values[0] = 20
Values[1] = 22
Local Tail:Int[] = New Int[1]
Tail[0] = 1
Local Joined:Int[] = Values + Tail
Local Names:String[] = New String[1]
If Names[0] = ""
	Names[0] = "ready"
End If

If Empty
	WriteStdout("invalid Array truth~n")
Else If Not Empty
	If Joined.length = 3
		If Sum(Joined) = 43
			If Names[0] = "ready"
				WriteStdout("bcc2 Array runtime ok~n")
			End If
		End If
	End If
End If
