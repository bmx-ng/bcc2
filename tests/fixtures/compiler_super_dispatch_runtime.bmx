SuperStrict

Type TSuperBase
	Field bias:Int
	Field label:String = "base"

	Method Score:Int(value:Int)
		Return value + 1 + bias
	End Method

	Method ToString:String() Override
		Return label
	End Method
End Type

Type TSuperDerived Extends TSuperBase
	Method Score:Int(value:Int) Override
		Return Super.Score(value) + 1
	End Method

	Method ToString:String() Override
		Return Super.ToString() + "-derived"
	End Method
End Type

Type TSuperLeaf Extends TSuperDerived
	Method Score:Int(value:Int) Override
		Return Super.Score(value) + 1
	End Method
End Type

Local derived:TSuperDerived = New TSuperDerived
Local leaf:TSuperLeaf = New TSuperLeaf

If derived.Score(40) = 42
	If leaf.Score(40) = 43
		If leaf.ToString() = "base-derived"
			WriteStdout("bcc2 Super dispatch runtime ok~n")
		End If
	End If
End If
