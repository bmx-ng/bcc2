SuperStrict

Framework BRL.Blitz

If AppArgs.length > 1 Then
	Local StaticArray fixed:Int[2]
	Local invalid:Int = fixed[2]
Else
	Local values:Int[] = [1, 2]
	Local invalid:Int = values[2]
End If
