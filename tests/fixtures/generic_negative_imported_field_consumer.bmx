SuperStrict
Framework BRL.StandardIO
Import "provider.bmx"

Function BindImportedField<T>:Closure<Int(value:Int)>(unused:T)
	Return MakeHolder().owner.Read
End Function

Local callback:Closure<Int(value:Int)> = BindImportedField<Int>(0)
Print callback(42)
