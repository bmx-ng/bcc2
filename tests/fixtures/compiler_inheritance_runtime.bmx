SuperStrict

Extern
	Function NativeInheritanceLayout:Int() = "bcc2_native_inheritance_layout"
End Extern

Type TBase
	Field baseValue:Int

	Method Value:Int()
		Return baseValue
	End Method

	Method Stable:Int()
		Return baseValue + 1
	End Method
End Type

Type TDerived Extends TBase
	Field derivedValue:Int

	Method Value:Int() Override
		Return baseValue + derivedValue
	End Method

	Method Extra:Int()
		Return derivedValue + 2
	End Method
End Type

Local value:TDerived = New TDerived
value.baseValue = 20
value.derivedValue = 22
Local base:TBase = value
If base.Value() = 42
	If value.Stable() = 21
		If value.Extra() = 24
			If NativeInheritanceLayout()
				WriteStdout("bcc2 inheritance runtime ok~n")
			End If
		End If
	End If
End If
