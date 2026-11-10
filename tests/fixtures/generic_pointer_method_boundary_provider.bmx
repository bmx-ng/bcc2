Function BoundaryPointerRead<T>:T(pointer:T Ptr, index:Int)
	Return pointer[index]
End Function

Type TBoundaryMethodOwner<T>
	Method Identity<U>:U(value:U)
		Return value
	End Method
End Type

Function BoundaryBind<T>:Closure<T(value:T)>(owner:TBoundaryMethodOwner<Int>)
	Return owner.Identity<T>
End Function
