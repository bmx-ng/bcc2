SuperStrict

Struct SPoint
	Field x:Int
	Field y:Int

	Method Translate(dx:Int, dy:Int)
		x = x + dx
		y = y + dy
	End Method
End Struct

Function Offset:SPoint(value:SPoint, dx:Int)
	value.x = value.x + dx
	Return value
End Function

Function Move(value:SPoint Var, dx:Int, dy:Int)
	value.x = value.x + dx
	value.y = value.y + dy
End Function

Function ForwardMove(value:SPoint Var, dx:Int, dy:Int)
	Move(value, dx, dy)
End Function

Local original:SPoint
original.x = 20
original.y = 22

Local copied:SPoint = original
copied.x = 1
copied.Translate(2, 3)

Local shifted:SPoint = Offset(original, 2)
ForwardMove(shifted, 3, 4)

Local result:Int = original.x + copied.x + copied.y + shifted.x + shifted.y
If result <> 99 Then result = 0
