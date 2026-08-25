SuperStrict

Framework BRL.StandardIO

Import BlitzMax.Language

Function Check(condition:Int, message:String)
	If Not condition Then Throw message
End Function

Function HasDiagnostic:Int(diagnostics:TDiagnostic[], code:String)
	For Local diagnostic:TDiagnostic = EachIn diagnostics
		If diagnostic.code = code Then Return True
	Next
	Return False
End Function

Local source:String = "SuperStrict~nConst Limit:Int = 3~nFunction RuntimeValue:Int()~nReturn 2~nEnd Function~nFunction Choose:Int(value:Int, amount:Byte = 255, text:String = ~qx~q, item:Object = Null)~nSelect value~nCase Limit, RuntimeValue()~nReturn amount~nDefault~nReturn 0~nEnd Select~nEnd Function~nLocal values:Int[] = New Int[RuntimeValue()]"
Local parsed:TParseResult = TBlitzMaxParser.ParseText(source, "compile-time.bmx")
Local model:TSemanticModel = TBlitzMaxSemanticAnalyzer.Analyze(parsed.syntaxTree)
TExpressionBinder.Bind(model)
TCompileTimeAnalyzer.Analyze(model)
Check(model.diagnostics.length = 0, "valid compile-time-context diagnostics")

Local choose:TSymbol = model.globalScope.LookupLocal("Choose")[0]
Check(choose.parameters[1].defaultValue.integerValue = 255, "numeric parameter default")
Check(choose.parameters[2].defaultValue.stringValue = "x", "string parameter default")
Check(choose.parameters[3].defaultValue.kind = CONSTANT_VALUE_NULL, "Null parameter default")
Local chooseSyntax:TRoutineDeclarationSyntax = TRoutineDeclarationSyntax(choose.declaration)
Local selectSyntax:TSelectStatementSyntax = TSelectStatementSyntax(chooseSyntax.body.statements[0])
Local boundSelect:TBoundSelectStatement = TBoundSelectStatement(model.BoundStatement(selectSyntax))
Check(boundSelect.cases[0].constantValues[0].integerValue = 3, "constant Select Case annotation")
Check(boundSelect.cases[0].constantValues[1] = Null, "dynamic Select Case remains legal")

Local invalidSource:String = "SuperStrict~nFunction RuntimeValue:Int()~nReturn 1~nEnd Function~nFunction InvalidDefaults(a:Int = RuntimeValue(), b:Byte = 300, c:Int = ~qbad~q)~nEnd Function~nLocal badDimension:Int[] = New Int[~qsize~q]~nSelect 1~nCase ~qone~q~nEnd Select"
Local invalidParsed:TParseResult = TBlitzMaxParser.ParseText(invalidSource, "invalid-compile-time.bmx")
Local invalidModel:TSemanticModel = TBlitzMaxSemanticAnalyzer.Analyze(invalidParsed.syntaxTree)
TExpressionBinder.Bind(invalidModel)
TCompileTimeAnalyzer.Analyze(invalidModel)
Check(HasDiagnostic(invalidModel.diagnostics, "BMX3610"), "nonconstant parameter default diagnostic")
Check(HasDiagnostic(invalidModel.diagnostics, "BMX3611"), "incompatible constant default diagnostic")
Check(HasDiagnostic(invalidModel.diagnostics, "BMX3603"), "parameter default range diagnostic")
Check(HasDiagnostic(invalidModel.diagnostics, "BMX3310"), "Select Case and array dimension conversion diagnostics")

