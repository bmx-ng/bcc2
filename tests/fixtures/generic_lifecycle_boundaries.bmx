SuperStrict

Framework BRL.StandardIO

Global lifecycleOrder:Int

Type TGenericLifecycleBase<T>
	Method Delete()
		lifecycleOrder = lifecycleOrder * 10 + 1
	End Method

	Method Read:T(value:T)
		Return value
	End Method
End Type

Type TGenericLifecycleDerived<T> Extends TGenericLifecycleBase<T>
	Method Delete()
		lifecycleOrder = lifecycleOrder * 10 + 2
	End Method

	Method ReadDerived:T(value:T)
		Return value
	End Method
End Type

Type TGenericLifecycleLeaf<T> Extends TGenericLifecycleDerived<T>
	Method ReadLeaf:T(value:T)
		Return value
	End Method
End Type

Function CreateLifecycleValue()
	Local value:TGenericLifecycleLeaf<String> = New TGenericLifecycleLeaf<String>
	If value.Read("base") <> "base" Or value.ReadDerived("derived") <> "derived" Or value.ReadLeaf("leaf") <> "leaf" Then Throw "generic lifecycle method layout failed"
End Function

CreateLifecycleValue()
GCCollect()
If lifecycleOrder <> 21 Then Throw "generic destructor order was " + lifecycleOrder + ", expected 21"
Print "bcc2 generic lifecycle boundaries ok"
