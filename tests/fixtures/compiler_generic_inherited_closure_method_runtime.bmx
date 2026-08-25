SuperStrict

Framework BRL.StandardIO

Interface IGenericClosureTransform<T>
	Method Transform:T(value:T)
End Interface

Type TGenericClosureBase<T> Implements IGenericClosureTransform<T>
	Field stored:T

	Method Transform:T(value:T)
		Return stored
	End Method

	Method Bind:Closure<T(value:T)>()
		Return Transform
	End Method
End Type

Type TStringClosureDerived Extends TGenericClosureBase<String>
	Method Transform:String(value:String) Override
		Return value + "-derived"
	End Method
End Type

Local derived:TStringClosureDerived = New TStringClosureDerived
derived.stored = "inherited"

Local callback:Closure<String(value:String)> = derived.Bind()
If callback("bound") <> "bound-derived" Then Throw "inherited generic Closure-returning Method lost virtual dispatch"

Local throughInterface:IGenericClosureTransform<String> = derived
If throughInterface.Transform("interface") <> "interface-derived" Then Throw "generic base Interface table was not rebuilt for derived override"

Print "generic-inherited-closure-method-ok"
