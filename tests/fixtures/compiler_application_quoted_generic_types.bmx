SuperStrict

Import Collections.LinkedList

Type TQuotedList<T> Extends TLinkedList<T>
End Type

Type TQuotedBox<T>
	Field value:T
End Type

Interface IQuotedTransform<T>
	Method Transform:T(value:T)
End Interface

Type TQuotedTransform<T> Implements IQuotedTransform<T>
	Method Transform:T(value:T)
		Return value
	End Method
End Type

Function WrapQuotedTransform<T>:Closure<Closure<T(value:T)>()>(callback:Closure<T(value:T)>)
	Return Function()
		Return callback
	End Function
End Function

Struct SQuotedPayload
	Field number:Int
End Struct

Type TQuotedBoundOwner<T>
	Field stored:T

	Method Transform:T(value:T)
		stored = value
		Return stored
	End Method
End Type

Function MakeQuotedBoundOwner:TQuotedBoundOwner<SQuotedPayload>(value:SQuotedPayload)
	Local owner:TQuotedBoundOwner<SQuotedPayload> = New TQuotedBoundOwner<SQuotedPayload>
	owner.stored = value
	Return owner
End Function

Function ReturnQuotedCallback<T>:Closure<T(value:T)>(callback:Closure<T(value:T)>)
	Return callback
End Function
