SuperStrict

Type TSimple
	Field a:Int
	Field b:Int
	Field c:Int

	Function Create:TSimple(a:Int, b:Int, c:Int)
		Local value:TSimple = New TSimple
		value.a = a
		value.b = b
		value.c = c
		Return value
	End Function

	Method Sum:Int()
		Return a + b + c
	End Method
End Type

Extern
	Function NativeSimpleTypeLayout:Int() = "bcc2_native_simple_type_layout"
End Extern

Local empty:TSimple
Local value:TSimple = TSimple.Create(20, 21, 1)

If Not empty
	If value
		If value <> empty And value.Sum() = 42 And NativeSimpleTypeLayout()
			WriteStdout("bcc2 simple Type runtime ok~n")
		End If
	End If
End If
