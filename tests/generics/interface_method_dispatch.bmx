SuperStrict

Framework BRL.StandardIO

Interface IGenericTag
	Method Tag<T>:Int(value:T, delta:Int = 0)
	Method Replace<T>(value:T Var, replacement:T)
End Interface

Interface IGenericDefault
	Method Base:Int()
	Method Value<T>:Int(value:T) Default
		Return Self.Base()
	End Method
End Interface

Interface IGenericOwnerTag<T>
	Method Tag<U>:Int(value:U)
End Interface

Type TFirstTag Implements IGenericTag
	Method Tag<T>:Int(value:T, delta:Int = 0)
		Return 1 + delta
	End Method

	Method Replace<T>(value:T Var, replacement:T)
		value = replacement
	End Method
End Type

Type TSecondTag Implements IGenericTag
	Method Tag<T>:Int(value:T, delta:Int = 0)
		Return 2 + delta
	End Method

	Method Replace<T>(value:T Var, replacement:T)
		value = replacement
	End Method
End Type

Type TDerivedTag Extends TFirstTag
	Method Tag<T>:Int(value:T, delta:Int = 0) Override
		Return 3 + delta
	End Method
End Type

Type TUsesGenericDefault Implements IGenericDefault
	Method Base:Int()
		Return 40
	End Method
End Type

Type TGenericTagOwner<T> Implements IGenericOwnerTag<T>
	Method Tag<U>:Int(value:U)
		Return 4
	End Method
End Type

Local first:IGenericTag = New TFirstTag
Local second:IGenericTag = New TSecondTag
Local derived:IGenericTag = New TDerivedTag
Local usesDefault:IGenericDefault = New TUsesGenericDefault
Local genericOwner:IGenericOwnerTag<String> = New TGenericTagOwner<String>

If first.Tag("first") <> 1 Then RuntimeError "String dispatch selected the wrong implementation"
If second.Tag("second") <> 2 Then RuntimeError "String dispatch did not distinguish the runtime class"
If first.Tag(10) <> 1 Then RuntimeError "Int dispatch selected the wrong implementation"
If second.Tag(20) <> 2 Then RuntimeError "Int dispatch did not distinguish the runtime class"
If derived.Tag("derived") <> 3 Then RuntimeError "derived override dispatch selected the inherited implementation"
If usesDefault.Value("default") <> 40 Then RuntimeError "generic Interface default body was not used as the typed fallback"
If genericOwner.Tag("generic owner") <> 4 Then RuntimeError "generic Type implementation did not retain its containing specialization identity"
If first.Tag(Object(first), 4) <> 5 Then RuntimeError "Object arguments or optional parameters used the wrong ABI"
Local values:Int[] = [1, 2]
If second.Tag(values, 3) <> 5 Then RuntimeError "managed Array arguments used the wrong ABI"

Local number:Int = 7
second.Replace(number, 9)
If number <> 9 Then RuntimeError "Var Int generic Interface dispatch lost addressability"
Local text:String = "before"
first.Replace(text, "after")
If text <> "after" Then RuntimeError "Var String generic Interface dispatch lost addressability"

Print "generic Interface method dispatch passed"
