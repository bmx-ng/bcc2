SuperStrict

Framework BRL.StandardIO

Import BlitzMax.Language

Function Check(condition:Int, message:String)
	If Not condition Then Throw message
End Function

Function FindDiagnostic:Int(diagnostics:TDiagnostic[], code:String)
	For Local diagnostic:TDiagnostic = EachIn diagnostics
		If diagnostic.code = code Then Return True
	Next
	Return False
End Function

Local source:String = "SuperStrict~nInterface IMarker~nEnd Interface~nType TPair<K, V>~nField First:K~nField Second:V~nEnd Type~nType TOuter~nType TInner~nEnd Type~nEnd Type~nType TDerived<T> Extends TPair<T, Int> Implements IMarker~nField items:TPair<String, T>[][]~nField matrix:Int[,,]~nField address:Byte Ptr Ptr~nField arrayAddress:Int Ptr[] Ptr~nField bad:TPair<Int>~nMethod Map:TPair<T, TOuter.TInner>(value%, text$)~nReturn Null~nEnd Method~nEnd Type~nEnum EState:Byte~nReady~nEnd Enum~nGlobal missing:MissingType"
Local parsed:TParseResult = TBlitzMaxParser.ParseText(source, "types.bmx")
Check(parsed.syntaxTree.diagnostics.length = 0, "type-resolution parser diagnostics")

Local options:TTypeResolutionOptions = New TTypeResolutionOptions
options.reportUnresolvedTypes = True
Local model:TSemanticModel = TBlitzMaxSemanticAnalyzer.Analyze(parsed.syntaxTree, options)
Check(model.diagnostics.length = 2, "type-resolution diagnostic count")
Check(FindDiagnostic(model.diagnostics, "BMX3100"), "unresolved type diagnostic")
Check(FindDiagnostic(model.diagnostics, "BMX3102"), "generic arity diagnostic")
Local unresolvedTypeDiagnostic:TDiagnostic
For Local diagnostic:TDiagnostic = EachIn model.diagnostics
	If diagnostic.code = "BMX3100" Then unresolvedTypeDiagnostic = diagnostic; Exit
Next
Check(unresolvedTypeDiagnostic.message.Contains("Type 'MissingType'") And unresolvedTypeDiagnostic.span.start = source.Find("MissingType") And unresolvedTypeDiagnostic.span.length = "MissingType".length, "unresolved named-type diagnostics exclude the declaration marker from their name and span")

Check(model.BuiltinType("int") = model.BuiltinType("INT"), "canonical case-insensitive builtin")
Check(model.BuiltinType("String").DisplayName() = "String", "builtin display name")

Local callableReturnParse:TParseResult = TBlitzMaxParser.ParseText("SuperStrict~nFunction Choose:Int(value:Int Var)(enabled:Int)~nReturn Null~nEnd Function", "callable-return-types.bmx")
Local callableReturnModel:TSemanticModel = TBlitzMaxSemanticAnalyzer.Analyze(callableReturnParse.syntaxTree)
Local chooseSymbol:TSymbol = callableReturnModel.globalScope.LookupLocal("Choose")[0]
Local chooseType:TCallableSemanticType = TCallableSemanticType(chooseSymbol.declaredType)
Check(callableReturnModel.diagnostics.length = 0 And chooseType <> Null And chooseType.DisplayName() = "Int(Int Var)", "routine callable return type resolves structurally")
Check(chooseSymbol.parameters.length = 1 And chooseSymbol.parameters[0].semanticType = callableReturnModel.BuiltinType("Int"), "routine parameters remain separate from callable return parameters")

Local strictCallableParse:TParseResult = TBlitzMaxParser.ParseText("Strict~nExtern~nFunction Decode:Object(readCallback(buffer:Byte Ptr, size:Int, count:Int, source:Object), closeCallback(source:Object))~nEnd Extern", "strict-callable-types.bmx")
Local strictCallableModel:TSemanticModel = TBlitzMaxSemanticAnalyzer.Analyze(strictCallableParse.syntaxTree)
Local decodeSymbol:TSymbol = strictCallableModel.globalScope.LookupLocal("Decode")[0]
Check(strictCallableModel.diagnostics.length = 0 And decodeSymbol.parameterTypes[0].DisplayName() = "Int(Byte Ptr, Int, Int, Object)" And decodeSymbol.parameterTypes[1].DisplayName() = "Int(Object)", "Strict omitted callable returns retain the traditional implicit Int type")

