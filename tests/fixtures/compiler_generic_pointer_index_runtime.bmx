SuperStrict

Framework BRL.StandardIO

Global pointerCalls:Int
Global indexCalls:Int
Global activePointer:Int Ptr

Struct SPointerValue
	Field number:Int
End Struct

Enum EPointerValue:Byte
	Ready = 7
	Done = 9
End Enum

Function PointerOnce:Int Ptr()
	pointerCalls :+ 1
	Return activePointer
End Function

Function IndexOnce:Int()
	indexCalls :+ 1
	Return 1
End Function

Function ReadAt<T>:T(pointer:T Ptr, index:Int)
	Return pointer[index]
End Function

Function WriteAt<T>(pointer:T Ptr, index:Int, value:T)
	pointer[index] = value
End Function

Function ReadFromCalls<T>:Int(dummy:T)
	Return PointerOnce()[IndexOnce()]
End Function

Local StaticArray integers:Int[2]
integers[0] = 17
integers[1] = 23
activePointer = Varptr integers[0]
If ReadAt<Int>(activePointer, 1) <> 23 Then Throw "Int pointer read failed"
WriteAt<Int>(activePointer, 0, 19)
If integers[0] <> 19 Then Throw "Int pointer assignment failed"
If ReadFromCalls<Int>(0) <> 23 Or pointerCalls <> 1 Or indexCalls <> 1 Then Throw "pointer or index was evaluated more than once"

Local StaticArray doubles:Double[2]
doubles[0] = 1.5
doubles[1] = 2.5
Local doublePointer:Double Ptr = Varptr doubles[0]
If ReadAt<Double>(doublePointer, 1) <> 2.5 Then Throw "Double pointer read failed"
WriteAt<Double>(doublePointer, 0, 3.5)
If doubles[0] <> 3.5 Then Throw "Double pointer assignment failed"

Local raw:Byte = 7
Local StaticArray pointers:Byte Ptr[2]
pointers[1] = Varptr raw
Local nestedPointer:Byte Ptr Ptr = Varptr pointers[0]
If ReadAt<Byte Ptr>(nestedPointer, 1) <> Varptr raw Then Throw "nested pointer read failed"

Local StaticArray unsigneds:UInt[2]
unsigneds[1] = 4000000000:UInt
Local unsignedPointer:UInt Ptr = Varptr unsigneds[0]
If ReadAt<UInt>(unsignedPointer, 1) <> 4000000000:UInt Then Throw "UInt pointer read failed"

Local StaticArray longs:Long[2]
longs[1] = 5000000000:Long
Local longPointer:Long Ptr = Varptr longs[0]
If ReadAt<Long>(longPointer, 1) <> 5000000000:Long Then Throw "Long pointer read failed"

Local StaticArray floats:Float[2]
floats[1] = 1.25
Local floatPointer:Float Ptr = Varptr floats[0]
If ReadAt<Float>(floatPointer, 1) <> 1.25 Then Throw "Float pointer read failed"

Local StaticArray records:SPointerValue[2]
records[1].number = 37
Local recordPointer:SPointerValue Ptr = Varptr records[0]
If ReadAt<SPointerValue>(recordPointer, 1).number <> 37 Then Throw "Struct pointer read failed"
Local replacement:SPointerValue
replacement.number = 41
WriteAt<SPointerValue>(recordPointer, 0, replacement)
If records[0].number <> 41 Then Throw "Struct pointer assignment failed"

Local StaticArray states:EPointerValue[2]
states[1] = EPointerValue.Done
Local statePointer:EPointerValue Ptr = Varptr states[0]
If ReadAt<EPointerValue>(statePointer, 1) <> EPointerValue.Done Then Throw "Enum pointer read failed"
WriteAt<EPointerValue>(statePointer, 0, EPointerValue.Ready)
If states[0] <> EPointerValue.Ready Then Throw "Enum pointer assignment failed"

Print "generic-pointer-index-ok"
