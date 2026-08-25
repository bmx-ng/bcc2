SuperStrict

Interface IFileBoundTransform
	Method Apply:Int(value:Int)
End Interface

Type TFileBoundBase Implements IFileBoundTransform
	Field offset:Int

	Method New(offset:Int)
		Self.offset = offset
	End Method

	Method Apply:Int(value:Int)
		Return value + offset
	End Method
End Type

Type TFileBoundDerived Extends TFileBoundBase
	Method Apply:Int(value:Int) Override
		Return value + offset + 1
	End Method
End Type

Type TFileBoundBox<T>
	Field suffix:T

	Method Join:T(value:T)
		Return value + suffix
	End Method
End Type

Function BindFileReceiver:Closure<Int(value:Int)>(receiver:TFileBoundBase)
	Return receiver.Apply
End Function

Function BindFileBox<T>:Closure<T(value:T)>(receiver:TFileBoundBox<T>)
	Return receiver.Join
End Function
