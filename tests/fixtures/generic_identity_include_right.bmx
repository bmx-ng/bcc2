Global IncludedRight:TIdentityEnvelope<Int> = New TIdentityEnvelope<Int>
IncludedRight.cell = New TIdentityCell<Int>
IncludedRight.cell.value = 40
IncludedRight.transform = Function:Int(value:Int)
	Return value + 2
End Function
