SuperStrict

Framework BRL.StandardIO

Import BlitzMax.Language

Function Check(condition:Int, message:String)
	If Not condition Then Throw message
End Function

Type TImmediateLanguageCancellation Extends TLanguageCancellationToken
	Method IsCancellationRequested:Int() Override
		Return True
	End Method
End Type

Local source:String = "SuperStrict~nConst Answer:Int = 40 + 2~nRem~nbbdoc: Doubles a value.~nreturns: The doubled value.~nparam: The @value to double.~nabout: Uses simple multiplication.~nEnd Rem~nFunction Twice:Int(value:Int)~nReturn value * 2~nEnd Function~nRem~nThis is not bbdoc.~nEnd Rem~nType TUndocumented~nEnd Type~nLocal result:Int = Twice(Answer)"
Local analysis:TLanguageAnalysis = TBlitzMaxLanguage.AnalyzeText(source, "module-smoke.bmx")
Check(analysis.Succeeded(), "unified module analysis succeeds")
Check(analysis.syntaxTree <> Null And analysis.model <> Null, "analysis exposes syntax and semantic models")
Local answer:TSymbol = analysis.model.globalScope.LookupLocal("Answer")[0]
Check(analysis.model.SymbolConstantValue(answer).integerValue = 42, "unified pipeline evaluates constants")
Local twice:TSymbol = analysis.model.globalScope.LookupLocal("Twice")[0]
Check(twice.documentation <> Null And twice.documentation.summary = "Doubles a value.", "language model associates bbdoc with declarations")
Check(twice.documentation.parameters.length = 1 And twice.documentation.parameters[0] = "The @value to double.", "language model retains ordered parameter documentation")
Check(twice.documentation.returnsDescription = "The doubled value." And twice.documentation.about = "Uses simple multiplication.", "language model parses returns and about sections")
Check(analysis.model.globalScope.LookupLocal("TUndocumented")[0].documentation = Null, "Rem blocks without bbdoc do not become documentation")
Check(analysis.model.BoundRoutineBody(twice) <> Null, "unified pipeline builds bound routines")
Check(analysis.model.ControlFlowGraph(twice) <> Null, "unified pipeline builds control flow")
Check(analysis.model.dataSection <> Null, "unified pipeline builds application data model")

Local genericTypeFunctionReferenceSource:String = "SuperStrict~nType TGenericFunctions<T>~nFunction Identity:T(value:T)~nReturn value~nEnd Function~nEnd Type~nLocal callback:Int(value:Int)=TGenericFunctions<Int>.Identity~nLocal result:Int=callback(42)"
Local genericTypeFunctionReference:TLanguageAnalysis = TBlitzMaxLanguage.AnalyzeText(genericTypeFunctionReferenceSource, "generic-type-function-reference.bmx")
Local genericTypeFunctionCallback:TSymbol = genericTypeFunctionReference.model.globalScope.LookupLocal("callback")[0]
Check(genericTypeFunctionReference.Succeeded() And genericTypeFunctionCallback.declaredType.DisplayName() = "Int(Int)", "generic Type Function references substitute the closed owner arguments into their callable signature")

Local pragmaSource:String = "SuperStrict~n'@bmk addccopt outer -DOUTER_PRAGMA~nFunction PragmaValue:Int()~n'@bmk addccopt nested -DNESTED_PRAGMA~nReturn 7~nEnd Function~nLocal value:Int = PragmaValue()"
Local pragmaAnalysis:TLanguageAnalysis = TBlitzMaxLanguage.AnalyzeText(pragmaSource, "pragma-smoke.bmx")
Check(pragmaAnalysis.Succeeded(), "build-manager pragmas have no language semantic or IR shape")
Local pragmaTokenCount:Int
For Local token:TSyntaxToken = EachIn pragmaAnalysis.syntaxTree.root.tokens
	If token.kind = TOKEN_PRAGMA Then pragmaTokenCount :+ 1
Next
Check(pragmaTokenCount = 2, "lossless language tokens retain top-level and nested build-manager pragmas")

Local cancelledOptions:TLanguageAnalysisOptions = TLanguageAnalysisOptions.Create()
cancelledOptions.cancellationToken = New TImmediateLanguageCancellation
Local cancelledAnalysis:TLanguageAnalysis = TBlitzMaxLanguage.AnalyzeText("SuperStrict~nLocal value:Int = 1", "cancelled.bmx", cancelledOptions)
Check(cancelledAnalysis.cancelled And Not cancelledAnalysis.Succeeded(), "cooperatively cancelled analysis is exposed without reporting success")

Print "BlitzMax.Language module tests passed"
