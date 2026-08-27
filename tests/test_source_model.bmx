SuperStrict

Framework BRL.StandardIO

Import BlitzMax.Language

Function Check(condition:Int, message:String)
	If Not condition Then Throw message
End Function

Local source:TSourceText = TSourceText.Create("one~ntwo~nthree", "sample.bmx")

Check(source.Length() = 13, "source length")
Check(source.LineCount() = 3, "line count")
Check(source.Position(0).ToString() = "1:1", "first position")
Check(source.Position(4).ToString() = "2:1", "second line")
Check(source.Position(source.Length()).ToString() = "3:6", "EOF position")
Check(source.Slice(TSourceSpan.Create(4, 3)) = "two", "span slicing")

Local diagnostic:TDiagnostic = TDiagnostic.Create("BMX0001", "example", DIAGNOSTIC_ERROR, TSourceSpan.Create(4, 3))
Check(diagnostic.Format(source) = "sample.bmx:2:1: error BMX0001: example", "diagnostic formatting")
Local foreignDiagnostic:TDiagnostic = TDiagnostic.Create("BMX0002", "foreign", DIAGNOSTIC_ERROR, TSourceSpan.Create(4, 1), "dependency.bmx")
Check(foreignDiagnostic.Format(source) = "dependency.bmx: error BMX0002: foreign", "diagnostic formatting retains a foreign path without inventing a position from unrelated source text")

Local result:TParseResult = TBlitzMaxParser.ParseText("Print ~qHello~q", "hello.bmx")
Check(result.syntaxTree <> Null, "parse tree")
Check(result.syntaxTree.source.path = "hello.bmx", "parse source path")
Check(result.syntaxTree.root.endOfFileToken.span.start = 13, "EOF span")
Check(result.syntaxTree.diagnostics.length = 0, "empty parser bootstrap diagnostics")
Check(result.syntaxTree.root.sourceMode = SOURCE_MODE_STRICT And result.syntaxTree.root.sourceModeDeclaration = Null, "implicit Strict source mode")

Local nativeParamSizeParse:TParseResult = TBlitzMaxParser.ParseText("SuperStrict~nLocal lp:Size_T=SizeOf LParam Null~nLocal wp:Size_T=SizeOf WParam Null", "native-param-sizeof.bmx")
Check(nativeParamSizeParse.syntaxTree.diagnostics.length = 0, "LParam and WParam are valid SizeOf type operands")

Local reservedVariableParse:TParseResult = TBlitzMaxParser.ParseText("SuperStrict~nLocal step:Int~nstep :+ 1", "reserved-variable.bmx")
Check(reservedVariableParse.syntaxTree.diagnostics.length > 0 And reservedVariableParse.syntaxTree.diagnostics[0].code = "BMX2004", "reserved keyword is rejected at its variable declaration")
Local reservedGlobalParse:TParseResult = TBlitzMaxParser.ParseText("SuperStrict~nGlobal step:Int~nstep :+ 1", "reserved-global.bmx")
Check(reservedGlobalParse.syntaxTree.diagnostics.length > 0 And reservedGlobalParse.syntaxTree.diagnostics[0].code = "BMX2004", "statement-ambiguous Step keyword is rejected as a Global name")

Local inferredLocalParse:TParseResult = TBlitzMaxParser.ParseText("SuperStrict~nLocal textBox := New TBox<String>(~qhello~q)", "inferred-local-syntax.bmx")
Local inferredLocalStatement:TVariableDeclarationStatementSyntax = TVariableDeclarationStatementSyntax(inferredLocalParse.syntaxTree.root.members[1])
Local inferredLocalDeclarator:TVariableDeclaratorSyntax = inferredLocalStatement.declarators[0]
Check(inferredLocalParse.syntaxTree.diagnostics.length = 0 And inferredLocalDeclarator.inferenceToken <> Null, "Local inference syntax parses without treating ':=' as a type")
Check(inferredLocalDeclarator.typeTokens.length = 0 And inferredLocalDeclarator.declaredType = Null And inferredLocalDeclarator.initializer <> Null, "inferred Local syntax retains an explicit inference marker and initializer")

Local invalidInferenceDeclarations:TParseResult = TBlitzMaxParser.ParseText("SuperStrict~nGlobal value := 1~nField member := 2~nConst fixed := 3~nThreadedGlobal threaded := 4", "invalid-inference-declarations.bmx")
Check(invalidInferenceDeclarations.syntaxTree.diagnostics.length = 4 And invalidInferenceDeclarations.syntaxTree.diagnostics[0].code = "BMX2050", "non-Local declarations reject inference syntax")
Local mixedInferenceParse:TParseResult = TBlitzMaxParser.ParseText("SuperStrict~nLocal first := 1, second:Int = 2", "mixed-inference-declaration.bmx")
Check(mixedInferenceParse.syntaxTree.diagnostics.length = 1 And mixedInferenceParse.syntaxTree.diagnostics[0].code = "BMX2051", "inferred Local syntax rejects multiple and mixed declarators")
Local missingInferenceParse:TParseResult = TBlitzMaxParser.ParseText("SuperStrict~nLocal value :=", "missing-inference-initializer.bmx")
Check(missingInferenceParse.syntaxTree.diagnostics.length = 1 And missingInferenceParse.syntaxTree.diagnostics[0].code = "BMX2052", "incomplete inferred Local syntax reports a focused missing-initializer diagnostic")
Local directInferenceAssignmentParse:TParseResult = TBlitzMaxParser.ParseText("SuperStrict~nLocal value:Int~nvalue := 1~nIf True Then value := 2", "direct-inference-assignment.bmx")
Check(directInferenceAssignmentParse.syntaxTree.diagnostics.length = 2 And directInferenceAssignmentParse.syntaxTree.diagnostics[0].code = "BMX2053", "direct existing-value ':=' is rejected for ordinary and inline assignments")
Local contextualFieldParse:TParseResult = TBlitzMaxParser.ParseText("SuperStrict~nType TApi~nField Object:ULong~nEnd Type~nLocal api:TApi~napi.Object = 1", "contextual-field.bmx")
Check(contextualFieldParse.syntaxTree.diagnostics.length = 0, "native API Fields retain contextual keyword names")

Local castAssignmentParse:TParseResult = TBlitzMaxParser.ParseText("SuperStrict~nLocal p:Byte Ptr~n(Byte Ptr p)[0]=Byte Null~nIf p Then (Byte Ptr p)[0]=1 Else (Byte Ptr p)[0]=Byte Null", "cast-target-assignment.bmx")
Check(castAssignmentParse.syntaxTree.diagnostics.length = 0 And TAssignmentStatementSyntax(castAssignmentParse.syntaxTree.root.members[2]) <> Null, "parenthesized cast/index targets parse as assignments")
Local castAssignmentIf:TIfStatementSyntax = TIfStatementSyntax(castAssignmentParse.syntaxTree.root.members[3])
Check(castAssignmentIf And TAssignmentStatementSyntax(castAssignmentIf.thenBlock.statements[0]) And TAssignmentStatementSyntax(castAssignmentIf.elseClause.block.statements[0]), "inline If retains parenthesized cast/index assignments in both branches")
Local builtinCastAssignmentParse:TParseResult = TBlitzMaxParser.ParseText("SuperStrict~nStruct SPacked~nField b:Byte~nMethod Set(value:Int)~nInt Ptr(Varptr b)[0]=value~nEnd Method~nEnd Struct", "builtin-cast-target-assignment.bmx")
Local builtinCastAssignmentType:TTypeDeclarationSyntax = TTypeDeclarationSyntax(builtinCastAssignmentParse.syntaxTree.root.members[1])
Local builtinCastAssignmentMethod:TRoutineDeclarationSyntax
If builtinCastAssignmentType Then builtinCastAssignmentMethod = TRoutineDeclarationSyntax(builtinCastAssignmentType.body.statements[1])
Check(builtinCastAssignmentParse.syntaxTree.diagnostics.length = 0 And builtinCastAssignmentMethod And TAssignmentStatementSyntax(builtinCastAssignmentMethod.body.statements[0]), "a builtin pointer-cast/index target may begin an assignment without redundant outer parentheses")

Local modeResult:TParseResult = TBlitzMaxParser.ParseText("SuperStrict~nPrint ~qtyped~q", "mode.bmx")
Check(modeResult.syntaxTree.root.sourceMode = SOURCE_MODE_SUPERSTRICT, "explicit SuperStrict source mode")
Check(modeResult.syntaxTree.root.sourceModeDeclaration.modeToken.text = "SuperStrict", "source mode declaration syntax")

Local dependencySource:String = "Framework brl.standardio~nImport brl.filesystem~nImport ~qhelper.bmx~q~nImport ~qglue.c~q~nInclude ~qparts/shared.bmx~q"
Local dependencyResult:TParseResult = TBlitzMaxParser.ParseText(dependencySource, "dependencies.bmx")
Check(dependencyResult.syntaxTree.diagnostics.length = 0, "dependency directive diagnostics")
Check(dependencyResult.syntaxTree.root.members.length = 5, "dependency directive count")
Local frameworkDirective:TImportDirectiveSyntax = TImportDirectiveSyntax(dependencyResult.syntaxTree.root.members[0])
Check(frameworkDirective <> Null And frameworkDirective.isFramework, "Framework directive syntax")
Check(frameworkDirective.targetText = "brl.standardio" And Not frameworkDirective.isFileImport, "Framework module target")
Local moduleDirective:TImportDirectiveSyntax = TImportDirectiveSyntax(dependencyResult.syntaxTree.root.members[1])
Check(moduleDirective <> Null And moduleDirective.targetText = "brl.filesystem", "Import module target")
Local fileDirective:TImportDirectiveSyntax = TImportDirectiveSyntax(dependencyResult.syntaxTree.root.members[2])
Check(fileDirective <> Null And fileDirective.isSourceImport And fileDirective.targetText = "helper.bmx", "Import source target")
Local nativeDirective:TImportDirectiveSyntax = TImportDirectiveSyntax(dependencyResult.syntaxTree.root.members[3])
Check(nativeDirective <> Null And nativeDirective.isNativeImport And nativeDirective.targetText = "glue.c", "Import native target")
Local includeDirective:TIncludeDirectiveSyntax = TIncludeDirectiveSyntax(dependencyResult.syntaxTree.root.members[4])
Check(includeDirective <> Null And includeDirective.pathText = "parts/shared.bmx", "Include source target")

Local missingDependencyTarget:TParseResult = TBlitzMaxParser.ParseText("Include missing.bmx", "bad-include.bmx")
Check(missingDependencyTarget.syntaxTree.diagnostics.length = 1 And missingDependencyTarget.syntaxTree.diagnostics[0].code = "BMX2442", "Include requires quoted path")

Local sample:String = "Rem~n ignored ~nEnd Rem~nPrint ~qHello~q ' comment~nEnd Method~n"
Local lexed:TLexResult = TBlitzMaxLexer.Lex(sample, "tokens.bmx")
Check(lexed.ReconstructSource() = sample, "lossless token reconstruction")
Check(lexed.diagnostics.length = 0, "valid source lexical diagnostics")
Check(lexed.tokens[0].kind = TOKEN_NEWLINE, "Rem comment is leading trivia")
Check(lexed.tokens[0].leadingTrivia.length = 1, "Rem comment trivia count")
Check(lexed.tokens[0].leadingTrivia[0].kind = TRIVIA_BLOCK_COMMENT, "Rem comment trivia kind")

Local tripleQuote:String = Chr(34) + Chr(34) + Chr(34)
Local special:String = "?bmxng~n'! int value;~n" + tripleQuote + "multi~nline" + tripleQuote + "~n' @bmk option~n"
Local specialLexed:TLexResult = TBlitzMaxLexer.Lex(special, "special.bmx")
Check(specialLexed.ReconstructSource() = special, "special token reconstruction")
Check(specialLexed.tokens[0].kind = TOKEN_DIRECTIVE, "conditional directive")
Check(specialLexed.tokens[2].kind = TOKEN_NATIVE_LINE, "native line")
Check(specialLexed.tokens[4].kind = TOKEN_MULTILINE_STRING_LITERAL, "multiline string")
Check(specialLexed.tokens[6].kind = TOKEN_PRAGMA, "bmk pragma")

Local escapePrefix:String = Chr(126)
Local documentedEscapes:String = Chr(34) + escapePrefix + "0" + escapePrefix + "t" + escapePrefix + "r" + escapePrefix + "n" + escapePrefix + "q" + escapePrefix + escapePrefix + escapePrefix + "65" + escapePrefix + escapePrefix + "$41" + escapePrefix + escapePrefix + "%1000001" + escapePrefix + Chr(34)
Local documentedEscapeLexed:TLexResult = TBlitzMaxLexer.Lex(documentedEscapes, "documented-escapes.bmx")
Check(documentedEscapeLexed.diagnostics.length = 0 And documentedEscapeLexed.ReconstructSource() = documentedEscapes, "documented String escapes lex without losing source text")
Local invalidEscape:TLexResult = TBlitzMaxLexer.Lex(Chr(34) + escapePrefix + "x" + Chr(34), "invalid-escape.bmx")
Check(invalidEscape.diagnostics.length = 1 And invalidEscape.diagnostics[0].code = "BMX1004", "unknown String escape is rejected")
Local unterminatedNumericEscape:TLexResult = TBlitzMaxLexer.Lex(Chr(34) + escapePrefix + "65" + Chr(34), "unterminated-numeric-escape.bmx")
Check(unterminatedNumericEscape.diagnostics.length = 1 And unterminatedNumericEscape.diagnostics[0].code = "BMX1004", "numeric String escape requires a closing tilde")
Local invalidHexEscape:TLexResult = TBlitzMaxLexer.Lex(Chr(34) + escapePrefix + "$G" + escapePrefix + Chr(34), "invalid-hex-escape.bmx")
Check(invalidHexEscape.diagnostics.length = 1 And invalidHexEscape.diagnostics[0].code = "BMX1004", "hexadecimal String escape rejects a non-hexadecimal digit")
Local invalidBinaryEscape:TLexResult = TBlitzMaxLexer.Lex(Chr(34) + escapePrefix + "%2" + escapePrefix + Chr(34), "invalid-binary-escape.bmx")
Check(invalidBinaryEscape.diagnostics.length = 1 And invalidBinaryEscape.diagnostics[0].code = "BMX1004", "binary String escape rejects a non-binary digit")

Local crlf:String = "Local value:Int = $ff + %10~r~n' trailing"
Local crlfLexed:TLexResult = TBlitzMaxLexer.Lex(crlf, "crlf.bmx")
Check(crlfLexed.ReconstructSource() = crlf, "CRLF and EOF trivia reconstruction")
Check(crlfLexed.tokens[crlfLexed.tokens.length - 1].leadingTrivia.length = 1, "EOF owns trailing comment")

