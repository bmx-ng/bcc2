SuperStrict

Extern
	Function RecordFieldInitializer:Int(value:Int) = "bcc2_record_field_initializer"
	Function CheckFieldInitializers:Int() = "bcc2_check_field_initializers"
End Extern

Type TBase
	Field baseFirst:Int = RecordFieldInitializer(1)
	Field baseSecond:Int = baseFirst + RecordFieldInitializer(2)

	Method New(value:Int)
		RecordFieldInitializer(3)
		baseSecond = baseSecond + value
	End Method
End Type

Type TDerived Extends TBase
	Field derivedFirst:Int = RecordFieldInitializer(4)
	Field derivedSecond:Int = baseSecond + derivedFirst

	Method New(value:Int)
		Super.New(value)
		RecordFieldInitializer(5)
	End Method
End Type

Type TPlain
	Field value:Int = RecordFieldInitializer(6)
	Field text:String = "ready"
	Field child:TBase = New TBase(7)
End Type

Local derived:TDerived = New TDerived(10)
Local plain:TPlain = New TPlain
If derived.baseFirst = 1 And derived.baseSecond = 13
	If derived.derivedFirst = 4 And derived.derivedSecond = 17
		If plain.value = 6 And plain.text = "ready"
			If plain.child.baseFirst = 1 And plain.child.baseSecond = 10 And CheckFieldInitializers()
				WriteStdout("bcc2 field initializers runtime ok~n")
			End If
		End If
	End If
End If
