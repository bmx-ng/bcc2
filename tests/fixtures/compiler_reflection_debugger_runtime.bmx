SuperStrict

Framework BRL.StandardIO
Import BRL.Reflection
Import "compiler_debugger_capture_stub.c"

Enum EReflectionDebugState:Int
	Ready
End Enum

Struct SReflectionDebugValue
	Field value:Int
End Struct

Interface IReflectionDebugValue
End Interface

Type TReflectionDebugStop Implements IReflectionDebugValue

	Method Hit(value:Object)
		DebugStop
	End Method
End Type

Function KeepValue:Int(value:Int)
	Return value
End Function

Local instance:TReflectionDebugStop = New TReflectionDebugStop
Local typeId:TTypeId = TTypeId.ForObject(instance)
Local reflectedMethod:TMethod = typeId.FindMethod("Hit")
Local raw:Byte Ptr
Local rawPointer:Byte Ptr Ptr = Varptr raw
Local callback:Int(value:Int) = KeepValue
Local callbacks:Int(value:Int)[]
callbacks = callbacks[..1]
callbacks[0] = callback
Local closureValue:Closure<Int(value:Int)> = Function(value:Int)
	Return value
End Function
Local StaticArray fixed:Int[4]
Local record:SReflectionDebugValue
Local iface:IReflectionDebugValue = instance
Local state:EReflectionDebugState = EReflectionDebugState.Ready
reflectedMethod.Invoke(instance, ["value"])
