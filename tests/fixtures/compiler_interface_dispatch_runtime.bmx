SuperStrict

Interface IReadable
	Method Read:Int(delta:Int)
End Interface

Interface INamed
	Method Name:String()
End Interface

Interface ICallable
	Method Apply:Int(left:Int, right:Int, operation:Int(a:Int, b:Int))
End Interface

Function AddValues:Int(left:Int, right:Int) { nomangle }
	Return left + right
End Function

Type TItem Implements IReadable, INamed
	Field base:Int
	Field label:String

	Method Read:Int(delta:Int)
		Return base + delta
	End Method

	Method Name:String()
		Return label
	End Method
End Type

Type TSpecial Extends TItem
	Method Read:Int(delta:Int) Override
		Return base + delta + 1
	End Method
End Type

Type TCallableItem Implements ICallable
	Method Apply:Int(left:Int, right:Int, operation:Int(a:Int, b:Int))
		Return operation(left, right)
	End Method
End Type

Type TCallableSpecial Extends TCallableItem
	Method Apply:Int(left:Int, right:Int, operation:Int(a:Int, b:Int)) Override
		Return operation(left, right) + 1
	End Method
End Type

Local item:TItem = New TItem
item.base = 40
item.label = "item"

Local readable:IReadable = item
Local named:INamed = item
Local value:Int = readable.Read(2)
Local label:String = named.Name()
Local special:TSpecial = New TSpecial
special.base = 40
special.label = "special"
Local specialReadable:IReadable = special
Local specialNamed:INamed = special
Local specialValue:Int = specialReadable.Read(2)
Local specialLabel:String = specialNamed.Name()
Local callable:ICallable = New TCallableItem
Local callableSpecial:ICallable = New TCallableSpecial
Local callableValue:Int = callable.Apply(20, 22, AddValues)
Local callableSpecialValue:Int = callableSpecial.Apply(20, 21, AddValues)

If readable
	If named
		If readable = named
			If value = 42
				If label = "item"
					If specialValue = 43
						If specialLabel = "special"
							If callableValue = 42 And callableSpecialValue = 42
								WriteStdout("bcc2 interface dispatch runtime ok~n")
							End If
						End If
					End If
				End If
			End If
		End If
	End If
End If
