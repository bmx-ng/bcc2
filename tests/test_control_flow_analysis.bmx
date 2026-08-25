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

Function HasEdge:Int(graph:TControlFlowGraph, kind:Int)
	For Local edge:TControlFlowEdge = EachIn graph.edges
		If edge.kind = kind Then Return True
	Next
	Return False
End Function

Function BlockForStatement:TControlFlowBlock(graph:TControlFlowGraph, statement:TBoundStatement)
	For Local block:TControlFlowBlock = EachIn graph.blocks
		If block.statement = statement Then Return block
	Next
	Return Null
End Function

Function BoundVariableName:String(statement:TBoundStatement)
	Local declaration:TBoundVariableDeclarationStatement = TBoundVariableDeclarationStatement(statement)
	If declaration And declaration.variables.length And declaration.variables[0].symbol Then Return declaration.variables[0].symbol.name
	Return ""
End Function

Local validSource:String = "SuperStrict~nFunction Choose:Int(value:Int)~nIf value~nReturn 1~nElse~nReturn 2~nEnd If~nEnd Function~nFunction Spin:Int()~nRepeat~nForever~nEnd Function~nFunction Walk()~n#outer~nFor Local i:Int = 0 Until 3~nWhile i~nContinue outer~nWend~nExit outer~nNext~nEnd Function~nFunction Cleanup:Int()~nTry~nReturn 1~nFinally~nLocal cleaned:Int = 1~nEnd Try~nEnd Function"
Local validParse:TParseResult = TBlitzMaxParser.ParseText(validSource, "valid-control-flow.bmx")
Local validModel:TSemanticModel = TBlitzMaxSemanticAnalyzer.Analyze(validParse.syntaxTree)
TExpressionBinder.Bind(validModel)
TControlFlowAnalyzer.Analyze(validModel)
Check(validModel.diagnostics.length = 0, "valid control-flow diagnostics")

Local choose:TSymbol = validModel.globalScope.LookupLocal("Choose")[0]
Local chooseGraph:TControlFlowGraph = validModel.ControlFlowGraph(choose)
Check(chooseGraph <> Null And chooseGraph.allPathsTerminate And Not chooseGraph.canFallThrough, "all If branches terminate value-returning routine")
Check(HasEdge(chooseGraph, CONTROL_FLOW_EDGE_TRUE) And HasEdge(chooseGraph, CONTROL_FLOW_EDGE_FALSE), "If graph has true and false edges")
Check(HasEdge(chooseGraph, CONTROL_FLOW_EDGE_RETURN), "return statements connect to routine exit")

Local spin:TSymbol = validModel.globalScope.LookupLocal("Spin")[0]
Check(validModel.ControlFlowGraph(spin).allPathsTerminate, "Forever loop prevents routine fallthrough")

Local walk:TSymbol = validModel.globalScope.LookupLocal("Walk")[0]
Local walkGraph:TControlFlowGraph = validModel.ControlFlowGraph(walk)
Check(HasEdge(walkGraph, CONTROL_FLOW_EDGE_CONTINUE), "labelled Continue resolves to outer loop")
Check(HasEdge(walkGraph, CONTROL_FLOW_EDGE_EXIT), "labelled Exit resolves to outer loop")
Check(TControlFlowDumper.Dump(walkGraph).Contains("continue-loop"), "control-flow graph can be dumped")
Local cleanup:TSymbol = validModel.globalScope.LookupLocal("Cleanup")[0]
Check(validModel.ControlFlowGraph(cleanup).allPathsTerminate, "exceptional Finally path is not ordinary routine fallthrough")

Local globalReturnParse:TParseResult = TBlitzMaxParser.ParseText("Strict~nReturn~nLocal unreachable:Int = 1", "global-return-control-flow.bmx")
Local globalReturnModel:TSemanticModel = TBlitzMaxSemanticAnalyzer.Analyze(globalReturnParse.syntaxTree)
TExpressionBinder.Bind(globalReturnModel)
TControlFlowAnalyzer.Analyze(globalReturnModel)
Check(Not HasDiagnostic(globalReturnModel.diagnostics, "BMX3406"), "module-level Return exits the implicit global entry routine")
Check(HasDiagnostic(globalReturnModel.diagnostics, "BMX3401"), "module-level Return makes following statements unreachable")

Local emptyConditionalAfterReturnParse:TParseResult = TBlitzMaxParser.ParseText("SuperStrict~nFunction Finish()~nReturn~n?bmxng~n?~nEnd Function", "empty-conditional-after-return.bmx")
Local emptyConditionalAfterReturnModel:TSemanticModel = TBlitzMaxSemanticAnalyzer.Analyze(emptyConditionalAfterReturnParse.syntaxTree)
TExpressionBinder.Bind(emptyConditionalAfterReturnModel)
TControlFlowAnalyzer.Analyze(emptyConditionalAfterReturnModel)
Check(Not HasDiagnostic(emptyConditionalAfterReturnModel.diagnostics, "BMX3401"), "an empty compile-time region after Return is not a runtime unreachable statement")

