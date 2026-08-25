SuperStrict

Framework BRL.Blitz

Interface IBuildValue<T>
	Method Read:T()
End Interface

Type TBuildValue<T> Implements IBuildValue<T>
	Field value:T

	Method Read:T()
		Return value
	End Method
End Type

Global concrete:TBuildValue<String> = New TBuildValue<String>
concrete.value = "interface"

Global abstractValue:IBuildValue<String> = concrete
Global observedInterface:String = abstractValue.Read()
