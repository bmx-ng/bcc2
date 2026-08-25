SuperStrict

Type TInheritedBase<T>
	Field value:T
	Field note:String

	Method New(value:T, suffix:String = "!")
		Self.value = value
		note = suffix
	End Method

	Method RuntimeKind:String()
		Return "base"
	End Method
End Type

Type TInheritedMiddle<T> Extends TInheritedBase<T>
End Type

Type TInheritedDeep<T> Extends TInheritedMiddle<T>
	Method RuntimeKind:String()
		Return "deep"
	End Method
End Type

Type TInheritedShadow<T> Extends TInheritedBase<T>
	Method New(value:Int)
		note = "direct-" + value
	End Method

	Method RuntimeKind:String()
		Return "shadow"
	End Method
End Type

Type TVarConstructorBase<T>
	Field value:T

	Method New(value:T Var)
		Self.value = value
	End Method
End Type

Type TVarConstructorDerived<T> Extends TVarConstructorBase<T>
End Type

Type TZeroConstructorBase<T>
	Field initialized:Int

	Method New()
		initialized = 41
	End Method
End Type

Type TZeroConstructorDerived<T> Extends TZeroConstructorBase<T>
End Type

Type TZeroConstructorShadow<T> Extends TZeroConstructorBase<T>
	Method New()
		initialized = 7
	End Method
End Type
