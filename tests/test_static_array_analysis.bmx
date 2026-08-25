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

Local source:String = "SuperStrict~nConst FixedSize:Int = 4~nEnum EFixedState:Byte~nIdle = 5~nReady = 9~nEnd Enum~nStruct SPoint~nField x:Int~nEnd Struct~nType THolder~nField StaticArray values:Int[FixedSize], points:SPoint[2]~nEnd Type~nFunction Fill:Int(StaticArray output:Int[4])~nLocal StaticArray scratch:Byte[FixedSize]~noutput[0] = scratch[0]~nReturn output.length~nEnd Function~nLocal StaticArray topLevel:Float[8]~nLocal StaticArray addresses:Byte Ptr[2]~nLocal StaticArray states:EFixedState[2]~nFunction Consume(buffer:Byte Ptr, length:Size_T)~nEnd Function~nStruct SBuffer~nField StaticArray name:Byte[8192]~nMethod Pointer:Byte Ptr()~nReturn Byte Ptr(name)~nEnd Method~nMethod Send()~nConsume(name, 8192)~nEnd Method~nEnd Struct"
Local parsed:TParseResult = TBlitzMaxParser.ParseText(source, "static-arrays.bmx")
Local model:TSemanticModel = TBlitzMaxSemanticAnalyzer.Analyze(parsed.syntaxTree)
TExpressionBinder.Bind(model)
TCompileTimeAnalyzer.Analyze(model)
Check(model.diagnostics.length = 0, "valid StaticArray diagnostics")

Local holder:TSymbol = model.globalScope.LookupLocal("THolder")[0]
Local valuesType:TStaticArraySemanticType = TStaticArraySemanticType(holder.memberScope.LookupLocal("values")[0].declaredType)
Local pointsType:TStaticArraySemanticType = TStaticArraySemanticType(holder.memberScope.LookupLocal("points")[0].declaredType)
Check(valuesType <> Null And valuesType.length = 4 And valuesType.elementType = model.BuiltinType("Int"), "field StaticArray semantic type")
Check(pointsType <> Null And pointsType.length = 2 And TNamedSemanticType(pointsType.elementType).symbol.name = "SPoint", "Struct StaticArray element type")

Local fill:TSymbol = model.globalScope.LookupLocal("Fill")[0]
Local parameterType:TStaticArraySemanticType = TStaticArraySemanticType(fill.parameterTypes[0])
Local scratchType:TStaticArraySemanticType = TStaticArraySemanticType(fill.memberScope.LookupLocal("scratch")[0].declaredType)
Check(parameterType <> Null And parameterType.length = 4, "StaticArray parameter type")
Check(scratchType <> Null And scratchType.length = 4 And scratchType.elementType = model.BuiltinType("Byte"), "local StaticArray type")
Local fillSyntax:TRoutineDeclarationSyntax = TRoutineDeclarationSyntax(fill.declaration)
Local assignment:TAssignmentStatementSyntax = TAssignmentStatementSyntax(fillSyntax.body.statements[1])
Check(model.ResolvedIndex(assignment.left).accessKind = INDEX_ACCESS_STATIC_ARRAY, "StaticArray indexed write")
Check(model.ResolvedIndex(assignment.right).accessKind = INDEX_ACCESS_STATIC_ARRAY, "StaticArray indexed read")
Local lengthReturn:TReturnStatementSyntax = TReturnStatementSyntax(fillSyntax.body.statements[2])
Local lengthMember:TMemberAccessExpressionSyntax = TMemberAccessExpressionSyntax(lengthReturn.expression)
Check(model.ExpressionType(lengthMember) = model.BuiltinType("Int"), "StaticArray length has Int type")
Check(model.ReferencedSymbol(lengthMember).name = "length" And model.ReferencedSymbol(lengthMember).isReadOnly, "StaticArray length resolves to its read-only intrinsic member")
Check(TConstantEvaluator.EvaluateExpressionValue(model, lengthMember).integerValue = 4, "StaticArray length exposes its compile-time extent")
Check(TStaticArraySemanticType(model.globalScope.LookupLocal("topLevel")[0].declaredType).length = 8, "top-level StaticArray")
Check(TPointerSemanticType(TStaticArraySemanticType(model.globalScope.LookupLocal("addresses")[0].declaredType).elementType) <> Null, "Pointer StaticArray element type")
Check(TConversionClassifier.IsEnum(TStaticArraySemanticType(model.globalScope.LookupLocal("states")[0].declaredType).elementType), "Enum StaticArray element type")
Local bufferSymbol:TSymbol = model.globalScope.LookupLocal("SBuffer")[0]
Local pointerMethod:TSymbol = bufferSymbol.memberScope.LookupLocal("Pointer")[0]
Local pointerReturn:TReturnStatementSyntax = TReturnStatementSyntax(TRoutineDeclarationSyntax(pointerMethod.declaration).body.statements[0])
Check(model.ExpressionType(pointerReturn.expression).DisplayName() = "Byte Ptr", "StaticArray explicitly casts to its element pointer type")
Local sendMethod:TSymbol = bufferSymbol.memberScope.LookupLocal("Send")[0]
Local sendCall:TCallExpressionSyntax = TCallExpressionSyntax(TCallStatementSyntax(TRoutineDeclarationSyntax(sendMethod.declaration).body.statements[0]).expression)
Check(model.ResolvedCall(sendCall) <> Null, "StaticArray implicitly decays for a pointer parameter")
Local boundSend:TBoundCallExpression = TBoundCallExpression(model.BoundExpression(sendCall))
Check(TBoundConversionExpression(boundSend.arguments[0]).conversionKind = CONVERSION_ARRAY_TO_POINTER, "bound StaticArray argument records its pointer decay")

Local invalidSource:String = "SuperStrict~nType TObjectElement~nEnd Type~nFunction RuntimeSize:Int()~nReturn 3~nEnd Function~nLocal StaticArray objects:TObjectElement[2]~nLocal StaticArray invalid:Void[2]~nLocal StaticArray dynamic:Int[RuntimeSize()]~nLocal StaticArray empty:Int[0]"
Local invalidParsed:TParseResult = TBlitzMaxParser.ParseText(invalidSource, "invalid-static-arrays.bmx")
Local invalidModel:TSemanticModel = TBlitzMaxSemanticAnalyzer.Analyze(invalidParsed.syntaxTree)
TExpressionBinder.Bind(invalidModel)
TCompileTimeAnalyzer.Analyze(invalidModel)
Check(HasDiagnostic(invalidModel.diagnostics, "BMX3620"), "StaticArray length diagnostic")
Check(HasDiagnostic(invalidModel.diagnostics, "BMX3621"), "StaticArray element type diagnostic")

Print "bcc2 StaticArray analysis tests passed"