Local finalNumericSource:String = "Print 10"
Local finalNumericLexed:TLexResult = TBlitzMaxLexer.Lex(finalNumericSource, "final-numeric.bmx")
Check(finalNumericLexed.ReconstructSource() = finalNumericSource, "numeric token at EOF reconstructs without a trailing newline")
Check(finalNumericLexed.tokens[finalNumericLexed.tokens.length - 2].kind = TOKEN_INTEGER_LITERAL And finalNumericLexed.tokens[finalNumericLexed.tokens.length - 2].text = "10", "numeric token retains its final digit at EOF")
Local finalNumericParse:TParseResult = TBlitzMaxParser.ParseText(finalNumericSource, "final-numeric.bmx")
Check(finalNumericParse.syntaxTree.diagnostics.length = 0, "call argument ending at EOF parses without recovery diagnostics")

Local malformed:TLexResult = TBlitzMaxLexer.Lex("Print ~qunclosed", "bad.bmx")
Check(malformed.ReconstructSource() = "Print ~qunclosed", "malformed source reconstruction")
Check(malformed.diagnostics.length = 1, "unterminated string diagnostic")
Check(malformed.diagnostics[0].code = "BMX1000", "unterminated string diagnostic code")

Local invalidComparisonAliases:TParseResult = TBlitzMaxParser.ParseText("SuperStrict~nLocal low:Int = 1 =< 2~nLocal high:Int = 2 => 1", "invalid-comparison-aliases.bmx")
Check(invalidComparisonAliases.syntaxTree.diagnostics.length > 0, "=< and => remain invalid syntax rather than comparison aliases")

Local routineSource:String = "Function Main()~nPrint ~qHello~q~nEnd~nEnd Function~n"
Local routineResult:TParseResult = TBlitzMaxParser.ParseText(routineSource, "routine.bmx")
Check(routineResult.syntaxTree.diagnostics.length = 0, "routine parser diagnostics")
Check(routineResult.syntaxTree.root.members.length = 1, "routine member count")
Local routine:TRoutineDeclarationSyntax = TRoutineDeclarationSyntax(routineResult.syntaxTree.root.members[0])
Check(routine <> Null, "routine declaration node")
Check(routine.nameToken.text = "Main", "routine name")
Check(routine.body.statements.length = 2, "routine body statement count")
Local printCall:TCallStatementSyntax = TCallStatementSyntax(routine.body.statements[0])
Check(printCall <> Null And Not printCall.hasParentheses, "statement-position call without parentheses")
Check(TEndStatementSyntax(routine.body.statements[1]) <> Null, "bare executable End")

Local callableReturnResult:TParseResult = TBlitzMaxParser.ParseText("Function Choose:Int(value:Int Var)(enabled:Int)~nReturn Null~nEnd Function", "callable-return.bmx")
Check(callableReturnResult.syntaxTree.diagnostics.length = 0, "callable-return routine parser diagnostics")
Local callableReturnRoutine:TRoutineDeclarationSyntax = TRoutineDeclarationSyntax(callableReturnResult.syntaxTree.root.members[0])
Check(callableReturnRoutine.signature.callableReturnType <> Null And callableReturnRoutine.signature.returnType = Null, "routine signature distinguishes a callable return type")
Check(callableReturnRoutine.signature.callableReturnType.parameters.length = 1 And callableReturnRoutine.signature.callableReturnType.parameters[0].varToken <> Null, "callable return signature retains nested Var modes")
Check(callableReturnRoutine.signature.parameters.length = 1 And callableReturnRoutine.signature.parameters[0].nameToken.text = "enabled", "routine parameters follow the callable return signature")
Check(routine.terminator.actualBlockKind = "function", "spaced function terminator")

Local compactResult:TParseResult = TBlitzMaxParser.ParseText("Function Compact();End;EndFunction", "compact.bmx")
Local compact:TRoutineDeclarationSyntax = TRoutineDeclarationSyntax(compactResult.syntaxTree.root.members[0])
Check(compactResult.syntaxTree.diagnostics.length = 0, "compact routine diagnostics")
Check(compact.body.statements.length = 1 And TEndStatementSyntax(compact.body.statements[0]) <> Null, "semicolon bare End")
Check(compact.terminator.actualBlockKind = "function", "combined function terminator")

Local typeSource:String = "Type TThing~nMethod Run()~nPrint()~nEnd Method~nEnd Type~n"
Local typeResult:TParseResult = TBlitzMaxParser.ParseText(typeSource, "type.bmx")
Check(typeResult.syntaxTree.diagnostics.length = 0, "type parser diagnostics")
Local typeDecl:TTypeDeclarationSyntax = TTypeDeclarationSyntax(typeResult.syntaxTree.root.members[0])
Check(typeDecl <> Null And typeDecl.body.statements.length = 1, "type declaration body")
Local methodDecl:TRoutineDeclarationSyntax = TRoutineDeclarationSyntax(typeDecl.body.statements[0])
Check(methodDecl <> Null And methodDecl.isMethod, "nested method declaration")
Local parenCall:TCallStatementSyntax = TCallStatementSyntax(methodDecl.body.statements[0])
Check(parenCall <> Null And parenCall.hasParentheses, "parenthesized call statement")

Local abstractResult:TParseResult = TBlitzMaxParser.ParseText("Type TBase~nMethod Run:Int() Abstract~nEnd Type", "abstract.bmx")
Check(abstractResult.syntaxTree.diagnostics.length = 0, "abstract routine diagnostics")
Local abstractType:TTypeDeclarationSyntax = TTypeDeclarationSyntax(abstractResult.syntaxTree.root.members[0])
Local abstractMethod:TRoutineDeclarationSyntax = TRoutineDeclarationSyntax(abstractType.body.statements[0])
Check(abstractMethod.body.statements.length = 0 And abstractMethod.terminator = Null, "bodyless abstract routine")

Local interfaceResult:TParseResult = TBlitzMaxParser.ParseText("Interface IValue~nMethod Get:Int()~nEnd Interface", "interface.bmx")
Check(interfaceResult.syntaxTree.diagnostics.length = 0, "interface method diagnostics")
Local interfaceType:TTypeDeclarationSyntax = TTypeDeclarationSyntax(interfaceResult.syntaxTree.root.members[0])
Local interfaceMethod:TRoutineDeclarationSyntax = TRoutineDeclarationSyntax(interfaceType.body.statements[0])
Check(interfaceMethod.body.statements.length = 0 And interfaceMethod.terminator = Null, "implicitly bodyless interface method")

Local externalResult:TParseResult = TBlitzMaxParser.ParseText("Function NativeCall:Int(value:Int)=~qint native_call(int)~q", "external.bmx")
Check(externalResult.syntaxTree.diagnostics.length = 0, "external routine binding diagnostics")
Local externalRoutine:TRoutineDeclarationSyntax = TRoutineDeclarationSyntax(externalResult.syntaxTree.root.members[0])
Check(externalRoutine.body.statements.length = 0 And externalRoutine.terminator = Null, "bodyless external routine binding")
Check(externalRoutine.signature.modifierTokens[0].text = "=", "external binding signature tail")

Local externBlockResult:TParseResult = TBlitzMaxParser.ParseText("Extern ~qC~q~nFunction NativeOne:Int(value:Int)~nFunction NativeTwo(value:String)~nEnd Extern", "extern-block.bmx")
Check(externBlockResult.syntaxTree.diagnostics.length = 0, "Extern block diagnostics")
Local externBlock:TExternBlockSyntax = TExternBlockSyntax(externBlockResult.syntaxTree.root.members[0])
Check(externBlock <> Null And externBlock.headerTokens.length = 1, "structured Extern block")
Check(externBlock.callingConventionToken <> Null And externBlock.callingConventionToken.text = "~qC~q", "Extern retains its calling-convention token")
Check(externBlock.body.statements.length = 2 And TRoutineDeclarationSyntax(externBlock.body.statements[0]).body.statements.length = 0, "Extern routines are bodyless")
Check(externBlock.terminator.actualBlockKind = "extern", "Extern block terminator")

Local callableConventionResult:TParseResult = TBlitzMaxParser.ParseText("SuperStrict~nGlobal callback:Int(value:Int) ~qWin32~q", "callable-convention.bmx")
Local callableConventionDeclaration:TVariableDeclarationStatementSyntax = TVariableDeclarationStatementSyntax(callableConventionResult.syntaxTree.root.members[1])
Local callableConventionType:TCallableTypeSyntax
If callableConventionDeclaration Then callableConventionType = callableConventionDeclaration.declarators[0].callableType
Check(callableConventionResult.syntaxTree.diagnostics.length = 0 And callableConventionType <> Null And callableConventionType.callingConventionToken <> Null And callableConventionType.callingConventionToken.text = "~qWin32~q", "callable values retain their trailing calling-convention token")

Local conditionalExternSource:String = "?win32~nExtern ~qwin32~q~n?linux~nExtern~n?~nFunction NativeOne:Int(value:Int)~nEnd Extern"
Local conditionalExternResult:TParseResult = TBlitzMaxParser.ParseText(conditionalExternSource, "conditional-extern.bmx")
Check(conditionalExternResult.syntaxTree.diagnostics.length = 0, "conditional Extern header diagnostics")
Local conditionalExtern:TConditionalRegionSyntax = TConditionalRegionSyntax(conditionalExternResult.syntaxTree.root.members[0])
Check(TExternBlockSyntax(conditionalExtern.branches[0].body.statements[0]) <> Null, "conditional Extern header syntax")
Local conditionalWin32Extern:TExternBlockSyntax = TExternBlockSyntax(conditionalExtern.branches[0].body.statements[0])
Local conditionalLinuxExtern:TExternBlockSyntax = TExternBlockSyntax(conditionalExtern.branches[1].body.statements[0])
Check(conditionalExternResult.syntaxTree.root.members.length = 1 And conditionalWin32Extern.body.statements.length = 1 And TRoutineDeclarationSyntax(conditionalWin32Extern.body.statements[0]) <> Null, "shared conditional Extern body is attached to each header")
Check(conditionalWin32Extern.body = conditionalLinuxExtern.body And conditionalWin32Extern.terminator = conditionalLinuxExtern.terminator And conditionalWin32Extern.terminator.actualBlockKind = "extern", "shared conditional Extern terminator is owned by each header")

Local guardedConditionalRoutineSource:String = "?win32~nExtern ~qwin32~q~nFunction Native:Int()~n?win32 and ptr64~nFunction NextHook:Long()~n?win32 and ptr32~nFunction NextHook:Int()~n?win32~nEnd Extern~n?win32 and ptr64~nFunction Hook:Long()~n?win32 and ptr32~nFunction Hook:Int()~n?win32~nReturn 1~nEnd Function~n?"
Local guardedConditionalRoutineResult:TParseResult = TBlitzMaxParser.ParseText(guardedConditionalRoutineSource, "guarded-conditional-routine.bmx")
Check(guardedConditionalRoutineResult.syntaxTree.diagnostics.length = 0, "guarded shared conditional Extern and routine tails parse")

Local configuredExpressionSource:String = "Local value:Int = 1 + ..~n?debug~n2~n?Not debug~n3~n?~n"
Local configuredDebugExpression:TParseResult = TBlitzMaxParser.ParseConfiguredText(configuredExpressionSource, "configured-expression.bmx", ["debug"])
Check(configuredDebugExpression.syntaxTree.diagnostics.length = 0, "configured conditional selection may occur inside a continued expression")
Local configuredExpression:TVariableDeclarationStatementSyntax = TVariableDeclarationStatementSyntax(configuredDebugExpression.syntaxTree.root.members[0])
Check(TLiteralExpressionSyntax(TBinaryExpressionSyntax(configuredExpression.declarators[0].initializer).right).literalToken.text = "2", "configured expression retains the active line")
Local configuredReleaseExpression:TParseResult = TBlitzMaxParser.ParseConfiguredText(configuredExpressionSource, "configured-expression.bmx", New String[0])
Check(configuredReleaseExpression.syntaxTree.diagnostics.length = 0 And TLiteralExpressionSyntax(TBinaryExpressionSyntax(TVariableDeclarationStatementSyntax(configuredReleaseExpression.syntaxTree.root.members[0]).declarators[0].initializer).right).literalToken.text = "3", "configured expression selects the alternative line")

Local configuredCatchSource:String = "Try~nThrow Null~n?debug~nCatch problem:Object~n?Not debug~nCatch problem:String~n?~nPrint problem~nEnd Try"
Local configuredCatchResult:TParseResult = TBlitzMaxParser.ParseConfiguredText(configuredCatchSource, "configured-catch.bmx", ["debug"])
Local configuredTry:TTryStatementSyntax = TTryStatementSyntax(configuredCatchResult.syntaxTree.root.members[0])
Check(configuredCatchResult.syntaxTree.diagnostics.length = 0 And configuredTry.catches.length = 1 And configuredTry.catches[0].declaredType.nameTokens[0].text = "Object", "configured selection may choose a Catch header")

Local configuredUsingSource:String = "Using~n?debug~nLocal resource:Object = Null~n?Not debug~nLocal resource:String = Null~n?~nDo~nPrint resource~nEnd Using"
Local configuredUsingResult:TParseResult = TBlitzMaxParser.ParseConfiguredText(configuredUsingSource, "configured-using.bmx", ["debug"])
Local configuredUsing:TUsingStatementSyntax = TUsingStatementSyntax(configuredUsingResult.syntaxTree.root.members[0])
Check(configuredUsingResult.syntaxTree.diagnostics.length = 0 And configuredUsing.resources.length = 1 And configuredUsing.resources[0].declarators[0].declaredType.nameTokens[0].text = "Object", "configured selection may choose a Using resource declaration")

Local configuredTypeSource:String = "?bmxng~nStruct TSelected~n?Not bmxng~nType TSelected~n?~nField value:Int~n?bmxng~nEnd Struct~n?Not bmxng~nEnd Type~n?"
Local configuredTypeResult:TParseResult = TBlitzMaxParser.ParseConfiguredText(configuredTypeSource, "configured-type.bmx", ["bmxng"])
Local configuredType:TTypeDeclarationSyntax = TTypeDeclarationSyntax(configuredTypeResult.syntaxTree.root.members[0])
Check(configuredTypeResult.syntaxTree.diagnostics.length = 0 And configuredType.declarationToken.text.ToLower() = "struct" And configuredType.terminator.actualBlockKind = "struct", "configured selection may choose matching Type or Struct headers and terminators")

Local configuredInvalidSource:String = "?debug~nLocal value:Int = 1 +~n?Not debug~nLocal value:Int = 1~n?"
Check(TBlitzMaxParser.ParseConfiguredText(configuredInvalidSource, "configured-invalid.bmx", New String[0]).syntaxTree.diagnostics.length = 0, "inactive invalid grammar does not diagnose")
Check(TBlitzMaxParser.ParseConfiguredText(configuredInvalidSource, "configured-invalid.bmx", ["debug"]).syntaxTree.diagnostics.length > 0, "the same invalid grammar diagnoses when active")