Local superStrictCallableParse:TParseResult = TBlitzMaxParser.ParseText("SuperStrict~nExtern~nFunction Decode:Object(readCallback(buffer:Byte Ptr, size:Int, count:Int, source:Object), closeCallback(source:Object))~nEnd Extern", "superstrict-callable-types.bmx")
Local superStrictCallableModel:TSemanticModel = TBlitzMaxSemanticAnalyzer.Analyze(superStrictCallableParse.syntaxTree)
Local superStrictDecodeSymbol:TSymbol = superStrictCallableModel.globalScope.LookupLocal("Decode")[0]
Check(superStrictCallableModel.diagnostics.length = 0 And superStrictDecodeSymbol.parameterTypes[0].DisplayName() = "(Byte Ptr, Int, Int, Object)" And superStrictDecodeSymbol.parameterTypes[1].DisplayName() = "(Object)", "SuperStrict omitted callable returns remain Void")

Local malformedCallableSource:String = "SuperStrict~nFunction Apply<T>:T(value:T, fn:T(T))~nReturn fn(value)~nEnd Function"
Local malformedCallableParse:TParseResult = TBlitzMaxParser.ParseText(malformedCallableSource, "malformed-callable-parameter.bmx")
Local malformedCallableModel:TSemanticModel = TBlitzMaxSemanticAnalyzer.Analyze(malformedCallableParse.syntaxTree)
Local malformedCallableCount:Int
Local malformedCallableDiagnostic:TDiagnostic
For Local diagnostic:TDiagnostic = EachIn malformedCallableModel.diagnostics
	If diagnostic.code = "BMX3103" Then malformedCallableCount :+ 1; malformedCallableDiagnostic = diagnostic
Next
Local malformedCallableInnerOffset:Int = malformedCallableSource.Find("T(T)") + 2
Check(malformedCallableCount = 1 And malformedCallableDiagnostic.message.Contains("Callable parameter 'T' requires an explicit type"), "SuperStrict reports an omitted thin-callable parameter type at its declaration")
Check(malformedCallableDiagnostic.span.start = malformedCallableInnerOffset And malformedCallableDiagnostic.span.length = 1, "omitted thin-callable parameter diagnostic targets the malformed parameter name")
Local malformedApplySymbol:TSymbol = malformedCallableModel.globalScope.LookupLocal("Apply")[0]
Local malformedApplyType:TCallableSemanticType = TCallableSemanticType(malformedApplySymbol.parameterTypes[1])
Check(TErrorSemanticType(malformedApplyType.parameterTypes[0]) <> Null, "malformed SuperStrict thin-callable parameter uses an error recovery type")

Local strictUntypedCallableParse:TParseResult = TBlitzMaxParser.ParseText("Strict~nFunction Apply:Int(value:Int, fn:Int(arg))~nReturn fn(value)~nEnd Function", "strict-untyped-callable-parameter.bmx")
Local strictUntypedCallableModel:TSemanticModel = TBlitzMaxSemanticAnalyzer.Analyze(strictUntypedCallableParse.syntaxTree)
Check(strictUntypedCallableModel.diagnostics.length = 0, "Strict retains legacy implicit Int parameters inside thin-callable signatures")