Local enumDefaultSource:String = "SuperStrict~nEnum EFormat~nLATIN1~nUTF8~nEnd Enum~nFunction SaveText(format:EFormat = EFormat.LATIN1)~nEnd Function"
Local enumDefaultParse:TParseResult = TBlitzMaxParser.ParseText(enumDefaultSource, "enum-default.bmx")
Local enumDefaultModel:TSemanticModel = TBlitzMaxSemanticAnalyzer.Analyze(enumDefaultParse.syntaxTree)
TExpressionBinder.Bind(enumDefaultModel)
TCompileTimeAnalyzer.Analyze(enumDefaultModel)
Check(enumDefaultModel.diagnostics.length = 0, "enum member is compatible with enum parameter default")
Local saveText:TSymbol = enumDefaultModel.globalScope.LookupLocal("SaveText")[0]
Check(saveText.parameters[0].defaultValue.semanticType.DisplayName() = "EFormat", "enum parameter default preserves enum type")

Local floatDefaultSource:String = "SuperStrict~nFunction Progress:Int(deltaTime:Float = 0.0)~nReturn True~nEnd Function"
Local floatDefaultParse:TParseResult = TBlitzMaxParser.ParseText(floatDefaultSource, "target-typed-float-default.bmx")
Local floatDefaultModel:TSemanticModel = TBlitzMaxSemanticAnalyzer.Analyze(floatDefaultParse.syntaxTree)
TExpressionBinder.Bind(floatDefaultModel)
TCompileTimeAnalyzer.Analyze(floatDefaultModel)
Check(floatDefaultModel.diagnostics.length = 0, "untyped floating literal leans toward Float parameter default")
Local progress:TSymbol = floatDefaultModel.globalScope.LookupLocal("Progress")[0]
Check(progress.parameters[0].defaultValue.semanticType = floatDefaultModel.BuiltinType("Float"), "floating parameter default retains its target type")

Local pointerDefaultSource:String = "SuperStrict~nFunction ReadPointer:Byte Ptr(value:Byte Ptr = 0)~nReturn value~nEnd Function"
Local pointerDefaultParse:TParseResult = TBlitzMaxParser.ParseText(pointerDefaultSource, "pointer-default.bmx")
Local pointerDefaultModel:TSemanticModel = TBlitzMaxSemanticAnalyzer.Analyze(pointerDefaultParse.syntaxTree)
TExpressionBinder.Bind(pointerDefaultModel)
TCompileTimeAnalyzer.Analyze(pointerDefaultModel)
Check(pointerDefaultModel.diagnostics.length = 0, "zero is accepted as the production compact-interface null pointer default")
Local readPointer:TSymbol = pointerDefaultModel.globalScope.LookupLocal("ReadPointer")[0]
Check(readPointer.parameters[0].defaultValue.integerValue = 0 And TPointerSemanticType(readPointer.parameters[0].defaultValue.semanticType) <> Null, "pointer zero default retains its target pointer type")

Local nullPrimitiveDefaultSource:String = "SuperStrict~nFunction Update(onlyChannel:Int = Null)~nEnd Function"
Local nullPrimitiveDefaultParse:TParseResult = TBlitzMaxParser.ParseText(nullPrimitiveDefaultSource, "null-primitive-default.bmx")
Local nullPrimitiveDefaultModel:TSemanticModel = TBlitzMaxSemanticAnalyzer.Analyze(nullPrimitiveDefaultParse.syntaxTree)
TExpressionBinder.Bind(nullPrimitiveDefaultModel)
TCompileTimeAnalyzer.Analyze(nullPrimitiveDefaultModel)
Check(nullPrimitiveDefaultModel.diagnostics.length = 0, "Null is compatible with a primitive parameter default")
Local updateWithNull:TSymbol = nullPrimitiveDefaultModel.globalScope.LookupLocal("Update")[0]
Check(updateWithNull.parameters[0].defaultValue.kind = CONSTANT_VALUE_NULL, "primitive Null default retains its contextual default representation")

