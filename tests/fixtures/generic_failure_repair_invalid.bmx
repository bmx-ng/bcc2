SuperStrict

Framework BRL.Blitz
Import BRL.StandardIO

Type TFailureRepairBox<T>
	Field value:T

	Method Read:T()
		Throw value
	End Method
End Type

Local box:TFailureRepairBox<Int> = New TFailureRepairBox<Int>
box.value = 2
Print box.Read()