Local compoundPrefixTypeParse:TParseResult = TBlitzMaxParser.ParseText("Type Mode~nMethod Create:Mode()~nEnd Method~nEnd Type~nType ShlValue~nEnd Type~nGlobal shifted:ShlValue", "compound-prefix-types.bmx")
Local compoundPrefixTypeModel:TSemanticModel = TBlitzMaxSemanticAnalyzer.Analyze(compoundPrefixTypeParse.syntaxTree, options)
Local modeType:TSymbol = compoundPrefixTypeModel.globalScope.LookupLocal("Mode")[0]
Local createMode:TSymbol = modeType.memberScope.LookupLocal("Create")[0]
Check(compoundPrefixTypeParse.syntaxTree.diagnostics.length = 0 And compoundPrefixTypeModel.diagnostics.length = 0, "type names beginning with alphabetic compound operators parse and resolve")
Check(TNamedSemanticType(createMode.declaredType).symbol = modeType, "Mod prefix remains part of a named return type after a colon")
Check(compoundPrefixTypeModel.globalScope.LookupLocal("shifted")[0].declaredType.DisplayName() = "ShlValue", "Shl prefix remains part of a named Global type after a colon")

Local derivedSymbol:TSymbol = model.globalScope.LookupLocal("tderived")[0]
Local derivedDeclaration:TTypeDeclarationSyntax = TTypeDeclarationSyntax(derivedSymbol.declaration)
Local derivedScope:TScope = model.ScopeFor(derivedDeclaration)
Local baseType:TSemanticType = model.TypeOf(derivedDeclaration.header.extendsTypes[0])
Check(baseType.DisplayName() = "TPair<T, Int>", "constructed generic base type")
Check(TNamedSemanticType(baseType).typeArguments[0] = derivedScope.LookupLocal("T")[0].declaredType, "generic parameter resolution")
Check(model.TypeOf(derivedDeclaration.header.implementedTypes[0]).DisplayName() = "IMarker", "implemented interface resolution")

Local items:TSymbol = derivedScope.LookupLocal("items")[0]
Check(items.declaredType.DisplayName() = "TPair<String, T>[][]", "nested generic array type")
Check(TArraySemanticType(items.declaredType).rank = 1, "outer array rank")
Local matrix:TSymbol = derivedScope.LookupLocal("matrix")[0]
Check(matrix.declaredType.DisplayName() = "Int[,,]", "ranked array type")
Check(TArraySemanticType(matrix.declaredType).rank = 3, "ranked array semantic rank")
Local address:TSymbol = derivedScope.LookupLocal("address")[0]
Check(address.declaredType.DisplayName() = "Byte Ptr Ptr", "nested pointer type")
Check(TPointerSemanticType(TPointerSemanticType(address.declaredType).elementType).elementType = model.BuiltinType("Byte"), "pointer element type")
Local arrayAddress:TSymbol = derivedScope.LookupLocal("arrayAddress")[0]
Check(arrayAddress.declaredType.DisplayName() = "Int Ptr[] Ptr", "interleaved pointer and array suffix order")
Local pointedArray:TArraySemanticType = TArraySemanticType(TPointerSemanticType(arrayAddress.declaredType).elementType)
Check(pointedArray <> Null And TPointerSemanticType(pointedArray.elementType).elementType = model.BuiltinType("Int"), "pointer to array of Int pointers structure")

Local mapSymbol:TSymbol = derivedScope.LookupLocal("map")[0]
Check(mapSymbol.declaredType.DisplayName() = "TPair<T, TOuter.TInner>", "qualified nested return type")
Local mapScope:TScope = model.ScopeFor(mapSymbol.declaration)
Check(mapScope.LookupLocal("value")[0].declaredType = model.BuiltinType("Int"), "percent marker maps to Int")
Check(mapScope.LookupLocal("text")[0].declaredType = model.BuiltinType("String"), "dollar marker maps to String")

Local enumSymbol:TSymbol = model.globalScope.LookupLocal("estate")[0]
Local enumDeclaration:TEnumDeclarationSyntax = TEnumDeclarationSyntax(enumSymbol.declaration)
Check(model.TypeOf(enumDeclaration.underlyingType) = model.BuiltinType("Byte"), "enum underlying type")
Local enumScope:TScope = model.ScopeFor(enumDeclaration)
Check(enumScope.LookupLocal("ready")[0].declaredType = enumSymbol.declaredType, "enum member semantic type")

