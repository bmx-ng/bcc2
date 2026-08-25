SuperStrict

Module Bcc2GenericInheritedMethod.Types

Interface IPublishedGenericClosureTransform<T>
	Method Transform:T(value:T)
End Interface

Type TPublishedGenericClosureBase<T> Implements IPublishedGenericClosureTransform<T>
	Field stored:T

	Method Transform:T(value:T)
		Return stored
	End Method

	Method Bind:Closure<T(value:T)>()
		Return Transform
	End Method
End Type

Type TPublishedStringClosureDerived Extends TPublishedGenericClosureBase<String>
	Method Transform:String(value:String) Override
		Return value + "-published"
	End Method
End Type
