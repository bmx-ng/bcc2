SuperStrict

Module Bcc2BoundMethodBoundary.Types

Interface IModuleBoundTransform
	Method Apply:Int(value:Int)
End Interface

Type TModuleBoundBase Implements IModuleBoundTransform
	Field offset:Int

	Method New(offset:Int)
		Self.offset = offset
	End Method

	Method Apply:Int(value:Int)
		Return value + offset
	End Method
End Type

Type TModuleBoundDerived Extends TModuleBoundBase
	Method Apply:Int(value:Int) Override
		Return value + offset + 1
	End Method
End Type

Type TModuleBoundBox<T>
	Field suffix:T

	Method Join:T(value:T)
		Return value + suffix
	End Method
End Type

Function BindModuleReceiver:Closure<Int(value:Int)>(receiver:TModuleBoundBase)
	Return receiver.Apply
End Function

Function BindModuleBox<T>:Closure<T(value:T)>(receiver:TModuleBoundBox<T>)
	Return receiver.Join
End Function
