SuperStrict

Module Bcc2SequenceBoundaryTest.Functions

Import BRL.Sequence

Global ModuleSequenceTotal:Int

Function ModuleSequenceEven:Int(value:Int)
	Return (value & 1) = 0
End Function

Function ModuleSequenceTriple:Int(value:Int)
	Return value * 3
End Function

Function ModuleSequenceAdd:Long(total:Long, value:Int)
	Return total + value
End Function

Function ModuleSequenceReset()
	ModuleSequenceTotal = 0
End Function

Function ModuleSequenceVisit(value:Int)
	ModuleSequenceTotal :+ value
End Function

Function ModuleSequenceVisited:Int()
	Return ModuleSequenceTotal
End Function

Type TModuleSequenceFunctions
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

Type TModuleGenericSequenceFunctions<T>
	Function Identity:T(value:T)
		Return value
	End Function
End Type

Function ModuleSequenceIdentity<T>:T(value:T)()
	Return Function:T(value:T)
		Return value
	End Function
End Function

Function ModuleGenericIdentity<T>:T(value:T)
	Return value
End Function

Function ModuleEvenSequence:Sequence<Int>(values:Int[])
	Return Sequence<Int>.FromArray(values).Filter(ModuleSequenceEven)
End Function

Function ModuleExpandSequence:Sequence<Int>(value:Int)
	Return Sequence<Int>.FromArray([value, value * 10])
End Function

Function ModuleSequenceBelowFive:Int(value:Int)
	Return value < 5
End Function