Local missing:TSymbol = model.globalScope.LookupLocal("missing")[0]
Check(TErrorSemanticType(missing.declaredType) <> Null, "unresolved type preserved as error type")

Local deferredParse:TParseResult = TBlitzMaxParser.ParseText("SuperStrict~nGlobal imported:BRL.Example.TImported", "imported.bmx")
Local deferredModel:TSemanticModel = TBlitzMaxSemanticAnalyzer.Analyze(deferredParse.syntaxTree)
Check(deferredModel.diagnostics.length = 0, "unresolved imported type deferred by default")
Check(TErrorSemanticType(deferredModel.globalScope.LookupLocal("imported")[0].declaredType) <> Null, "deferred imported error type")

Local genericRoutineParse:TParseResult = TBlitzMaxParser.ParseText("SuperStrict~nType TContainer<T>~nMethod Convert<U>:U(value:T, fallback:U) Where U Extends Object~nReturn fallback~nEnd Method~nEnd Type", "generic-routine-types.bmx")
Local genericRoutineModel:TSemanticModel = TBlitzMaxSemanticAnalyzer.Analyze(genericRoutineParse.syntaxTree, options)
Check(genericRoutineModel.diagnostics.length = 0, "generic routine type-resolution diagnostics")
Local containerSymbol:TSymbol = genericRoutineModel.globalScope.LookupLocal("tcontainer")[0]
Local containerScope:TScope = genericRoutineModel.ScopeFor(containerSymbol.declaration)
Local convertSymbol:TSymbol = containerScope.LookupLocal("convert")[0]
Local convertScope:TScope = genericRoutineModel.ScopeFor(convertSymbol.declaration)
Local routineU:TSymbol = convertScope.LookupLocal("U")[0]
Check(convertSymbol.genericArity = 1 And routineU.kind = SYMBOL_TYPE_PARAMETER, "generic method owns type parameter")
Check(convertSymbol.declaredType = routineU.declaredType, "generic method return type resolves to routine parameter")
Check(convertSymbol.parameterTypes[0] = containerScope.LookupLocal("T")[0].declaredType, "generic method sees containing type parameter")
Check(convertSymbol.parameterTypes[1] = routineU.declaredType, "generic method parameter resolves to routine parameter")
Check(convertSymbol.genericConstraints.length = 1 And convertSymbol.genericConstraints[0].parameterSymbol = routineU, "generic method constraint ownership")
Check(convertSymbol.genericConstraints[0].bounds[0] = genericRoutineModel.BuiltinType("Object"), "generic method constraint bound")

Local ambiguousParse:TParseResult = TBlitzMaxParser.ParseText("Type TDup~nEnd Type~nType tdup~nEnd Type~nGlobal conflict:TDup", "ambiguous.bmx")
Local ambiguousModel:TSemanticModel = TBlitzMaxSemanticAnalyzer.Analyze(ambiguousParse.syntaxTree)
Check(ambiguousModel.diagnostics.length = 2, "duplicate and ambiguous type diagnostics")
Check(FindDiagnostic(ambiguousModel.diagnostics, "BMX3000"), "duplicate type declaration diagnostic")
Check(FindDiagnostic(ambiguousModel.diagnostics, "BMX3101"), "ambiguous type reference diagnostic")
Local detailedAmbiguity:Int
For Local diagnostic:TDiagnostic = EachIn ambiguousModel.diagnostics
	If diagnostic.code = "BMX3101" And diagnostic.message.Contains("Candidates:") And diagnostic.message.Contains("ambiguous.bmx") Then detailedAmbiguity = True
Next
Check(detailedAmbiguity, "ambiguous type diagnostic identifies its candidates")
Check(TErrorSemanticType(ambiguousModel.globalScope.LookupLocal("conflict")[0].declaredType) <> Null, "ambiguous reference error type")

Local dump:String = TSemanticDumper.Dump(model)
Check(dump.Contains("Field matrix : Int[,,]"), "semantic dump resolved field type")
Check(dump.Contains("Routine Map : TPair<T, TOuter.TInner>"), "semantic dump resolved return type")

Print "bcc2 type-resolution tests passed"
