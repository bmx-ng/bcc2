SuperStrict

Framework BRL.StandardIO
Import BRL.Reflection

Type TReflectionPeer
End Type

Function DoubleValue:Int(value:Int)
	Return value * 2
End Function

Function TripleValue:Int(value:Int)
	Return value * 3
End Function

Type TCallableReflectionHolder
	Field callback:Int(value:Int) = DoubleValue
	Field callbacks:Int(index:Int, sender:TReflectionPeer)[]
	Global globalCallback:Int(value:Int) = TripleValue

	Method InvokeNested:Int(callback:Int(value:Int), value:Int)
		Return callback(value)
	End Method

	Method ChooseCallback:Int(value:Int)(triple:Int)
		If triple Then Return TripleValue
		Return DoubleValue
	End Method
End Type

Type TClosureReflectionHolder
	Field callback:Closure<Int(value:Int)>
	Field nested:Closure<Closure<Int()>()>
	Field mutate:Closure<(value:Int Var)>

	Method Keep:Closure<Int(value:Int)>(operation:Closure<Int(value:Int)>)
		Return operation
	End Method
End Type

Struct SCallableReflectionHolder
	Field callback:Int(value:Int) = DoubleValue

	Method ChooseCallback:Int(value:Int)(triple:Int)
		If triple Then Return TripleValue
		Return DoubleValue
	End Method
End Struct

Struct SImplicitReflectionValue
	Field text:String = "implicit"

	Method New(text:String)
		Self.text = text
	End Method
End Struct

Struct SExplicitReflectionValue
	Field text:String

	Method New()
		text = "explicit"
	End Method
End Struct

Local typeId:TTypeId = TTypeId.ForName("TCallableReflectionHolder")
If Not typeId Then Throw "callable reflection holder was not registered"

Local fieldCount:Int
For Local field:TField = EachIn typeId.EnumFields()
	Local fieldType:TTypeId = field.TypeId()
	If Not fieldType Then Throw "callable field type was not resolved: " + field.Name()
	fieldCount :+ 1
Next

If fieldCount <> 2 Then Throw "expected two callable fields, found " + fieldCount

Local closureHolderType:TTypeId = TTypeId.ForName("TClosureReflectionHolder")
If Not closureHolderType Then Throw "Closure reflection holder was not registered"
Local closureField:TField = closureHolderType.FindField("callback")
If Not closureField Then Throw "Closure field was not reflected"
Local closureFieldType:TTypeId = closureField.TypeId()
If Not closureFieldType Or Not closureFieldType.ExtendsType(ClosureTypeId) Or Not closureFieldType.IsReferenceType() Then Throw "Closure field did not retain its managed structural type"
If closureFieldType.Name() <> "Closure<Int(Int)>" Or closureFieldType.ReturnType() <> IntTypeId Or closureFieldType.ArgTypes().length <> 1 Or closureFieldType.ArgTypes()[0] <> IntTypeId Then Throw "Closure field signature was not reconstructed"
If TTypeId.ForName("Closure<Int(value:Int)>") <> closureFieldType Then Throw "Closure type lookup did not canonicalize parameter names"
Local nestedClosureField:TField = closureHolderType.FindField("nested")
If Not nestedClosureField Or nestedClosureField.TypeId().ReturnType().Name() <> "Closure<Int()>" Then Throw "Closure-valued Closure return was not reflected"
Local mutateClosureField:TField = closureHolderType.FindField("mutate")
If Not mutateClosureField Or mutateClosureField.TypeId().Name() <> "Closure<(Int Var)>" Or mutateClosureField.TypeId().ReturnType() <> VoidTypeId Or Not mutateClosureField.TypeId().ArgTypes()[0].ExtendsType(VarTypeId) Then Throw "Closure Var parameter or implied no-return signature was not reflected"
Local closureKeep:TMethod = closureHolderType.FindMethod("Keep")
If Not closureKeep Or closureKeep.ReturnType() <> closureFieldType Or closureKeep.ArgTypes()[0] <> closureFieldType Then Throw "Closure method signature was not reflected"

Local holder:TCallableReflectionHolder = New TCallableReflectionHolder
Local callbackField:TField = typeId.FindField("callback")
If Not callbackField Then Throw "callable field was not found"
If Int(String(callbackField.Invoke(holder, ["21"]))) <> 42 Then Throw "callable field reflection invocation failed"

Local callbackGlobal:TGlobal = typeId.FindGlobal("globalCallback")
If Not callbackGlobal Then Throw "callable Global was not found"
If Int(String(callbackGlobal.Invoke(["14"]))) <> 42 Then Throw "callable Global reflection invocation failed"

Local nestedCallableMethod:TMethod = typeId.FindMethod("InvokeNested")
If Not nestedCallableMethod Then Throw "nested-callable method was not found"
If Int(String(nestedCallableMethod.Invoke(holder, [callbackField.Get(holder), "21"]))) <> 42 Then Throw "nested-callable method reflection invocation failed"

Local returnedCallableMethod:TMethod = typeId.FindMethod("ChooseCallback")
If Not returnedCallableMethod Then Throw "callable-return method was not found"
callbackField.Set(holder, returnedCallableMethod.Invoke(holder, ["1"]))
If Int(String(callbackField.Invoke(holder, ["14"]))) <> 42 Then Throw "callable-return method reflection invocation failed"

Local structType:TTypeId = TTypeId.ForName("SCallableReflectionHolder")
If Not structType Then Throw "callable reflection Struct was not registered"
Local structValue:Object = structType.NewObject()
Local structCallbackField:TField = structType.FindField("callback")
If Not structCallbackField Then Throw "callable Struct field was not found"
If Int(String(structCallbackField.Invoke(structValue, ["21"]))) <> 42 Then Throw "callable Struct field reflection invocation failed"
Local structReturnedCallableMethod:TMethod = structType.FindMethod("ChooseCallback")
If Not structReturnedCallableMethod Then Throw "callable-return Struct method was not found"
structCallbackField.Set(structValue, structReturnedCallableMethod.Invoke(structValue, ["1"]))
If Int(String(structCallbackField.Invoke(structValue, ["14"]))) <> 42 Then Throw "callable-return Struct method reflection invocation failed"

Local implicitType:TTypeId = TTypeId.ForName("SImplicitReflectionValue")
If Not implicitType Then Throw "implicit reflection Struct was not registered"
Local implicitValue:Object = implicitType.NewObject()
If String(implicitType.FindField("text").Get(implicitValue)) <> "implicit" Then Throw "implicit reflection Struct default construction failed"

Local explicitType:TTypeId = TTypeId.ForName("SExplicitReflectionValue")
If Not explicitType Then Throw "explicit reflection Struct was not registered"
Local explicitValue:Object = explicitType.NewObject()
If String(explicitType.FindField("text").Get(explicitValue)) <> "explicit" Then Throw "explicit reflection Struct default construction failed"
Print "bcc2 callable reflection runtime ok"