Local inlineGuardSource:String = "SuperStrict~nFunction Print(message:String)~nEnd Function~nFunction IsRoomOwner:Int(figure:Object, room:Object)~nIf Not room Then Print ~qIsRoomOwner: room-object is null.~q;Return False~nIf Not figure Then Print ~qIsRoomOwner: figure-object is null.~q;Return False~nIf Not figure Then Return False~nReturn True~nEnd Function"
Local inlineGuardParse:TParseResult = TBlitzMaxParser.ParseText(inlineGuardSource, "inline-guard-control-flow.bmx")
Local inlineGuardModel:TSemanticModel = TBlitzMaxSemanticAnalyzer.Analyze(inlineGuardParse.syntaxTree)
TExpressionBinder.Bind(inlineGuardModel)
TControlFlowAnalyzer.Analyze(inlineGuardModel)
Check(inlineGuardModel.diagnostics.length = 0, "semicolon Returns remain conditional in single-line guard clauses")
Local roomOwner:TSymbol = inlineGuardModel.globalScope.LookupLocal("IsRoomOwner")[0]
Local roomOwnerBody:TBoundBlockStatement = inlineGuardModel.BoundRoutineBody(roomOwner)
Check(TBoundIfStatement(roomOwnerBody.statements[0]).thenBody.statements.length = 2 And TBoundIfStatement(roomOwnerBody.statements[1]).thenBody.statements.length = 2, "bound single-line guards retain both Then statements")

Local invalidSource:String = "SuperStrict~nFunction Missing:Int(value:Int)~nIf value~nReturn 1~nEnd If~nEnd Function~nFunction Dead()~nReturn~nLocal unreachable:Int = 1~nEnd Function~nFunction BadFlow()~nExit~nContinue~nContinue nowhere~nEnd Function"
Local defaultReturnParse:TParseResult = TBlitzMaxParser.ParseText("SuperStrict~nFunction Defaulted:Int()~nEnd Function", "implicit-default-return.bmx")
Local defaultReturnModel:TSemanticModel = TBlitzMaxSemanticAnalyzer.Analyze(defaultReturnParse.syntaxTree)
TExpressionBinder.Bind(defaultReturnModel)
TControlFlowAnalyzer.Analyze(defaultReturnModel)
Check(Not HasDiagnostic(defaultReturnModel.diagnostics, "BMX3400"), "BlitzMax implicit default return is accepted by default")
Local invalidParse:TParseResult = TBlitzMaxParser.ParseText(invalidSource, "invalid-control-flow.bmx")
Local invalidModel:TSemanticModel = TBlitzMaxSemanticAnalyzer.Analyze(invalidParse.syntaxTree)
TExpressionBinder.Bind(invalidModel)
Local controlOptions:TControlFlowAnalysisOptions = TControlFlowAnalysisOptions.Create()
controlOptions.reportImplicitDefaultReturns = True
TControlFlowAnalyzer.Analyze(invalidModel, controlOptions)
Check(HasDiagnostic(invalidModel.diagnostics, "BMX3400"), "missing return diagnostic")
For Local diagnostic:TDiagnostic = EachIn invalidModel.diagnostics
	If diagnostic.code = "BMX3400" Then Check(diagnostic.severity = DIAGNOSTIC_WARNING, "implicit default return lint is a warning")
Next
Check(HasDiagnostic(invalidModel.diagnostics, "BMX3401"), "unreachable statement diagnostic")
Check(HasDiagnostic(invalidModel.diagnostics, "BMX3402"), "Exit outside loop diagnostic")
Check(HasDiagnostic(invalidModel.diagnostics, "BMX3403"), "Continue outside loop diagnostic")
Check(HasDiagnostic(invalidModel.diagnostics, "BMX3404"), "unknown Continue label diagnostic")

