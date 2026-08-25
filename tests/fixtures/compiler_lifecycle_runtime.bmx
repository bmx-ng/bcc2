SuperStrict

Extern
	Function RecordDelete(value:Int) = "bcc2_record_delete"
	Function CheckLifecycle:Int() = "bcc2_check_lifecycle"
End Extern

Type TBase
	Field baseValue:Int

	Method New(value:Int)
		baseValue = value
	End Method

	Method Delete()
		RecordDelete(1)
	End Method
End Type

Type TDerived Extends TBase
	Field derivedValue:Int

	Method New(baseValue:Int, derivedValue:Int)
		Super.New(baseValue)
		Self.derivedValue = derivedValue
	End Method

	Method Delete()
		RecordDelete(2)
	End Method
End Type

Local value:TDerived = New TDerived(20, 22)
If value.baseValue = 20
	If value.derivedValue = 22
		If CheckLifecycle()
			WriteStdout("bcc2 lifecycle runtime ok~n")
		End If
	End If
End If
