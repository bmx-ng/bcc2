SuperStrict

Framework BRL.StandardIO

Type TInitializationBase<T>
	Global First:Int = 40
	Global Second:Int = First + 1

	Method BaseValue:Int()
		Return Second
	End Method
End Type

Type TInitializationDerived<T> Extends TInitializationBase<T>
	Global Derived:Int = Second + 1

	Method DerivedValue:Int()
		Return Derived
	End Method
End Type

Type TInitializationProducer<T>
	Global Value:Int = 41

	Method Read:Int()
		Return Value
	End Method
End Type

Type TInitializationConsumer<T>
	Global Observed:Int = (New TInitializationProducer<T>).Read() + 1

	Method Read:Int()
		Return Observed
	End Method
End Type

Type TInitializationStorage<T>
	Global Value:Int = 1

	Method Read:Int()
		Return Value
	End Method

	Method Write(nextValue:Int)
		Value = nextValue
	End Method
End Type

Type TInitializationDefault<T>
	Global Value:T

	Method Read:T()
		Return Value
	End Method
End Type

Struct SInitializationOrder<T>
	Global First:Int = 20
	Global Second:Int = First + 2

	Method Read:Int()
		Return Second
	End Method
End Struct

Local base:TInitializationBase<String> = New TInitializationBase<String>
Local derived:TInitializationDerived<String> = New TInitializationDerived<String>
If base.BaseValue() <> 41 Then Throw "same-specialization initialization order failed"
If derived.DerivedValue() <> 42 Then Throw "base-before-derived initialization order failed"

Local consumer:TInitializationConsumer<String> = New TInitializationConsumer<String>
If consumer.Read() <> 42 Then Throw "cross-specialization initialization order failed: " + consumer.Read()

Local stringStorage:TInitializationStorage<String> = New TInitializationStorage<String>
Local intStorage:TInitializationStorage<Int> = New TInitializationStorage<Int>
stringStorage.Write(42)
If stringStorage.Read() <> 42 Or intStorage.Read() <> 1 Then Throw "closed specialization static storage was shared"

Local stringDefault:TInitializationDefault<String> = New TInitializationDefault<String>
Local arrayDefault:TInitializationDefault<Int[]> = New TInitializationDefault<Int[]>
Local objectDefault:TInitializationDefault<Object> = New TInitializationDefault<Object>
Local closureDefault:TInitializationDefault<Closure<Int()>> = New TInitializationDefault<Closure<Int()>>
If stringDefault.Read() <> "" Then Throw "generic String static default was not the runtime empty sentinel"
If arrayDefault.Read().length <> 0 Then Throw "generic Array static default was not the runtime empty sentinel"
If objectDefault.Read() <> Null Then Throw "generic Object static default was not the runtime Null sentinel"
If closureDefault.Read() <> Null Then Throw "generic Closure static default was not Null"

Local structOrder:SInitializationOrder<String>
If structOrder.Read() <> 22 Then Throw "generic Struct static initialization order failed"

Print "bcc2 generic initialization ordering ok"