Local conditionalSource:String = "?ptr32~nFunction Width:Int()~nReturn 32~nEnd Function~n?ptr64~nFunction Width:Int()~nReturn 64~nEnd Function~n?~nPrint Width()"
Local conditionalResult:TParseResult = TBlitzMaxParser.ParseText(conditionalSource, "conditional.bmx")
Check(conditionalResult.syntaxTree.diagnostics.length = 0, "conditional region diagnostics")
Local conditional:TConditionalRegionSyntax = TConditionalRegionSyntax(conditionalResult.syntaxTree.root.members[0])
Check(conditional <> Null And conditional.branches.length = 2, "conditional region branches")
Check(conditional.branches[0].conditionText = "ptr32", "first conditional branch text")
Check(conditional.branches[1].conditionText = "ptr64", "second conditional branch text")
Check(TRoutineDeclarationSyntax(conditional.branches[0].body.statements[0]) <> Null, "declaration inside conditional branch")
Check(conditional.endDirectiveToken.text = "?", "conditional closing directive")
Check(TCallStatementSyntax(conditionalResult.syntaxTree.root.members[1]) <> Null, "statement after conditional region")

Local compoundConditionalSource:String = "?win32 And ptr64~nPrint 1~n?linux Or macos~nPrint 2~n?Not threaded And (linux Or macos)~nPrint 3~n?"
Local compoundConditionalResult:TParseResult = TBlitzMaxParser.ParseText(compoundConditionalSource, "compound-conditional.bmx")
Check(compoundConditionalResult.syntaxTree.diagnostics.length = 0, "compound conditional diagnostics")
Local compoundConditional:TConditionalRegionSyntax = TConditionalRegionSyntax(compoundConditionalResult.syntaxTree.root.members[0])
Check(compoundConditional.branches.length = 3, "compound conditional branch count")
Local firstConditional:TConditionalBinarySyntax = TConditionalBinarySyntax(compoundConditional.branches[0].condition)
Check(firstConditional <> Null And firstConditional.operatorToken.text.ToLower() = "and", "conditional And expression")
Local secondConditional:TConditionalBinarySyntax = TConditionalBinarySyntax(compoundConditional.branches[1].condition)
Check(secondConditional <> Null And secondConditional.operatorToken.text.ToLower() = "or", "conditional Or expression")
Local thirdConditional:TConditionalBinarySyntax = TConditionalBinarySyntax(compoundConditional.branches[2].condition)
Check(TConditionalNotSyntax(thirdConditional.left) <> Null, "conditional Not expression")
Check(TConditionalParenthesizedSyntax(thirdConditional.right) <> Null, "parenthesized conditional expression")

Local eofConditionalResult:TParseResult = TBlitzMaxParser.ParseText("?disabled~nFunction DisabledDriver()~nEnd Function", "disabled-driver.bmx")
Check(eofConditionalResult.syntaxTree.diagnostics.length = 0 And TConditionalRegionSyntax(eofConditionalResult.syntaxTree.root.members[0]).endDirectiveToken = Null, "top-level conditional regions may end implicitly at end-of-file")

Local winBranches:Int[] = TConditionalEvaluator.ActiveBranchIndexes(compoundConditional, ["win32", "ptr64"])
Check(winBranches.length = 1 And winBranches[0] = 0, "win32 ptr64 active conditional branch")
Local mixedCaseBranches:Int[] = TConditionalEvaluator.ActiveBranchIndexes(compoundConditional, ["WIN32", "Ptr64"])
Check(mixedCaseBranches.length = 1 And mixedCaseBranches[0] = 0, "conditional symbols are matched without case-sensitive allocation")
Local linuxBranches:Int[] = TConditionalEvaluator.ActiveBranchIndexes(compoundConditional, ["linux"])
Check(linuxBranches.length = 2 And linuxBranches[0] = 1 And linuxBranches[1] = 2, "linux active conditional branches")
Local threadedBranches:Int[] = TConditionalEvaluator.ActiveBranchIndexes(compoundConditional, ["linux", "threaded"])
Check(threadedBranches.length = 1 And threadedBranches[0] = 1, "threaded conditional branch filtering")
Local inactiveBranches:Int[] = TConditionalEvaluator.ActiveBranchIndexes(compoundConditional, ["disabled"])
Check(inactiveBranches.length = 0, "inactive conditional branches return an empty array")
Local allBranches:Int[] = TConditionalEvaluator.ActiveBranchIndexes(compoundConditional, ["win32", "ptr64", "linux"])
Check(allBranches.length = 3 And allBranches[0] = 0 And allBranches[1] = 1 And allBranches[2] = 2, "all active conditional branches reuse the complete array")
Local conditionalPrecedenceResult:TParseResult = TBlitzMaxParser.ParseText("?win32 Or linux And ptr64~nPrint 1~n?", "conditional-precedence.bmx")
Local conditionalPrecedence:TConditionalBinarySyntax = TConditionalBinarySyntax(TConditionalRegionSyntax(conditionalPrecedenceResult.syntaxTree.root.members[0]).branches[0].condition)
Check(conditionalPrecedence.operatorToken.text.ToLower() = "or", "conditional Or has lower precedence than And")
Check(TConditionalBinarySyntax(conditionalPrecedence.right).operatorToken.text.ToLower() = "and", "conditional And binds within Or")

Local assignmentResult:TParseResult = TBlitzMaxParser.ParseText("a = GetAmount()", "assignment.bmx")
Local assignment:TAssignmentStatementSyntax = TAssignmentStatementSyntax(assignmentResult.syntaxTree.root.members[0])
Check(assignment <> Null, "assignment statement syntax")
Check(TNameExpressionSyntax(assignment.left) <> Null, "assignment name target")
Check(TCallExpressionSyntax(assignment.right) <> Null, "RHS call expression")

Local selfAssignmentResult:TParseResult = TBlitzMaxParser.ParseText("Self.value = GetAmount()", "self_assignment.bmx")
Local selfAssignment:TAssignmentStatementSyntax = TAssignmentStatementSyntax(selfAssignmentResult.syntaxTree.root.members[0])
Check(selfAssignment <> Null, "Self-qualified assignment statement syntax")
Check(TMemberAccessExpressionSyntax(selfAssignment.left) <> Null, "Self-qualified assignment target")
Check(TCallExpressionSyntax(selfAssignment.right) <> Null, "Self-qualified assignment RHS call")

Local precedenceResult:TParseResult = TBlitzMaxParser.ParseText("value = 1 + 2 * 3", "precedence.bmx")
Local precedenceAssignment:TAssignmentStatementSyntax = TAssignmentStatementSyntax(precedenceResult.syntaxTree.root.members[0])
Local addition:TBinaryExpressionSyntax = TBinaryExpressionSyntax(precedenceAssignment.right)
Check(addition <> Null And addition.operatorToken.text = "+", "addition expression root")
Local multiplication:TBinaryExpressionSyntax = TBinaryExpressionSyntax(addition.right)
Check(multiplication <> Null And multiplication.operatorToken.text = "*", "multiplication precedence")

Local declarationSource:String = "Local amount:Int = GetAmount(), doubled:Int = amount * 2"
Local declarationResult:TParseResult = TBlitzMaxParser.ParseText(declarationSource, "declaration.bmx")
Check(declarationResult.syntaxTree.diagnostics.length = 0, "variable declaration diagnostics")
Local declaration:TVariableDeclarationStatementSyntax = TVariableDeclarationStatementSyntax(declarationResult.syntaxTree.root.members[0])
Check(declaration <> Null And declaration.declarators.length = 2, "variable declarator count")
Check(declaration.declarators[0].nameToken.text = "amount", "first variable name")
Check(declaration.declarators[0].typeTokens.length = 2, "first declared type tokens")
Check(TCallExpressionSyntax(declaration.declarators[0].initializer) <> Null, "declaration call initializer")
Check(TBinaryExpressionSyntax(declaration.declarators[1].initializer) <> Null, "declaration binary initializer")

Local postfixResult:TParseResult = TBlitzMaxParser.ParseText("result = service.Get(1, values[2])", "postfix.bmx")
Local postfixAssignment:TAssignmentStatementSyntax = TAssignmentStatementSyntax(postfixResult.syntaxTree.root.members[0])
Local invocation:TCallExpressionSyntax = TCallExpressionSyntax(postfixAssignment.right)
Check(invocation <> Null And invocation.arguments.length = 2, "member call arguments")
Check(TMemberAccessExpressionSyntax(invocation.callee) <> Null, "member access call target")
Check(TIndexExpressionSyntax(invocation.arguments[1]) <> Null, "index expression argument")

Local typedResult:TParseResult = TBlitzMaxParser.ParseText("value = -42:Long + 3:UInt", "typed.bmx")
Check(typedResult.syntaxTree.diagnostics.length = 0, "numeric type suffix diagnostics")
Local typedAssignment:TAssignmentStatementSyntax = TAssignmentStatementSyntax(typedResult.syntaxTree.root.members[0])
Local typedAddition:TBinaryExpressionSyntax = TBinaryExpressionSyntax(typedAssignment.right)
Check(TUnaryExpressionSyntax(typedAddition.left) <> Null, "typed negative unary expression")
Check(TTypeAscriptionExpressionSyntax(TUnaryExpressionSyntax(typedAddition.left).operand) <> Null, "typed negative operand")
Check(TTypeAscriptionExpressionSyntax(typedAddition.right).targetType.nameTokens[0].text = "UInt", "numeric suffix target type")

Local rejectedPostfixTypeSource:String = "value = item:String~nvalue = values[0]:Object~nvalue = GetValue():Int~nvalue = (item):String~nvalue = Null:Object"
Local rejectedPostfixTypeResult:TParseResult = TBlitzMaxParser.ParseText(rejectedPostfixTypeSource, "rejected-postfix-types.bmx")
Check(rejectedPostfixTypeResult.syntaxTree.diagnostics.length = 5, "general postfix type syntax produces one diagnostic per expression")
Check(rejectedPostfixTypeResult.syntaxTree.diagnostics[0].span.start = rejectedPostfixTypeSource.Find(":String") And rejectedPostfixTypeResult.syntaxTree.diagnostics[0].span.length = 7, "postfix type diagnostic selects only the removable colon and type")
For Local rejectedPostfixTypeDiagnostic:TDiagnostic = EachIn rejectedPostfixTypeResult.syntaxTree.diagnostics
	Check(rejectedPostfixTypeDiagnostic.code = "BMX2105", "general postfix type syntax receives the dedicated diagnostic")
	Check(rejectedPostfixTypeDiagnostic.message.Contains("Type(expression)"), "postfix type diagnostic identifies explicit conversion syntax")
Next

Local rejectedGenericPostfixResult:TParseResult = TBlitzMaxParser.ParseText("Function Convert<A, B>:B(value:A)~nReturn value:B~nEnd Function", "rejected-generic-postfix-type.bmx")
Check(rejectedGenericPostfixResult.syntaxTree.diagnostics.length = 1 And rejectedGenericPostfixResult.syntaxTree.diagnostics[0].code = "BMX2105", "generic postfix types are rejected before specialization")

Local castResult:TParseResult = TBlitzMaxParser.ParseText("pointer = Byte Ptr(12345)~nobjects = TObject[](value)~nnumber = Int(value)", "cast.bmx")
Check(castResult.syntaxTree.diagnostics.length = 0, "cast expression diagnostics")
Local pointerCast:TCastExpressionSyntax = TCastExpressionSyntax(TAssignmentStatementSyntax(castResult.syntaxTree.root.members[0]).right)
Local arrayCast:TCastExpressionSyntax = TCastExpressionSyntax(TAssignmentStatementSyntax(castResult.syntaxTree.root.members[1]).right)
Local numericCast:TCastExpressionSyntax = TCastExpressionSyntax(TAssignmentStatementSyntax(castResult.syntaxTree.root.members[2]).right)
Check(pointerCast <> Null And pointerCast.targetType.pointerTokens.length = 1, "pointer cast type")
Check(arrayCast <> Null And arrayCast.targetType.arrayRanks.length = 1, "array cast type")
Check(numericCast <> Null And numericCast.targetType.nameTokens[0].text = "Int", "built-in numeric cast")

Local prefixCastResult:TParseResult = TBlitzMaxParser.ParseText("pointer = Byte Ptr GetString(obj).ToInt()~nSetString(obj, String.FromInt(Int value))~nfptr = Byte Ptr Int Ptr(base + offset)[0]", "prefix-cast.bmx")
Check(prefixCastResult.syntaxTree.diagnostics.length = 0, "unparenthesized prefix cast diagnostics")
Local directPointerCast:TCastExpressionSyntax = TCastExpressionSyntax(TAssignmentStatementSyntax(prefixCastResult.syntaxTree.root.members[0]).right)
Check(directPointerCast <> Null And directPointerCast.targetType.pointerTokens.length = 1 And TCallExpressionSyntax(directPointerCast.expression) <> Null, "pointer prefix cast consumes a postfix call operand")
Local setStringCall:TCallExpressionSyntax = TCallExpressionSyntax(TCallStatementSyntax(prefixCastResult.syntaxTree.root.members[1]).expression)
Local fromIntCall:TCallExpressionSyntax = TCallExpressionSyntax(setStringCall.arguments[1])
Check(fromIntCall <> Null And TCastExpressionSyntax(fromIntCall.arguments[0]) <> Null And TCastExpressionSyntax(fromIntCall.arguments[0]).targetType.nameTokens[0].text = "Int", "numeric prefix cast is retained inside a nested call")
Local nestedPointerCast:TCastExpressionSyntax = TCastExpressionSyntax(TAssignmentStatementSyntax(prefixCastResult.syntaxTree.root.members[2]).right)
Local dereferencedPointer:TIndexExpressionSyntax = TIndexExpressionSyntax(nestedPointerCast.expression)
Check(nestedPointerCast <> Null And dereferencedPointer <> Null And TCastExpressionSyntax(dereferencedPointer.expression).targetType.pointerTokens.length = 1, "nested pointer cast indexes before applying its outer cast")

Local omittedArgsResult:TParseResult = TBlitzMaxParser.ParseText("result = Parse(value, start,,, flags)", "omitted_args.bmx")
Check(omittedArgsResult.syntaxTree.diagnostics.length = 0, "omitted call argument diagnostics")
Local omittedCall:TCallExpressionSyntax = TCallExpressionSyntax(TAssignmentStatementSyntax(omittedArgsResult.syntaxTree.root.members[0]).right)
Check(omittedCall.arguments.length = 5, "omitted call argument slots")
Check(TOmittedArgumentExpressionSyntax(omittedCall.arguments[2]) <> Null, "first omitted call argument node")
Check(TOmittedArgumentExpressionSyntax(omittedCall.arguments[3]) <> Null, "second omitted call argument node")

