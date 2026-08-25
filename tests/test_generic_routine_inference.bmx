SuperStrict

Framework BRL.StandardIO

Import BlitzMax.Language

Function Check(condition:Int, message:String)
	If Not condition Then Throw message
End Function

Local source:String = "SuperStrict~nType TList<T>~nEnd Type~nFunction Identity<T>:T(value:T)~nReturn value~nEnd Function~nFunction First<T>:T(values:TList<T>)~nReturn Null~nEnd Function~nFunction Choose<T>:T(first:T, second:T)~nReturn first~nEnd Function~nFunction Create<T>:T()~nReturn Null~nEnd Function"
Local parsed:TParseResult = TBlitzMaxParser.ParseText(source, "generic-inference.bmx")
Local model:TSemanticModel = TBlitzMaxSemanticAnalyzer.Analyze(parsed.syntaxTree)
Check(model.diagnostics.length = 0, "generic inference model diagnostics")

Local identity:TSymbol = model.globalScope.LookupLocal("Identity")[0]
Local identityBinding:TGenericRoutineBinding = TGenericRoutineInference.Infer(identity, [model.BuiltinType("String")])
Check(identityBinding.success And identityBinding.typeArguments[0] = model.BuiltinType("String"), "direct generic argument inference")
Check(identityBinding.returnType = model.BuiltinType("String"), "inferred generic return type")

Local listSymbol:TSymbol = model.globalScope.LookupLocal("TList")[0]
Local stringList:TNamedSemanticType = New TNamedSemanticType
stringList.kind = SEMANTIC_TYPE_NAMED
stringList.symbol = listSymbol
stringList.typeArguments = [model.BuiltinType("String")]
Local firstRoutine:TSymbol = model.globalScope.LookupLocal("First")[0]
Local nestedBinding:TGenericRoutineBinding = TGenericRoutineInference.Infer(firstRoutine, [stringList])
Check(nestedBinding.success And nestedBinding.typeArguments[0] = model.BuiltinType("String"), "nested constructed type inference")

Local choose:TSymbol = model.globalScope.LookupLocal("Choose")[0]
Local conflict:TGenericRoutineBinding = TGenericRoutineInference.Infer(choose, [model.BuiltinType("String"), model.BuiltinType("Int")])
Check(Not conflict.success And conflict.message.length, "conflicting generic inference fails")

Local createRoutine:TSymbol = model.globalScope.LookupLocal("Create")[0]
Local missing:TGenericRoutineBinding = TGenericRoutineInference.Infer(createRoutine, New TSemanticType[0])
Check(Not missing.success, "return-only type parameter is not inferred")
Local explicit:TGenericRoutineBinding = TGenericRoutineInference.Infer(createRoutine, New TSemanticType[0], [model.BuiltinType("String")])
Check(explicit.success And explicit.returnType = model.BuiltinType("String"), "explicit generic type argument binding")

Print "bcc2 generic-routine inference tests passed"