Local callableDefaultSource:String = "SuperStrict~nFunction CompareObjects:Int(left:Object, right:Object)~nReturn 0~nEnd Function~nFunction Sort(compareFunc:Int(left:Object, right:Object) = CompareObjects)~nEnd Function"
Local callableDefaultParse:TParseResult = TBlitzMaxParser.ParseText(callableDefaultSource, "callable-default.bmx")
Local callableDefaultModel:TSemanticModel = TBlitzMaxSemanticAnalyzer.Analyze(callableDefaultParse.syntaxTree)
TExpressionBinder.Bind(callableDefaultModel)
TCompileTimeAnalyzer.Analyze(callableDefaultModel)
Check(callableDefaultModel.diagnostics.length = 0, "static function reference is a valid callable parameter default")
Local sortRoutine:TSymbol = callableDefaultModel.globalScope.LookupLocal("Sort")[0]
Check(sortRoutine.parameters[0].defaultValue.kind = CONSTANT_VALUE_CALLABLE, "callable parameter default is retained as a callable constant")
Check(sortRoutine.parameters[0].defaultValue.callableSymbol.name = "CompareObjects", "callable parameter default retains its target function")

Local callableStaticArraySource:String = "SuperStrict~nConst WIDTH:Int=4~nLocal callback:Int(StaticArray values:Int[WIDTH])"
Local callableStaticArrayParse:TParseResult = TBlitzMaxParser.ParseText(callableStaticArraySource, "callable-static-array-bound.bmx")
Local callableStaticArrayModel:TSemanticModel = TBlitzMaxSemanticAnalyzer.Analyze(callableStaticArrayParse.syntaxTree)
TExpressionBinder.Bind(callableStaticArrayModel)
TCompileTimeAnalyzer.Analyze(callableStaticArrayModel)
Check(callableStaticArrayModel.diagnostics.length = 0, "StaticArray bounds nested in callable types are valid compile-time contexts")
Local callbackSymbol:TSymbol = callableStaticArrayModel.globalScope.LookupLocal("callback")[0]
Local callbackType:TCallableSemanticType = TCallableSemanticType(callbackSymbol.declaredType)
Check(TStaticArraySemanticType(callbackType.parameterTypes[0]).length = 4, "callable parameter retains its evaluated StaticArray extent")

Local referenceStaticArraySource:String = "SuperStrict~nType TCell~nEnd Type~nType THolder~nField StaticArray cells:TCell[8]~nEnd Type"
Local referenceStaticArrayParse:TParseResult = TBlitzMaxParser.ParseText(referenceStaticArraySource, "reference-static-array.bmx")
Local referenceStaticArrayModel:TSemanticModel = TBlitzMaxSemanticAnalyzer.Analyze(referenceStaticArrayParse.syntaxTree)
TExpressionBinder.Bind(referenceStaticArrayModel)
TCompileTimeAnalyzer.Analyze(referenceStaticArrayModel)
Check(referenceStaticArrayModel.diagnostics.length = 0, "StaticArray accepts managed Type references as inline pointer cells")

Local genericStaticArraySource:String = "SuperStrict~nFunction Retain<T>(value:T)~nLocal StaticArray values:T[2]~nvalues[0] = value~nEnd Function"
Local genericStaticArrayParse:TParseResult = TBlitzMaxParser.ParseText(genericStaticArraySource, "generic-static-array.bmx")
Local genericStaticArrayModel:TSemanticModel = TBlitzMaxSemanticAnalyzer.Analyze(genericStaticArrayParse.syntaxTree)
TExpressionBinder.Bind(genericStaticArrayModel)
TCompileTimeAnalyzer.Analyze(genericStaticArrayModel)
Check(genericStaticArrayModel.diagnostics.length = 0, "StaticArray accepts a generic element whose closed ABI is validated during specialization")

Local invalidCallableStaticArraySource:String = "SuperStrict~nGlobal RuntimeWidth:Int = 4~nLocal callback:Int(StaticArray values:Int[RuntimeWidth])"
Local invalidCallableStaticArrayParse:TParseResult = TBlitzMaxParser.ParseText(invalidCallableStaticArraySource, "invalid-callable-static-array-bound.bmx")
Local invalidCallableStaticArrayModel:TSemanticModel = TBlitzMaxSemanticAnalyzer.Analyze(invalidCallableStaticArrayParse.syntaxTree)
TExpressionBinder.Bind(invalidCallableStaticArrayModel)
TCompileTimeAnalyzer.Analyze(invalidCallableStaticArrayModel)
Check(HasDiagnostic(invalidCallableStaticArrayModel.diagnostics, "BMX3620"), "nonconstant StaticArray bounds nested in callable types are rejected")