Local sliceResult:TParseResult = TBlitzMaxParser.ParseText("a = values[1..last]~nb = values[..last]~nc = values[first..]", "slice.bmx")
Check(sliceResult.syntaxTree.diagnostics.length = 0, "slice diagnostics")
Local fullSlice:TSliceExpressionSyntax = TSliceExpressionSyntax(TAssignmentStatementSyntax(sliceResult.syntaxTree.root.members[0]).right)
Local openSlice:TSliceExpressionSyntax = TSliceExpressionSyntax(TAssignmentStatementSyntax(sliceResult.syntaxTree.root.members[1]).right)
Local tailSlice:TSliceExpressionSyntax = TSliceExpressionSyntax(TAssignmentStatementSyntax(sliceResult.syntaxTree.root.members[2]).right)
Check(fullSlice.lowerBound <> Null And fullSlice.upperBound <> Null, "bounded slice")
Check(openSlice.lowerBound = Null And openSlice.upperBound <> Null, "open lower slice")
Check(tailSlice.lowerBound <> Null And tailSlice.upperBound = Null, "open upper slice")

Local newResult:TParseResult = TBlitzMaxParser.ParseText("Local instance:TThing = New TThing~nLocal sized:Int[] = New Int[10]~nLocal matrix:Int[,] = New Int[4, 5]~nLocal jagged:Int[][] = New Int[6][]", "new.bmx")
Check(newResult.syntaxTree.diagnostics.length = 0, "New expression diagnostics")
Local newObject:TNewExpressionSyntax = TNewExpressionSyntax(TVariableDeclarationStatementSyntax(newResult.syntaxTree.root.members[0]).declarators[0].initializer)
Local newArray:TNewExpressionSyntax = TNewExpressionSyntax(TVariableDeclarationStatementSyntax(newResult.syntaxTree.root.members[1]).declarators[0].initializer)
Check(newObject <> Null And newObject.createdType.nameTokens[0].text = "TThing", "object creation expression")
Check(newArray <> Null And newArray.dimensions.length = 1, "array creation dimensions")
Check(newArray.dimensionRanks.length = 1 And newArray.dimensionRanks[0] = 1, "array creation dimension rank")
Local newMatrix:TNewExpressionSyntax = TNewExpressionSyntax(TVariableDeclarationStatementSyntax(newResult.syntaxTree.root.members[2]).declarators[0].initializer)
Check(newMatrix.dimensions.length = 2 And newMatrix.dimensionRanks[0] = 2, "ranked array creation dimensions")
Local newJagged:TNewExpressionSyntax = TNewExpressionSyntax(TVariableDeclarationStatementSyntax(newResult.syntaxTree.root.members[3]).declarators[0].initializer)
Check(newJagged <> Null And newJagged.dimensions.length = 1 And newJagged.dimensionRanks.length = 2 And newJagged.dimensionRanks[0] = 1 And newJagged.dimensionRanks[1] = 1, "partially allocated jagged array creation retains its allocated and empty ranks")
Local chainedNewStatementResult:TParseResult = TBlitzMaxParser.ParseText("New TSorter<Int>().Sort(values, 0, 1)", "new_call_statement.bmx")
Local chainedNewStatement:TCallStatementSyntax = TCallStatementSyntax(chainedNewStatementResult.syntaxTree.root.members[0])
Check(chainedNewStatement <> Null And chainedNewStatement.hasParentheses And TCallExpressionSyntax(chainedNewStatement.expression) <> Null, "New receiver followed by a method call parses as a complete call statement")

Local arrayLiteralResult:TParseResult = TBlitzMaxParser.ParseText("values = [New TThing, 2:UInt, source[1..]]", "array_literal.bmx")
Check(arrayLiteralResult.syntaxTree.diagnostics.length = 0, "array literal diagnostics")
Local arrayLiteral:TArrayLiteralExpressionSyntax = TArrayLiteralExpressionSyntax(TAssignmentStatementSyntax(arrayLiteralResult.syntaxTree.root.members[0]).right)
Check(arrayLiteral <> Null And arrayLiteral.elements.length = 3, "array literal elements")
Check(TNewExpressionSyntax(arrayLiteral.elements[0]) <> Null, "New expression in array literal")
Check(TTypeAscriptionExpressionSyntax(arrayLiteral.elements[1]) <> Null, "typed value in array literal")
Check(TSliceExpressionSyntax(arrayLiteral.elements[2]) <> Null, "slice in array literal")

Local multilineArrayResult:TParseResult = TBlitzMaxParser.ParseText("values = [ ..~nNew TThing(1),~nNew TThing(2),~nNew TThing(3)~n]", "multiline_array.bmx")
Check(multilineArrayResult.syntaxTree.diagnostics.length = 0, "multiline array literal diagnostics")
Local multilineArray:TArrayLiteralExpressionSyntax = TArrayLiteralExpressionSyntax(TAssignmentStatementSyntax(multilineArrayResult.syntaxTree.root.members[0]).right)
Check(multilineArray.elements.length = 3, "multiline array literal elements")

Local continuationSource:String = "Function Add:Int( ..~nleft:Int, ..~nright:Int ..~n)~nReturn left + right~nEnd Function~nLocal first:Int = 1, ..~nsecond:Int = 2~nfirst :Mod..~nsecond"
Local continuationResult:TParseResult = TBlitzMaxParser.ParseText(continuationSource, "continuation.bmx")
Check(continuationResult.syntaxTree.diagnostics.length = 0, "line continuation diagnostics")
Local continuationRoutine:TRoutineDeclarationSyntax = TRoutineDeclarationSyntax(continuationResult.syntaxTree.root.members[0])
Check(continuationRoutine.signature.parameters.length = 2, "continued routine parameters")
Local continuedDeclaration:TVariableDeclarationStatementSyntax = TVariableDeclarationStatementSyntax(continuationResult.syntaxTree.root.members[1])
Check(continuedDeclaration.declarators.length = 2, "continued variable declarators")
Local continuedAssignment:TAssignmentStatementSyntax = TAssignmentStatementSyntax(continuationResult.syntaxTree.root.members[2])
Check(continuedAssignment <> Null And continuedAssignment.operatorToken.text.ToLower() = ":mod", "continued assignment expression")

Local alphabeticCompoundBoundary:TLexResult = TBlitzMaxLexer.Lex("Local value:Mode~nvalue :Mod 2~nLocal shifted:ShlValue~nshifted :Shl 1", "alphabetic-compound-boundary.bmx")
Check(alphabeticCompoundBoundary.diagnostics.length = 0 And alphabeticCompoundBoundary.ReconstructSource() = "Local value:Mode~nvalue :Mod 2~nLocal shifted:ShlValue~nshifted :Shl 1", "alphabetic compound-assignment boundary remains lossless")
Local modAssignmentCount:Int
Local shlAssignmentCount:Int
For Local token:TSyntaxToken = EachIn alphabeticCompoundBoundary.tokens
	If token.text.ToLower() = ":mod" Then modAssignmentCount :+ 1
	If token.text.ToLower() = ":shl" Then shlAssignmentCount :+ 1
Next
Check(modAssignmentCount = 1 And shlAssignmentCount = 1, "alphabetic compound assignments require a trailing word boundary")

Local legacyContinuationSource:String = "SuperStrict~nLocal values:Int[] = [ _~n0, 1, _~n2 _~n]~n"
Local legacyContinuationResult:TParseResult = TBlitzMaxParser.ParseText(legacyContinuationSource, "legacy-continuation.bmx")
Check(legacyContinuationResult.syntaxTree.diagnostics.length = 0, "underscore line continuation diagnostics")
Local legacyContinuationDeclaration:TVariableDeclarationStatementSyntax = TVariableDeclarationStatementSyntax(legacyContinuationResult.syntaxTree.root.members[1])
Local legacyContinuationLiteral:TArrayLiteralExpressionSyntax = TArrayLiteralExpressionSyntax(legacyContinuationDeclaration.declarators[0].initializer)
Check(legacyContinuationLiteral <> Null And legacyContinuationLiteral.elements.length = 3, "underscore line continuation preserves array elements")

Local metadataResult:TParseResult = TBlitzMaxParser.ParseText("Field value:Int = 1 {description=~qexample~q}", "metadata.bmx")
Check(metadataResult.syntaxTree.diagnostics.length = 0, "field metadata diagnostics")
Local metadataField:TVariableDeclarationStatementSyntax = TVariableDeclarationStatementSyntax(metadataResult.syntaxTree.root.members[0])
Check(metadataField.declarators[0].metadataTokens.length = 5, "field metadata tokens")

Local semicolonIfResult:TParseResult = TBlitzMaxParser.ParseText("If False;End", "semicolon_if.bmx")
Check(semicolonIfResult.syntaxTree.diagnostics.length = 0, "semicolon single-line If diagnostics")
Local semicolonIf:TIfStatementSyntax = TIfStatementSyntax(semicolonIfResult.syntaxTree.root.members[0])
Check(semicolonIf.singleLine And TEndStatementSyntax(semicolonIf.thenBlock.statements[0]) <> Null, "semicolon single-line If body")

Local multiStatementIfResult:TParseResult = TBlitzMaxParser.ParseText("If Not figure Then Print ~qfigure is null~q;Return False~nReturn True", "semicolon_if_body.bmx")
Check(multiStatementIfResult.syntaxTree.diagnostics.length = 0, "multi-statement single-line If diagnostics")
Local multiStatementIf:TIfStatementSyntax = TIfStatementSyntax(multiStatementIfResult.syntaxTree.root.members[0])
Check(multiStatementIf.thenBlock.statements.length = 2, "semicolon-separated statements remain in the single-line Then block")
Check(TCallStatementSyntax(multiStatementIf.thenBlock.statements[0]) <> Null And TReturnStatementSyntax(multiStatementIf.thenBlock.statements[1]) <> Null, "single-line Then block preserves call and Return statements")
Check(TReturnStatementSyntax(multiStatementIfResult.syntaxTree.root.members[1]) <> Null, "the following physical line remains outside the single-line If")
Local inlineForIfResult:TParseResult = TBlitzMaxParser.ParseText("If values Then For Local child:Int = EachIn values; Use child; Next; Return", "inline_for_if.bmx")
Local inlineForIf:TIfStatementSyntax = TIfStatementSyntax(inlineForIfResult.syntaxTree.root.members[0])
Local inlineFor:TForStatementSyntax
If inlineForIf And inlineForIf.thenBlock.statements.length Then inlineFor = TForStatementSyntax(inlineForIf.thenBlock.statements[0])
Check(inlineForIfResult.syntaxTree.diagnostics.length = 0 And inlineFor <> Null And inlineFor.body.statements.length = 1 And inlineFor.terminator <> Null, "single-line If retains a complete semicolon-delimited For body and terminator")
Check(inlineForIf.thenBlock.statements.length = 2 And TReturnStatementSyntax(inlineForIf.thenBlock.statements[1]) <> Null, "statement following compact For remains in the enclosing single-line If branch")

Local noParenResult:TParseResult = TBlitzMaxParser.ParseText("Print amount * 2", "call.bmx")
Local noParenCall:TCallStatementSyntax = TCallStatementSyntax(noParenResult.syntaxTree.root.members[0])
Check(noParenCall.argumentExpressions.length = 1, "non-parenthesized call argument count")
Check(TBinaryExpressionSyntax(noParenCall.argumentExpressions[0]) <> Null, "non-parenthesized call argument expression")
Local unaryCommandResult:TParseResult = TBlitzMaxParser.ParseText("stream.WriteLine -mode", "unary-command-call.bmx")
Local unaryCommandCall:TCallStatementSyntax = TCallStatementSyntax(unaryCommandResult.syntaxTree.root.members[0])
Check(unaryCommandResult.syntaxTree.diagnostics.length = 0 And unaryCommandCall <> Null And unaryCommandCall.argumentExpressions.length = 1, "member command call accepts a leading unary argument")
Check(TUnaryExpressionSyntax(unaryCommandCall.argumentExpressions[0]) <> Null, "member command call retains its negative argument as unary syntax")
Local equalityCommandResult:TParseResult = TBlitzMaxParser.ParseText("canvas.SetColorMask i=0,i=1,i=2,i=3", "equality-command-call.bmx")
Local equalityCommandCall:TCallStatementSyntax = TCallStatementSyntax(equalityCommandResult.syntaxTree.root.members[0])
Check(equalityCommandResult.syntaxTree.diagnostics.length = 0 And equalityCommandCall <> Null And equalityCommandCall.argumentExpressions.length = 4, "command call accepts equality expressions as arguments")
For Local equalityArgument:TExpressionSyntax = EachIn equalityCommandCall.argumentExpressions
	Check(TBinaryExpressionSyntax(equalityArgument) <> Null, "command call retains equality argument syntax")
Next

Local statementArgsResult:TParseResult = TBlitzMaxParser.ParseText("Graphics 640, 480, flags~nUsePointer Varptr values[1]", "statement_args.bmx")
Check(statementArgsResult.syntaxTree.diagnostics.length = 0, "statement argument diagnostics")
Local graphicsCall:TCallStatementSyntax = TCallStatementSyntax(statementArgsResult.syntaxTree.root.members[0])
Check(graphicsCall.argumentExpressions.length = 3, "brace-free call argument count")
Local pointerCall:TCallStatementSyntax = TCallStatementSyntax(statementArgsResult.syntaxTree.root.members[1])
Local varptrExpression:TUnaryExpressionSyntax = TUnaryExpressionSyntax(pointerCall.argumentExpressions[0])
Check(varptrExpression <> Null And varptrExpression.operatorToken.text.ToLower() = "varptr", "Varptr unary expression")

Local intrinsicPostfixResult:TParseResult = TBlitzMaxParser.ParseText("Local upper:String = Chr(65).ToUpper()", "intrinsic-postfix.bmx")
Check(intrinsicPostfixResult.syntaxTree.diagnostics.length = 0, "intrinsic postfix diagnostics")
Local intrinsicPostfixDeclaration:TVariableDeclarationStatementSyntax = TVariableDeclarationStatementSyntax(intrinsicPostfixResult.syntaxTree.root.members[0])
Local intrinsicPostfixCall:TCallExpressionSyntax = TCallExpressionSyntax(intrinsicPostfixDeclaration.declarators[0].initializer)
Local intrinsicPostfixMember:TMemberAccessExpressionSyntax = TMemberAccessExpressionSyntax(intrinsicPostfixCall.callee)
Check(intrinsicPostfixMember <> Null And TUnaryExpressionSyntax(intrinsicPostfixMember.expression) <> Null, "intrinsic postfix binds to intrinsic result")
Check(TParenthesizedExpressionSyntax(TUnaryExpressionSyntax(intrinsicPostfixMember.expression).operand) <> Null, "intrinsic retains parenthesized operand")
Check(TIndexExpressionSyntax(varptrExpression.operand) <> Null, "Varptr indexed operand")

Local scopeResult:TParseResult = TBlitzMaxParser.ParseText("value = localValue + .globalValue", "scope.bmx")
Check(scopeResult.syntaxTree.diagnostics.length = 0, "explicit scope diagnostics")
Local scopeBinary:TBinaryExpressionSyntax = TBinaryExpressionSyntax(TAssignmentStatementSyntax(scopeResult.syntaxTree.root.members[0]).right)
Local scopedMember:TMemberAccessExpressionSyntax = TMemberAccessExpressionSyntax(scopeBinary.right)
Check(scopedMember <> Null And TScopeExpressionSyntax(scopedMember.expression) <> Null, "explicit global scope expression")

