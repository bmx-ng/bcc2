SuperStrict

Import Acme.ElementInit

Local cells:SElementCell[,] = New SElementCell[2, 3]

If cells[0, 0].value = 17 And cells[1, 2].value = 17 And ..
		cells[0, 0].text = "ready" And cells[1, 2].text = "ready"
	WriteStdout("bcc2 Struct element-initializer ABI ok~n")
Else
	Throw "imported multidimensional Struct cells were not initialized"
End If
