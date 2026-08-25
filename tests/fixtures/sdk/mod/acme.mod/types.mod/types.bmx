SuperStrict

Module acme.types

Type TPublished
	Field Value:Int
	Field Peer:TSecond
	Field Items:Int[]

	Method New(initialValue:Int)
		Value = initialValue
	End Method

	Method Read:Int(delta:Int)
		Return Value + delta
	End Method

	Method EchoPeer:TSecond(newPeer:TSecond = Null)
		Peer = newPeer
		Return Peer
	End Method

	Method EchoItems:Int[](newItems:Int[] = Null)
		Items = newItems
		Return Items
	End Method

	Function Identity:Int(value:Int)
		Return value
	End Function
End Type

Type TSecond
	Field Value:Int

	Method New(initialValue:Int)
		Value = initialValue
	End Method

	Method Read:Int(delta:Int)
		Return Value + delta
	End Method
End Type

Private

Type THidden
	Field Value:Int

	Method Read:Int(delta:Int)
		Return Value + delta
	End Method
End Type