Local cleanupSource:String = "SuperStrict~nType TFlowProblem~nEnd Type~nFunction NestedCleanup:Int()~nTry~nTry~nReturn 1~nFinally~nLocal innerCleanup:Int = 1~nEnd Try~nFinally~nLocal outerCleanup:Int = 1~nEnd Try~nEnd Function~nFunction Raise()~nTry~nThrow New TFlowProblem~nFinally~nLocal throwCleanup:Int = 1~nEnd Try~nEnd Function~nFunction ExitAcross(flag:Int)~n#outer~nWhile flag~nTry~nExit outer~nFinally~nLocal exitCleanup:Int = 1~nEnd Try~nWend~nEnd Function~nFunction ExitWithin(flag:Int)~nTry~nWhile flag~nExit~nWend~nFinally~nLocal normalCleanup:Int = 1~nEnd Try~nEnd Function~nFunction ContinueAcross(flag:Int)~n#outer~nWhile flag~nTry~nContinue outer~nFinally~nLocal continueCleanup:Int = 1~nEnd Try~nWend~nEnd Function~nFunction OverrideReturn:Int()~nTry~nReturn 1~nFinally~nReturn 2~nEnd Try~nEnd Function~nFunction CatchReturn:Int()~nTry~nThrow New TFlowProblem~nCatch problem:TFlowProblem~nReturn 3~nFinally~nLocal catchCleanup:Int = 1~nEnd Try~nEnd Function~nFunction ReadProtected()~nLocal target:Int~nTry~nReadData target~nFinally~nLocal readCleanup:Int = 1~nEnd Try~nEnd Function"
Local cleanupParse:TParseResult = TBlitzMaxParser.ParseText(cleanupSource, "finally-routing.bmx")
Local cleanupModel:TSemanticModel = TBlitzMaxSemanticAnalyzer.Analyze(cleanupParse.syntaxTree)
TExpressionBinder.Bind(cleanupModel)
TControlFlowAnalyzer.Analyze(cleanupModel)
Check(cleanupModel.diagnostics.length = 0, "precise Finally routing diagnostics")

Local nestedCleanup:TSymbol = cleanupModel.globalScope.LookupLocal("NestedCleanup")[0]
Local nestedGraph:TControlFlowGraph = cleanupModel.ControlFlowGraph(nestedCleanup)
Local nestedBody:TBoundBlockStatement = cleanupModel.BoundRoutineBody(nestedCleanup)
Local outerTry:TBoundTryStatement = TBoundTryStatement(nestedBody.statements[0])
Local innerTry:TBoundTryStatement = TBoundTryStatement(outerTry.body.statements[0])
Local nestedReturnBlock:TControlFlowBlock = BlockForStatement(nestedGraph, innerTry.body.statements[0])
Local innerCleanupBlock:TControlFlowBlock = nestedReturnBlock.outgoing[0].target
Local outerCleanupBlock:TControlFlowBlock = innerCleanupBlock.outgoing[0].target
Check(BoundVariableName(innerCleanupBlock.statement) = "innerCleanup", "Return first executes innermost Finally")
Check(BoundVariableName(outerCleanupBlock.statement) = "outerCleanup", "Return then executes enclosing Finally")
Check(outerCleanupBlock.outgoing[0].kind = CONTROL_FLOW_EDGE_RETURN And outerCleanupBlock.outgoing[0].target = nestedGraph.exitBlock, "Return reaches routine exit only after all cleanup")

Local raiseRoutine:TSymbol = cleanupModel.globalScope.LookupLocal("Raise")[0]
Local raiseGraph:TControlFlowGraph = cleanupModel.ControlFlowGraph(raiseRoutine)
Local raiseTry:TBoundTryStatement = TBoundTryStatement(cleanupModel.BoundRoutineBody(raiseRoutine).statements[0])
Local throwBlock:TControlFlowBlock = BlockForStatement(raiseGraph, raiseTry.body.statements[0])
Local throwCleanupBlock:TControlFlowBlock = throwBlock.outgoing[0].target
Check(BoundVariableName(throwCleanupBlock.statement) = "throwCleanup", "Throw executes Finally before propagation")
Check(throwCleanupBlock.outgoing[0].kind = CONTROL_FLOW_EDGE_THROW, "Throw propagates only after cleanup")

Local exitAcrossRoutine:TSymbol = cleanupModel.globalScope.LookupLocal("ExitAcross")[0]
Local exitAcrossGraph:TControlFlowGraph = cleanupModel.ControlFlowGraph(exitAcrossRoutine)
Local exitAcrossLoop:TBoundWhileStatement = TBoundWhileStatement(cleanupModel.BoundRoutineBody(exitAcrossRoutine).statements[0])
Local exitAcrossTry:TBoundTryStatement = TBoundTryStatement(exitAcrossLoop.body.statements[0])
Local crossingExitBlock:TControlFlowBlock = BlockForStatement(exitAcrossGraph, exitAcrossTry.body.statements[0])
Local exitCleanupBlock:TControlFlowBlock = crossingExitBlock.outgoing[0].target
Check(BoundVariableName(exitCleanupBlock.statement) = "exitCleanup", "Exit crossing a Try boundary executes Finally")
Check(exitCleanupBlock.outgoing[0].kind = CONTROL_FLOW_EDGE_EXIT, "Exit reaches loop target after cleanup")

