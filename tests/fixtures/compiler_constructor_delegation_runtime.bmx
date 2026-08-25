SuperStrict

Extern
	Function RecordConstructorDelegation:Int(value:Int) = "bcc2_record_constructor_delegation"
	Function CheckConstructorDelegation:Int() = "bcc2_check_constructor_delegation"
End Extern

Type TBase
	Field baseValue:Int = RecordConstructorDelegation(5)
End Type

Type TDelegating Extends TBase
	Field value:Int = RecordConstructorDelegation(1)

	Method New()
		New(RecordConstructorDelegation(4))
		RecordConstructorDelegation(3)
	End Method

	Method New(value:Int)
		RecordConstructorDelegation(2)
		Self.value = value
	End Method
End Type

Local item:TDelegating = New TDelegating
If item.baseValue = 5 And item.value = 4 And CheckConstructorDelegation()
	WriteStdout("bcc2 constructor delegation runtime ok~n")
End If
