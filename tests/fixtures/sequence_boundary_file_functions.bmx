SuperStrict

Import BRL.Sequence

Global FileSequenceTotal:Int

Function FileSequenceEven:Int(value:Int)
	Return (value & 1) = 0
End Function

Function FileSequenceTriple:Int(value:Int)
	Return value * 3
End Function

Function FileSequenceAdd:Long(total:Long, value:Int)
	Return total + value
End Function

Function FileSequenceReset()
	FileSequenceTotal = 0
End Function

Function FileSequenceVisit(value:Int)
	FileSequenceTotal :+ value
End Function

Function FileSequenceVisited:Int()
	Return FileSequenceTotal
End Function

Type TFileSequenceFunctions
	Function AboveTwo:Int(value:Int)
		Return value > 2
	End Function

	Function Double:Int(value:Int)
		Return value * 2
	End Function

	Function Add:Long(total:Long, value:Int)
		Return total + value
	End Function
End Type

Type TFileGenericSequenceFunctions<T>
	Function Identity:T(value:T)
		Return value
	End Function
End Type

Function FileSequenceIdentity<T>:T(value:T)()
	Return Function:T(value:T)
		Return value
	End Function
End Function

Function FileGenericIdentity<T>:T(value:T)
	Return value
End Function

Function FileEvenSequence:Sequence<Int>(values:Int[])
	Return Sequence<Int>.FromArray(values).Filter(FileSequenceEven)
End Function

Function FileExpandSequence:Sequence<Int>(value:Int)
	Return Sequence<Int>.FromArray([value, value * 10])
End Function

Function FileSequenceBelowFive:Int(value:Int)
	Return value < 5
End Function
