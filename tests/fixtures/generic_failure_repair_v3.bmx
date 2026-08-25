SuperStrict

Framework BRL.Blitz
Import BRL.StandardIO

Type TFailureRepairBox<T>
	Field value:T

	Method Read:T()
		Return value
	End Method
End Type

Local box:TFailureRepairBox<Int> = New TFailureRepairBox<Int>
box.value = 3
Print box.Read()
