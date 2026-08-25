SuperStrict

Module Bcc2YieldBoundary.Values

ModuleInfo "Version: 1.00"
ModuleInfo "License: zlib/libpng"

Import BRL.Blitz

Function Words:ICloseableIterator<String>(prefix:String, count:Int)
	For Local index:Int = 1 To count
		Yield prefix + index
	Next
End Function

Function Once<T>:ICloseableIterator<T>(value:T)
	Yield value
End Function

Function Nested<T>:ICloseableIterator<T>(value:T)
	For Local item:T = EachIn Once<T>(value)
		Yield item
	Next
End Function

Function Owned<T>:ICloseableIterator<T>(value:T)
	Using
		Local inner:ICloseableIterator<T> = Once<T>(value)
	Do
		Yield value
	End Using
End Function

Function Protected<T>:ICloseableIterator<T>(value:T)
	Try
		Yield value
		Throw "boundary"
	Catch message:String
		Yield value
	Finally
		Local completed:Int = 1
	End Try
	Yield value
End Function

Function Captured<T>:ICloseableIterator<T>(value:T)
	Local current:T = value
	Local read:Closure<T()> = Function()
		Return current
	End Function
	Yield read()
End Function

Function Factory<T>:Closure<ICloseableIterator<T>()>(value:T)
	Return Function()
		Yield value
	End Function
End Function

Function StaticValues<T>:ICloseableIterator<T>(first:T, second:T)
	Local StaticArray values:T[2]
	values[0] = first
	values[1] = second
	Yield values[0]
	For Local value:T = EachIn values
		Yield value
	Next
End Function

Function Delegated<T>:ICloseableIterator<T>(values:T[])
	Yield From values
End Function

Function NestedDelegated<T>:ICloseableIterator<T>(values:T[])
	Yield From Delegated<T>(values)
End Function

Type TBox<T>
	Field value:T

	Method Values:ICloseableIterator<T>(count:Int)
		For Local index:Int = 1 To count
			Yield value
		Next
	End Method
End Type
