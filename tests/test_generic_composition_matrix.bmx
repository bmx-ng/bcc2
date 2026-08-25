SuperStrict

Framework BRL.StandardIO

Import BlitzMax.Compiler

Const OWNER_GENERIC_TYPE:Int = 1
Const OWNER_GENERIC_STRUCT:Int = 2
Const OWNER_GENERIC_METHOD:Int = 3
Const OWNER_GENERIC_INHERITANCE:Int = 4

Const PAYLOAD_STRING:Int = 1
Const PAYLOAD_OBJECT:Int = 2
Const PAYLOAD_ARRAY:Int = 3
Const PAYLOAD_CLOSURE:Int = 4

Type TCompositionMatrixRow
	Field name:String
	Field ownerKind:Int
	Field payloadKind:Int

	Method New(name:String, ownerKind:Int, payloadKind:Int)
		Self.name = name
		Self.ownerKind = ownerKind
		Self.payloadKind = payloadKind
	End Method
End Type

Function CompilationSummary:String(result:TCompilerResult)
	If Not result Then Return "no compiler result"
	Local summary:String = "succeeded=" + result.Succeeded()
	If result.analysis Then
		If result.analysis.syntaxTree Then
			For Local diagnostic:TDiagnostic = EachIn result.analysis.syntaxTree.diagnostics
				summary :+ "; " + diagnostic.code + " " + diagnostic.message
			Next
		End If
		If result.analysis.model Then
			For Local diagnostic:TDiagnostic = EachIn result.analysis.model.diagnostics
				summary :+ "; " + diagnostic.code + " " + diagnostic.message
			Next
		End If
	End If
	For Local diagnostic:TCompilerDiagnostic = EachIn result.diagnostics
		summary :+ "; " + diagnostic.code + " " + diagnostic.message
	Next
	Return summary
End Function

Function PayloadType:String(kind:Int)
	Select kind
		Case PAYLOAD_STRING Return "String"
		Case PAYLOAD_OBJECT Return "TMatrixPayload"
		Case PAYLOAD_ARRAY Return "Int[]"
		Case PAYLOAD_CLOSURE Return "Closure<Int()>"
	End Select
	Throw "unknown matrix payload"
End Function

Function PayloadPrelude:String(kind:Int)
	Select kind
		Case PAYLOAD_OBJECT
			Return "Type TMatrixPayload~nField text:String~nEnd Type~n"
		Case PAYLOAD_CLOSURE
			Return "Global payloadSeed:Closure<Int()>=Function()~nReturn 42~nEnd Function~n"
	End Select
	Return ""
End Function

Function PayloadInitializer:String(kind:Int)
	Select kind
		Case PAYLOAD_STRING Return "~qseed~q"
		Case PAYLOAD_OBJECT Return "New TMatrixPayload"
		Case PAYLOAD_ARRAY Return "[1,2]"
		Case PAYLOAD_CLOSURE Return "payloadSeed"
	End Select
	Throw "unknown matrix payload"
End Function

Function PayloadUse:String(kind:Int)
	Select kind
		Case PAYLOAD_STRING Return "Global observed:String=result"
		Case PAYLOAD_OBJECT Return "Global observed:TMatrixPayload=result"
		Case PAYLOAD_ARRAY Return "Global observed:Int=result[0]"
		Case PAYLOAD_CLOSURE Return "Global observed:Int=result()"
	End Select
	Throw "unknown matrix payload"
End Function

Function SharedPairDeclaration:String()
	Return "Struct SMatrixPair<T>~n" + ..
		"Field value:T~n" + ..
		"Field transform:Closure<T(value:T)>~n" + ..
		"End Struct~n"
End Function

Function ApplyBody:String(valueName:String = "value", transformName:String = "transform", beforeReturn:String = "")
	Return "Local pair:SMatrixPair<T>~n" + ..
		"pair.value=" + valueName + "~n" + ..
		"pair.transform=" + transformName + "~n" + ..
		"Local pairs:SMatrixPair<T>[]=[pair]~n" + ..
		"pairs=pairs+[pair]~n" + ..
		"Local matrix:T[,]=New T[1,2]~n" + ..
		"For Local current:SMatrixPair<T>=EachIn pairs~n" + ..
		"matrix[0,1]=current.transform(current.value)~n" + ..
		"Next~n" + ..
		beforeReturn + ..
		"Return matrix[0,1]~n"
End Function

Function OwnerDeclaration:String(kind:Int)
	Select kind
		Case OWNER_GENERIC_TYPE
			Return "Type TMatrixOwner<T>~n" + ..
				"Method Apply:T(value:T,transform:Closure<T(value:T)>)~n" + ApplyBody() + ..
				"End Method~nEnd Type~n"
		Case OWNER_GENERIC_STRUCT
			Return "Struct SMatrixOwner<T>~n" + ..
				"Method Apply:T(value:T,transform:Closure<T(value:T)>)~n" + ApplyBody() + ..
				"End Method~nEnd Struct~n"
		Case OWNER_GENERIC_METHOD
			Return "Type TMatrixFactory~n" + ..
				"Method Apply<T>:T(value:T,transform:Closure<T(value:T)>)~n" + ApplyBody() + ..
				"End Method~nEnd Type~n"
		Case OWNER_GENERIC_INHERITANCE
			Return "Type TMatrixBase<A,B>~n" + ..
				"Field values:B~n" + ..
				"Method Values:B()~nReturn values~nEnd Method~n" + ..
				"End Type~n" + ..
				"Type TMatrixMiddle<X> Extends TMatrixBase<String,X[]>~nEnd Type~n" + ..
				"Type TMatrixOwner<T> Extends TMatrixMiddle<T>~n" + ..
				"Method Apply:T(value:T,transform:Closure<T(value:T)>)~n" + ApplyBody("value", "transform", "values=[value]~n") + ..
				"End Method~nEnd Type~n"
	End Select
	Throw "unknown matrix owner"