Local dynamicCallableDefaultSource:String = "SuperStrict~nGlobal CurrentCompare:Int(left:Object, right:Object)~nFunction Sort(compareFunc:Int(left:Object, right:Object) = CurrentCompare)~nEnd Function"
Local dynamicCallableDefaultParse:TParseResult = TBlitzMaxParser.ParseText(dynamicCallableDefaultSource, "dynamic-callable-default.bmx")
Local dynamicCallableDefaultModel:TSemanticModel = TBlitzMaxSemanticAnalyzer.Analyze(dynamicCallableDefaultParse.syntaxTree)
TExpressionBinder.Bind(dynamicCallableDefaultModel)
TCompileTimeAnalyzer.Analyze(dynamicCallableDefaultModel)
Check(HasDiagnostic(dynamicCallableDefaultModel.diagnostics, "BMX3610"), "dynamic callable value is not a constant parameter default")

Local unsignedRadixSource:String = "SuperStrict~nConst SIGNBIT_64:ULong = $8000000000000000:ULong~nConst MAX_64:ULong = $ffffffffffffffff:ULong"
Local unsignedRadixParse:TParseResult = TBlitzMaxParser.ParseText(unsignedRadixSource, "unsigned-radix-constants.bmx")
Local unsignedRadixModel:TSemanticModel = TBlitzMaxSemanticAnalyzer.Analyze(unsignedRadixParse.syntaxTree)
TExpressionBinder.Bind(unsignedRadixModel)
TCompileTimeAnalyzer.Analyze(unsignedRadixModel)
Check(unsignedRadixModel.diagnostics.length = 0, "typed ULong radix literals are constant initializers across the full 64-bit range")
Local signBitValue:TConstantValue = unsignedRadixModel.SymbolConstantValue(unsignedRadixModel.globalScope.LookupLocal("SIGNBIT_64")[0])
Check(signBitValue <> Null, "ULong sign-bit constant is evaluated")
Check(signBitValue.DisplayValue() = "9223372036854775808", "ULong sign-bit constant is displayed as an unsigned value")

Local castConstantSource:String = "SuperStrict~nConst LONG_MAX:Long = (Long(1) Shl 63) - 1~nConst LONG_MIN:Long = -(Long(1) Shl 63)~nConst UL64_MAX:ULong = ULong(-1)"
Local castConstantParse:TParseResult = TBlitzMaxParser.ParseText(castConstantSource, "named-cast-constants.bmx")
Local castConstantModel:TSemanticModel = TBlitzMaxSemanticAnalyzer.Analyze(castConstantParse.syntaxTree)
TExpressionBinder.Bind(castConstantModel)
TCompileTimeAnalyzer.Analyze(castConstantModel)
Check(castConstantModel.diagnostics.length = 0, "named numeric casts and shifted Long expressions are constant initializers")
Check(castConstantModel.SymbolConstantValue(castConstantModel.globalScope.LookupLocal("LONG_MAX")[0]).DisplayValue() = "9223372036854775807", "Long maximum constant value")
Check(castConstantModel.SymbolConstantValue(castConstantModel.globalScope.LookupLocal("LONG_MIN")[0]).DisplayValue() = "-9223372036854775808", "Long minimum constant value")
Check(castConstantModel.SymbolConstantValue(castConstantModel.globalScope.LookupLocal("UL64_MAX")[0]).DisplayValue() = "18446744073709551615", "ULong maximum cast constant value")

Print "bcc2 compile-time analysis tests passed"