Local scopedCallResult:TParseResult = TBlitzMaxParser.ParseText(".SetViewport(1,2,3,4)~n.Flip 1~nIf ready Then .Flip 1 Else .Flip 0", "scoped-call-statements.bmx")
Check(scopedCallResult.syntaxTree.diagnostics.length = 0, "leading-dot global call statement diagnostics")
Check(TCallStatementSyntax(scopedCallResult.syntaxTree.root.members[0]) And TCallStatementSyntax(scopedCallResult.syntaxTree.root.members[0]).hasParentheses, "parenthesized leading-dot invocation is a call statement")
Check(TCallStatementSyntax(scopedCallResult.syntaxTree.root.members[1]) And Not TCallStatementSyntax(scopedCallResult.syntaxTree.root.members[1]).hasParentheses, "command-style leading-dot invocation is a call statement")
Local scopedInlineIf:TIfStatementSyntax = TIfStatementSyntax(scopedCallResult.syntaxTree.root.members[2])
Check(scopedInlineIf And TCallStatementSyntax(scopedInlineIf.thenBlock.statements[0]) And TCallStatementSyntax(scopedInlineIf.elseClause.block.statements[0]), "single-line If retains leading-dot calls in both branches")

Local signatureSource:String = "Function Transform:TList<String[]>(StaticArray values:Int[10], output:String Var, limit:Int = 3) Export~nEnd Function"
Local signatureResult:TParseResult = TBlitzMaxParser.ParseText(signatureSource, "signature.bmx")
Check(signatureResult.syntaxTree.diagnostics.length = 0, "routine signature diagnostics")
Local signatureRoutine:TRoutineDeclarationSyntax = TRoutineDeclarationSyntax(signatureResult.syntaxTree.root.members[0])
Local signature:TRoutineSignatureSyntax = signatureRoutine.signature
Check(signature <> Null And signature.parameters.length = 3, "structured routine signature")
Check(signature.returnType <> Null And signature.returnType.genericArguments.length = 1, "generic return type")
Check(signature.returnType.genericArguments[0].arrayRanks.length = 1, "generic array type argument")
Check(signature.parameters[0].modifierTokens[0].text.ToLower() = "staticarray", "static array parameter modifier")
Check(signature.parameters[0].staticArrayToken <> Null And signature.parameters[0].declaredType.arrayRanks.length = 0, "fixed array parameter is distinct from heap array syntax")
Check(TLiteralExpressionSyntax(signature.parameters[0].staticArrayBound.lengthExpression) <> Null, "fixed array parameter bound syntax")
Check(signature.parameters[1].varToken.text.ToLower() = "var", "Var parameter syntax")
Check(TLiteralExpressionSyntax(signature.parameters[2].defaultValue) <> Null, "default parameter expression")
Check(signature.modifierTokens[0].text.ToLower() = "export", "routine modifier syntax")

Local genericRoutineSource:String = "Function Swap<T>(a:T Var, b:T Var)~nLocal temp:T = a~na = b~nb = temp~nEnd Function~nFunction Convert<T, U>:U(value:T, fallback:U) Where T Extends Object, U Extends Object Export~nReturn fallback~nEnd Function"
Local genericRoutineResult:TParseResult = TBlitzMaxParser.ParseText(genericRoutineSource, "generic-routines.bmx")
Check(genericRoutineResult.syntaxTree.diagnostics.length = 0, "generic routine diagnostics")
Local swapSignature:TRoutineSignatureSyntax = TRoutineDeclarationSyntax(genericRoutineResult.syntaxTree.root.members[0]).signature
Check(swapSignature.genericParameters.length = 1 And swapSignature.genericParameters[0].nameToken.text = "T", "generic function parameter syntax")
Check(swapSignature.parameters.length = 2 And swapSignature.parameters[0].varToken <> Null And swapSignature.parameters[1].varToken <> Null, "generic function Var parameters")
Check(swapSignature.parameters[0].declaredType.nameTokens[0].text = "T", "routine generic parameter type reference")
Local convertSignature:TRoutineSignatureSyntax = TRoutineDeclarationSyntax(genericRoutineResult.syntaxTree.root.members[1]).signature
Check(convertSignature.genericParameters.length = 2, "multiple routine generic parameters")
Check(convertSignature.returnType.nameTokens[0].text = "U", "generic routine return type")
Check(convertSignature.constraints.length = 2 And convertSignature.constraints[0].constraintTypes.length = 1, "routine generic constraints")
Check(convertSignature.modifierTokens.length = 1 And convertSignature.modifierTokens[0].text.ToLower() = "export", "generic routine trailing modifier")

Local genericCallResult:TParseResult = TBlitzMaxParser.ParseText("Swap<Human>(frank, bob)~nresult = factory.Create<TLinkedList<String>>(value)~ncomparison = a < b", "generic-calls.bmx")
Check(genericCallResult.syntaxTree.diagnostics.length = 0, "explicit generic call diagnostics")
Local swapCallStatement:TCallStatementSyntax = TCallStatementSyntax(genericCallResult.syntaxTree.root.members[0])
Local swapCall:TCallExpressionSyntax = TCallExpressionSyntax(swapCallStatement.expression)
Check(swapCall <> Null And swapCall.typeArguments.length = 1, "explicit generic function call")
Check(swapCall.typeArguments[0].nameTokens[0].text = "Human" And swapCall.arguments.length = 2, "generic function call type and value arguments")
Local memberGenericCall:TCallExpressionSyntax = TCallExpressionSyntax(TAssignmentStatementSyntax(genericCallResult.syntaxTree.root.members[1]).right)
Check(memberGenericCall <> Null And TMemberAccessExpressionSyntax(memberGenericCall.callee) <> Null, "explicit generic method call")
Check(memberGenericCall.typeArguments[0].genericArguments.length = 1, "nested explicit generic type argument")
Local comparisonRight:TExpressionSyntax = TAssignmentStatementSyntax(genericCallResult.syntaxTree.root.members[2]).right
Check(comparisonRight <> Null And TCallExpressionSyntax(comparisonRight) = Null, "comparison syntax is not mistaken for a generic call")

Local embeddedSource:String = "Function Outer:Int()~nFunction Inner:Int(value:Int = 1)~nReturn value~nEnd Function~nReturn Inner()~nEnd Function"
Local embeddedResult:TParseResult = TBlitzMaxParser.ParseText(embeddedSource, "embedded.bmx")
Check(embeddedResult.syntaxTree.diagnostics.length = 0, "embedded function diagnostics")
Local outerRoutine:TRoutineDeclarationSyntax = TRoutineDeclarationSyntax(embeddedResult.syntaxTree.root.members[0])
Check(TRoutineDeclarationSyntax(outerRoutine.body.statements[0]) <> Null, "embedded function remains nested syntax")
Check(TRoutineDeclarationSyntax(outerRoutine.body.statements[0]).signature.parameters.length = 1, "embedded function signature")

Local controlSource:String = "If ready Then~nPrint ~qready~q~nElseIf count > 0 Then~nWhile count > 0~ncount :- 1~nWend~nElse~nEnd~nEnd If~nRepeat~ncount :+ 1~nUntil count >= 3~nFor Local i:Int = 0 Until 2~nPrint i~nNext i"
Local controlResult:TParseResult = TBlitzMaxParser.ParseText(controlSource, "control.bmx")
Check(controlResult.syntaxTree.diagnostics.length = 0, "control-flow diagnostics")
Local ifStatement:TIfStatementSyntax = TIfStatementSyntax(controlResult.syntaxTree.root.members[0])
Check(ifStatement <> Null And ifStatement.elseIfClauses.length = 1, "If and ElseIf structure")
Check(ifStatement.elseClause <> Null, "Else structure")
Check(TWhileStatementSyntax(ifStatement.elseIfClauses[0].block.statements[0]) <> Null, "nested While structure")
Check(TEndStatementSyntax(ifStatement.elseClause.block.statements[0]) <> Null, "bare End in Else block")
Check(ifStatement.terminator.actualBlockKind = "if", "If terminator")
Local repeatStatement:TRepeatStatementSyntax = TRepeatStatementSyntax(controlResult.syntaxTree.root.members[1])
Check(repeatStatement <> Null And repeatStatement.condition <> Null, "Repeat Until structure")
Local forStatement:TForStatementSyntax = TForStatementSyntax(controlResult.syntaxTree.root.members[2])
Check(forStatement <> Null And forStatement.body.statements.length = 1, "For Next structure")
Check(forStatement.header.localToken.text.ToLower() = "local", "For local declaration")
Check(forStatement.header.declaration.nameToken.text = "i", "For declared variable")
Check(forStatement.header.declaration.declaredType.nameTokens[0].text = "Int", "For declared variable type")
Check(TLiteralExpressionSyntax(forStatement.header.initialValue) <> Null, "For initial value")
Check(forStatement.header.rangeToken.text.ToLower() = "until", "For Until range")
Check(TLiteralExpressionSyntax(forStatement.header.limit) <> Null, "For range limit")

Local forFormsSource:String = "For item = EachIn values~nPrint item~nNext~nFor Local i:Int = GetStart() To count - 1 Step -2~nPrint i~nNext i~nFor matrix[row] = 0 Until Width()~nPrint row~nNext"
Local forFormsResult:TParseResult = TBlitzMaxParser.ParseText(forFormsSource, "for-forms.bmx")
Check(forFormsResult.syntaxTree.diagnostics.length = 0, "structured For forms diagnostics")
Local eachInFor:TForStatementSyntax = TForStatementSyntax(forFormsResult.syntaxTree.root.members[0])
Check(TNameExpressionSyntax(eachInFor.header.target) <> Null, "EachIn existing target")
Check(eachInFor.header.eachInToken.text.ToLower() = "eachin", "EachIn token")
Check(TNameExpressionSyntax(eachInFor.header.collection) <> Null, "EachIn collection")
Local steppedFor:TForStatementSyntax = TForStatementSyntax(forFormsResult.syntaxTree.root.members[1])
Check(TCallExpressionSyntax(steppedFor.header.initialValue) <> Null, "For call initial value")
Check(steppedFor.header.rangeToken.text.ToLower() = "to", "For To range")
Check(TBinaryExpressionSyntax(steppedFor.header.limit) <> Null, "For range expression")
Check(TUnaryExpressionSyntax(steppedFor.header.stepExpression) <> Null, "For negative Step")
Local indexedFor:TForStatementSyntax = TForStatementSyntax(forFormsResult.syntaxTree.root.members[2])
Check(TIndexExpressionSyntax(indexedFor.header.target) <> Null, "For assignable index target")

Local genericEachInResult:TParseResult = TBlitzMaxParser.ParseText("For Local current:TBox<Int>=EachIn values~nPrint current~nNext", "generic-eachin.bmx")
Check(genericEachInResult.syntaxTree.diagnostics.length = 0, "generic EachIn declaration accepts adjacent close and assignment")
Local genericEachIn:TForStatementSyntax = TForStatementSyntax(genericEachInResult.syntaxTree.root.members[0])
Check(genericEachIn.header.declaration.declaredType.genericArguments.length = 1 And genericEachIn.header.eachInToken.text.ToLower() = "eachin", "generic EachIn declaration retains its constructed type and clause")

Local deconstructEachInResult:TParseResult = TBlitzMaxParser.ParseText("For Local key:String, value:TBox<Int, String> = EachIn values~nPrint key~nNext", "deconstruct-eachin.bmx")
Check(deconstructEachInResult.syntaxTree.diagnostics.length = 0, "two-binding EachIn header parses without confusing binding and generic-argument commas")
Local deconstructEachIn:TForStatementSyntax = TForStatementSyntax(deconstructEachInResult.syntaxTree.root.members[0])
Check(deconstructEachIn.header.declarations.length = 2 And deconstructEachIn.header.declaration = deconstructEachIn.header.declarations[0], "two-binding EachIn retains every declarator and the first-declaration compatibility view")
Check(deconstructEachIn.header.declarations[0].nameToken.text = "key" And deconstructEachIn.header.declarations[1].nameToken.text = "value" And deconstructEachIn.header.declarations[1].declaredType.genericArguments.length = 2, "two-binding EachIn retains independent names and component types")
Local deconstructNavigator:TSyntaxNavigator = TSyntaxNavigator.Create(deconstructEachInResult.syntaxTree)
Check(deconstructNavigator.ContainsNode(deconstructEachIn.header.declarations[1]) And deconstructNavigator.Parent(deconstructEachIn.header.declarations[1]) = deconstructEachIn.header, "syntax navigation indexes every EachIn binding")
Local invalidRangeBindings:TParseResult = TBlitzMaxParser.ParseText("For Local first:Int, second:Int = 0 Until 2~nNext", "invalid-range-bindings.bmx")
Check(invalidRangeBindings.syntaxTree.diagnostics.length = 1 And invalidRangeBindings.syntaxTree.diagnostics[0].code = "BMX2319", "multiple loop bindings are restricted to EachIn")

Local flowSource:String = "Function CheckValue:Int(value:Int)~nAssert value >= 0 Else ~qnegative~q~nIf value = 0 Then Return~nIf value > 100 Then Throw New TException(~qlarge~q)~nReturn value~nEnd Function~n#loop~nFor Local i:Int = 0 Until 10~nIf i = 2 Then Continue loop~nIf i = 8 Then Exit loop~nNext"
Local flowResult:TParseResult = TBlitzMaxParser.ParseText(flowSource, "flow-transfer.bmx")
Check(flowResult.syntaxTree.diagnostics.length = 0, "flow-transfer diagnostics")
Local flowRoutine:TRoutineDeclarationSyntax = TRoutineDeclarationSyntax(flowResult.syntaxTree.root.members[0])
Local assertStatement:TAssertStatementSyntax = TAssertStatementSyntax(flowRoutine.body.statements[0])
Check(assertStatement <> Null And assertStatement.separatorToken.text.ToLower() = "else", "Assert Else structure")
Check(TBinaryExpressionSyntax(assertStatement.condition) <> Null And TLiteralExpressionSyntax(assertStatement.message) <> Null, "Assert expressions")
Local returnIf:TIfStatementSyntax = TIfStatementSyntax(flowRoutine.body.statements[1])
Check(TReturnStatementSyntax(returnIf.thenBlock.statements[0]) <> Null And TReturnStatementSyntax(returnIf.thenBlock.statements[0]).expression = Null, "empty inline Return")
Local throwIf:TIfStatementSyntax = TIfStatementSyntax(flowRoutine.body.statements[2])
Check(TThrowStatementSyntax(throwIf.thenBlock.statements[0]) <> Null And TNewExpressionSyntax(TThrowStatementSyntax(throwIf.thenBlock.statements[0]).expression) <> Null, "inline Throw expression")
Check(TReturnStatementSyntax(flowRoutine.body.statements[3]).expression <> Null, "Return value expression")
Local labelledFor:TForStatementSyntax = TForStatementSyntax(flowResult.syntaxTree.root.members[1])
Check(labelledFor.label <> Null And labelledFor.label.nameToken.text = "loop", "structured loop label")
Local continueIf:TIfStatementSyntax = TIfStatementSyntax(labelledFor.body.statements[0])
Local exitIf:TIfStatementSyntax = TIfStatementSyntax(labelledFor.body.statements[1])
Check(TNameExpressionSyntax(TContinueStatementSyntax(continueIf.thenBlock.statements[0]).label) <> Null, "Continue label expression")
Check(TNameExpressionSyntax(TExitStatementSyntax(exitIf.thenBlock.statements[0]).label) <> Null, "Exit label expression")

