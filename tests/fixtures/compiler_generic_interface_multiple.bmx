SuperStrict

Interface IRoot<T>
	Method Read:T()
End Interface

Interface ILeft<T> Extends IRoot<T>
	Method Left:T()
End Interface

Interface IRight<T> Extends IRoot<T>
	Method Right:T()
End Interface

Interface IDiamond<T> Extends ILeft<T>, IRight<T>
	Method Diamond:T()
End Interface

Interface IExtra<T>
	Method Extra:T()
End Interface

Type TMultiValue<T> Implements IDiamond<T>, IExtra<T>
	Field value:T

	Method Read:T()
		Return value
	End Method

	Method Left:T()
		Return value
	End Method

	Method Right:T()
		Return value
	End Method

	Method Diamond:T()
		Return value
	End Method

	Method Extra:T()
		Return value
	End Method
End Type

Global concrete:TMultiValue<String> = New TMultiValue<String>
concrete.value = "multiple"
Global rootValue:IRoot<String> = concrete
Global leftValue:ILeft<String> = concrete
Global rightValue:IRight<String> = concrete
Global diamondValue:IDiamond<String> = concrete
Global extraValue:IExtra<String> = concrete
Global observedRoot:String = rootValue.Read()
Global observedLeft:String = leftValue.Left()
Global observedRight:String = rightValue.Right()
Global observedDiamond:String = diamondValue.Diamond()
Global observedExtra:String = extraValue.Extra()
