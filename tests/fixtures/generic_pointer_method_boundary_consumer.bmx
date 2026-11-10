Local StaticArray values:Int[2]
values[0] = 12
values[1] = 42
Local pointer:Int Ptr = Varptr values[0]
If BoundaryPointerRead<Int>(pointer, 1) <> 42 Then Throw "generic pointer import failed"

Local owner:TBoundaryMethodOwner<Int> = New TBoundaryMethodOwner<Int>
Local callback:Closure<String(value:String)> = BoundaryBind<String>(owner)
If callback("generic") <> "generic" Then Throw "specialized Method reference import failed"

Print "generic-pointer-method-boundary-ok"
