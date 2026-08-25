SuperStrict

Framework BRL.Blitz

Type TReceiverBase<T>
	Field value:T

	Method Read:T()
		Return value
	End Method
End Type

Type TReceiverDerived<T> Extends TReceiverBase<T>
	Field value:T
	Field peer:TReceiverBase<T>

	Method Read:T() Override
		Return value
	End Method

	Method FromParameter:T(other:TReceiverBase<T>)
		Return other.Read()
	End Method

	Method FromField:T()
		Return peer.Read()
	End Method

	Method FromLocal:T(other:TReceiverDerived<T>)
		Local widened:TReceiverBase<T> = other
		Return widened.Read()
	End Method

	Method FromSelf:T()
		Return Self.Read()
	End Method

	Method FromSuper:T()
		Return Super.Read()
	End Method
End Type

Local item:TReceiverDerived<String> = New TReceiverDerived<String>
Local baseView:TReceiverBase<String> = item
baseView.value = "base"
item.value = "derived"
item.peer = item

Assert item.FromParameter(item) = "derived"
Assert item.FromField() = "derived"
Assert item.FromLocal(item) = "derived"
Assert item.FromSelf() = "derived"
Assert item.FromSuper() = "base"
