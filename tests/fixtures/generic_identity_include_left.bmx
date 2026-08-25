Global IncludedLeft:TIdentityEnvelope<String> = New TIdentityEnvelope<String>
IncludedLeft.cell = New TIdentityCell<String>
IncludedLeft.cell.value = "left"
IncludedLeft.transform = Function:String(value:String)
	Return value + "-include"
End Function