Local exitWithinRoutine:TSymbol = cleanupModel.globalScope.LookupLocal("ExitWithin")[0]
Local exitWithinGraph:TControlFlowGraph = cleanupModel.ControlFlowGraph(exitWithinRoutine)
Local exitWithinTry:TBoundTryStatement = TBoundTryStatement(cleanupModel.BoundRoutineBody(exitWithinRoutine).statements[0])
Local exitWithinLoop:TBoundWhileStatement = TBoundWhileStatement(exitWithinTry.body.statements[0])
Local internalExitBlock:TControlFlowBlock = BlockForStatement(exitWithinGraph, exitWithinLoop.body.statements[0])
Check(internalExitBlock.outgoing[0].kind = CONTROL_FLOW_EDGE_EXIT And internalExitBlock.outgoing[0].target.statement = Null, "Exit staying inside a Try does not execute Finally early")

Local continueAcrossRoutine:TSymbol = cleanupModel.globalScope.LookupLocal("ContinueAcross")[0]
Local continueAcrossGraph:TControlFlowGraph = cleanupModel.ControlFlowGraph(continueAcrossRoutine)
Local continueAcrossLoop:TBoundWhileStatement = TBoundWhileStatement(cleanupModel.BoundRoutineBody(continueAcrossRoutine).statements[0])
Local continueAcrossTry:TBoundTryStatement = TBoundTryStatement(continueAcrossLoop.body.statements[0])
Local crossingContinueBlock:TControlFlowBlock = BlockForStatement(continueAcrossGraph, continueAcrossTry.body.statements[0])
Local continueCleanupBlock:TControlFlowBlock = crossingContinueBlock.outgoing[0].target
Check(BoundVariableName(continueCleanupBlock.statement) = "continueCleanup", "Continue crossing a Try boundary executes Finally")
Check(continueCleanupBlock.outgoing[0].kind = CONTROL_FLOW_EDGE_CONTINUE, "Continue reaches loop header after cleanup")

Local overrideRoutine:TSymbol = cleanupModel.globalScope.LookupLocal("OverrideReturn")[0]
Local overrideGraph:TControlFlowGraph = cleanupModel.ControlFlowGraph(overrideRoutine)
Local overrideTry:TBoundTryStatement = TBoundTryStatement(cleanupModel.BoundRoutineBody(overrideRoutine).statements[0])
Local originalReturnBlock:TControlFlowBlock = BlockForStatement(overrideGraph, overrideTry.body.statements[0])
Local finallyReturnBlock:TControlFlowBlock = originalReturnBlock.outgoing[0].target
Check(TBoundReturnStatement(finallyReturnBlock.statement) <> Null, "Return in Finally replaces the pending Return path")
Check(finallyReturnBlock.outgoing[0].kind = CONTROL_FLOW_EDGE_RETURN And finallyReturnBlock.outgoing[0].target = overrideGraph.exitBlock, "replacement Return reaches routine exit")

Local catchRoutine:TSymbol = cleanupModel.globalScope.LookupLocal("CatchReturn")[0]
Local catchGraph:TControlFlowGraph = cleanupModel.ControlFlowGraph(catchRoutine)
Local catchTry:TBoundTryStatement = TBoundTryStatement(cleanupModel.BoundRoutineBody(catchRoutine).statements[0])
Local caughtReturnBlock:TControlFlowBlock = BlockForStatement(catchGraph, catchTry.catches[0].body.statements[0])
Local catchCleanupBlock:TControlFlowBlock = caughtReturnBlock.outgoing[0].target
Check(BoundVariableName(catchCleanupBlock.statement) = "catchCleanup", "Return from Catch executes the associated Finally")
Check(catchCleanupBlock.outgoing[0].kind = CONTROL_FLOW_EDGE_RETURN, "Catch Return resumes after cleanup")

Local readProtectedRoutine:TSymbol = cleanupModel.globalScope.LookupLocal("ReadProtected")[0]
Local readProtectedGraph:TControlFlowGraph = cleanupModel.ControlFlowGraph(readProtectedRoutine)
Local readProtectedTry:TBoundTryStatement = TBoundTryStatement(cleanupModel.BoundRoutineBody(readProtectedRoutine).statements[1])
Local protectedReadBlock:TControlFlowBlock = BlockForStatement(readProtectedGraph, readProtectedTry.body.statements[0])
Local foundOutOfDataCleanup:Int
For Local readEdge:TControlFlowEdge = EachIn protectedReadBlock.outgoing
	If BoundVariableName(readEdge.target.statement) <> "readCleanup" Then Continue
	For Local cleanupEdge:TControlFlowEdge = EachIn readEdge.target.outgoing
		If cleanupEdge.kind = CONTROL_FLOW_EDGE_OUT_OF_DATA Then foundOutOfDataCleanup = True
	Next
Next
Check(foundOutOfDataCleanup, "ReadData exhaustion executes Finally before its exceptional edge")

Print "bcc2 control-flow analysis tests passed"
