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

Type TQuotedArray<T>
	Field data:T[16]
End Type

Global quotedComponents:Object[16]

Type TQuotedEntity
	Method SetComponent<T>(component:T)
		quotedComponents[0] = New TQuotedArray<T>
		TQuotedArray<T>(quotedComponents[0]).data[0] = component
	End Method

	Method GetComponent<T>:T()
		Return TQuotedArray<T>(quotedComponents[0]).data[0]
	End Method
End Type

Struct SQuotedGenericOwner
	Field marker:Int

	Method Echo<T>:T(value:T)
		Return value
	End Method
End Struct