Local dataSource:String = "SuperStrict~nLocal name:String~nLocal age:Int, skill:Int~nReadData name~nReadData age, skill~nRestoreData people~n#people~nDefData ~qSimon~q, 37, 5000"
Local dataResult:TParseResult = TBlitzMaxParser.ParseText(dataSource, "data.bmx")
Check(dataResult.syntaxTree.diagnostics.length = 0, "data statement diagnostics")
Check(dataResult.syntaxTree.root.sourceMode = SOURCE_MODE_SUPERSTRICT, "data source mode")
Local firstRead:TReadDataStatementSyntax = TReadDataStatementSyntax(dataResult.syntaxTree.root.members[3])
Local secondRead:TReadDataStatementSyntax = TReadDataStatementSyntax(dataResult.syntaxTree.root.members[4])
Check(firstRead.targets.length = 1 And TNameExpressionSyntax(firstRead.targets[0]) <> Null, "single ReadData target")
Check(secondRead.targets.length = 2, "multiple ReadData targets")
Local restoreNode:TRestoreDataStatementSyntax = TRestoreDataStatementSyntax(dataResult.syntaxTree.root.members[5])
Check(TNameExpressionSyntax(restoreNode.label) <> Null, "RestoreData label expression")
Local dataNode:TDefDataStatementSyntax = TDefDataStatementSyntax(dataResult.syntaxTree.root.members[6])
Check(dataNode.label.nameToken.text = "people", "DefData label")
Check(dataNode.values.length = 3 And TLiteralExpressionSyntax(dataNode.values[0]) <> Null, "DefData values")

Local enumSource:String = "Enum EMonth : Byte~nJan, Feb~nMar = 10~nApr~nEnd Enum~nEnum EDays:Int Flags Sunday Monday Tuesday Weekend = Sunday | Saturday EndEnum~nEnum EState~nOff = 0~nRunning = 5~nSleeping = Running + 5~nEnd Enum"
Local enumResult:TParseResult = TBlitzMaxParser.ParseText(enumSource, "enums.bmx")
Check(enumResult.syntaxTree.diagnostics.length = 0, "enum diagnostics")
Local monthEnum:TEnumDeclarationSyntax = TEnumDeclarationSyntax(enumResult.syntaxTree.root.members[0])
Check(monthEnum <> Null And monthEnum.nameToken.text = "EMonth", "enum declaration")
Check(monthEnum.underlyingType.nameTokens[0].text = "Byte", "enum underlying type")
Check(monthEnum.values.length = 4 And monthEnum.values[0].separatorToken.text = ",", "enum comma and values")
Check(TLiteralExpressionSyntax(monthEnum.values[2].value) <> Null, "explicit enum value")
Check(monthEnum.terminator.actualBlockKind = "enum", "spaced enum terminator")
Local daysEnum:TEnumDeclarationSyntax = TEnumDeclarationSyntax(enumResult.syntaxTree.root.members[1])
Check(daysEnum.flagsToken.text.ToLower() = "flags", "flags enum")
Check(daysEnum.underlyingType.nameTokens[0].text = "Int", "flags enum underlying type")
Check(daysEnum.values.length = 4, "same-line enum values without commas")
Check(TBinaryExpressionSyntax(daysEnum.values[3].value) <> Null, "flags composite value")
Check(daysEnum.terminator.endToken.text.ToLower() = "endenum", "combined enum terminator")
Local stateEnum:TEnumDeclarationSyntax = TEnumDeclarationSyntax(enumResult.syntaxTree.root.members[2])
Check(TBinaryExpressionSyntax(stateEnum.values[2].value) <> Null, "enum value references prior value")
Local incompleteEnumResult:TParseResult = TBlitzMaxParser.ParseText("Enum ETest~n~tRem~n~tOne~n~tTwo~n~tThree~nEnd Enum", "incomplete-enum-rem.bmx")
Local incompleteEnum:TEnumDeclarationSyntax = TEnumDeclarationSyntax(incompleteEnumResult.syntaxTree.root.members[0])
Check(incompleteEnum <> Null And incompleteEnum.nameToken.text = "ETest", "unfinished Rem retains the recovered enum declaration")
Check(incompleteEnum.span.start <= incompleteEnum.nameToken.span.start And incompleteEnum.span.EndOffset() >= incompleteEnum.nameToken.span.EndOffset(), "recovered enum span contains its name while the unfinished Rem hides its body")

Local declarationHeaderSource:String = "Type TBox<K, V> Extends TBase<K> Implements IFoo<V>, ICloseable Final {serializable}~nPrivate Field value:V~nProtected~nMethod Get:V()~nReturn value~nEnd Method~nPublic~nFunction Create:TBox<K,V>()~nReturn New TBox<K,V>~nEnd Function~nEnd Type~nInterface IThing<T> Extends IBase<T>, IOther~nMethod Get:T()~nEnd Interface~nStruct SPoint {valueType}~nField x:Double~nField y:Double~nEnd Struct~nType TConstrained<T, U> Where T Extends IBase And ICloseable, U Extends IOther Extends TBase<T> Implements IFoo<U> Abstract {generic}~nEnd Type"
Local declarationHeaderResult:TParseResult = TBlitzMaxParser.ParseText(declarationHeaderSource, "declaration-headers.bmx")
Check(declarationHeaderResult.syntaxTree.diagnostics.length = 0, "type declaration header diagnostics")
Local genericType:TTypeDeclarationSyntax = TTypeDeclarationSyntax(declarationHeaderResult.syntaxTree.root.members[0])
Check(genericType.declarationToken.text.ToLower() = "type", "Type declaration kind")
Check(genericType.header.genericParameters.length = 2, "generic declaration parameters")
Check(genericType.header.extendsTypes.length = 1 And genericType.header.extendsTypes[0].genericArguments.length = 1, "generic base type")
Check(genericType.header.implementedTypes.length = 2, "implemented interface list")
Check(genericType.header.modifierTokens[0].text.ToLower() = "final", "type Final modifier")
Check(genericType.header.metadataTokens.length > 0, "type metadata tokens")
Check(TVisibilitySectionSyntax(genericType.body.statements[0]).visibility = VISIBILITY_PRIVATE, "inline Private section")
Check(TVariableDeclarationStatementSyntax(genericType.body.statements[1]) <> Null, "member after inline visibility")
Check(TVisibilitySectionSyntax(genericType.body.statements[2]).visibility = VISIBILITY_PROTECTED, "Protected section")
Check(TVisibilitySectionSyntax(genericType.body.statements[4]).visibility = VISIBILITY_PUBLIC, "Public section")
Local combinedVisibilitySource:String = "SuperStrict~nType TCombined~nPrivate Internal~nField family:Int~nProtected Internal~nField shared:Int~nEnd Type"
Local combinedVisibilityResult:TParseResult = TBlitzMaxParser.ParseText(combinedVisibilitySource, "combined-visibility.bmx")
Check(combinedVisibilityResult.syntaxTree.diagnostics.length = 0, "combined visibility parser diagnostics")
Local combinedVisibilityType:TTypeDeclarationSyntax = TTypeDeclarationSyntax(combinedVisibilityResult.syntaxTree.root.members[1])
Local privateInternalSection:TVisibilitySectionSyntax = TVisibilitySectionSyntax(combinedVisibilityType.body.statements[0])
Local protectedInternalSection:TVisibilitySectionSyntax = TVisibilitySectionSyntax(combinedVisibilityType.body.statements[2])
Check(privateInternalSection.visibility = VISIBILITY_PRIVATE_INTERNAL And privateInternalSection.internalToken.text.ToLower() = "internal", "Private Internal visibility section")
Check(protectedInternalSection.visibility = VISIBILITY_PROTECTED_INTERNAL And protectedInternalSection.internalToken.text.ToLower() = "internal", "Protected Internal visibility section")
Check(privateInternalSection.span.length = Len("Private Internal"), "combined visibility span covers both modifiers")
Local genericInterface:TTypeDeclarationSyntax = TTypeDeclarationSyntax(declarationHeaderResult.syntaxTree.root.members[1])
Check(genericInterface.declarationToken.text.ToLower() = "interface", "Interface declaration kind")
Check(genericInterface.header.genericParameters.length = 1 And genericInterface.header.extendsTypes.length = 2, "generic interface bases")
Local pointStruct:TTypeDeclarationSyntax = TTypeDeclarationSyntax(declarationHeaderResult.syntaxTree.root.members[2])
Check(pointStruct.declarationToken.text.ToLower() = "struct" And pointStruct.header.metadataTokens.length > 0, "Struct declaration and metadata")
Local constrainedType:TTypeDeclarationSyntax = TTypeDeclarationSyntax(declarationHeaderResult.syntaxTree.root.members[3])
Check(constrainedType.header.whereToken.text.ToLower() = "where" And constrainedType.header.whereTokens.length > 0, "generic Where clause retained")
Check(constrainedType.header.constraints.length = 2, "generic constraint clauses")
Check(constrainedType.header.constraints[0].constraintTypes.length = 2 And constrainedType.header.constraints[0].andTokens.length = 1, "multiple generic bounds")
Check(constrainedType.header.constraints[1].parameterNameToken.text = "U", "second generic constraint")
Check(constrainedType.header.extendsTypes.length = 1, "post-Where Extends clause")
Check(constrainedType.header.implementedTypes.length = 1, "post-Where Implements clause")
Check(constrainedType.header.modifierTokens.length = 1, "post-Where declaration modifier")
Check(constrainedType.header.metadataTokens.length > 0, "post-Where declaration metadata")

Local inlineIfResult:TParseResult = TBlitzMaxParser.ParseText("If 1 = 0 Then End", "inline_if.bmx")
Local inlineIf:TIfStatementSyntax = TIfStatementSyntax(inlineIfResult.syntaxTree.root.members[0])
Check(inlineIf <> Null And inlineIf.singleLine, "single-line If structure")
Check(TEndStatementSyntax(inlineIf.thenBlock.statements[0]) <> Null, "single-line executable End")

Local inlineElseResult:TParseResult = TBlitzMaxParser.ParseText("If a Print ~qA~q Else If b Then Print ~qB~q Else Print ~qC~q", "inline_else.bmx")
Check(inlineElseResult.syntaxTree.diagnostics.length = 0, "single-line Else diagnostics")
Local inlineElse:TIfStatementSyntax = TIfStatementSyntax(inlineElseResult.syntaxTree.root.members[0])
Check(inlineElse.elseClause <> Null, "single-line Else structure")
Local nestedInlineIf:TIfStatementSyntax = TIfStatementSyntax(inlineElse.elseClause.block.statements[0])
Check(nestedInlineIf <> Null And nestedInlineIf.elseClause <> Null, "chained single-line Else If structure")
Check(TCallStatementSyntax(nestedInlineIf.elseClause.block.statements[0]) <> Null, "chained final Else body")

Local chainedMultilineResult:TParseResult = TBlitzMaxParser.ParseText("If a If b~nPrint ~qboth~q~nEndIf~nPrint ~qafter~q", "chained_multiline_if.bmx")
Check(chainedMultilineResult.syntaxTree.diagnostics.length = 0 And chainedMultilineResult.syntaxTree.root.members.length = 2, "chained multiline If diagnostics and following-statement recovery")
Local chainedMultilineOuter:TIfStatementSyntax = TIfStatementSyntax(chainedMultilineResult.syntaxTree.root.members[0])
Local chainedMultilineInner:TIfStatementSyntax
If chainedMultilineOuter And chainedMultilineOuter.thenBlock.statements.length Then chainedMultilineInner = TIfStatementSyntax(chainedMultilineOuter.thenBlock.statements[0])
Check(chainedMultilineOuter And chainedMultilineOuter.singleLine And chainedMultilineOuter.terminator = Null, "chained multiline If retains its compact outer condition")
Check(chainedMultilineInner And Not chainedMultilineInner.singleLine And chainedMultilineInner.terminator And TCallStatementSyntax(chainedMultilineInner.thenBlock.statements[0]), "deepest chained If owns the multiline body and single terminator")

Local chainedMultilineThenResult:TParseResult = TBlitzMaxParser.ParseText("If a Then If b If c Then~nPrint ~qall~q~nEnd If", "chained_multiline_then_if.bmx")
Check(chainedMultilineThenResult.syntaxTree.diagnostics.length = 0, "chained multiline If accepts optional Then at every header level")
Local chainedMultilineThenOuter:TIfStatementSyntax = TIfStatementSyntax(chainedMultilineThenResult.syntaxTree.root.members[0])
Local chainedMultilineThenMiddle:TIfStatementSyntax = TIfStatementSyntax(chainedMultilineThenOuter.thenBlock.statements[0])
Local chainedMultilineThenInner:TIfStatementSyntax = TIfStatementSyntax(chainedMultilineThenMiddle.thenBlock.statements[0])
Check(chainedMultilineThenOuter.thenToken And chainedMultilineThenMiddle.singleLine And chainedMultilineThenInner.thenToken And chainedMultilineThenInner.terminator, "three chained conditions retain Then tokens and one deepest terminator")

Local inlineElseIfResult:TParseResult = TBlitzMaxParser.ParseText("If ready Then value=1 ElseIf waiting Then value=2 Else value=3", "inline_elseif.bmx")
Local inlineElseIf:TIfStatementSyntax = TIfStatementSyntax(inlineElseIfResult.syntaxTree.root.members[0])
Check(inlineElseIfResult.syntaxTree.diagnostics.length = 0 And inlineElseIf And inlineElseIf.singleLine, "single-line ElseIf diagnostics and structure")
Check(inlineElseIf.elseIfClauses.length = 1 And TAssignmentStatementSyntax(inlineElseIf.thenBlock.statements[0]) And TAssignmentStatementSyntax(inlineElseIf.elseIfClauses[0].block.statements[0]), "single-line ElseIf retains its Then and ElseIf statements")
Check(inlineElseIf.elseClause And TAssignmentStatementSyntax(inlineElseIf.elseClause.block.statements[0]), "single-line ElseIf retains its final Else statement")

