SuperStrict

Interface IIterator
	Method Current:Int()
	Method MoveNext:Int()
End Interface

Interface IIterable
	Method GetIterator:IIterator()
End Interface

Type TProtocolIterator Implements IIterator
	Field index:Int

	Method Current:Int()
		Return index
	End Method

	Method MoveNext:Int()
		index = index + 1
		Return index <= 3
	End Method
End Type

Type TProtocolValues Implements IIterable
	Field created:Int

	Method GetIterator:IIterator()
		created = created + 1
		Return New TProtocolIterator
	End Method
End Type

Local total:Int
#Outer
For Local value:Int = EachIn New TProtocolValues
	If value = 2 Then Continue Outer
	total = total + value
Next

Local direct:TProtocolIterator = New TProtocolIterator
For Local value:Int = EachIn direct
	If value = 2 Then Exit
	total = total + value
Next

If total = 5 Then WriteStdout("interface eachin runtime ok~n")
