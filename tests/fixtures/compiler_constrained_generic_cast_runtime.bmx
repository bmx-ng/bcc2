SuperStrict

Framework BRL.StandardIO

Type TCastBase
	Field value:Int
End Type

Type TCastChild Extends TCastBase
End Type

Function CastObject<T>:T(value:Object) Where T Extends Object
	Return T(value)
End Function

Function CastBase<T>:T(value:TCastBase) Where T Extends TCastChild
	Return T(value)
End Function

Local source:TCastChild = New TCastChild
source.value = 42
Local fromObject:TCastChild = CastObject<TCastChild>(source)
Local fromBase:TCastChild = CastBase<TCastChild>(source)
If fromObject <> source Or fromBase <> source Or fromObject.value <> 42 Then RuntimeError "constrained generic cast lost its runtime object"

Print "constrained generic casts passed"