Local selectSource:String = "Select value~nCase 1, 2 + 3~nPrint ~qsmall~q~nCase GetValue()~nEnd~nDefault~nPrint ~qother~q~nEnd Select"
Local selectResult:TParseResult = TBlitzMaxParser.ParseText(selectSource, "select.bmx")
Check(selectResult.syntaxTree.diagnostics.length = 0, "Select diagnostics")
Local selectStatement:TSelectStatementSyntax = TSelectStatementSyntax(selectResult.syntaxTree.root.members[0])
Check(selectStatement <> Null And selectStatement.cases.length = 2, "Select Case structure")
Check(selectStatement.cases[0].values.length = 2, "comma-separated Case values")
Check(TBinaryExpressionSyntax(selectStatement.cases[0].values[1]) <> Null, "Case value expression")
Check(TEndStatementSyntax(selectStatement.cases[1].body.statements[0]) <> Null, "bare End in Case")
Check(selectStatement.defaultClauses.length = 1 And selectStatement.defaultClause = selectStatement.defaultClauses[0], "Select Default structure and singular compatibility view")
Check(selectStatement.terminator.actualBlockKind = "select", "Select terminator")

Local compactCaseIfSource:String = "Select country~nCase ~qSCO~q If HasProvider(~qUK~q) Return ~qUK~q Else Return ~q~q~nEnd Select"
Local compactCaseIfResult:TParseResult = TBlitzMaxParser.ParseText(compactCaseIfSource, "compact-case-if.bmx")
Check(compactCaseIfResult.syntaxTree.diagnostics.length = 0, "compact Case If/Else diagnostics")
Local compactCaseIfSelect:TSelectStatementSyntax = TSelectStatementSyntax(compactCaseIfResult.syntaxTree.root.members[0])
Local compactCaseIf:TIfStatementSyntax = TIfStatementSyntax(compactCaseIfSelect.cases[0].body.statements[0])
Check(compactCaseIf <> Null And compactCaseIf.singleLine And compactCaseIf.elseClause <> Null, "compact Case If/Else structure")
Check(TReturnStatementSyntax(compactCaseIf.thenBlock.statements[0]) <> Null, "compact Case If return body")
Check(TReturnStatementSyntax(compactCaseIf.elseClause.block.statements[0]) <> Null, "compact Case Else return body")

Local conditionalSelectResult:TParseResult = TBlitzMaxParser.ParseText("Select value~n?BigEndian~nCase 1~nPrint ~qbig~q~n?LittleEndian~nCase 2~nPrint ~qlittle~q~n?~nEnd Select", "conditional-select.bmx")
Local conditionalSelect:TSelectStatementSyntax = TSelectStatementSyntax(conditionalSelectResult.syntaxTree.root.members[0])
Check(conditionalSelectResult.syntaxTree.diagnostics.length = 0 And conditionalSelect.cases.length = 2, "Select accepts conditionally compiled Case clauses")
Check(TConditionalNameSyntax(conditionalSelect.cases[0].conditionalExpression).nameToken.text = "BigEndian" And TConditionalNameSyntax(conditionalSelect.cases[1].conditionalExpression).nameToken.text = "LittleEndian", "conditional Select cases retain their target expressions")

Local conditionalDefaultResult:TParseResult = TBlitzMaxParser.ParseText("Select value~n?BigEndian~nDefault~nPrint ~qbig~q~n?LittleEndian~nDefault~nPrint ~qlittle~q~n?~nEnd Select", "conditional-default.bmx")
Local conditionalDefault:TSelectStatementSyntax = TSelectStatementSyntax(conditionalDefaultResult.syntaxTree.root.members[0])
Check(conditionalDefaultResult.syntaxTree.diagnostics.length = 0 And conditionalDefault.defaultClauses.length = 2, "Select preserves mutually exclusive conditional Default clauses")
Check(TConditionalNameSyntax(conditionalDefault.defaultClauses[0].conditionalExpression).nameToken.text = "BigEndian" And TConditionalNameSyntax(conditionalDefault.defaultClauses[1].conditionalExpression).nameToken.text = "LittleEndian", "conditional Select defaults retain their target expressions")

Local conditionalCaseBodyResult:TParseResult = TBlitzMaxParser.ParseText("Select value~nCase 1~n?BigEndian~nPrint ~qbig~q~n?~nCase 2~nPrint ~qother~q~nEnd Select", "conditional-case-body.bmx")
Local conditionalCaseBody:TSelectStatementSyntax = TSelectStatementSyntax(conditionalCaseBodyResult.syntaxTree.root.members[0])
Check(conditionalCaseBodyResult.syntaxTree.diagnostics.length = 0 And conditionalCaseBody.cases.length = 2, "Select accepts conditional regions inside a Case body")

Local conditionalSharedCaseBodyResult:TParseResult = TBlitzMaxParser.ParseText("Select value~n?Not ptr64~nCase 1~n?ptr64~nCase 2~n?~nPrint ~qshared~q~nCase 3~nPrint ~qother~q~nEnd Select", "conditional-shared-case-body.bmx")
Local conditionalSharedCaseBody:TSelectStatementSyntax = TSelectStatementSyntax(conditionalSharedCaseBodyResult.syntaxTree.root.members[0])
Check(conditionalSharedCaseBodyResult.syntaxTree.diagnostics.length = 0 And conditionalSharedCaseBody.cases.length = 3, "Select accepts conditional Case labels followed by a shared body")
Check(conditionalSharedCaseBody.cases[0].body.statements.length = 1 And conditionalSharedCaseBody.cases[1].body.statements.length = 1 And conditionalSharedCaseBody.cases[2].body.statements.length = 1, "each conditional Case alternative owns the shared body while the following ordinary Case remains separate")
Check(TConditionalRegionSyntax(conditionalCaseBody.cases[0].body.statements[0]) <> Null, "Case-body conditional remains an executable statement")

Local conditionalSharedDefaultBodyResult:TParseResult = TBlitzMaxParser.ParseText("Select value~n?Not ptr64~nDefault~n?ptr64~nCase 2~n?~nPrint ~qshared~q~nEnd Select", "conditional-shared-default-body.bmx")
Local conditionalSharedDefaultBody:TSelectStatementSyntax = TSelectStatementSyntax(conditionalSharedDefaultBodyResult.syntaxTree.root.members[0])
Check(conditionalSharedDefaultBodyResult.syntaxTree.diagnostics.length = 0 And conditionalSharedDefaultBody.defaultClauses.length = 1 And conditionalSharedDefaultBody.cases.length = 1 And conditionalSharedDefaultBody.defaultClauses[0].body.statements.length = 1 And conditionalSharedDefaultBody.cases[0].body.statements.length = 1, "conditional Default and Case alternatives can share the body after their closing directive")

Local inlineSelectResult:TParseResult = TBlitzMaxParser.ParseText("Select value~nCase 1 Print ~qone~q~nDefault Print ~qother~q~nEndSelect", "inline_select.bmx")
Check(inlineSelectResult.syntaxTree.diagnostics.length = 0, "same-line Select clause diagnostics")
Local inlineSelect:TSelectStatementSyntax = TSelectStatementSyntax(inlineSelectResult.syntaxTree.root.members[0])
Check(TCallStatementSyntax(inlineSelect.cases[0].body.statements[0]) <> Null, "same-line Case body")
Check(TCallStatementSyntax(inlineSelect.defaultClauses[0].body.statements[0]) <> Null, "same-line Default body")
Local compactCaseResult:TParseResult = TBlitzMaxParser.ParseText("Select value~nCase 1 Local n:Int Return n~nEnd Select", "compact-case.bmx")
Local compactCase:TSelectStatementSyntax = TSelectStatementSyntax(compactCaseResult.syntaxTree.root.members[0])
Check(compactCaseResult.syntaxTree.diagnostics.length = 0 And compactCase.cases[0].body.statements.length = 2, "compact Case retains adjacent declaration and flow statements")
Check(TVariableDeclarationStatementSyntax(compactCase.cases[0].body.statements[0]) And TReturnStatementSyntax(compactCase.cases[0].body.statements[1]), "compact Case statement kinds")

Local trySource:String = "Try~nDangerous()~nCatch ex:TSpecificError~nHandle ex~nCatch message:String~nPrint message~nFinally~nCleanup()~nEndTry"
Local tryResult:TParseResult = TBlitzMaxParser.ParseText(trySource, "try.bmx")
Check(tryResult.syntaxTree.diagnostics.length = 0, "Try diagnostics")
Local tryStatement:TTryStatementSyntax = TTryStatementSyntax(tryResult.syntaxTree.root.members[0])
Check(tryStatement <> Null And tryStatement.catches.length = 2, "Try Catch structure")
Check(tryStatement.catches[0].nameToken.text = "ex", "Catch value name")
Check(tryStatement.catches[0].declaredType <> Null, "Catch declared type")
Check(tryStatement.finallyClause <> Null, "Try Finally structure")
Check(tryStatement.terminator.actualBlockKind = "try", "Try terminator")

Local usingSource:String = "Using~nLocal first:TResource = OpenFirst()~nLocal second:TResource = OpenSecond()~nDo~nWhile first.MoveNext()~nPrint first.Current()~nWend~nEnd Using"
Local usingResult:TParseResult = TBlitzMaxParser.ParseText(usingSource, "using.bmx")
Check(usingResult.syntaxTree.diagnostics.length = 0, "Using diagnostics")
Local usingStatement:TUsingStatementSyntax = TUsingStatementSyntax(usingResult.syntaxTree.root.members[0])
Check(usingStatement <> Null And usingStatement.resources.length = 2, "Using resource declarations")
Check(usingStatement.doToken.text.ToLower() = "do", "Using Do boundary")
Check(TWhileStatementSyntax(usingStatement.body.statements[0]) <> Null, "structured body inside Using")
Check(usingStatement.terminator.actualBlockKind = "using", "Using terminator")

Local inlineUsingResult:TParseResult = TBlitzMaxParser.ParseText("Using Local tx:TTransaction = BeginTransaction()~nDo~ntx.Commit()~nEnd Using", "inline-using.bmx")
Check(inlineUsingResult.syntaxTree.diagnostics.length = 0, "inline Using Local diagnostics")
Local inlineUsing:TUsingStatementSyntax = TUsingStatementSyntax(inlineUsingResult.syntaxTree.root.members[0])
Check(inlineUsing.resources.length = 1 And inlineUsing.resources[0].declarators[0].nameToken.text = "tx", "inline Using Local resource")

Local parenthesizedReceiverCallResult:TParseResult = TBlitzMaxParser.ParseText("(root / ~qsub~q).CreateDir(True)", "parenthesized-receiver-call.bmx")
Check(parenthesizedReceiverCallResult.syntaxTree.diagnostics.length = 0, "parenthesized receiver call statement diagnostics")
Local parenthesizedReceiverCall:TCallStatementSyntax = TCallStatementSyntax(parenthesizedReceiverCallResult.syntaxTree.root.members[0])
Check(parenthesizedReceiverCall <> Null And parenthesizedReceiverCall.hasParentheses And TCallExpressionSyntax(parenthesizedReceiverCall.expression) <> Null, "member invocation on a parenthesized operator result remains a call statement")

Local conditionalRoutineSource:String = "Type TPlatformValue~n?Ptr64~nMethod Value:Long()~nLocal result:Long=1~n?Ptr32~nMethod Value:Int()~nLocal result:Int=1~n?~nReturn result~nEnd Method~nEnd Type"
Local conditionalRoutineResult:TParseResult = TBlitzMaxParser.ParseText(conditionalRoutineSource, "conditional-routine-header.bmx")
Check(conditionalRoutineResult.syntaxTree.diagnostics.length = 0, "conditional routine header diagnostics")
Local conditionalRoutineType:TTypeDeclarationSyntax = TTypeDeclarationSyntax(conditionalRoutineResult.syntaxTree.root.members[0])
Local conditionalRoutine:TConditionalRegionSyntax = TConditionalRegionSyntax(conditionalRoutineType.body.statements[0])
Check(conditionalRoutine.branches.length = 2, "conditional routine alternatives")
Check(TRoutineDeclarationSyntax(conditionalRoutine.branches[0].body.statements[0]).signature.returnType.nameTokens[0].text = "Long", "Ptr64 routine signature")
Check(TRoutineDeclarationSyntax(conditionalRoutine.branches[1].body.statements[0]).signature.returnType.nameTokens[0].text = "Int", "Ptr32 routine signature")
Check(conditionalRoutine.sharedRoutineBody <> Null, "conditional routine shared body exists")
Check(conditionalRoutine.sharedRoutineBody.statements.length = 1 And TRoutineDeclarationSyntax(conditionalRoutine.branches[0].body.statements[0]).body.statements.length = 2 And TRoutineDeclarationSyntax(conditionalRoutine.branches[1].body.statements[0]).body.statements.length = 2, "conditional routine branch prefixes combine with the shared body")
Check(TReturnStatementSyntax(conditionalRoutine.sharedRoutineBody.statements[0]) <> Null, "conditional routine shared return")
Check(conditionalRoutine.sharedRoutineTerminator.actualBlockKind = "method", "conditional routine shared terminator")

Local conditionalForHeaderSource:String = "?ptr64~nFor Local outer:Long=0 Until 2~nFor Local inner:Long=0 Until 2~n?Not ptr64~nFor Local outer:Int=0 Until 2~nFor Local inner:Int=0 Until 2~n?~nPrint outer+inner~nNext~nNext"
Local conditionalForHeaderResult:TParseResult = TBlitzMaxParser.ParseText(conditionalForHeaderSource, "conditional-for-header.bmx")
Check(conditionalForHeaderResult.syntaxTree.diagnostics.length = 0, "conditional For header alternatives may share their nested body and Next terminators")
Local conditionalForHeader:TConditionalRegionSyntax = TConditionalRegionSyntax(conditionalForHeaderResult.syntaxTree.root.members[0])
Local conditionalOuterFor:TForStatementSyntax = TForStatementSyntax(conditionalForHeader.branches[0].body.statements[0])
Local conditionalInnerFor:TForStatementSyntax = TForStatementSyntax(conditionalOuterFor.body.statements[0])
Check(conditionalForHeader.branches.length = 2 And conditionalOuterFor.terminator <> Null And conditionalInnerFor.terminator <> Null And conditionalInnerFor.body.statements.length = 1, "each conditional For header branch owns the shared nested loop structure")

Local conditionalIfHeaderSource:String = "?bmxng~nIf left <> right~n?Not bmxng~nIf left.ToString() <> right.ToString()~n?~nPrint 1~nElse~nPrint 2~nEndIf"
Local conditionalIfHeaderResult:TParseResult = TBlitzMaxParser.ParseText(conditionalIfHeaderSource, "conditional-if-header.bmx")
Check(conditionalIfHeaderResult.syntaxTree.diagnostics.length = 0, "conditional If header alternatives may share their body, Else clause, and EndIf")
Local conditionalIfHeader:TConditionalRegionSyntax = TConditionalRegionSyntax(conditionalIfHeaderResult.syntaxTree.root.members[0])
Local conditionalFirstIf:TIfStatementSyntax = TIfStatementSyntax(conditionalIfHeader.branches[0].body.statements[0])
Local conditionalSecondIf:TIfStatementSyntax = TIfStatementSyntax(conditionalIfHeader.branches[1].body.statements[0])
Check(conditionalIfHeader.branches.length = 2 And conditionalFirstIf.terminator <> Null And conditionalSecondIf.terminator <> Null, "each conditional If header branch owns the shared terminator")
Check(conditionalFirstIf.thenBlock.statements.length = 1 And conditionalSecondIf.thenBlock.statements.length = 1 And conditionalFirstIf.elseClause <> Null And conditionalSecondIf.elseClause <> Null, "each conditional If header branch owns the shared body and Else clause")