End Function

Function Invocation:String(row:TCompositionMatrixRow)
	Local payload:String = PayloadType(row.payloadKind)
	Local initializer:String = PayloadInitializer(row.payloadKind)
	Local transformType:String = "Closure<" + payload + "(value:" + payload + ")>"
	Local result:String = "Global transform:" + transformType + "=Function(value)~nReturn value~nEnd Function~n"
	Select row.ownerKind
		Case OWNER_GENERIC_TYPE
			result :+ "Global owner:TMatrixOwner<" + payload + ">=New TMatrixOwner<" + payload + ">~n"
			result :+ "Global result:" + payload + "=owner.Apply(" + initializer + ",transform)~n"
		Case OWNER_GENERIC_STRUCT
			result :+ "Global owner:SMatrixOwner<" + payload + ">~n"
			result :+ "Global result:" + payload + "=owner.Apply(" + initializer + ",transform)~n"
		Case OWNER_GENERIC_METHOD
			result :+ "Global owner:TMatrixFactory=New TMatrixFactory~n"
			result :+ "Global result:" + payload + "=owner.Apply<" + payload + ">(" + initializer + ",transform)~n"
		Case OWNER_GENERIC_INHERITANCE
			result :+ "Global owner:TMatrixOwner<" + payload + ">=New TMatrixOwner<" + payload + ">~n"
			result :+ "Global result:" + payload + "=owner.Apply(" + initializer + ",transform)~n"
			result :+ "Global base:TMatrixBase<String," + payload + "[]>=owner~n"
			result :+ "Global inheritedValues:" + payload + "[]=base.Values()~n"
	End Select
	Return result + PayloadUse(row.payloadKind) + "~n"
End Function

Function ProgramFor:String(row:TCompositionMatrixRow)
	Return "SuperStrict~n" + PayloadPrelude(row.payloadKind) + SharedPairDeclaration() + OwnerDeclaration(row.ownerKind) + Invocation(row)
End Function

Local rows:TCompositionMatrixRow[] = [ ..
	New TCompositionMatrixRow("type-string", OWNER_GENERIC_TYPE, PAYLOAD_STRING), ..
	New TCompositionMatrixRow("type-object", OWNER_GENERIC_TYPE, PAYLOAD_OBJECT), ..
	New TCompositionMatrixRow("type-array", OWNER_GENERIC_TYPE, PAYLOAD_ARRAY), ..
	New TCompositionMatrixRow("type-closure", OWNER_GENERIC_TYPE, PAYLOAD_CLOSURE), ..
	New TCompositionMatrixRow("struct-string", OWNER_GENERIC_STRUCT, PAYLOAD_STRING), ..
	New TCompositionMatrixRow("struct-object", OWNER_GENERIC_STRUCT, PAYLOAD_OBJECT), ..
	New TCompositionMatrixRow("struct-array", OWNER_GENERIC_STRUCT, PAYLOAD_ARRAY), ..
	New TCompositionMatrixRow("struct-closure", OWNER_GENERIC_STRUCT, PAYLOAD_CLOSURE), ..
	New TCompositionMatrixRow("method-string", OWNER_GENERIC_METHOD, PAYLOAD_STRING), ..
	New TCompositionMatrixRow("method-object", OWNER_GENERIC_METHOD, PAYLOAD_OBJECT), ..
	New TCompositionMatrixRow("method-array", OWNER_GENERIC_METHOD, PAYLOAD_ARRAY), ..
	New TCompositionMatrixRow("method-closure", OWNER_GENERIC_METHOD, PAYLOAD_CLOSURE), ..
	New TCompositionMatrixRow("inheritance-string", OWNER_GENERIC_INHERITANCE, PAYLOAD_STRING), ..
	New TCompositionMatrixRow("inheritance-object", OWNER_GENERIC_INHERITANCE, PAYLOAD_OBJECT), ..
	New TCompositionMatrixRow("inheritance-array", OWNER_GENERIC_INHERITANCE, PAYLOAD_ARRAY), ..
	New TCompositionMatrixRow("inheritance-closure", OWNER_GENERIC_INHERITANCE, PAYLOAD_CLOSURE) ..
]

Local options:TCompilerOptions = TCompilerOptions.CreateDefault()
options.requireCoreInterface = False

For Local row:TCompositionMatrixRow = EachIn rows
	Local result:TCompilerResult = TBlitzMaxCompiler.Compile("generic-composition-" + row.name + ".bmx", ProgramFor(row), Null, options)
	If Not result.Succeeded() Then Throw row.name + " failed: " + CompilationSummary(result)
	Local runtimeDiagnostics:TCompilerDiagnostic[]
	TBlitzMaxCompiler.EmitRuntimeC(result, runtimeDiagnostics)
	If runtimeDiagnostics.length Then Throw row.name + " runtime C emission failed: " + runtimeDiagnostics[0].code + " " + runtimeDiagnostics[0].message
	Local implementations:String
	For Local unit:TCompilerGenericUnit = EachIn result.genericPlan.units
		implementations :+ unit.implementation
		If unit.implementation.Contains("bbArrayNew1DStruct_") And Not unit.implementation.Contains("BBArray *bbArrayNew1DStruct_") Then Throw row.name + " uses a specialized Struct Array helper without a C99 declaration"
	Next
	If implementations.Contains("bbArrayNew1DStruct_(") Then Throw row.name + " emitted an unnamed generic Struct Array helper"
	If Not implementations.Contains("bbArrayConcat(") Then Throw row.name + " did not retain managed Array concatenation"
Next

Print "bcc2 generic composition matrix passed: " + rows.length + " cases"
