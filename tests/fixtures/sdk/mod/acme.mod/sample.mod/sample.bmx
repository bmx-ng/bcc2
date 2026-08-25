SuperStrict

Module acme.sample

Private

Function CompareValues:Int(left:Int, right:Int)
	Return left - right
End Function

Public

Function DefaultCompare:Int(a:Int, b:Int)
	Return a - b
End Function

Function Apply:Int(left:Int, right:Int = 1, callback:Int(a:Int, b:Int) = DefaultCompare)
	Return callback(left, right)
End Function

Function Describe:String(value:String = "ready")
	Return value
End Function

Global Value:Int = 1
Global Compare:Int(left:Int, right:Int) = CompareValues

Private

Global Hidden:Int

Public

Const DefaultValue:Int = 3 + 4
Const Label:String = "sample"