Local conditionalElseSource:String = "Function SelectValue:Int(flag:Int)~nIf flag~nReturn 1~n?debug~nElse~nReturn 2~n?~nEndIf~nReturn 3~nEnd Function"
Local conditionalElseResult:TParseResult = TBlitzMaxParser.ParseText(conditionalElseSource, "conditional-else.bmx")
Local conditionalElseRoutine:TRoutineDeclarationSyntax = TRoutineDeclarationSyntax(conditionalElseResult.syntaxTree.root.members[0])
Local conditionalElseIf:TIfStatementSyntax = TIfStatementSyntax(conditionalElseRoutine.body.statements[0])
Check(conditionalElseResult.syntaxTree.diagnostics.length = 0 And conditionalElseIf <> Null And conditionalElseIf.elseClause <> Null And conditionalElseIf.terminator <> Null, "a conditional region may introduce Else between an ordinary If and EndIf")
Local conditionalElseRegion:TConditionalRegionSyntax = TConditionalRegionSyntax(conditionalElseIf.elseClause.block.statements[0])
Check(conditionalElseIf.thenBlock.statements.length = 1 And conditionalElseRegion <> Null And conditionalElseRegion.branches[0].body.statements.length = 1 And TReturnStatementSyntax(conditionalElseRegion.branches[0].body.statements[0]) <> Null, "conditional Else retains its selected body outside the If then-body")

Local conditionalTypeFunctionSource:String = "Type TPlatformFactory~n?Not win32~nFunction Create:TPlatformFactory(handle:Int)~n?win32 And ptr32~nFunction Create:TPlatformFactory(handle:Int)~n?win32 And ptr64~nFunction Create:TPlatformFactory(handle:Long)~n?~nReturn New TPlatformFactory~nEnd Function~nFunction CreateDefault:TPlatformFactory()~n?ptr64~nLocal handle:Long=1~n?Not ptr64~nLocal handle:Int=1~n?~nReturn Create(handle)~nEnd Function~nEnd Type"
Local conditionalTypeFunctionResult:TParseResult = TBlitzMaxParser.ParseText(conditionalTypeFunctionSource, "conditional-type-function-header.bmx")
Check(conditionalTypeFunctionResult.syntaxTree.diagnostics.length = 0, "conditional Type-function header and following Type function diagnostics")
Local conditionalTypeFunctionType:TTypeDeclarationSyntax = TTypeDeclarationSyntax(conditionalTypeFunctionResult.syntaxTree.root.members[0])
Local conditionalTypeFunction:TConditionalRegionSyntax = TConditionalRegionSyntax(conditionalTypeFunctionType.body.statements[0])
Check(conditionalTypeFunction.sharedRoutineTerminator.actualBlockKind = "function" And Not TRoutineDeclarationSyntax(conditionalTypeFunctionType.body.statements[1]).isMethod, "conditional Type-function body retains its Function terminator and does not consume the following declaration")

Local conditionalIfTerminatorSource:String = "Function PlatformPath:String()~n?Not win32~nReturn ~q~q~n?win32~nIf Not cached Then~nLocal path:String~n?win32x86~npath = ~qx86~q~n?win32x64~npath = ~qx64~q~n?win32~ncached = path~nEnd If~nReturn cached~n?~nEnd Function"
Local conditionalIfTerminatorResult:TParseResult = TBlitzMaxParser.ParseText(conditionalIfTerminatorSource, "conditional-if-terminator.bmx")
Check(conditionalIfTerminatorResult.syntaxTree.diagnostics.length = 0, "conditional region may supply an enclosing If terminator")
Local conditionalIfRoutine:TRoutineDeclarationSyntax = TRoutineDeclarationSyntax(conditionalIfTerminatorResult.syntaxTree.root.members[0])
Local conditionalIfOuter:TConditionalRegionSyntax = TConditionalRegionSyntax(conditionalIfRoutine.body.statements[0])
Local conditionalIf:TIfStatementSyntax = TIfStatementSyntax(conditionalIfOuter.branches[1].body.statements[0])
Check(conditionalIf <> Null And conditionalIf.terminator <> Null And conditionalIf.terminator.actualBlockKind = "if", "conditional If retains its cross-region terminator")
Check(conditionalIfOuter.branches[1].body.statements.length = 2 And TConditionalRegionSyntax(conditionalIfOuter.branches[1].body.statements[1]) <> Null, "statements after the conditional If terminator remain in the enclosing conditional branch")

Local conditionalElseTerminatorSource:String = "Function MultiSys:Int(outer:Int)~nIf outer~nLocal threaded:Int~n?threaded~nthreaded = True~nIf threaded Then~nReturn 1~nElse~n?~nReturn 2~n?threaded~nEnd If~n?~nEnd If~nEnd Function"
Local conditionalElseTerminatorResult:TParseResult = TBlitzMaxParser.ParseText(conditionalElseTerminatorSource, "conditional-else-terminator.bmx")
Check(conditionalElseTerminatorResult.syntaxTree.diagnostics.length = 0, "conditional region may supply an inner If terminator after a shared Else body")
Local conditionalElseTerminatorRoutine:TRoutineDeclarationSyntax = TRoutineDeclarationSyntax(conditionalElseTerminatorResult.syntaxTree.root.members[0])
Local conditionalElseTerminatorOuterIf:TIfStatementSyntax = TIfStatementSyntax(conditionalElseTerminatorRoutine.body.statements[0])
Local conditionalElseTerminatorRegion:TConditionalRegionSyntax = TConditionalRegionSyntax(conditionalElseTerminatorOuterIf.thenBlock.statements[1])
Local conditionalElseTerminatorInnerIf:TIfStatementSyntax = TIfStatementSyntax(conditionalElseTerminatorRegion.branches[0].body.statements[1])
Check(conditionalElseTerminatorInnerIf.terminator <> Null And conditionalElseTerminatorOuterIf.terminator <> Null And conditionalElseTerminatorInnerIf.terminator.span.start < conditionalElseTerminatorOuterIf.terminator.span.start, "conditional and ordinary End If tokens close their respective nested statements")
Check(conditionalElseTerminatorInnerIf.elseClause <> Null And conditionalElseTerminatorInnerIf.elseClause.block.statements.length = 3 And TReturnStatementSyntax(conditionalElseTerminatorInnerIf.elseClause.block.statements[1]) <> Null, "shared Else statements remain attached to the conditionally terminated inner If")

Local conditionalElseIfTerminatorSource:String = "Function Choose:Int(outer:Int)~nIf outer~n?threaded~nIf outer Then~nReturn 1~nElseIf Not outer Then~n?~nReturn 2~n?threaded~nEnd If~n?~nEnd If~nEnd Function"
Local conditionalElseIfTerminatorResult:TParseResult = TBlitzMaxParser.ParseText(conditionalElseIfTerminatorSource, "conditional-elseif-terminator.bmx")
Check(conditionalElseIfTerminatorResult.syntaxTree.diagnostics.length = 0, "conditional region may supply an inner If terminator after a shared ElseIf body")
Local conditionalElseIfTerminatorRoutine:TRoutineDeclarationSyntax = TRoutineDeclarationSyntax(conditionalElseIfTerminatorResult.syntaxTree.root.members[0])
Local conditionalElseIfTerminatorOuterIf:TIfStatementSyntax = TIfStatementSyntax(conditionalElseIfTerminatorRoutine.body.statements[0])
Local conditionalElseIfTerminatorRegion:TConditionalRegionSyntax = TConditionalRegionSyntax(conditionalElseIfTerminatorOuterIf.thenBlock.statements[0])
Local conditionalElseIfTerminatorInnerIf:TIfStatementSyntax = TIfStatementSyntax(conditionalElseIfTerminatorRegion.branches[0].body.statements[0])
Check(conditionalElseIfTerminatorInnerIf.elseIfClauses.length = 1 And conditionalElseIfTerminatorInnerIf.terminator.span.start < conditionalElseIfTerminatorOuterIf.terminator.span.start, "conditional End If after ElseIf does not consume the enclosing runtime terminator")

Local missingResult:TParseResult = TBlitzMaxParser.ParseText("Function Missing()~nPrint ~qstill parsed~q", "missing.bmx")
Check(missingResult.syntaxTree.diagnostics.length = 1, "missing terminator diagnostic count")
Check(missingResult.syntaxTree.diagnostics[0].code = "BMX2001", "missing terminator diagnostic code")

Local inlineRoutineSource:String = "Type TLayout~nMethod IsABlob:Int() Return True End Method~nMethod Something:Int()~nReturn 10~nEnd Method~nEnd Type"
Local inlineRoutineResult:TParseResult = TBlitzMaxParser.ParseText(inlineRoutineSource, "inline-routine.bmx")
Check(inlineRoutineResult.syntaxTree.diagnostics.length = 0, "same-line routine body and terminator diagnostics")
Local inlineRoutineType:TTypeDeclarationSyntax = TTypeDeclarationSyntax(inlineRoutineResult.syntaxTree.root.members[0])
Check(inlineRoutineType.body.statements.length = 2, "same-line routine does not consume the following type members")
Local inlineRoutine:TRoutineDeclarationSyntax = TRoutineDeclarationSyntax(inlineRoutineType.body.statements[0])
Check(inlineRoutine.body.statements.length = 1 And TReturnStatementSyntax(inlineRoutine.body.statements[0]) <> Null, "same-line routine retains its Return statement")
Check(inlineRoutine.terminator.actualBlockKind = "method", "same-line routine retains its End Method terminator")

Local incompleteExpressionResult:TParseResult = TBlitzMaxParser.ParseText("SuperStrict~nLocal value:Int = 1 +", "incomplete-expression.bmx")
Check(incompleteExpressionResult.syntaxTree.diagnostics.length > 0, "expression ending in an operator reports a recoverable diagnostic")
Local deepExpressionSource:String = "SuperStrict~nLocal value:Int = "
For Local depth:Int = 0 Until 600
	deepExpressionSource :+ "Not "
Next
deepExpressionSource :+ "True"
Local deepExpressionResult:TParseResult = TBlitzMaxParser.ParseText(deepExpressionSource, "deep-expression.bmx")
Local depthDiagnosticFound:Int
For Local diagnostic:TDiagnostic = EachIn deepExpressionResult.syntaxTree.diagnostics
	If diagnostic.code = "BMX2103" Then depthDiagnosticFound = True
Next
Check(depthDiagnosticFound, "excessive expression nesting is bounded by a recoverable diagnostic")

Local extendedSizeOfResult:TParseResult = TBlitzMaxParser.ParseText("SuperStrict~nLocal a:Int = SizeOf(Float64 Null)~nLocal b:Int = SizeOf(Float128 Null)~nLocal c:Int = SizeOf(Double128 Null)~nLocal d:Int = SizeOf(Int128 Null)", "extended-sizeof-defaults.bmx")
Check(extendedSizeOfResult.syntaxTree.diagnostics.length = 0, "extended numeric builtins accept legacy prefix-cast default expressions inside SizeOf")

Local dump:String = TSyntaxDumper.Dump(routineResult.syntaxTree)
Check(dump.Find("EndStatement") >= 0 And dump.Find("BlockTerminator") >= 0, "syntax dump contains contextual End nodes")

Local functionLiteralParse:TParseResult = TBlitzMaxParser.ParseText("SuperStrict~nLocal add:Int(value:Int) = Function(value)~nReturn value + 1~nEnd Function~nLocal answer:Int = add(41)", "function-literal.bmx")
Check(functionLiteralParse.syntaxTree.diagnostics.length = 0, "block Function literal parses without recovery diagnostics")
Local functionLiteralDeclaration:TVariableDeclarationStatementSyntax = TVariableDeclarationStatementSyntax(functionLiteralParse.syntaxTree.root.members[1])
Local functionLiteral:TFunctionLiteralExpressionSyntax = TFunctionLiteralExpressionSyntax(functionLiteralDeclaration.declarators[0].initializer)
Check(functionLiteral And functionLiteral.parameters.length = 1 And functionLiteral.body.statements.length = 1, "Function literal retains contextual parameters and block body")
Check(functionLiteral.terminator And functionLiteral.terminator.actualBlockKind = "function", "Function literal retains End Function terminator")
Local functionLiteralNavigator:TSyntaxNavigator = TSyntaxNavigator.Create(functionLiteralParse.syntaxTree)
Check(functionLiteralNavigator.ContainsNode(functionLiteral.body) And functionLiteralNavigator.Parent(functionLiteral.body) = functionLiteral, "syntax navigation indexes Function literal body")
Check(TSyntaxDumper.Dump(functionLiteralParse.syntaxTree).Find("FunctionLiteralExpression") >= 0, "syntax dump includes Function literal node")

Local closureTypeParse:TParseResult = TBlitzMaxParser.ParseText("SuperStrict~nLocal add:Closure<Int(value:Int)>~nLocal notify:Closure<()>~nLocal factory:Closure<Closure<Int()>()>~nLocal apply:Closure<Int(callback:Closure<Int()>)>", "closure-type.bmx")
Check(closureTypeParse.syntaxTree.diagnostics.length = 0, "explicit managed Closure signatures parse without recovery diagnostics")
Local closureDeclaration:TVariableDeclarationStatementSyntax = TVariableDeclarationStatementSyntax(closureTypeParse.syntaxTree.root.members[1])
Local closureTypeSyntax:TTypeReferenceSyntax = closureDeclaration.declarators[0].declaredType
Check(closureTypeSyntax And closureTypeSyntax.closureSignature And closureTypeSyntax.closureSignature.parameters.length = 1, "Closure retains its named parameter signature in type syntax")
Local closureFactoryDeclaration:TVariableDeclarationStatementSyntax = TVariableDeclarationStatementSyntax(closureTypeParse.syntaxTree.root.members[3])
Local closureFactoryType:TTypeReferenceSyntax = closureFactoryDeclaration.declarators[0].declaredType
Check(closureFactoryType And closureFactoryType.closureSignature And closureFactoryType.closureSignature.returnType And closureFactoryType.closureSignature.returnType.closureSignature, "Closure return types recursively retain their own managed signature syntax")
Local closureApplyDeclaration:TVariableDeclarationStatementSyntax = TVariableDeclarationStatementSyntax(closureTypeParse.syntaxTree.root.members[4])
Local closureApplyType:TTypeReferenceSyntax = closureApplyDeclaration.declarators[0].declaredType
Check(closureApplyType.closureSignature.parameters[0].declaredType.closureSignature <> Null, "Closure parameters recursively retain their own managed signature syntax")

Print "bcc2 source-model tests passed"
