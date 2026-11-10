SuperStrict
Framework BRL.StandardIO

Type TFieldOwner
	Method Read:Int(value:Int)
		Return value
	End Method
End Type

Type TFieldHolder
	Field owner:TFieldOwner
End Type

Function MakeHolder:TFieldHolder()
	Local holder:TFieldHolder = New TFieldHolder
	holder.owner = New TFieldOwner
	Return holder
End Function

Function BindField<T>:Closure<Int(value:Int)>(unused:T)
	Return MakeHolder().owner.Read
End Function

Local callback:Closure<Int(value:Int)> = BindField<Int>(0)
Print callback(42)
