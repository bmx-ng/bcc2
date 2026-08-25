SuperStrict

Framework BRL.StandardIO

Import BRL.Reflection

Function AddReflectionMarker:String(value:String)
	Return value + "!"
End Function

Function IncrementReflectionValue:Int(value:Int Var)
	value :+ 1
	Return value
End Function

Function PickGenericCallback<T>:Int(value:Int Var)(enabled:Int)
	If enabled Then Return IncrementReflectionValue
	Return Null
End Function

Interface IGenericCallbackChooser<T>
	Method Choose:Int(value:Int Var)(enabled:Int)
End Interface

Type TGenericCallbackChooser<T> Implements IGenericCallbackChooser<T>
	Method Choose:Int(value:Int Var)(enabled:Int)
		If enabled Then Return IncrementReflectionValue
		Return Null
	End Method
End Type

Function ForwardGenericCallback<T>:Int(value:Int Var)(chooser:IGenericCallbackChooser<T>, enabled:Int)
	Return chooser.Choose(enabled)
End Function

Struct SGenericCallbackChooser<T>
	Method Choose:Int(value:Int Var)(enabled:Int)
		If enabled Then Return IncrementReflectionValue
		Return Null
	End Method
End Struct

Type TReflectionCallbackSource
	Field Callback:String(value:String) = AddReflectionMarker
End Type

Type TReflected<T> { entity="generic" }
	ThreadedGlobal Current:Int = 7 { reflect category="tls" }
	Field Value:T { reflect category="state" }

	Method New(input:T) { role="constructor" }
		Value = input
	End Method

	Method Echo:T(input:T) { role="method" }
		Return input
	End Method

	Method Apply:T(callback:T(value:T), input:T) { role="callable-method" }
		Return callback(input)
	End Method

	Method ChooseCallback:String(value:String)(enabled:Int) { role="callable-return" }
		If enabled Then Return AddReflectionMarker
		Return Null
	End Method
End Type

' Force the canonical specialization and its registration unit into the app.
Global reflectedValue:TReflected<String> = New TReflected<String>("direct")

Local typeId:TTypeId = TTypeId.ForName("TReflected<string>")
If Not typeId Then RuntimeError "specialized Type was not registered for reflection"
If Not typeId.HasMetaData("entity") Or typeId.MetaData("entity") <> "generic" Then RuntimeError "specialized Type metadata was not retained"

Local field:TField = typeId.FindField("Value")
If Not field Or field.MetaData("category") <> "state" Then RuntimeError "specialized field metadata was not retained"

Local constructor:TMethod = typeId.FindMethod("New")
Local instance:Object = typeId.NewObject(constructor, ["constructed"])
If field.GetString(instance) <> "constructed" Then RuntimeError "specialized constructor reflection wrapper returned an invalid object"

Local echo:TMethod = typeId.FindMethod("Echo")
If Not echo Or echo.MetaData("role") <> "method" Then RuntimeError "specialized method metadata was not retained"
If String(echo.Invoke(instance, ["invoked"])) <> "invoked" Then RuntimeError "specialized method reflection wrapper returned an invalid value"

Local apply:TMethod = typeId.FindMethod("Apply")
If Not apply Or apply.MetaData("role") <> "callable-method" Then RuntimeError "specialized callable method metadata was not retained"
Local callbackSourceType:TTypeId = TTypeId.ForName("TReflectionCallbackSource")
Local callbackSource:TReflectionCallbackSource = New TReflectionCallbackSource
Local callbackValue:Object = callbackSourceType.FindField("Callback").Get(callbackSource)
If String(apply.Invoke(instance, [callbackValue, "invoked"])) <> "invoked!" Then RuntimeError "specialized callable method reflection invocation failed"

Local chooseCallback:TMethod = typeId.FindMethod("ChooseCallback")
If Not chooseCallback Or chooseCallback.MetaData("role") <> "callable-return" Then RuntimeError "specialized callable-return method metadata was not retained"
callbackSourceType.FindField("Callback").Set(callbackSource, chooseCallback.Invoke(instance, ["1"]))
If String(callbackSourceType.FindField("Callback").Invoke(callbackSource, ["returned"])) <> "returned!" Then RuntimeError "specialized callable-return method reflection invocation failed"

Local routineCallback:Int(value:Int Var) = PickGenericCallback<String>(True)
Local directValue:Int = 39
If routineCallback(directValue) <> 40 Then RuntimeError "generic routine callable-return ABI failed"
Local chooser:IGenericCallbackChooser<String> = New TGenericCallbackChooser<String>
Local interfaceCallback:Int(value:Int Var) = ForwardGenericCallback<String>(chooser, True)
If interfaceCallback(directValue) <> 41 Then RuntimeError "generic Interface callable-return ABI failed"
Local structChooser:SGenericCallbackChooser<String>
Local structCallback:Int(value:Int Var) = structChooser.Choose(True)
If structCallback(directValue) <> 42 Then RuntimeError "generic Struct callable-return ABI failed"

Local current:TGlobal = typeId.FindGlobal("Current")
If Not current Or current.GetInt() <> 7 Or current.MetaData("category") <> "tls" Then RuntimeError "specialized ThreadedGlobal reflection address was not registered"

Print "bcc2 generic reflection runtime regression passed"
