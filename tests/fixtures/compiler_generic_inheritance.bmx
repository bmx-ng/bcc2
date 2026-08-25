SuperStrict

Framework BRL.Blitz

Type TBuildBase<T>
	Field baseValue:T

	Method GetBase:T()
		Return baseValue
	End Method
End Type

Type TBuildDerived<T> Extends TBuildBase<T>
	Field derivedValue:T

	Method GetDerived:T()
		Return derivedValue
	End Method
End Type

Global inherited:TBuildDerived<String> = New TBuildDerived<String>

inherited.baseValue = "base"
inherited.derivedValue = "derived"

Global observedBase:String = inherited.GetBase()
Global observedDerived:String = inherited.GetDerived()
