SuperStrict

Interface IBaseValue
	Method BaseValue:Int(delta:Int)
End Interface

Interface ILeftValue Extends IBaseValue
	Method LeftValue:Int()
End Interface

Interface IRightValue Extends IBaseValue
	Method RightValue:Int()
End Interface

Interface IDiamondValue Extends ILeftValue, IRightValue
	Method DiamondValue:Int()
End Interface

Type TDiamondValue Implements IDiamondValue
	Field base:Int

	Method BaseValue:Int(delta:Int)
		Return base + delta
	End Method

	Method LeftValue:Int()
		Return base + 1
	End Method

	Method RightValue:Int()
		Return base + 2
	End Method

	Method DiamondValue:Int()
		Return base + 3
	End Method
End Type

Local item:TDiamondValue = New TDiamondValue
item.base = 39

Local root:IBaseValue = item
Local left:ILeftValue = item
Local right:IRightValue = item
Local diamond:IDiamondValue = item
Local inheritedRoot:IBaseValue = diamond

If root.BaseValue(3) = 42
	If left.BaseValue(3) = 42
		If left.LeftValue() = 40
			If right.RightValue() = 41
				If diamond.BaseValue(3) = 42
					If inheritedRoot.BaseValue(3) = 42
						If diamond.LeftValue() = 40
							If diamond.RightValue() = 41
								If diamond.DiamondValue() = 42
									WriteStdout("bcc2 interface inheritance runtime ok~n")
								End If
							End If
						End If
					End If
				End If
			End If
		End If
	End If
End If
