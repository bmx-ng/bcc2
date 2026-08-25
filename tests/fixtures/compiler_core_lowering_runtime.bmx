SuperStrict

Struct SLoweringCell
	Field value:Int
End Struct

Type TLoweringValue
End Type

Function Compute:Int(limit:Int)
	Function Factor:Int(value:Int)
		If value <= 1 Then Return 1
		Return value * Factor(value - 1)
	End Function

	Local cell:SLoweringCell
	Local pointer:SLoweringCell Ptr = VarPtr cell
	If Not pointer Then Return 0
	pointer.value = Factor(limit)
	Return pointer.value
End Function

Function EmptyArray:Int[]()
	Return Null
End Function

Function EmptyObject:TLoweringValue()
	Return Null
End Function

Function EmptyPointer:Byte Ptr()
	Return Null
End Function

Function AddOne:Int(value:Int)
	Return value + 1
End Function

Function Double:Int(value:Int)
	Return value * 2
End Function

Function OptionalFilter:Int(value:Int, filter:Int(value:Int) = Null)
	If filter And Not filter(value) Then Return 0
	If Not filter Or filter(value) Then Return 1
	Return 0
End Function

Global initializationTrace:String

Function RecordInitialization:Int(marker:String)
	initializationTrace :+ marker
	Return marker[0]
End Function

RecordInitialization("1")
Global firstInitialization:Int = RecordInitialization("2")
RecordInitialization("3")
Global secondInitialization:Int = RecordInitialization("4")

Local callbacks:Int(value:Int)[] = [AddOne, Null]
Local callableDefaultIsUnset:Int = Not callbacks[1]
callbacks[1] = Double

Local boxedEmptyArray:Object
Local castEmptyArray:TLoweringValue[] = TLoweringValue[](boxedEmptyArray)
Local castEmptyCount:Int
For Local value:TLoweringValue = EachIn castEmptyArray
	castEmptyCount :+ 1
Next
Local originalArray:TLoweringValue[] = [New TLoweringValue]
Local boxedArray:Object = originalArray
Local castArray:TLoweringValue[] = TLoweringValue[](boxedArray)

If initializationTrace = "1234" And Compute(5) = 120 And Not EmptyArray() And Not EmptyObject() And Not EmptyPointer() And callableDefaultIsUnset And callbacks[0](20) + callbacks[1](10) = 41 And OptionalFilter(42) = 1 And Not castEmptyArray And castEmptyCount = 0 And castArray.length = 1 And castArray[0] = originalArray[0]
	WriteStdout("bcc2 core lowering runtime ok~n")
End If
