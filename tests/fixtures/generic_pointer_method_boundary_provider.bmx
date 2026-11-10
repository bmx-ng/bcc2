Function BoundaryPointerRead<T>:T(pointer:T Ptr, index:Int)
	Return pointer[index]
End Function

Type TBoundaryMethodOwner<T>
	Field delta:Int

	Method Identity<U>:U(value:U)
		Return value
	End Method

	Method Add:Int(value:Int)
		Return value + delta
	End Method
End Type

Global boundaryReceiverFactoryCalls:Int

Function MakeBoundaryOwner:TBoundaryMethodOwner<Int>()
	boundaryReceiverFactoryCalls :+ 1
	Local owner:TBoundaryMethodOwner<Int> = New TBoundaryMethodOwner<Int>
	owner.delta = boundaryReceiverFactoryCalls * 10
	Return owner
End Function

Function BoundaryBindComputed<T>:Closure<Int(value:Int)>(unused:T)
	Return MakeBoundaryOwner().Add
End Function

Function BoundaryBindComputedGeneric<T>:Closure<T(value:T)>(unused:T)
	Return MakeBoundaryOwner().Identity<T>
End Function

Type TBoundaryOwnerHolder
	Field owner:TBoundaryMethodOwner<Int>
	Method Owner:TBoundaryMethodOwner<Int>()
		Return owner
	End Method
End Type

Function MakeBoundaryHolder:TBoundaryOwnerHolder()
	Local holder:TBoundaryOwnerHolder = New TBoundaryOwnerHolder
	holder.owner = MakeBoundaryOwner()
	Return holder
End Function

Function BoundaryBindMember<T>:Closure<Int(value:Int)>(unused:T)
	Return MakeBoundaryHolder().Owner().Add
End Function

Function MakeBoundaryOwnerArray:TBoundaryMethodOwner<Int>[]()
	Return [MakeBoundaryOwner()]
End Function

Function BoundaryBindIndexed<T>:Closure<Int(value:Int)>(unused:T)
	Return MakeBoundaryOwnerArray()[0].Add
End Function

Interface IBoundaryBase
	Method Bump:Int(value:Int Var)
End Interface

Interface IBoundaryAdvanced Extends IBoundaryBase
	Method Read:Int()
End Interface

Type TBoundaryInterfaceBox<T> Implements IBoundaryAdvanced
	Method Bump:Int(value:Int Var)
		value :+ 1
		Return value
	End Method

	Method Read:Int()
		Return 42
	End Method
End Type

Function BoundaryBind<T>:Closure<T(value:T)>(owner:TBoundaryMethodOwner<Int>)
	Return owner.Identity<T>
End Function
