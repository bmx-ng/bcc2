SuperStrict

Framework BRL.Blitz

Interface IDefaultValue<T>
	Method Identity:T(value:T)

	Method Describe:T(value:T) Default
		Return Self.Identity(value)
	End Method

	Method Label:String() Default
		Return "base"
	End Method
End Interface

Interface IDecoratedValue<T> Extends IDefaultValue<T>
	Method Label:String() Override Default
		Return Super<IDefaultValue<T>>.Label() + "!"
	End Method
End Interface

Type TDefaultValue<T> Implements IDecoratedValue<T>
	Method Identity:T(value:T)
		Return value
	End Method
End Type

Global item:TDefaultValue<String> = New TDefaultValue<String>
Global view:IDecoratedValue<String> = item
Global described:String = view.Describe("generic-default")
Assert described = "generic-default"
Assert view.Label() = "base!"
