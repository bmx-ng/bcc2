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

Local unresolvedExpressionOptions:TLanguageAnalysisOptions = TLanguageAnalysisOptions.Create()
unresolvedExpressionOptions.typeResolution = New TTypeResolutionOptions
unresolvedExpressionOptions.typeResolution.reportUnresolvedTypes = True
Local unresolvedExpressionSource:String = "SuperStrict~nNew TExpressionOnlyMissing()"
Local unresolvedExpressionAnalysis:TLanguageAnalysis = TBlitzMaxLanguage.AnalyzeText(unresolvedExpressionSource, "unresolved-expression-type.bmx", unresolvedExpressionOptions)
Local unresolvedExpressionCount:Int
Local unresolvedExpressionDiagnostic:TDiagnostic
For Local diagnostic:TDiagnostic = EachIn unresolvedExpressionAnalysis.model.diagnostics
	If diagnostic.code = "BMX3100" Then unresolvedExpressionCount :+ 1; unresolvedExpressionDiagnostic = diagnostic
Next
Check(unresolvedExpressionCount = 1, "expression-only New types honour unresolved-type reporting")
Check(unresolvedExpressionDiagnostic.path = "unresolved-expression-type.bmx" And unresolvedExpressionDiagnostic.span.start = unresolvedExpressionSource.Find("TExpressionOnlyMissing"), "expression type diagnostics retain their source location")

Local rangeSyntaxParse:TParseResult = TBlitzMaxParser.ParseText("SuperStrict~nLocal selected:Range=1..^2~nLocal suffix:Range=(^2..)~nLocal all:Range=(..)", "range-expression-syntax.bmx")
Check(rangeSyntaxParse.syntaxTree.diagnostics.length = 0, "Range expression forms parse without syntax diagnostics")
Local selectedRangeDeclaration:TVariableDeclarationStatementSyntax = TVariableDeclarationStatementSyntax(rangeSyntaxParse.syntaxTree.root.members[1])
Local selectedRangeSyntax:TRangeExpressionSyntax = TRangeExpressionSyntax(selectedRangeDeclaration.declarators[0].initializer)
Check(selectedRangeSyntax <> Null And selectedRangeSyntax.lowerBound <> Null And selectedRangeSyntax.upperFromEndToken <> Null, "closed Range syntax retains its from-end upper endpoint")
Local suffixRangeDeclaration:TVariableDeclarationStatementSyntax = TVariableDeclarationStatementSyntax(rangeSyntaxParse.syntaxTree.root.members[2])
Local suffixParentheses:TParenthesizedExpressionSyntax = TParenthesizedExpressionSyntax(suffixRangeDeclaration.declarators[0].initializer)
Local suffixRangeSyntax:TRangeExpressionSyntax = TRangeExpressionSyntax(suffixParentheses.expression)
Check(suffixRangeSyntax <> Null And suffixRangeSyntax.lowerFromEndToken <> Null And suffixRangeSyntax.upperBound = Null, "parentheses preserve an open-ended Range without colliding with line continuation")

Local continuationParse:TParseResult = TBlitzMaxParser.ParseText("SuperStrict~nLocal total:Int=1 ..~n + 2", "range-line-continuation.bmx")
Local continuationDeclaration:TVariableDeclarationStatementSyntax = TVariableDeclarationStatementSyntax(continuationParse.syntaxTree.root.members[1])
Check(continuationParse.syntaxTree.diagnostics.length = 0 And TBinaryExpressionSyntax(continuationDeclaration.declarators[0].initializer) <> Null, "end-of-line '..' remains the existing continuation marker")

Local ambiguousFromEndParse:TParseResult = TBlitzMaxParser.ParseText("SuperStrict~nLocal selected:Range=1..^1^2", "range-from-end-power-diagnostic.bmx")
Check(HasDiagnostic(ambiguousFromEndParse.syntaxTree.diagnostics, "BMX2115"), "an unparenthesized power in a from-end endpoint receives the targeted diagnostic")

Local source:String = "SuperStrict~nType Human~nEnd Type~nFunction Swap<T>(a:T Var, b:T Var)~nLocal temp:T = a~na = b~nb = temp~nEnd Function~nFunction Identity<T>:T(value:T)~nReturn value~nEnd Function~nFunction Describe:String(value:Human)~nReturn ~qhuman~q~nEnd Function~nFunction Describe<T>:String(value:T)~nReturn ~qvalue~q~nEnd Function~nLocal frank:Human = New Human~nLocal bob:Human = New Human~nSwap(frank, bob)~nLocal same:Human = Identity<Human>(frank)~nLocal label:String = Describe(frank)"
Local parsed:TParseResult = TBlitzMaxParser.ParseText(source, "expression-binding.bmx")
Local model:TSemanticModel = TBlitzMaxSemanticAnalyzer.Analyze(parsed.syntaxTree)
TExpressionBinder.Bind(model)
Check(model.diagnostics.length = 0, "expression binding diagnostics")

Local swapStatement:TCallStatementSyntax = TCallStatementSyntax(parsed.syntaxTree.root.members[8])
Local swapCall:TCallExpressionSyntax = TCallExpressionSyntax(swapStatement.expression)
Local resolvedSwap:TResolvedCall = model.ResolvedCall(swapCall)
Check(resolvedSwap <> Null And resolvedSwap.routine.name = "Swap", "generic call resolves routine")
Check(resolvedSwap.typeArguments.length = 1 And resolvedSwap.typeArguments[0].DisplayName() = "Human", "generic call infers Human")
Check(model.ExpressionType(swapCall).DisplayName() = "Void", "generic call return type")

Local sameDeclaration:TVariableDeclarationStatementSyntax = TVariableDeclarationStatementSyntax(parsed.syntaxTree.root.members[9])
Local identityCall:TCallExpressionSyntax = TCallExpressionSyntax(sameDeclaration.declarators[0].initializer)
Check(model.ResolvedCall(identityCall).typeArguments[0].DisplayName() = "Human", "explicit call type argument")
Check(model.ExpressionType(identityCall).DisplayName() = "Human", "substituted explicit return type")

Local malformedCallableAnalysis:TLanguageAnalysis = TBlitzMaxLanguage.AnalyzeText("SuperStrict~nFunction Apply<T>:T(value:T, fn:T(T))~nReturn fn(value)~nEnd Function", "malformed-callable-parameter-binding.bmx")
Check(malformedCallableAnalysis.syntaxTree.diagnostics.length = 0 And malformedCallableAnalysis.model.diagnostics.length = 1, "malformed SuperStrict callable parameter produces one focused semantic diagnostic")
Check(malformedCallableAnalysis.model.diagnostics[0].code = "BMX3103" And malformedCallableAnalysis.model.diagnostics[0].message.Contains("Callable parameter 'T'"), "malformed callable parameter is diagnosed at its declaration without an indirect-call cascade")

Local explicitConversionSource:String = "SuperStrict~nInterface IExplicitTarget<T>~nEnd Interface~nType TExplicitOwner Implements IExplicitTarget<Int>~nEnd Type~nFunction AcceptExplicit<T>:Int(value:IExplicitTarget<T>)~nReturn 1~nEnd Function~nFunction WidenExplicit<T>:Long(value:Long)~nReturn value~nEnd Function~nLocal owner:TExplicitOwner=New TExplicitOwner~nLocal accepted:Int=AcceptExplicit<Int>(owner)~nLocal widened:Long=WidenExplicit<String>(1)"
Local explicitConversionAnalysis:TLanguageAnalysis = TBlitzMaxLanguage.AnalyzeText(explicitConversionSource, "explicit-generic-argument-conversions.bmx")
Check(explicitConversionAnalysis.syntaxTree.diagnostics.length = 0 And explicitConversionAnalysis.model.diagnostics.length = 0, "explicit generic arguments retain ordinary Interface and numeric argument conversions")

Local genericReferenceSource:String = "SuperStrict~nFunction Identity<T>:T(value:T)~nReturn value~nEnd Function~nLocal callback:Int(value:Int)=Identity<Int>~nLocal answer:Int=callback(42)"
Local genericReferenceAnalysis:TLanguageAnalysis = TBlitzMaxLanguage.AnalyzeText(genericReferenceSource, "generic-routine-reference.bmx")
Check(genericReferenceAnalysis.syntaxTree.diagnostics.length = 0 And genericReferenceAnalysis.model.diagnostics.length = 0, "explicit generic routine reference diagnostics")
Local genericReferenceDeclaration:TVariableDeclarationStatementSyntax = TVariableDeclarationStatementSyntax(genericReferenceAnalysis.syntaxTree.root.members[2])
Local genericReferenceSyntax:TNameExpressionSyntax = TNameExpressionSyntax(genericReferenceDeclaration.declarators[0].initializer)
Local genericReferenceBound:TBoundRoutineReferenceExpression = TBoundRoutineReferenceExpression(genericReferenceAnalysis.model.BoundExpression(genericReferenceSyntax))
Check(genericReferenceSyntax <> Null And genericReferenceSyntax.typeArguments.length = 1, "explicit generic routine reference retains its syntax type arguments")
Check(genericReferenceBound <> Null And genericReferenceBound.routine.name = "Identity" And genericReferenceBound.typeArguments.length = 1 And genericReferenceBound.typeArguments[0].DisplayName() = "Int", "explicit generic routine reference binds a closed routine identity")
Check(genericReferenceAnalysis.model.ExpressionType(genericReferenceSyntax).DisplayName() = "Int(Int)", "explicit generic routine reference exposes its substituted callable signature")
Local constrainedReference:TLanguageAnalysis = TBlitzMaxLanguage.AnalyzeText("SuperStrict~nInterface IMarker~nEnd Interface~nFunction Mark<T>:T(value:T) Where T Extends IMarker~nReturn value~nEnd Function~nLocal callback:Int(value:Int)=Mark<Int>", "constrained-generic-routine-reference.bmx")
Check(HasDiagnostic(constrainedReference.model.diagnostics, "BMX3341"), "explicit generic routine references enforce routine constraints")
Local relationalReferenceParse:TParseResult = TBlitzMaxParser.ParseText("SuperStrict~nLocal a:Int=1~nLocal b:Int=2~nLocal c:Int=3~nLocal comparison:Int=a < b > c", "generic-reference-relational-ambiguity.bmx")
Local relationalDeclaration:TVariableDeclarationStatementSyntax = TVariableDeclarationStatementSyntax(relationalReferenceParse.syntaxTree.root.members[4])
Check(TBinaryExpressionSyntax(relationalDeclaration.declarators[0].initializer) <> Null, "relational a < b > c remains a binary expression")

Local labelDeclaration:TVariableDeclarationStatementSyntax = TVariableDeclarationStatementSyntax(parsed.syntaxTree.root.members[10])
Local describeCall:TCallExpressionSyntax = TCallExpressionSyntax(labelDeclaration.declarators[0].initializer)
Check(model.ResolvedCall(describeCall).routine.genericArity = 0, "non-generic exact overload preferred")
Check(model.ExpressionType(describeCall) = model.BuiltinType("String"), "resolved overload return type")
Local resolvedDescribeSignatures:TCallSignatureSet = model.CallSignatures(describeCall)
Local selectedDescribeSignatures:Int
For Local candidate:TCallSignatureCandidate = EachIn resolvedDescribeSignatures.candidates
	If candidate.selected Then selectedDescribeSignatures :+ 1
Next
Check(resolvedDescribeSignatures.candidates.length = 2 And selectedDescribeSignatures = 1, "semantic call signatures retain the overload set and selected candidate independently of resolution")

Local incompleteSignatureSource:String = "SuperStrict~nFunction Choose:Int(value:Object)~nReturn 1~nEnd Function~nFunction Choose:String(value:String)~nReturn value~nEnd Function~nChoose("
Local incompleteSignatureAnalysis:TLanguageAnalysis = TBlitzMaxLanguage.AnalyzeText(incompleteSignatureSource, "incomplete-call-signatures.bmx")
Local incompleteSignatureStatement:TCallStatementSyntax = TCallStatementSyntax(incompleteSignatureAnalysis.syntaxTree.root.members[3])
Local incompleteSignatureCall:TCallExpressionSyntax = TCallExpressionSyntax(incompleteSignatureStatement.expression)
Local incompleteSignatures:TCallSignatureSet = incompleteSignatureAnalysis.model.CallSignatures(incompleteSignatureCall)
Check(incompleteSignatureAnalysis.model.ResolvedCall(incompleteSignatureCall) = Null And incompleteSignatures <> Null And incompleteSignatures.candidates.length = 2, "incomplete calls retain callable candidates without masquerading as resolved calls")
Check(incompleteSignatures.candidates[0].compatible And incompleteSignatures.candidates[1].compatible, "an empty argument prefix keeps every arity-compatible overload available to editor tooling")

Local completionRankingSource:String = "SuperStrict~nFunction MakeText:String()~nReturn ~qtext~q~nEnd Function~nFunction MakeObject:Object()~nReturn Null~nEnd Function~nLocal text:String = Ma"
Local completionRankingAnalysis:TLanguageAnalysis = TBlitzMaxLanguage.AnalyzeText(completionRankingSource, "completion-ranking-context.bmx")
Local completionRankingOffset:Int = completionRankingSource.length
Local completionRanking:TCompletionRankingContext = TCompletionRankingContext.Query(completionRankingAnalysis.model, TSyntaxNavigator.Create(completionRankingAnalysis.syntaxTree), completionRankingOffset)
Local makeTextSymbol:TSymbol = completionRankingAnalysis.model.globalScope.LookupLocal("MakeText")[0]
Local makeObjectSymbol:TSymbol = completionRankingAnalysis.model.globalScope.LookupLocal("MakeObject")[0]
Check(completionRanking.expectedType = completionRankingAnalysis.model.BuiltinType("String"), "completion ranking recovers an initializer's expected semantic type from incomplete text")
Check(completionRanking.SortKey(makeTextSymbol, Null, Null, 1).Compare(completionRanking.SortKey(makeObjectSymbol, Null, Null, 0), True) < 0, "expected-type compatibility outranks declaration order without removing incompatible completion candidates")

Local explicitGlobalSource:String = "SuperStrict~nExtern~nFunction NativeTicks:Long()~nEnd Extern~nType TClock~nFunction Ticks:Long()~nReturn .NativeTicks()~nEnd Function~nEnd Type"
Local explicitGlobalAnalysis:TLanguageAnalysis = TBlitzMaxLanguage.AnalyzeText(explicitGlobalSource, "explicit-global-call.bmx")
Check(explicitGlobalAnalysis.model.diagnostics.length = 0, "leading-dot global routine diagnostics")
Local explicitGlobalType:TTypeDeclarationSyntax = TTypeDeclarationSyntax(explicitGlobalAnalysis.syntaxTree.root.members[2])
Local explicitGlobalRoutine:TRoutineDeclarationSyntax = TRoutineDeclarationSyntax(explicitGlobalType.body.statements[0])
Local explicitGlobalReturn:TReturnStatementSyntax = TReturnStatementSyntax(explicitGlobalRoutine.body.statements[0])
Local explicitGlobalCall:TCallExpressionSyntax = TCallExpressionSyntax(explicitGlobalReturn.expression)
Check(explicitGlobalAnalysis.model.ResolvedCall(explicitGlobalCall) <> Null And explicitGlobalAnalysis.model.ResolvedCall(explicitGlobalCall).routine.name = "NativeTicks", "leading-dot call selects global routine")

Local genericInterfaceReturnSource:String = "SuperStrict~nInterface ICollection<T>~nEnd Interface~nInterface IList<T> Extends ICollection<T>~nEnd Interface~nType TEmptyImmutableList<T> Implements IList<T>~nEnd Type~nType THashMap<K>~nMethod Keys:ICollection<K>()~nReturn New TEmptyImmutableList<K>~nEnd Method~nEnd Type"
Local genericInterfaceReturnParse:TParseResult = TBlitzMaxParser.ParseText(genericInterfaceReturnSource, "generic-interface-return.bmx")
Local genericInterfaceReturnModel:TSemanticModel = TBlitzMaxSemanticAnalyzer.Analyze(genericInterfaceReturnParse.syntaxTree)
TExpressionBinder.Bind(genericInterfaceReturnModel)
Check(genericInterfaceReturnModel.diagnostics.length = 0, "constructed generic interface inheritance satisfies return conversion")

Local genericClosureBaseSource:String = "SuperStrict~nType TBase<A,B>~nEnd Type~nType TMiddle<X> Extends TBase<String,X[]>~nEnd Type~nType TOwner<T> Extends TMiddle<T>~nEnd Type~nLocal owner:TOwner<Closure<Int()>>=New TOwner<Closure<Int()>>~nLocal base:TBase<String,Closure<Int()>[]>=owner"
Local genericClosureBaseAnalysis:TLanguageAnalysis = TBlitzMaxLanguage.AnalyzeText(genericClosureBaseSource, "generic-closure-base.bmx")
Check(genericClosureBaseAnalysis.model.diagnostics.length = 0, "transitive generic inheritance substitutes Closure types inside Array arguments")

Local constrainedMemberSource:String = "SuperStrict~nInterface IReadable<T>~nMethod Read:T()~nEnd Interface~nInterface ILayered<T> Extends IReadable<T>~nEnd Interface~nType TValue<T> Implements ILayered<T>~nField value:T~nMethod Read:T()~nReturn value~nEnd Method~nEnd Type~nFunction ReadConstrained<T,V>:V(source:T) Where T Extends IReadable<V>~nReturn source.Read()~nEnd Function~nType TReader<T,V> Where T Extends IReadable<V>~nMethod ReadFrom:V(source:T)~nReturn source.Read()~nEnd Method~nEnd Type~nLocal value:TValue<String> = New TValue<String>~nLocal direct:String = ReadConstrained<TValue<String>,String>(value)~nLocal reader:TReader<TValue<String>,String> = New TReader<TValue<String>,String>~nLocal nested:String = reader.ReadFrom(value)"
Local constrainedMemberAnalysis:TLanguageAnalysis = TBlitzMaxLanguage.AnalyzeText(constrainedMemberSource, "constrained-member-binding.bmx")
Check(constrainedMemberAnalysis.model.diagnostics.length = 0, "routine and Type parameters expose members inherited through their generic bounds")

Local callableReturnSource:String = "SuperStrict~nFunction Increment:Int(value:Int)~nReturn value+1~nEnd Function~nFunction Choose:Int(value:Int)(enabled:Int)~nIf enabled Then Return Increment~nReturn Null~nEnd Function~nLocal callback:Int(value:Int)=Choose(True)~nLocal first:Int=callback(41)~nLocal second:Int=Choose(True)(41)"
Local callableReturnParse:TParseResult = TBlitzMaxParser.ParseText(callableReturnSource, "callable-return-binding.bmx")
Local callableReturnModel:TSemanticModel = TBlitzMaxSemanticAnalyzer.Analyze(callableReturnParse.syntaxTree)
TExpressionBinder.Bind(callableReturnModel)
Check(callableReturnModel.diagnostics.length = 0, "callable returns bind through assignment and immediate invocation")
Local chooseDeclaration:TRoutineDeclarationSyntax = TRoutineDeclarationSyntax(callableReturnParse.syntaxTree.root.members[2])
Local chooseSymbol:TSymbol = callableReturnModel.DeclaredSymbol(chooseDeclaration)
Check(chooseSymbol.declaredType.DisplayName() = "Int(Int)", "bound routine retains its callable return type")
Local immediateDeclaration:TVariableDeclarationStatementSyntax = TVariableDeclarationStatementSyntax(callableReturnParse.syntaxTree.root.members[5])
Local immediateCall:TCallExpressionSyntax = TCallExpressionSyntax(immediateDeclaration.declarators[0].initializer)
Check(callableReturnModel.ExpressionType(immediateCall) = callableReturnModel.BuiltinType("Int") And callableReturnModel.ResolvedCall(immediateCall).routine = Null, "immediate invocation resolves as an indirect call on the returned callable")
Local rejectedCallableReturn:TLanguageAnalysis = TBlitzMaxLanguage.AnalyzeText("SuperStrict~nFunction Text:String(value:Int)~nReturn ~qx~q~nEnd Function~nFunction Bad:Int(value:Int)(enabled:Int)~nReturn Text~nEnd Function", "bad-callable-return.bmx")
Check(HasDiagnostic(rejectedCallableReturn.model.diagnostics, "BMX3310"), "callable return rejects an incompatible routine signature")

Local inferredCallbackDefault:TLanguageAnalysis = TBlitzMaxLanguage.AnalyzeText("SuperStrict~nFunction CompareObjects:Int(left:Object,right:Object)~nReturn 0~nEnd Function~nFunction Sort(compareFunc(left:Object,right:Object)=CompareObjects)~nLocal result:Int=compareFunc(Null,Null)~nEnd Function", "inferred-callback-default.bmx")
Check(inferredCallbackDefault.model.diagnostics.length = 0, "callable parameter without an explicit return type inherits it from its default routine")
Local inferredSort:TSymbol = inferredCallbackDefault.model.globalScope.Lookup("Sort")[0]
Check(inferredSort <> Null And inferredSort.parameterTypes[0].DisplayName() = "Int(Object, Object)", "default-routine callable return inference is retained in the routine signature")

Local multiArgumentNewSource:String = "SuperStrict~nType TPair<K,V>~nEnd Type~nLocal pair:TPair<Int,String> = New TPair<Int,String>"
Local multiArgumentNewParse:TParseResult = TBlitzMaxParser.ParseText(multiArgumentNewSource, "multi-argument-new.bmx")
Local multiArgumentNewModel:TSemanticModel = TBlitzMaxSemanticAnalyzer.Analyze(multiArgumentNewParse.syntaxTree)
TExpressionBinder.Bind(multiArgumentNewModel)
Check(multiArgumentNewModel.diagnostics.length = 0, "multi-argument generic New initializer diagnostics")
Local pairDeclaration:TVariableDeclarationStatementSyntax = TVariableDeclarationStatementSyntax(multiArgumentNewParse.syntaxTree.root.members[2])
Local pairCreation:TNewExpressionSyntax = TNewExpressionSyntax(pairDeclaration.declarators[0].initializer)
Check(pairDeclaration.declarators.length = 1 And pairCreation.createdType.genericArguments.length = 2, "generic comma inside New does not split the variable declaration")
Check(multiArgumentNewModel.ExpressionType(pairCreation).DisplayName() = "TPair<Int, String>", "multi-argument New retains its constructed type")

Local nestedGenericCastSource:String = "SuperStrict~nInterface IMapNode<K,V>~nEnd Interface~nInterface IIterator<T>~nMethod Current:T()~nEnd Interface~nFunction GetIterator:IIterator<IMapNode<String,Object>>()~nReturn Null~nEnd Function~nLocal iter:IIterator<IMapNode<String,Object>> = IIterator<IMapNode<String,Object>>(GetIterator())~nLocal node:IMapNode<String,Object> = IMapNode<String,Object>(iter.Current())"
Local nestedGenericCastParse:TParseResult = TBlitzMaxParser.ParseText(nestedGenericCastSource, "nested-generic-casts.bmx")
Local nestedGenericCastModel:TSemanticModel = TBlitzMaxSemanticAnalyzer.Analyze(nestedGenericCastParse.syntaxTree)
TExpressionBinder.Bind(nestedGenericCastModel)
Check(nestedGenericCastModel.diagnostics.length = 0, "nested multi-argument generic cast diagnostics")
Local iterCastDeclaration:TVariableDeclarationStatementSyntax = TVariableDeclarationStatementSyntax(nestedGenericCastParse.syntaxTree.root.members[4])
Local iterCast:TCallExpressionSyntax = TCallExpressionSyntax(iterCastDeclaration.declarators[0].initializer)
Check(iterCastDeclaration.declarators.length = 1 And iterCast.typeArguments.length = 1 And iterCast.typeArguments[0].genericArguments.length = 2, "nested generic cast comma does not split the variable declaration")
Check(nestedGenericCastModel.NamedCastTarget(iterCast).DisplayName() = "IIterator<IMapNode<String, Object>>", "nested generic cast retains its complete target type")

Local runtimeInterfaceCastSource:String = "SuperStrict~nType TDriver Abstract~nEnd Type~nInterface IWrappedDriver~nMethod Driver:TDriver()~nEnd Interface~nInterface INamedDriver~nEnd Interface~nLocal driver:TDriver~nLocal wrapped:IWrappedDriver=IWrappedDriver(driver)~nLocal named:INamedDriver=INamedDriver(wrapped)"
Local runtimeInterfaceCastParse:TParseResult = TBlitzMaxParser.ParseText(runtimeInterfaceCastSource, "runtime-interface-casts.bmx")
Local runtimeInterfaceCastModel:TSemanticModel = TBlitzMaxSemanticAnalyzer.Analyze(runtimeInterfaceCastParse.syntaxTree)
TExpressionBinder.Bind(runtimeInterfaceCastModel)
Check(runtimeInterfaceCastModel.diagnostics.length = 0, "explicit Interface casts retain runtime-derived Type and cross-Interface possibilities")

Local rejectedSource:String = "SuperStrict~nInterface IMarker~nEnd Interface~nType Human Implements IMarker~nEnd Type~nFunction Swap<T>(a:T Var, b:T Var)~nEnd Function~nFunction Mark<T>(value:T) Where T Extends IMarker~nEnd Function~nLocal frank:Human = New Human~nSwap(frank, New Human)~nMark(1)"
Local rejectedParse:TParseResult = TBlitzMaxParser.ParseText(rejectedSource, "rejected-generic-calls.bmx")
Local rejectedModel:TSemanticModel = TBlitzMaxSemanticAnalyzer.Analyze(rejectedParse.syntaxTree)
TExpressionBinder.Bind(rejectedModel)
Check(rejectedModel.diagnostics.length = 2, "Var and constraint call diagnostics")
Local rejectedSwap:TCallExpressionSyntax = TCallExpressionSyntax(TCallStatementSyntax(rejectedParse.syntaxTree.root.members[6]).expression)
Local rejectedMark:TCallExpressionSyntax = TCallExpressionSyntax(TCallStatementSyntax(rejectedParse.syntaxTree.root.members[7]).expression)
Check(rejectedModel.ResolvedCall(rejectedSwap) = Null, "Var parameter rejects temporary argument")
Check(rejectedModel.ResolvedCall(rejectedMark) = Null, "routine constraint rejects invalid inferred argument")

Local nestedSource:String = "SuperStrict~nType TLinkedList<T>~nMethod ToBatches:TLinkedList<TLinkedList<T>>(size:Int)~nReturn Null~nEnd Method~nEnd Type~nLocal list:TLinkedList<String> = New TLinkedList<String>~nLocal batches:TLinkedList<TLinkedList<String>> = list.ToBatches(3)"
Local nestedParse:TParseResult = TBlitzMaxParser.ParseText(nestedSource, "nested-receiver-substitution.bmx")
Local nestedModel:TSemanticModel = TBlitzMaxSemanticAnalyzer.Analyze(nestedParse.syntaxTree)
TExpressionBinder.Bind(nestedModel)
Check(nestedModel.diagnostics.length = 0, "nested receiver substitution diagnostics")
Local batchesDeclaration:TVariableDeclarationStatementSyntax = TVariableDeclarationStatementSyntax(nestedParse.syntaxTree.root.members[3])
Local batchesCall:TCallExpressionSyntax = TCallExpressionSyntax(batchesDeclaration.declarators[0].initializer)
Check(nestedModel.ResolvedCall(batchesCall).returnType.DisplayName() = "TLinkedList<TLinkedList<String>>", "containing generic substitution preserves nested return type")

Local nestedClosureCall:TLanguageAnalysis = TBlitzMaxLanguage.AnalyzeText("SuperStrict~nFunction Identity<T>:T(value:T)~nReturn value~nEnd Function~nLocal source:Closure<Int()>~nLocal result:Closure<Int()> = Identity<Closure<Int()>>(source)", "nested-closure-generic-call.bmx")
Check(nestedClosureCall.syntaxTree.diagnostics.length = 0 And nestedClosureCall.model.diagnostics.length = 0, "an explicit generic call accepts a Closure signature with adjacent nested closing brackets")

Local selfReferenceSource:String = "SuperStrict~nType TLinkedListNode<T>~nEnd Type~nType TLinkedList<T>~nMethod AddLast:TLinkedListNode<T>(value:T)~nReturn Null~nEnd Method~nMethod ToBatches:TLinkedList<TLinkedList<T>>(size:Int)~nLocal out:TLinkedList<TLinkedList<T>> = New TLinkedList<TLinkedList<T>>~nLocal cur:TLinkedList<T> = New TLinkedList<T>~nout.AddLast(cur)~nReturn out~nEnd Method~nEnd Type"
Local selfReferenceParse:TParseResult = TBlitzMaxParser.ParseText(selfReferenceSource, "self-reference-call.bmx")
Local selfReferenceModel:TSemanticModel = TBlitzMaxSemanticAnalyzer.Analyze(selfReferenceParse.syntaxTree)
TExpressionBinder.Bind(selfReferenceModel)
Check(selfReferenceModel.diagnostics.length = 0, "self-reference method call diagnostics")
Local linkedListDeclaration:TTypeDeclarationSyntax = TTypeDeclarationSyntax(selfReferenceParse.syntaxTree.root.members[2])
Local toBatchesDeclaration:TRoutineDeclarationSyntax = TRoutineDeclarationSyntax(linkedListDeclaration.body.statements[1])
Local addLastStatement:TCallStatementSyntax = TCallStatementSyntax(toBatchesDeclaration.body.statements[2])
Local addLastCall:TCallExpressionSyntax = TCallExpressionSyntax(addLastStatement.expression)
Local resolvedAddLast:TResolvedCall = selfReferenceModel.ResolvedCall(addLastCall)
Check(resolvedAddLast <> Null And resolvedAddLast.parameterTypes[0].DisplayName() = "TLinkedList<T>", "nested receiver substitutes AddLast parameter without losing a level")
Local toBatchesSymbol:TSymbol = selfReferenceModel.DeclaredSymbol(toBatchesDeclaration)
Local toBatchesBody:TBoundBlockStatement = selfReferenceModel.BoundRoutineBody(toBatchesSymbol)
Check(toBatchesBody <> Null And toBatchesBody.statements.length = 4, "routine symbol exposes a complete bound body root")
Local boundOutDeclaration:TBoundVariableDeclarationStatement = TBoundVariableDeclarationStatement(toBatchesBody.statements[0])
Check(boundOutDeclaration <> Null And TBoundNewExpression(boundOutDeclaration.variables[0].initializer) <> Null, "bound local declaration retains its typed initializer")
Local boundAddLastStatement:TBoundExpressionStatement = TBoundExpressionStatement(toBatchesBody.statements[2])
Check(boundAddLastStatement <> Null And TBoundCallExpression(boundAddLastStatement.expression).resolvedCall = resolvedAddLast, "bound expression statement retains selected nested generic call")
Check(TBoundDumper.DumpRoutine(selfReferenceModel, toBatchesSymbol).Contains("BoundReturn"), "routine bound tree can be dumped as a reusable root")

Local selfReferentialMemberSource:String = "SuperStrict~nInterface IMapNode<K,V>~nEnd Interface~nType TTreeMapNode<K,V> Implements IMapNode<K,V>~nField parent:TTreeMapNode<K,V>~nField rightNode:TTreeMapNode<K,V>~nMethod NextNode:TTreeMapNode<K,V>()~nLocal node:TTreeMapNode<K,V>=Self~nLocal parent:TTreeMapNode<K,V>=parent~nWhile parent And node = parent.rightNode~nnode = parent~nparent = parent.parent~nWend~nReturn parent~nEnd Method~nEnd Type"
Local selfReferentialMemberParse:TParseResult = TBlitzMaxParser.ParseText(selfReferentialMemberSource, "self-referential-generic-member.bmx")
Local selfReferentialMemberModel:TSemanticModel = TBlitzMaxSemanticAnalyzer.Analyze(selfReferentialMemberParse.syntaxTree)
TExpressionBinder.Bind(selfReferentialMemberModel)
Check(selfReferentialMemberModel.diagnostics.length = 0, "self-referential generic member diagnostics")
Local selfReferentialType:TTypeDeclarationSyntax = TTypeDeclarationSyntax(selfReferentialMemberParse.syntaxTree.root.members[2])
Local nextNodeDeclaration:TRoutineDeclarationSyntax = TRoutineDeclarationSyntax(selfReferentialType.body.statements[2])
Local nextNodeSymbol:TSymbol = selfReferentialMemberModel.DeclaredSymbol(nextNodeDeclaration)
Local nextNodeBody:TBoundBlockStatement = selfReferentialMemberModel.BoundRoutineBody(nextNodeSymbol)
Local parentDeclaration:TBoundVariableDeclarationStatement = TBoundVariableDeclarationStatement(nextNodeBody.statements[1])
Local parentInitializer:TBoundSymbolExpression = TBoundSymbolExpression(parentDeclaration.variables[0].initializer)
Check(parentInitializer <> Null And parentInitializer.symbol.kind = SYMBOL_FIELD And parentInitializer.receiver <> Null, "a Local is not visible in its own initializer, allowing an identically named field through implicit Self")

Local declarationPointSource:String = "SuperStrict~nType TLookupTarget~nMethod Contains:Int(value:Object)~nReturn True~nEnd Method~nEnd Type~nType TDeclarationPoint~nField indexed:TLookupTarget=New TLookupTarget~nMethod Check:Int()~nLocal result:Int=indexed.Contains(Null)~nLocal indexed:Int=1~nReturn result+indexed~nEnd Method~nEnd Type"
Local declarationPointParse:TParseResult = TBlitzMaxParser.ParseText(declarationPointSource, "declaration-point-local.bmx")
Local declarationPointModel:TSemanticModel = TBlitzMaxSemanticAnalyzer.Analyze(declarationPointParse.syntaxTree)
TExpressionBinder.Bind(declarationPointModel)
Check(declarationPointModel.diagnostics.length = 0, "a later Local does not hide an identically named field before the Local declaration point")

Local deferredOverloadSource:String = "SuperStrict~nFunction GenericMatch:Int(a:Int, b:Int)~nReturn a = b~nEnd Function~nFunction GenericMatch:Int(a:String, b:String)~nReturn a = b~nEnd Function~nType TGenericMatcher<K>~nMethod KeysEqual:Int(a:K, b:K)~nReturn GenericMatch(a, b)~nEnd Method~nEnd Type"
Local deferredOverloadParse:TParseResult = TBlitzMaxParser.ParseText(deferredOverloadSource, "deferred-generic-overload.bmx")
Local deferredOverloadModel:TSemanticModel = TBlitzMaxSemanticAnalyzer.Analyze(deferredOverloadParse.syntaxTree)
TExpressionBinder.Bind(deferredOverloadModel)
Check(deferredOverloadModel.diagnostics.length = 0, "open generic overload call is deferred without diagnostics")
Local genericMatcherType:TTypeDeclarationSyntax = TTypeDeclarationSyntax(deferredOverloadParse.syntaxTree.root.members[3])
Local keysEqualMethod:TRoutineDeclarationSyntax = TRoutineDeclarationSyntax(genericMatcherType.body.statements[0])
Local genericMatchReturn:TReturnStatementSyntax = TReturnStatementSyntax(keysEqualMethod.body.statements[0])
Local genericMatchCall:TCallExpressionSyntax = TCallExpressionSyntax(genericMatchReturn.expression)
Local deferredMatch:TResolvedCall = deferredOverloadModel.ResolvedCall(genericMatchCall)
Check(deferredMatch <> Null And deferredMatch.isDeferred And deferredMatch.candidates.length = 2, "deferred generic call retains its overload candidates")
Check(deferredMatch.routine = Null And deferredMatch.returnType = deferredOverloadModel.BuiltinType("Int"), "deferred generic call has no premature selection and retains its common return type")

Local invalidDeferredSource:String = "SuperStrict~nType THuman~nEnd Type~nFunction Fixed:Int(a:Int, b:Int)~nReturn 0~nEnd Function~nType TInvalidGeneric<K>~nMethod Probe:Int(a:K, concrete:THuman)~nReturn Fixed(a, concrete)~nEnd Method~nEnd Type"
Local invalidDeferredParse:TParseResult = TBlitzMaxParser.ParseText(invalidDeferredSource, "invalid-deferred-generic-overload.bmx")
Local invalidDeferredModel:TSemanticModel = TBlitzMaxSemanticAnalyzer.Analyze(invalidDeferredParse.syntaxTree)
TExpressionBinder.Bind(invalidDeferredModel)
Check(HasDiagnostic(invalidDeferredModel.diagnostics, "BMX3302"), "concrete argument mismatches are not hidden by deferred generic overload resolution")

Local genericStringIndexerSource:String = "SuperStrict~nType TMap<K,V>~nMethod Operator []:V(key:K)~nLocal value:V~nReturn value~nEnd Method~nMethod Operator []=(key:K, value:V)~nEnd Method~nEnd Type~nLocal map:TMap<String,String> = New TMap<String,String>~nmap[~qa~q] = ~qalpha~q~nLocal got:String = map[~qb~q]"
Local genericStringIndexerParse:TParseResult = TBlitzMaxParser.ParseText(genericStringIndexerSource, "generic-string-indexer.bmx")
Local genericStringIndexerModel:TSemanticModel = TBlitzMaxSemanticAnalyzer.Analyze(genericStringIndexerParse.syntaxTree)
TExpressionBinder.Bind(genericStringIndexerModel)
Check(genericStringIndexerModel.diagnostics.length = 0, "overloaded generic String indexer diagnostics")
Local stringSetterStatement:TAssignmentStatementSyntax = TAssignmentStatementSyntax(genericStringIndexerParse.syntaxTree.root.members[3])
Local resolvedStringSetter:TResolvedCall = genericStringIndexerModel.ResolvedCall(stringSetterStatement)
Check(resolvedStringSetter <> Null And resolvedStringSetter.routine.name = "[]=" And resolvedStringSetter.parameterTypes[0] = genericStringIndexerModel.BuiltinType("String") And resolvedStringSetter.parameterTypes[1] = genericStringIndexerModel.BuiltinType("String"), "generic index setter substitutes String key and value types")
Local boundStringSetter:TBoundAssignmentStatement = TBoundAssignmentStatement(genericStringIndexerModel.BoundStatement(stringSetterStatement))
Local boundStringSetterTarget:TBoundIndexExpression = TBoundIndexExpression(boundStringSetter.target)
Check(boundStringSetterTarget <> Null And boundStringSetterTarget.receiver <> Null And boundStringSetterTarget.indexes.length = 1 And boundStringSetterTarget.access.resolvedCall = resolvedStringSetter, "bound generic index setter retains its receiver, index arguments, and selected operator")
Local stringGetterDeclaration:TVariableDeclarationStatementSyntax = TVariableDeclarationStatementSyntax(genericStringIndexerParse.syntaxTree.root.members[4])
Local stringGetter:TIndexExpressionSyntax = TIndexExpressionSyntax(stringGetterDeclaration.declarators[0].initializer)
Local resolvedStringGetter:TResolvedCall = genericStringIndexerModel.ResolvedCall(stringGetter)
Check(resolvedStringGetter <> Null And resolvedStringGetter.routine.name = "[]" And resolvedStringGetter.parameterTypes[0] = genericStringIndexerModel.BuiltinType("String") And resolvedStringGetter.returnType = genericStringIndexerModel.BuiltinType("String"), "generic index getter accepts String and returns the substituted value type")

Local variableSource:String = "SuperStrict~nStruct SPosition~nField x:Float~nField y:Float~nMethod New(x:Float, y:Float)~nSelf.x = x~nSelf.y = y~nEnd Method~nEnd Struct~nType TExample~nField positions:SPosition[]~nFunction Create:TExample(count:Int = 1)~nReturn New TExample~nEnd Function~nMethod Update()~nSelf.positions[0].x :+ 1.0~nEnd Method~nEnd Type~nLocal example:TExample = TExample.Create()~nLocal values:SPosition[] = [New SPosition(1.0, 2.0)]~nLocal x:Float = values[0].x + example.positions[0].x~nLocal pointer:SPosition Ptr~nLocal pointerX:Float = pointer[0].x"
Local variableParse:TParseResult = TBlitzMaxParser.ParseText(variableSource, "variable-expressions.bmx")
Local variableModel:TSemanticModel = TBlitzMaxSemanticAnalyzer.Analyze(variableParse.syntaxTree)
TExpressionBinder.Bind(variableModel)
Check(variableModel.diagnostics.length = 0, "variable-oriented expression diagnostics")
Local exampleDeclaration:TVariableDeclarationStatementSyntax = TVariableDeclarationStatementSyntax(variableParse.syntaxTree.root.members[3])
Local createCall:TCallExpressionSyntax = TCallExpressionSyntax(exampleDeclaration.declarators[0].initializer)
Check(variableModel.ResolvedCall(createCall) <> Null And variableModel.ExpressionType(createCall).DisplayName() = "TExample", "type-qualified call with optional argument")
Local valuesDeclaration:TVariableDeclarationStatementSyntax = TVariableDeclarationStatementSyntax(variableParse.syntaxTree.root.members[4])
Check(variableModel.ExpressionType(valuesDeclaration.declarators[0].initializer).DisplayName() = "SPosition[]", "array literal element inference")
Local xDeclaration:TVariableDeclarationStatementSyntax = TVariableDeclarationStatementSyntax(variableParse.syntaxTree.root.members[5])
Check(variableModel.ExpressionType(xDeclaration.declarators[0].initializer) = variableModel.BuiltinType("Float"), "indexed member and binary expression type")
Local pointerXDeclaration:TVariableDeclarationStatementSyntax = TVariableDeclarationStatementSyntax(variableParse.syntaxTree.root.members[7])
Check(variableModel.ExpressionType(pointerXDeclaration.declarators[0].initializer) = variableModel.BuiltinType("Float"), "pointer index member type")

Local implicitIntArraySource:String = "Strict~nGlobal Values[] = [0, 1, 2]~nLocal First = Values[0]"
Local implicitIntArrayParse:TParseResult = TBlitzMaxParser.ParseText(implicitIntArraySource, "implicit-int-array.bmx")
Local implicitIntArrayModel:TSemanticModel = TBlitzMaxSemanticAnalyzer.Analyze(implicitIntArrayParse.syntaxTree)
TExpressionBinder.Bind(implicitIntArrayModel)
Check(implicitIntArrayModel.diagnostics.length = 0, "Strict implicit Int array declaration diagnostics")
Local implicitValuesDeclaration:TVariableDeclarationStatementSyntax = TVariableDeclarationStatementSyntax(implicitIntArrayParse.syntaxTree.root.members[1])
Local implicitValuesSymbol:TSymbol = implicitIntArrayModel.DeclaredSymbol(implicitValuesDeclaration.declarators[0])
Check(implicitValuesSymbol.declaredType.DisplayName() = "Int[]" And implicitIntArrayModel.ExpressionType(implicitValuesDeclaration.declarators[0].initializer).DisplayName() = "Int[]", "Strict suffix-only declaration retains an implicit Int base type")

Local inferredLocalSource:String = "SuperStrict~nStruct SPoint~nField x:Int~nEnd Struct~nType TBox<T>~nField value:T~nMethod New(value:T)~nSelf.value=value~nEnd Method~nEnd Type~nFunction Identity<T>:T(value:T)~nReturn value~nEnd Function~nFunction Twice:Int(value:Int)~nReturn value*2~nEnd Function~nLocal number := 42~nLocal text := ~qhello~q~nLocal values := [1,2,3]~nLocal box := New TBox<String>(text)~nLocal point := New SPoint~nLocal same := Identity<Long>(number)~nLocal callback := Twice~nLocal raw:Int~nLocal pointer := Varptr raw~nnumber = 7"
Local inferredLocalAnalysis:TLanguageAnalysis = TBlitzMaxLanguage.AnalyzeText(inferredLocalSource, "inferred-locals.bmx")
Check(inferredLocalAnalysis.syntaxTree.diagnostics.length = 0 And inferredLocalAnalysis.model.diagnostics.length = 0, "inferred scalar, aggregate, generic, callable, and pointer locals bind without diagnostics")
Local inferredNames:String[] = ["number", "text", "values", "box", "point", "same", "callback", "pointer"]
Local inferredTypes:String[] = ["Int", "String", "Int[]", "TBox<String>", "SPoint", "Long", "Int(Int)", "Int Ptr"]
For Local inferredIndex:Int = 0 Until inferredNames.length
	Local inferredSymbols:TSymbol[] = inferredLocalAnalysis.model.globalScope.LookupLocal(inferredNames[inferredIndex])
	Check(inferredSymbols.length = 1 And inferredSymbols[0].isTypeInferred And inferredSymbols[0].declaredType.DisplayName() = inferredTypes[inferredIndex], "inferred Local '" + inferredNames[inferredIndex] + "' has an explicit semantic inference marker and fixed type '" + inferredTypes[inferredIndex] + "'")
Next

Local fixedInference:TLanguageAnalysis = TBlitzMaxLanguage.AnalyzeText("SuperStrict~nLocal value := 1~nvalue = ~qwrong~q", "fixed-inferred-local.bmx")
Check(HasDiagnostic(fixedInference.model.diagnostics, "BMX3310"), "later assignments to an inferred Local use its fixed type and ordinary conversion rules")
Local invalidInference:TLanguageAnalysis = TBlitzMaxLanguage.AnalyzeText("SuperStrict~nFunction NoValue()~nEnd Function~nLocal absent := Null~nLocal empty := []~nLocal nothing := NoValue()~nLocal missing := MissingValue", "invalid-local-inference.bmx")
Check(HasDiagnostic(invalidInference.model.diagnostics, "BMX3350") And HasDiagnostic(invalidInference.model.diagnostics, "BMX3351") And HasDiagnostic(invalidInference.model.diagnostics, "BMX3352") And HasDiagnostic(invalidInference.model.diagnostics, "BMX3300"), "invalid inference from empty arrays, Null, Void, and unresolved expressions receives focused diagnostics")

Local shadowInference:TLanguageAnalysis = TBlitzMaxLanguage.AnalyzeText("SuperStrict~nLocal value:String=~qouter~q~nIf True~nLocal value := value~nEnd If", "shadowed-local-inference.bmx")
Check(shadowInference.model.diagnostics.length = 0, "an inferred Local is excluded from its own initializer so an outer shadowed value remains visible")

Local closureInference:TLanguageAnalysis = TBlitzMaxLanguage.AnalyzeText("SuperStrict~nFunction MakeAction:Closure<Int(value:Int)>()~nReturn Function(value)~nReturn value+1~nEnd Function~nEnd Function~nLocal action := MakeAction()", "inferred-closure-local.bmx")
Local closureInferenceSymbols:TSymbol[] = closureInference.model.globalScope.LookupLocal("action")
Check(closureInference.model.diagnostics.length = 0 And closureInferenceSymbols.length = 1 And closureInferenceSymbols[0].declaredType.DisplayName() = "Closure<Int(value:Int)>", "a managed Closure result supplies the inferred Local's exact fixed type")

Local superStrictImplicitIntArrayParse:TParseResult = TBlitzMaxParser.ParseText("SuperStrict~nGlobal Values[] = [0, 1, 2]", "super-strict-implicit-int-array.bmx")
Local superStrictImplicitIntArrayModel:TSemanticModel = TBlitzMaxSemanticAnalyzer.Analyze(superStrictImplicitIntArrayParse.syntaxTree)
TExpressionBinder.Bind(superStrictImplicitIntArrayModel)
Check(HasDiagnostic(superStrictImplicitIntArrayModel.diagnostics, "BMX3103"), "SuperStrict suffix-only declaration still requires an explicit base type")

Local callbackSource:String = "SuperStrict~nType TIter~nEnd Type~nType TSystem~nField callback(iter:TIter)~nMethod Run(iter:TIter)~ncallback(iter)~nEnd Method~nEnd Type~nFunction Move(iter:TIter)~nEnd Function~nFunction Register(callback(iter:TIter))~ncallback(New TIter)~nEnd Function~nRegister(Move)~nLocal system:TSystem = New TSystem~nsystem.callback(New TIter)~nFunction Compare:Int(a:Int, b:Int)~nReturn a - b~nEnd Function~nFunction UseComparator(callback:Int(a:Int, b:Int))~nLocal result:Int = callback(1, 2)~nEnd Function~nUseComparator(Compare)"
Local callbackParse:TParseResult = TBlitzMaxParser.ParseText(callbackSource, "callable-values.bmx")
Local callbackModel:TSemanticModel = TBlitzMaxSemanticAnalyzer.Analyze(callbackParse.syntaxTree)
TExpressionBinder.Bind(callbackModel)
Check(callbackModel.diagnostics.length = 0, "callable field, parameter, and routine-reference diagnostics")
Local systemType:TTypeDeclarationSyntax = TTypeDeclarationSyntax(callbackParse.syntaxTree.root.members[2])
Local callbackField:TVariableDeclarationStatementSyntax = TVariableDeclarationStatementSyntax(systemType.body.statements[0])
Local callbackFieldSymbol:TSymbol = callbackModel.DeclaredSymbol(callbackField.declarators[0])
Check(callbackFieldSymbol.declaredType.DisplayName() = "(TIter)", "callable field semantic type")
Local registerCall:TCallExpressionSyntax = TCallExpressionSyntax(TCallStatementSyntax(callbackParse.syntaxTree.root.members[5]).expression)
Check(callbackModel.ResolvedCall(registerCall) <> Null, "routine reference satisfies callable parameter")
Local moveReference:TNameExpressionSyntax = TNameExpressionSyntax(registerCall.arguments[0])
Check(callbackModel.ExpressionType(moveReference).DisplayName() = "(TIter)", "routine name expression has callable type")
Local systemCallbackCall:TCallExpressionSyntax = TCallExpressionSyntax(TCallStatementSyntax(callbackParse.syntaxTree.root.members[7]).expression)
Check(callbackModel.ResolvedCall(systemCallbackCall) <> Null And callbackModel.ResolvedCall(systemCallbackCall).returnType = callbackModel.BuiltinType("Void"), "callable field invocation")
Local compareCall:TCallExpressionSyntax = TCallExpressionSyntax(TCallStatementSyntax(callbackParse.syntaxTree.root.members[10]).expression)
Check(callbackModel.ExpressionType(compareCall.arguments[0]).DisplayName() = "Int(Int, Int)", "non-Void callable return type")

Local callablePointerSource:String = "SuperStrict~nType TEventBase~nEnd Type~nType TFunctionHolder~nField _ref:Byte Ptr~nField _function:Int(triggeredByEvent:TEventBase)~nMethod Matches:Int(other:TFunctionHolder)~nReturn _ref = Byte Ptr(other._function)~nEnd Method~nEnd Type~nLocal holder:TFunctionHolder~nLocal raw:Byte Ptr"
Local callablePointerParse:TParseResult = TBlitzMaxParser.ParseText(callablePointerSource, "callable-pointer-casts.bmx")
Local callablePointerModel:TSemanticModel = TBlitzMaxSemanticAnalyzer.Analyze(callablePointerParse.syntaxTree)
TExpressionBinder.Bind(callablePointerModel)
Check(callablePointerModel.diagnostics.length = 0, "callable value explicitly casts to Byte Ptr")
Local functionHolderType:TTypeDeclarationSyntax = TTypeDeclarationSyntax(callablePointerParse.syntaxTree.root.members[2])
Local functionFieldDeclaration:TVariableDeclarationStatementSyntax = TVariableDeclarationStatementSyntax(functionHolderType.body.statements[1])
Local functionFieldSymbol:TSymbol = callablePointerModel.DeclaredSymbol(functionFieldDeclaration.declarators[0])
Local rawPointerDeclaration:TVariableDeclarationStatementSyntax = TVariableDeclarationStatementSyntax(callablePointerParse.syntaxTree.root.members[4])
Local rawPointerSymbol:TSymbol = callablePointerModel.DeclaredSymbol(rawPointerDeclaration.declarators[0])
Local callablePointerConversions:TConversionClassifier = TConversionClassifier.Create(callablePointerModel)
Check(callablePointerConversions.ClassifyExplicit(functionFieldSymbol.declaredType, rawPointerSymbol.declaredType).Exists(), "callable-to-Byte-Ptr explicit conversion is classified")
Check(callablePointerConversions.ClassifyExplicit(rawPointerSymbol.declaredType, functionFieldSymbol.declaredType).Exists(), "Byte-Ptr-to-callable explicit conversion is classified")
Check(callablePointerConversions.Classify(rawPointerSymbol.declaredType, functionFieldSymbol.declaredType).kind = CONVERSION_BYTE_POINTER_TO_CALLABLE, "reflection metadata Byte Ptr implicitly materializes a callable value")
Check(Not callablePointerConversions.Classify(functionFieldSymbol.declaredType, rawPointerSymbol.declaredType).Exists(), "callable-to-Byte-Ptr remains an explicit boundary")

Local nativeCallbackSource:String = "SuperStrict~nFunction ReadCallback:Int(buffer:Byte Ptr,count:Int,context:Object)~nReturn count~nEnd Function~nExtern~nFunction InstallCallback:Int(callback:Byte Ptr)~nEnd Extern~nLocal result:Int=InstallCallback(ReadCallback)"
Local nativeCallbackParse:TParseResult = TBlitzMaxParser.ParseText(nativeCallbackSource, "native-byte-pointer-callback.bmx")
Local nativeCallbackModel:TSemanticModel = TBlitzMaxSemanticAnalyzer.Analyze(nativeCallbackParse.syntaxTree)
TExpressionBinder.Bind(nativeCallbackModel)
Check(nativeCallbackModel.diagnostics.length = 0, "a direct free-routine reference supplies a legacy native Byte Ptr callback")
Local nativeCallbackDeclaration:TVariableDeclarationStatementSyntax = TVariableDeclarationStatementSyntax(nativeCallbackParse.syntaxTree.root.members[3])
Local nativeCallbackCall:TCallExpressionSyntax = TCallExpressionSyntax(nativeCallbackDeclaration.declarators[0].initializer)
Local boundNativeCallback:TBoundCallExpression = TBoundCallExpression(nativeCallbackModel.BoundExpression(nativeCallbackCall))
Check(TBoundConversionExpression(boundNativeCallback.arguments[0]).conversionKind = CONVERSION_CALLABLE_REFERENCE_TO_BYTE_POINTER, "native callback conversion remains explicit in the bound model")

Local outerRoutineFallbackSource:String = "SuperStrict~nType TStream~nEnd Type~nFunction OpenCsvStream:TStream(url:Object)~nReturn New TStream~nEnd Function~nType TCsvParser~nMethod OpenCsvStream:Int(data:Byte Ptr, n:Size_T, size:Size_T)~nReturn 0~nEnd Method~nFunction Parse:TStream(path:String)~nReturn OpenCsvStream(path)~nEnd Function~nFunction Probe:Int(data:Byte Ptr)~nReturn OpenCsvStream(data, 1, 1)~nEnd Function~nEnd Type"
Local outerRoutineFallbackParse:TParseResult = TBlitzMaxParser.ParseText(outerRoutineFallbackSource, "outer-routine-fallback.bmx")
Local outerRoutineFallbackModel:TSemanticModel = TBlitzMaxSemanticAnalyzer.Analyze(outerRoutineFallbackParse.syntaxTree)
TExpressionBinder.Bind(outerRoutineFallbackModel)
Check(outerRoutineFallbackModel.diagnostics.length = 0, "inapplicable type member falls back to an outer routine overload")
Local csvParserType:TTypeDeclarationSyntax = TTypeDeclarationSyntax(outerRoutineFallbackParse.syntaxTree.root.members[3])
Local csvParseRoutine:TRoutineDeclarationSyntax = TRoutineDeclarationSyntax(csvParserType.body.statements[1])
Local csvParseCall:TCallExpressionSyntax = TCallExpressionSyntax(TReturnStatementSyntax(csvParseRoutine.body.statements[0]).expression)
Local csvProbeRoutine:TRoutineDeclarationSyntax = TRoutineDeclarationSyntax(csvParserType.body.statements[2])
Local csvProbeCall:TCallExpressionSyntax = TCallExpressionSyntax(TReturnStatementSyntax(csvProbeRoutine.body.statements[0]).expression)
Check(outerRoutineFallbackModel.ResolvedCall(csvParseCall).routine.containingScope.kind = SCOPE_COMPILATION_UNIT, "outer global routine is selected when the same-named member has incompatible arity")
Check(outerRoutineFallbackModel.ResolvedCall(csvProbeCall).routine.containingScope.owner.name = "TCsvParser", "an applicable same-named type member retains priority over the outer routine tier")

Local inheritedGlobalCollisionSource:String = "SuperStrict~nFunction GetPerson:Int(index:Int)~nReturn index~nEnd Function~nType TPersonBase~nMethod GetPerson:Int()~nReturn 42~nEnd Method~nEnd Type~nType TPersonDerived Extends TPersonBase~nMethod Read:Int()~nReturn GetPerson()~nEnd Method~nEnd Type"
Local inheritedGlobalCollisionParse:TParseResult = TBlitzMaxParser.ParseText(inheritedGlobalCollisionSource, "inherited-global-routine-collision.bmx")
Local inheritedGlobalCollisionModel:TSemanticModel = TBlitzMaxSemanticAnalyzer.Analyze(inheritedGlobalCollisionParse.syntaxTree)
TExpressionBinder.Bind(inheritedGlobalCollisionModel)
Check(inheritedGlobalCollisionModel.diagnostics.length = 0, "an inherited method remains visible beside a same-named global overload")
Local personDerivedType:TTypeDeclarationSyntax = TTypeDeclarationSyntax(inheritedGlobalCollisionParse.syntaxTree.root.members[3])
Local personReadMethod:TRoutineDeclarationSyntax = TRoutineDeclarationSyntax(personDerivedType.body.statements[0])
Local inheritedPersonCall:TCallExpressionSyntax = TCallExpressionSyntax(TReturnStatementSyntax(personReadMethod.body.statements[0]).expression)
Check(inheritedGlobalCollisionModel.ResolvedCall(inheritedPersonCall) <> Null And inheritedGlobalCollisionModel.ResolvedCall(inheritedPersonCall).routine.containingScope.owner.name = "TPersonBase", "an unqualified call selects the applicable inherited method rather than the same-named global routine")

Local importedRoutineProvider:TLanguageAnalysis = TBlitzMaxLanguage.AnalyzeText("SuperStrict~nFunction ClientWidth:Int(gadget:Object)~nReturn 1~nEnd Function", "imported-routine-provider.bmx")
Local importedInheritedFallbackParse:TParseResult = TBlitzMaxParser.ParseText("SuperStrict~nType TWindowsBase~nMethod ClientWidth:Int()~nReturn 2~nEnd Method~nEnd Type~nType TWindowsDerived Extends TWindowsBase~nMethod Read:Int(group:Object)~nReturn ClientWidth(group)~nEnd Method~nEnd Type", "imported-inherited-routine-fallback.bmx")
Local importedInheritedFallbackModel:TSemanticModel = TBlitzMaxSemanticAnalyzer.Analyze(importedInheritedFallbackParse.syntaxTree)
importedInheritedFallbackModel.directImportedScopes :+ [importedRoutineProvider.model.globalScope]
importedInheritedFallbackModel.importedScopes :+ [importedRoutineProvider.model.globalScope]
TExpressionBinder.Bind(importedInheritedFallbackModel)
Check(importedInheritedFallbackModel.diagnostics.length = 0, "an inapplicable inherited member falls back to an imported global routine overload")
Local windowsDerivedType:TTypeDeclarationSyntax = TTypeDeclarationSyntax(importedInheritedFallbackParse.syntaxTree.root.members[2])
Local windowsReadMethod:TRoutineDeclarationSyntax = TRoutineDeclarationSyntax(windowsDerivedType.body.statements[0])
Local importedClientWidthCall:TCallExpressionSyntax = TCallExpressionSyntax(TReturnStatementSyntax(windowsReadMethod.body.statements[0]).expression)
Check(importedInheritedFallbackModel.ResolvedCall(importedClientWidthCall) <> Null And importedInheritedFallbackModel.ResolvedCall(importedClientWidthCall).routine.containingScope.kind = SCOPE_COMPILATION_UNIT, "the imported global routine is selected when the inherited member has incompatible arity")

Local initializerRoutineShadowParse:TParseResult = TBlitzMaxParser.ParseText("SuperStrict~nFunction Resolve:Int(value:Int)~nReturn value~nEnd Function~nLocal Resolve:Int=Resolve(42)", "initializer-routine-shadow.bmx")
Local initializerRoutineShadowModel:TSemanticModel = TBlitzMaxSemanticAnalyzer.Analyze(initializerRoutineShadowParse.syntaxTree)
TExpressionBinder.Bind(initializerRoutineShadowModel)
Local initializerRoutineShadowDeclaration:TVariableDeclarationStatementSyntax = TVariableDeclarationStatementSyntax(initializerRoutineShadowParse.syntaxTree.root.members[2])
Local initializerRoutineShadowCall:TCallExpressionSyntax = TCallExpressionSyntax(initializerRoutineShadowDeclaration.declarators[0].initializer)
Check(initializerRoutineShadowModel.diagnostics.length = 0 And initializerRoutineShadowModel.ResolvedCall(initializerRoutineShadowCall).routine.name = "Resolve", "a variable is excluded from call-target lookup within its own initializer")

Local objectArrayCastSource:String = "SuperStrict~nType TCatchStmt~nEnd Type~nType TObjectList~nMethod ToArray:Object[]()~nReturn [New TCatchStmt]~nEnd Method~nEnd Type~nLocal objects:Object[] = [New TCatchStmt]~nLocal list:TObjectList = New TObjectList~nLocal catches:TCatchStmt[] = TCatchStmt[](list.ToArray())~nLocal bytes:Byte[]~nLocal ints:Int[]"
Local objectArrayCastParse:TParseResult = TBlitzMaxParser.ParseText(objectArrayCastSource, "object-array-casts.bmx")
Local objectArrayCastModel:TSemanticModel = TBlitzMaxSemanticAnalyzer.Analyze(objectArrayCastParse.syntaxTree)
TExpressionBinder.Bind(objectArrayCastModel)
Check(objectArrayCastModel.diagnostics.length = 0, "Object array explicitly casts to a typed object array")
Local objectsDeclaration:TVariableDeclarationStatementSyntax = TVariableDeclarationStatementSyntax(objectArrayCastParse.syntaxTree.root.members[3])
Local catchesDeclaration:TVariableDeclarationStatementSyntax = TVariableDeclarationStatementSyntax(objectArrayCastParse.syntaxTree.root.members[5])
Local bytesDeclaration:TVariableDeclarationStatementSyntax = TVariableDeclarationStatementSyntax(objectArrayCastParse.syntaxTree.root.members[6])
Local intsDeclaration:TVariableDeclarationStatementSyntax = TVariableDeclarationStatementSyntax(objectArrayCastParse.syntaxTree.root.members[7])
Local objectsSymbol:TSymbol = objectArrayCastModel.DeclaredSymbol(objectsDeclaration.declarators[0])
Local catchesSymbol:TSymbol = objectArrayCastModel.DeclaredSymbol(catchesDeclaration.declarators[0])
Local bytesSymbol:TSymbol = objectArrayCastModel.DeclaredSymbol(bytesDeclaration.declarators[0])
Local intsSymbol:TSymbol = objectArrayCastModel.DeclaredSymbol(intsDeclaration.declarators[0])
Local objectArrayConversions:TConversionClassifier = TConversionClassifier.Create(objectArrayCastModel)
Check(objectArrayConversions.ClassifyExplicit(objectsSymbol.declaredType, catchesSymbol.declaredType).Exists(), "Object[] to Type[] has an explicit legacy runtime conversion")
Check(Not objectArrayConversions.Classify(objectsSymbol.declaredType, catchesSymbol.declaredType).Exists(), "Object[] to Type[] remains invalid without an explicit cast")
Check(Not objectArrayConversions.ClassifyExplicit(bytesSymbol.declaredType, intsSymbol.declaredType).Exists(), "primitive arrays do not gain the unchecked object-array cast")

Local operatorSource:String = "SuperStrict~nType TBox<T>~nField value:T~nMethod Operator[]:T(index:Int)~nReturn value~nEnd Method~nMethod Operator[]=(index:Int, newValue:T)~nvalue = newValue~nEnd Method~nEnd Type~nLocal box:TBox<String> = New TBox<String>~nbox[0] = ~qhello~q~nLocal selected:String = box[0]~nStruct SAmount~nField value:Int~nMethod Operator+:SAmount(other:SAmount)~nReturn Self~nEnd Method~nMethod Operator-:SAmount()~nReturn Self~nEnd Method~nMethod Operator :+:SAmount(other:SAmount)~nReturn Self~nEnd Method~nEnd Struct~nLocal amount:SAmount = New SAmount~nLocal other:SAmount = New SAmount~nLocal sum:SAmount = amount + other~nLocal negative:SAmount = -amount~namount :+ other"
Local operatorParse:TParseResult = TBlitzMaxParser.ParseText(operatorSource, "operator-binding.bmx")
Local operatorModel:TSemanticModel = TBlitzMaxSemanticAnalyzer.Analyze(operatorParse.syntaxTree)
TExpressionBinder.Bind(operatorModel)
Check(operatorModel.diagnostics.length = 0, "index and user-defined operator diagnostics")
Local boxType:TTypeDeclarationSyntax = TTypeDeclarationSyntax(operatorParse.syntaxTree.root.members[1])
Local getOperator:TRoutineDeclarationSyntax = TRoutineDeclarationSyntax(boxType.body.statements[1])
Local setOperator:TRoutineDeclarationSyntax = TRoutineDeclarationSyntax(boxType.body.statements[2])
Check(operatorModel.DeclaredSymbol(getOperator).name = "[]" And operatorModel.DeclaredSymbol(setOperator).name = "[]=", "source operators use canonical symbol names")
Local setStatement:TAssignmentStatementSyntax = TAssignmentStatementSyntax(operatorParse.syntaxTree.root.members[3])
Local resolvedSetter:TResolvedCall = operatorModel.ResolvedCall(setStatement)
Check(resolvedSetter <> Null And resolvedSetter.routine.name = "[]=", "named index assignment resolves setter")
Check(resolvedSetter.parameterTypes[1] = operatorModel.BuiltinType("String"), "generic index setter substitutes value type")
Local selectedDeclaration:TVariableDeclarationStatementSyntax = TVariableDeclarationStatementSyntax(operatorParse.syntaxTree.root.members[4])
Local getIndex:TIndexExpressionSyntax = TIndexExpressionSyntax(selectedDeclaration.declarators[0].initializer)
Check(operatorModel.ResolvedCall(getIndex).routine.name = "[]" And operatorModel.ExpressionType(getIndex) = operatorModel.BuiltinType("String"), "generic named index getter type")
Check(operatorModel.ResolvedIndex(getIndex).accessKind = INDEX_ACCESS_OPERATOR, "user-defined indexing remains distinct from array and pointer access")
Local sumDeclaration:TVariableDeclarationStatementSyntax = TVariableDeclarationStatementSyntax(operatorParse.syntaxTree.root.members[8])
Local sumExpression:TBinaryExpressionSyntax = TBinaryExpressionSyntax(sumDeclaration.declarators[0].initializer)
Check(operatorModel.ResolvedCall(sumExpression).routine.name = "+" And operatorModel.ExpressionType(sumExpression).DisplayName() = "SAmount", "binary operator binding")
Check(TBoundBinaryExpression(operatorModel.BoundExpression(sumExpression)).resolvedCall.routine.name = "+", "bound binary operation retains user-defined operator call")

Local setterOnlySource:String = "SuperStrict~nType TSetterOnly~nMethod Operator[]=(first:String, second:String, value:String)~nEnd Method~nEnd Type~nLocal target:TSetterOnly = New TSetterOnly~ntarget[~qfoo~q, ~qbar~q] = ~qbaz~q"
Local setterOnlyParse:TParseResult = TBlitzMaxParser.ParseText(setterOnlySource, "setter-only-index-binding.bmx")
Local setterOnlyModel:TSemanticModel = TBlitzMaxSemanticAnalyzer.Analyze(setterOnlyParse.syntaxTree)
TExpressionBinder.Bind(setterOnlyModel)
Check(setterOnlyModel.diagnostics.length = 0, "a multi-index Operator[]= does not require a matching Operator[] getter")
Local setterOnlyStatement:TAssignmentStatementSyntax = TAssignmentStatementSyntax(setterOnlyParse.syntaxTree.root.members[3])
Local setterOnlyCall:TResolvedCall = setterOnlyModel.ResolvedCall(setterOnlyStatement)
Check(setterOnlyCall And setterOnlyCall.routine.name = "[]=" And setterOnlyCall.parameterTypes.length = 3, "multi-index assignment passes every bracket argument followed by the assigned value")
Local invalidSetterOnly:TLanguageAnalysis = TBlitzMaxLanguage.AnalyzeText("SuperStrict~nType TSetterOnly~nMethod Operator[]=(first:String, second:String, value:String)~nEnd Method~nEnd Type~nLocal target:TSetterOnly = New TSetterOnly~ntarget[~qfoo~q] = ~qbaz~q", "invalid-setter-only-index-binding.bmx")
Check(HasDiagnostic(invalidSetterOnly.model.diagnostics, "BMX3304"), "an inapplicable setter-only index assignment still reports a strict indexing diagnostic")
Local inheritedSetterOverloadSource:String = "SuperStrict~nType TIndexBase<K, V>~nMethod Operator[]:V(key:K)~nReturn Null~nEnd Method~nMethod Operator[]=(key:K, value:V)~nEnd Method~nEnd Type~nType TIndexDerived<A, B, V> Extends TIndexBase<A, TIndexBase<B, V>>~nMethod Operator[]=(first:A, second:B, value:V)~nLocal inner:TIndexBase<B, V> = Self[first]~nSelf[first] = inner~ninner[second] = value~nEnd Method~nEnd Type"
Local inheritedSetterOverload:TLanguageAnalysis = TBlitzMaxLanguage.AnalyzeText(inheritedSetterOverloadSource, "inherited-setter-overload-binding.bmx")
Check(inheritedSetterOverload.model.diagnostics.length = 0, "a derived multi-index setter overload retains access to an inherited single-index setter")
Local inheritedSetterType:TTypeDeclarationSyntax = TTypeDeclarationSyntax(inheritedSetterOverload.syntaxTree.root.members[2])
Local inheritedSetterMethod:TRoutineDeclarationSyntax = TRoutineDeclarationSyntax(inheritedSetterType.body.statements[0])
Local inheritedSetterAssignment:TAssignmentStatementSyntax = TAssignmentStatementSyntax(inheritedSetterMethod.body.statements[1])
Local inheritedSetterCall:TResolvedCall = inheritedSetterOverload.model.ResolvedCall(inheritedSetterAssignment)
Check(inheritedSetterCall And inheritedSetterCall.routine.containingScope.owner.name = "TIndexBase" And inheritedSetterCall.parameterTypes.length = 2, "inherited operator overload resolution substitutes the nested constructed base value type")
Local negativeDeclaration:TVariableDeclarationStatementSyntax = TVariableDeclarationStatementSyntax(operatorParse.syntaxTree.root.members[9])
Local negativeExpression:TUnaryExpressionSyntax = TUnaryExpressionSyntax(negativeDeclaration.declarators[0].initializer)
Check(operatorModel.ResolvedCall(negativeExpression).routine.name = "-" And operatorModel.ExpressionType(negativeExpression).DisplayName() = "SAmount", "unary operator binding")
Local compoundStatement:TAssignmentStatementSyntax = TAssignmentStatementSyntax(operatorParse.syntaxTree.root.members[10])
Check(operatorModel.ResolvedCall(compoundStatement).routine.name = ":+", "compound assignment operator binding")

Local assignmentOperatorSource:String = "SuperStrict~nType TMutableValue~nMethod Operator :=:TMutableValue(value:String)~nReturn Self~nEnd Method~nEnd Type~nLocal current:TMutableValue=New TMutableValue~ncurrent=~qchanged~q~ncurrent=New TMutableValue"
Local assignmentOperatorParse:TParseResult = TBlitzMaxParser.ParseText(assignmentOperatorSource, "assignment-operator-binding.bmx")
Local assignmentOperatorModel:TSemanticModel = TBlitzMaxSemanticAnalyzer.Analyze(assignmentOperatorParse.syntaxTree)
TExpressionBinder.Bind(assignmentOperatorModel)
Local assignmentOperatorStatement:TAssignmentStatementSyntax = TAssignmentStatementSyntax(assignmentOperatorParse.syntaxTree.root.members[3])
Local newReferenceAssignment:TAssignmentStatementSyntax = TAssignmentStatementSyntax(assignmentOperatorParse.syntaxTree.root.members[4])
Check(assignmentOperatorModel.diagnostics.length = 0 And assignmentOperatorModel.ResolvedCall(assignmentOperatorStatement).routine.name = ":=", "ordinary assignment selects a matching user-defined assignment-initialization operator")
Check(assignmentOperatorModel.ResolvedCall(newReferenceAssignment) = Null, "assignment from an explicit New expression retains ordinary reference replacement semantics")

Local genericInterfaceOverrideSource:String = "SuperStrict~nEnum EHeader~nUnknown~nEnd Enum~nInterface IMap<K,V>~nMethod TryGetValue:Int(key:K, value:V Var)~nEnd Interface~nType THashMap<K,V> Implements IMap<K,V>~nMethod TryGetValue:Int(key:K, value:V Var)~nReturn True~nEnd Method~nEnd Type~nLocal map:THashMap<String,EHeader> = New THashMap<String,EHeader>~nLocal header:EHeader~nLocal found:Int = map.TryGetValue(~qname~q, header)"
Local genericInterfaceOverrideParse:TParseResult = TBlitzMaxParser.ParseText(genericInterfaceOverrideSource, "generic-interface-override.bmx")
Local genericInterfaceOverrideModel:TSemanticModel = TBlitzMaxSemanticAnalyzer.Analyze(genericInterfaceOverrideParse.syntaxTree)
TExpressionBinder.Bind(genericInterfaceOverrideModel)
Check(genericInterfaceOverrideModel.diagnostics.length = 0, "constructed generic implementation hides the equivalent interface member")
Local foundDeclaration:TVariableDeclarationStatementSyntax = TVariableDeclarationStatementSyntax(genericInterfaceOverrideParse.syntaxTree.root.members[6])
Local tryGetValueCall:TCallExpressionSyntax = TCallExpressionSyntax(foundDeclaration.declarators[0].initializer)
Check(genericInterfaceOverrideModel.ResolvedCall(tryGetValueCall).routine.containingScope.owner.name = "THashMap", "generic implementation member is selected instead of its substituted interface declaration")

Local inheritedInterfaceSelectorSource:String = "SuperStrict~nInterface IObjectValue~nMethod Value:Object()~nEnd Interface~nInterface IStringValue~nMethod Value:String()~nEnd Interface~nInterface ICombinedValue Extends IObjectValue, IStringValue~nEnd Interface~nLocal combined:ICombinedValue~nLocal selected:Object = combined.Value()"
Local inheritedInterfaceSelectorParse:TParseResult = TBlitzMaxParser.ParseText(inheritedInterfaceSelectorSource, "inherited-interface-selector.bmx")
Local inheritedInterfaceSelectorModel:TSemanticModel = TBlitzMaxSemanticAnalyzer.Analyze(inheritedInterfaceSelectorParse.syntaxTree)
TExpressionBinder.Bind(inheritedInterfaceSelectorModel)
Local inheritedInterfaceSelectorDeclaration:TVariableDeclarationStatementSyntax = TVariableDeclarationStatementSyntax(inheritedInterfaceSelectorParse.syntaxTree.root.members[5])
Local inheritedInterfaceSelectorCall:TCallExpressionSyntax = TCallExpressionSyntax(inheritedInterfaceSelectorDeclaration.declarators[0].initializer)
Check(inheritedInterfaceSelectorModel.diagnostics.length = 0 And inheritedInterfaceSelectorModel.ResolvedCall(inheritedInterfaceSelectorCall).routine.containingScope.owner.name = "IObjectValue", "compatible inherited Interface selectors preserve declared parent order like production bcc")

Local ambiguousMessageSource:String = "SuperStrict~nFunction Choose:Int(a:Int, b:Float)~nReturn 1~nEnd Function~nFunction Choose:Int(a:Float, b:Int)~nReturn 2~nEnd Function~nLocal selected:Int = Choose(1, 1)"
Local ambiguousMessageParse:TParseResult = TBlitzMaxParser.ParseText(ambiguousMessageSource, "ambiguous-candidates.bmx")
Local ambiguousMessageModel:TSemanticModel = TBlitzMaxSemanticAnalyzer.Analyze(ambiguousMessageParse.syntaxTree)
TExpressionBinder.Bind(ambiguousMessageModel)
Check(ambiguousMessageModel.diagnostics.length = 1 And ambiguousMessageModel.diagnostics[0].code = "BMX3303", "cross-preferred overloads remain ambiguous")
Check(ambiguousMessageModel.diagnostics[0].message.Contains("Candidates:") And ambiguousMessageModel.diagnostics[0].message.Contains("Choose(Int, Float)") And ambiguousMessageModel.diagnostics[0].message.Contains("Choose(Float, Int)"), "ambiguity diagnostic lists every applicable candidate")

Local externalCaseRedeclarationSource:String = "SuperStrict~nExtern~nFunction Native_free:Int(value:Byte Ptr)=~qnative_free~q~nFunction Native_Free:Int(value:Byte Ptr)=~qnative_Free~q~nEnd Extern~nLocal value:Byte Ptr~nLocal result:Int=Native_Free(value)"
Local externalCaseRedeclarationParse:TParseResult = TBlitzMaxParser.ParseText(externalCaseRedeclarationSource, "external-case-redeclaration.bmx")
Local externalCaseRedeclarationModel:TSemanticModel = TBlitzMaxSemanticAnalyzer.Analyze(externalCaseRedeclarationParse.syntaxTree)
TExpressionBinder.Bind(externalCaseRedeclarationModel)
Local externalCaseResultDeclaration:TVariableDeclarationStatementSyntax = TVariableDeclarationStatementSyntax(externalCaseRedeclarationParse.syntaxTree.root.members[externalCaseRedeclarationParse.syntaxTree.root.members.length - 1])
Check(externalCaseResultDeclaration <> Null, "case-equivalent external redeclaration fixture retains its result declaration")
Local externalCaseCall:TCallExpressionSyntax = TCallExpressionSyntax(externalCaseResultDeclaration.declarators[0].initializer)
Check(externalCaseRedeclarationModel.diagnostics.length = 0, "case-equivalent external redeclarations are not ambiguous")
Local externalCaseResolved:TResolvedCall = externalCaseRedeclarationModel.ResolvedCall(externalCaseCall)
Check(externalCaseResolved <> Null, "case-equivalent external redeclaration call resolves")
Check(externalCaseResolved.routine <> Null, "case-equivalent external redeclaration call selects a routine")
Check(externalCaseResolved.routine.externalName = "native_free", "case-equivalent external redeclarations preserve the first production ABI declaration")

Local inheritedSource:String = "SuperStrict~nType TBase<T>~nField item:T~nMethod Get:T()~nReturn item~nEnd Method~nMethod Operator[]:T(index:Int)~nReturn item~nEnd Method~nMethod Operator[]=(index:Int, value:T)~nitem = value~nEnd Method~nEnd Type~nType TDerived<U> Extends TBase<U>~nMethod ReadField:U()~nReturn item~nEnd Method~nMethod ReadMethod:U()~nReturn Get()~nEnd Method~nEnd Type~nLocal derived:TDerived<String> = New TDerived<String>~nLocal inheritedField:String = derived.item~nLocal inheritedMethod:String = derived.Get()~nLocal inheritedIndex:String = derived[0]~nderived[0] = ~qupdated~q"
Local inheritedParse:TParseResult = TBlitzMaxParser.ParseText(inheritedSource, "inherited-expression-binding.bmx")
Local inheritedModel:TSemanticModel = TBlitzMaxSemanticAnalyzer.Analyze(inheritedParse.syntaxTree)
TExpressionBinder.Bind(inheritedModel)
Check(inheritedModel.diagnostics.length = 0, "inherited generic member diagnostics")
Local derivedType:TTypeDeclarationSyntax = TTypeDeclarationSyntax(inheritedParse.syntaxTree.root.members[2])
Local readFieldMethod:TRoutineDeclarationSyntax = TRoutineDeclarationSyntax(derivedType.body.statements[0])
Local readFieldReturn:TReturnStatementSyntax = TReturnStatementSyntax(readFieldMethod.body.statements[0])
Check(inheritedModel.ExpressionType(readFieldReturn.expression) = inheritedModel.TypeOf(readFieldMethod.signature.returnType), "unqualified inherited field inside derived type")
Local readMethodMethod:TRoutineDeclarationSyntax = TRoutineDeclarationSyntax(derivedType.body.statements[1])
Local readMethodReturn:TReturnStatementSyntax = TReturnStatementSyntax(readMethodMethod.body.statements[0])
Local unqualifiedInheritedCall:TCallExpressionSyntax = TCallExpressionSyntax(readMethodReturn.expression)
Check(inheritedModel.ResolvedCall(unqualifiedInheritedCall).returnType = inheritedModel.TypeOf(readMethodMethod.signature.returnType), "unqualified inherited method inside derived type")
Local inheritedFieldDeclaration:TVariableDeclarationStatementSyntax = TVariableDeclarationStatementSyntax(inheritedParse.syntaxTree.root.members[4])
Check(inheritedModel.ExpressionType(inheritedFieldDeclaration.declarators[0].initializer) = inheritedModel.BuiltinType("String"), "inherited generic field substitution")
Local inheritedMethodDeclaration:TVariableDeclarationStatementSyntax = TVariableDeclarationStatementSyntax(inheritedParse.syntaxTree.root.members[5])
Local inheritedMethodCall:TCallExpressionSyntax = TCallExpressionSyntax(inheritedMethodDeclaration.declarators[0].initializer)
Check(inheritedModel.ResolvedCall(inheritedMethodCall).returnType = inheritedModel.BuiltinType("String"), "inherited generic method return substitution")
Local inheritedIndexDeclaration:TVariableDeclarationStatementSyntax = TVariableDeclarationStatementSyntax(inheritedParse.syntaxTree.root.members[6])
Local inheritedIndex:TIndexExpressionSyntax = TIndexExpressionSyntax(inheritedIndexDeclaration.declarators[0].initializer)
Check(inheritedModel.ResolvedCall(inheritedIndex).returnType = inheritedModel.BuiltinType("String"), "inherited generic index getter")
Local inheritedSet:TAssignmentStatementSyntax = TAssignmentStatementSyntax(inheritedParse.syntaxTree.root.members[7])
Check(inheritedModel.ResolvedCall(inheritedSet).parameterTypes[1] = inheritedModel.BuiltinType("String"), "inherited generic index setter")

Local conversionSource:String = "SuperStrict~nType TBaseValue~nEnd Type~nInterface ITagged~nEnd Interface~nType TChildValue Extends TBaseValue Implements ITagged~nEnd Type~nFunction Promote:String(value:Int)~nReturn ~qint~q~nEnd Function~nFunction Promote:String(value:Long)~nReturn ~qlong~q~nEnd Function~nFunction Real:String(value:Float)~nReturn ~qfloat~q~nEnd Function~nFunction Real:String(value:Double)~nReturn ~qdouble~q~nEnd Function~nFunction Reference:String(value:TBaseValue)~nReturn ~qbase~q~nEnd Function~nFunction Reference:String(value:Object)~nReturn ~qobject~q~nEnd Function~nFunction InterfacePick:String(value:ITagged)~nReturn ~qtagged~q~nEnd Function~nFunction InterfacePick:String(value:Object)~nReturn ~qobject~q~nEnd Function~nFunction GenericFixed<T>:T(value:Long, fallback:T)~nReturn fallback~nEnd Function~nFunction AcceptChild(value:TChildValue)~nEnd Function~nLocal small:Byte~nLocal whole:Int~nLocal child:TChildValue = New TChildValue~nLocal promoted:String = Promote(small)~nLocal realValue:String = Real(whole)~nLocal referenceValue:String = Reference(child)~nLocal interfaceValue:String = InterfacePick(child)~nLocal inferredFixed:String = GenericFixed(small, ~qok~q)~nAcceptChild(Null)"
Local conversionParse:TParseResult = TBlitzMaxParser.ParseText(conversionSource, "conversion-overloads.bmx")
Local conversionModel:TSemanticModel = TBlitzMaxSemanticAnalyzer.Analyze(conversionParse.syntaxTree)
TExpressionBinder.Bind(conversionModel)
Check(conversionModel.diagnostics.length = 0, "ranked conversion diagnostics")
Local promotedDeclaration:TVariableDeclarationStatementSyntax = TVariableDeclarationStatementSyntax(conversionParse.syntaxTree.root.members[17])
Local promotedCall:TCallExpressionSyntax = TCallExpressionSyntax(promotedDeclaration.declarators[0].initializer)
Check(conversionModel.ResolvedCall(promotedCall).parameterTypes[0] = conversionModel.BuiltinType("Int"), "nearest numeric widening overload")
Local boundPromotedCall:TBoundCallExpression = TBoundCallExpression(conversionModel.BoundExpression(promotedCall))
Check(boundPromotedCall <> Null And boundPromotedCall.resolvedCall.routine = conversionModel.ResolvedCall(promotedCall).routine, "bound call retains selected overload")
Local promotedArgumentConversion:TBoundConversionExpression = TBoundConversionExpression(boundPromotedCall.arguments[0])
Check(promotedArgumentConversion <> Null And promotedArgumentConversion.conversionKind = CONVERSION_NUMERIC_WIDENING And promotedArgumentConversion.semanticType = conversionModel.BuiltinType("Int"), "bound call makes numeric argument conversion explicit")
Local realDeclaration:TVariableDeclarationStatementSyntax = TVariableDeclarationStatementSyntax(conversionParse.syntaxTree.root.members[18])
Local realCall:TCallExpressionSyntax = TCallExpressionSyntax(realDeclaration.declarators[0].initializer)
Check(conversionModel.ResolvedCall(realCall).parameterTypes[0] = conversionModel.BuiltinType("Float"), "Float preferred over more distant Double widening")
Local referenceDeclaration:TVariableDeclarationStatementSyntax = TVariableDeclarationStatementSyntax(conversionParse.syntaxTree.root.members[19])
Local referenceCall:TCallExpressionSyntax = TCallExpressionSyntax(referenceDeclaration.declarators[0].initializer)
Check(conversionModel.ResolvedCall(referenceCall).parameterTypes[0].DisplayName() = "TBaseValue", "nearest reference upcast overload")
Local interfaceDeclaration:TVariableDeclarationStatementSyntax = TVariableDeclarationStatementSyntax(conversionParse.syntaxTree.root.members[20])
Local interfaceCall:TCallExpressionSyntax = TCallExpressionSyntax(interfaceDeclaration.declarators[0].initializer)
Check(conversionModel.ResolvedCall(interfaceCall).parameterTypes[0].DisplayName() = "ITagged", "direct interface conversion preferred over Object")
Local fixedDeclaration:TVariableDeclarationStatementSyntax = TVariableDeclarationStatementSyntax(conversionParse.syntaxTree.root.members[21])
Local fixedCall:TCallExpressionSyntax = TCallExpressionSyntax(fixedDeclaration.declarators[0].initializer)
Check(conversionModel.ResolvedCall(fixedCall).typeArguments[0] = conversionModel.BuiltinType("String"), "generic inference with converted fixed parameter")
Local nullCall:TCallExpressionSyntax = TCallExpressionSyntax(TCallStatementSyntax(conversionParse.syntaxTree.root.members[22]).expression)
Check(conversionModel.ResolvedCall(nullCall) <> Null, "Null converts to reference parameter")

Local narrowingArgumentSource:String = "SuperStrict~nFunction WideValue:Double()~nReturn 1.5~nEnd Function~nType TAreaDrawer~nMethod DrawArea:Int(x:Float,y:Float,width:Float,height:Float,frame:Int=-1,borders:Int=0)~nReturn 1~nEnd Method~nMethod DrawArea:Int(x:Float,y:Float,width:Float,height:Float,frame:Int,borders:Int,clip:Int)~nReturn 2~nEnd Method~nEnd Type~nLocal drawer:TAreaDrawer=New TAreaDrawer~ndrawer.DrawArea(0,0,10,WideValue(),-1,0)"
Local narrowingArgumentParse:TParseResult = TBlitzMaxParser.ParseText(narrowingArgumentSource, "numeric-narrowing-argument.bmx")
Local narrowingArgumentModel:TSemanticModel = TBlitzMaxSemanticAnalyzer.Analyze(narrowingArgumentParse.syntaxTree)
TExpressionBinder.Bind(narrowingArgumentModel)
Check(narrowingArgumentModel.diagnostics.length = 0, "ordinary value parameters accept BlitzMax numeric narrowing")
Local narrowingArgumentStatement:TCallStatementSyntax = TCallStatementSyntax(narrowingArgumentParse.syntaxTree.root.members[narrowingArgumentParse.syntaxTree.root.members.length - 1])
Local narrowingArgumentCall:TCallExpressionSyntax = TCallExpressionSyntax(narrowingArgumentStatement.expression)
Local narrowingArgumentBound:TBoundCallExpression = TBoundCallExpression(narrowingArgumentModel.BoundExpression(narrowingArgumentCall))
Check(narrowingArgumentModel.ResolvedCall(narrowingArgumentCall).routine.parameters.length = 6 And TBoundConversionExpression(narrowingArgumentBound.arguments[3]).conversionKind = CONVERSION_NUMERIC_NARROWING, "overload ranking prefers the applicable defaulted shape and retains Double-to-Float argument narrowing explicitly")

Local mixedNumericOverloadSource:String = "SuperStrict~nFunction Compare:Int(expected:Int,actual:Int)~nReturn 1~nEnd Function~nFunction Compare:Int(expected:ULong,actual:ULong)~nReturn 2~nEnd Function~nFunction Compare:Int(expected:Float,actual:Float,delta:Float=0)~nReturn 3~nEnd Function~nLocal index:Int=3~nLocal actual:ULong=9~nLocal result:Int=Compare(index*index,actual)"
Local mixedNumericOverloadAnalysis:TLanguageAnalysis = TBlitzMaxLanguage.AnalyzeText(mixedNumericOverloadSource, "mixed-numeric-overload.bmx")
Check(mixedNumericOverloadAnalysis.model.diagnostics.length = 0, "a mixed Int and ULong call resolves through the all-widening overload")
Local mixedNumericResult:TVariableDeclarationStatementSyntax = TVariableDeclarationStatementSyntax(mixedNumericOverloadAnalysis.syntaxTree.root.members[mixedNumericOverloadAnalysis.syntaxTree.root.members.length - 1])
Local mixedNumericCall:TCallExpressionSyntax = TCallExpressionSyntax(mixedNumericResult.declarators[0].initializer)
Check(mixedNumericOverloadAnalysis.model.ResolvedCall(mixedNumericCall).parameterTypes[0] = mixedNumericOverloadAnalysis.model.BuiltinType("Float"), "all-widening Float overload outranks candidates requiring numeric narrowing")

Local literalOverloadSource:String = "SuperStrict~nType TLiteralOverload~nMethod Calc(a:Byte)~nEnd Method~nMethod Calc(a:Int)~nEnd Method~nMethod Calc(a:UInt)~nEnd Method~nMethod Calc(a:Float)~nEnd Method~nMethod Calc(a:Long)~nEnd Method~nEnd Type~nLocal overload:TLiteralOverload = New TLiteralOverload~noverload.Calc(1)~noverload.Calc(1:Byte)~noverload.Calc(1:UInt)"
Local literalOverloadParse:TParseResult = TBlitzMaxParser.ParseText(literalOverloadSource, "literal-overloads.bmx")
Local literalOverloadModel:TSemanticModel = TBlitzMaxSemanticAnalyzer.Analyze(literalOverloadParse.syntaxTree)
TExpressionBinder.Bind(literalOverloadModel)
Check(literalOverloadModel.diagnostics.length = 0, "numeric literal overload diagnostics")
Local defaultLiteralCall:TCallExpressionSyntax = TCallExpressionSyntax(TCallStatementSyntax(literalOverloadParse.syntaxTree.root.members[3]).expression)
Local byteLiteralCall:TCallExpressionSyntax = TCallExpressionSyntax(TCallStatementSyntax(literalOverloadParse.syntaxTree.root.members[4]).expression)
Local uintLiteralCall:TCallExpressionSyntax = TCallExpressionSyntax(TCallStatementSyntax(literalOverloadParse.syntaxTree.root.members[5]).expression)
Check(literalOverloadModel.ResolvedCall(defaultLiteralCall).parameterTypes[0] = literalOverloadModel.BuiltinType("Int"), "unsuffixed integer literal selects Int overload")
Check(literalOverloadModel.ResolvedCall(byteLiteralCall).parameterTypes[0] = literalOverloadModel.BuiltinType("Byte"), "Byte-suffixed integer literal selects Byte overload")
Check(literalOverloadModel.ResolvedCall(uintLiteralCall).parameterTypes[0] = literalOverloadModel.BuiltinType("UInt"), "UInt-suffixed integer literal selects UInt overload")

Local taggedOverloadSource:String = "SuperStrict~nType TRectangle~nEnd Type~nStruct SRectI~nEnd Struct~nType TSprite~nMethod DrawResized(tX:Float, tY:Float, tW:Float, tH:Float, sX:Float, sY:Float, sW:Float, sH:Float, frame:Int=-1, drawCompleteImage:Int=False, clipRect:TRectangle=Null, forceTileMode:Int=0)~nEnd Method~nMethod DrawResized(tX:Float, tY:Float, tW:Float, tH:Float, sX:Float, sY:Float, sW:Float, sH:Float, frame:Int=-1, drawCompleteImage:Int=False, doClipping:Int, clipRect:SRectI, forceTileMode:Int=0)~nEnd Method~nMethod DrawClipped(x:Float, y:Float, w:Float, h:Float, offsetX:Float=0, offsetY:Float=0, frame:Int=-1)~nDrawResized(x, y, 0#, 0#, offsetX, offsetY, w, h, frame)~nEnd Method~nEnd Type"
Local taggedOverloadParse:TParseResult = TBlitzMaxParser.ParseText(taggedOverloadSource, "tagged-literal-overload.bmx")
Check(taggedOverloadParse.syntaxTree.diagnostics.length = 0, "postfix Float literal tags preserve the complete argument list")
Local taggedOverloadModel:TSemanticModel = TBlitzMaxSemanticAnalyzer.Analyze(taggedOverloadParse.syntaxTree)
TExpressionBinder.Bind(taggedOverloadModel)
Check(taggedOverloadModel.diagnostics.length = 0, "required parameters after optional parameters exclude the longer DrawResized overload")
Local taggedSprite:TTypeDeclarationSyntax = TTypeDeclarationSyntax(taggedOverloadParse.syntaxTree.root.members[3])
Local taggedDrawClipped:TRoutineDeclarationSyntax = TRoutineDeclarationSyntax(taggedSprite.body.statements[2])
Local taggedDrawStatement:TCallStatementSyntax = TCallStatementSyntax(taggedDrawClipped.body.statements[0])
Local taggedDrawCall:TCallExpressionSyntax = TCallExpressionSyntax(taggedDrawStatement.expression)
Check(taggedDrawCall.arguments.length = 9 And taggedOverloadModel.ExpressionType(taggedDrawCall.arguments[2]) = taggedOverloadModel.BuiltinType("Float"), "0# binds as one Float argument")
Check(taggedOverloadModel.ResolvedCall(taggedDrawCall).routine.parameters.length = 12, "DrawResized call selects the only overload whose remaining parameters are optional")

Local interfaceOnlyTagParse:TParseResult = TBlitzMaxParser.ParseText("SuperStrict~nLocal value:Long = 1%%", "interface-only-literal-tag.bmx")
Check(interfaceOnlyTagParse.syntaxTree.diagnostics.length > 0, "interface-only compact type markers are rejected in source literals")

Local callableArraySource:String = "SuperStrict~nType TGUIObject~nEnd Type~nType TButtonOwner~nField buttonCallbacks:Int(index:Int, sender:TGUIObject)[]~nMethod TrimCallbacks()~nbuttonCallbacks = buttonCallbacks[..1]~nEnd Method~nEnd Type"
Local callableArrayParse:TParseResult = TBlitzMaxParser.ParseText(callableArraySource, "callable-array-slice.bmx")
Local callableArrayModel:TSemanticModel = TBlitzMaxSemanticAnalyzer.Analyze(callableArrayParse.syntaxTree)
TExpressionBinder.Bind(callableArrayModel)
Check(callableArrayModel.diagnostics.length = 0, "arrays of callable values support slicing")
Local buttonOwner:TTypeDeclarationSyntax = TTypeDeclarationSyntax(callableArrayParse.syntaxTree.root.members[2])
Local callableArrayField:TVariableDeclarationStatementSyntax = TVariableDeclarationStatementSyntax(buttonOwner.body.statements[0])
Local callableArraySymbol:TSymbol = callableArrayModel.DeclaredSymbol(callableArrayField.declarators[0])
Local callbackArrayType:TArraySemanticType = TArraySemanticType(callableArraySymbol.declaredType)
Check(callbackArrayType <> Null And TCallableSemanticType(callbackArrayType.elementType) <> Null, "callable array retains its array and element types")
Local trimCallbacks:TRoutineDeclarationSyntax = TRoutineDeclarationSyntax(buttonOwner.body.statements[1])
Local callbackSlice:TSliceExpressionSyntax = TSliceExpressionSyntax(TAssignmentStatementSyntax(trimCallbacks.body.statements[0]).right)
Local callbackSliceType:TArraySemanticType = TArraySemanticType(callableArrayModel.ExpressionType(callbackSlice))
Check(callbackSliceType <> Null And TCallableSemanticType(callbackSliceType.elementType) <> Null, "slicing a callable array preserves the array type")

Local callableArrayNullSource:String = "SuperStrict~nFunction FormatFirst:String(value:Int)~nReturn ~qfirst~q~nEnd Function~nLocal callbacks:String(value:Int)[] = [FormatFirst, Null]"
Local callableArrayNullParse:TParseResult = TBlitzMaxParser.ParseText(callableArrayNullSource, "callable-array-null.bmx")
Local callableArrayNullModel:TSemanticModel = TBlitzMaxSemanticAnalyzer.Analyze(callableArrayNullParse.syntaxTree)
TExpressionBinder.Bind(callableArrayNullModel)
Check(callableArrayNullModel.diagnostics.length = 0, "Null in an identity-compatible callable array literal receives the contextual element type")
Local callableArrayNullDeclaration:TVariableDeclarationStatementSyntax = TVariableDeclarationStatementSyntax(callableArrayNullParse.syntaxTree.root.members[2])
Local callableArrayNullBound:TBoundArrayLiteralExpression = TBoundArrayLiteralExpression(TBoundVariableDeclarationStatement(callableArrayNullModel.BoundStatement(callableArrayNullDeclaration)).variables[0].initializer)
Local callableArrayNullConversion:TBoundConversionExpression = TBoundConversionExpression(callableArrayNullBound.elements[1])
Check(callableArrayNullBound.contextualElementType.DisplayName() = "String(Int)" And callableArrayNullConversion <> Null And callableArrayNullConversion.conversionKind = CONVERSION_DEFAULT_VALUE And callableArrayNullConversion.semanticType.DisplayName() = "String(Int)", "callable array Null is retained as an explicit typed default conversion")

Local referenceArrayContextSource:String = "SuperStrict~nType TContextNode~nEnd Type~nFunction AcceptObjects(values:Object[])~nEnd Function~nLocal node:TContextNode = New TContextNode~nLocal value:Object = Null~nAcceptObjects([node, value])"
Local referenceArrayContextParse:TParseResult = TBlitzMaxParser.ParseText(referenceArrayContextSource, "reference-array-context.bmx")
Local referenceArrayContextModel:TSemanticModel = TBlitzMaxSemanticAnalyzer.Analyze(referenceArrayContextParse.syntaxTree)
TExpressionBinder.Bind(referenceArrayContextModel)
Check(referenceArrayContextModel.diagnostics.length = 0, "a mixed derived/Object array literal accepts Object[] call context")
Local referenceArrayContextCall:TCallExpressionSyntax = TCallExpressionSyntax(TCallStatementSyntax(referenceArrayContextParse.syntaxTree.root.members[5]).expression)
Local referenceArrayContextBoundCall:TBoundCallExpression = TBoundCallExpression(referenceArrayContextModel.BoundExpression(referenceArrayContextCall))
Local referenceArrayContextLiteral:TBoundArrayLiteralExpression = TBoundArrayLiteralExpression(referenceArrayContextBoundCall.arguments[0])
Local referenceArrayContextFirst:TBoundConversionExpression = TBoundConversionExpression(referenceArrayContextLiteral.elements[0])
Check(referenceArrayContextLiteral.semanticType.DisplayName() = "Object[]" And referenceArrayContextLiteral.contextualElementType.DisplayName() = "Object", "reference-converted array literals retain the required Object element context")
Check(referenceArrayContextFirst <> Null And referenceArrayContextFirst.conversionKind = CONVERSION_REFERENCE And referenceArrayContextFirst.semanticType.DisplayName() = "Object", "derived literal elements receive explicit Object reference conversions")

Local omittedArgumentSource:String = "SuperStrict~nStruct SVec2I~nEnd Struct~nType TBitmapFont~nMethod GetSimpleDimension:SVec2I(s:String, trimWhitespace:Int=False, fixedLineHeight:Int=-1)~nEnd Method~nMethod Measure:SVec2I(s:String, fixedLineHeight:Int)~nLocal dim:SVec2I = GetSimpleDimension(s, ,fixedLineHeight)~nReturn dim~nEnd Method~nEnd Type"
Local omittedArgumentParse:TParseResult = TBlitzMaxParser.ParseText(omittedArgumentSource, "omitted-optional-argument.bmx")
Local omittedArgumentModel:TSemanticModel = TBlitzMaxSemanticAnalyzer.Analyze(omittedArgumentParse.syntaxTree)
TExpressionBinder.Bind(omittedArgumentModel)
Check(omittedArgumentModel.diagnostics.length = 0, "omitted optional call argument diagnostics")
Local bitmapFont:TTypeDeclarationSyntax = TTypeDeclarationSyntax(omittedArgumentParse.syntaxTree.root.members[2])
Local measureRoutine:TRoutineDeclarationSyntax = TRoutineDeclarationSyntax(bitmapFont.body.statements[1])
Local dimensionDeclaration:TVariableDeclarationStatementSyntax = TVariableDeclarationStatementSyntax(measureRoutine.body.statements[0])
Local dimensionCall:TCallExpressionSyntax = TCallExpressionSyntax(dimensionDeclaration.declarators[0].initializer)
Check(TOmittedArgumentExpressionSyntax(dimensionCall.arguments[1]) <> Null, "comma gap has explicit omitted-argument syntax")
Local dimensionResolution:TResolvedCall = omittedArgumentModel.ResolvedCall(dimensionCall)
Check(dimensionResolution <> Null And dimensionResolution.omittedArguments[1], "resolved call records use of the optional parameter default")
Local boundDimensionCall:TBoundCallExpression = TBoundCallExpression(omittedArgumentModel.BoundExpression(dimensionCall))
Local boundOmitted:TBoundOmittedArgumentExpression = TBoundOmittedArgumentExpression(boundDimensionCall.arguments[1])
Check(boundOmitted <> Null And boundOmitted.semanticType = omittedArgumentModel.BuiltinType("Int") And boundOmitted.parameter.optional, "bound omitted argument retains its parameter and type")

Local bracelessOmittedSource:String = "SuperStrict~nFunction UseDefaults(value:String, enabled:Int=False, count:Int=-1)~nEnd Function~nUseDefaults ~qvalue~q,,3"
Local bracelessOmittedParse:TParseResult = TBlitzMaxParser.ParseText(bracelessOmittedSource, "braceless-omitted-optional-argument.bmx")
Local bracelessOmittedModel:TSemanticModel = TBlitzMaxSemanticAnalyzer.Analyze(bracelessOmittedParse.syntaxTree)
TExpressionBinder.Bind(bracelessOmittedModel)
Check(bracelessOmittedModel.diagnostics.length = 0, "braceless calls preserve omitted optional argument positions")
Local bracelessOmittedCall:TCallStatementSyntax = TCallStatementSyntax(bracelessOmittedParse.syntaxTree.root.members[2])
Check(bracelessOmittedCall.argumentExpressions.length = 3 And TOmittedArgumentExpressionSyntax(bracelessOmittedCall.argumentExpressions[1]) <> Null, "braceless comma gap has explicit omitted-argument syntax")

Local requiredGapParse:TParseResult = TBlitzMaxParser.ParseText("SuperStrict~nFunction Required(a:Int, b:Int)~nEnd Function~nRequired(1,)", "omitted-required-argument.bmx")
Local requiredGapModel:TSemanticModel = TBlitzMaxSemanticAnalyzer.Analyze(requiredGapParse.syntaxTree)
TExpressionBinder.Bind(requiredGapModel)
Check(HasDiagnostic(requiredGapModel.diagnostics, "BMX3302"), "omitting a required argument remains an inapplicable call")

Local memberVarSource:String = "SuperStrict~nStruct SVarSettings~nEnd Struct~nStruct SVarEffect~nEnd Struct~nType TEffectBox~nField data:SVarEffect~nEnd Type~nType TSettingsBox~nField data:SVarSettings~nEnd Type~nType TVarFont~nGlobal defaultSettings:SVarSettings~nGlobal defaultEffect:SVarEffect~nEnd Type~nStruct SVarCalculator~nMethod Calculate(txt:String Var, width:Float, height:Float, font:TVarFont)~nCalculate(txt, width, height, font, TVarFont.defaultSettings)~nEnd Method~nMethod Calculate(txt:String Var, width:Float, height:Float, font:TVarFont, settings:SVarSettings Var)~nEnd Method~nEnd Struct~nType TVarCache~nMethod Cache:Int(font:TVarFont, text:String, w:Int, h:Int, alignment:Int, color:Int)~nReturn Cache(font, text, w, h, alignment, color, font.defaultEffect, font.defaultSettings)~nEnd Method~nMethod Cache:Int(font:TVarFont, text:String, w:Int, h:Int, alignment:Int, color:Int, effect:TEffectBox, settings:TSettingsBox)~nReturn Cache(font, text, w, h, alignment, color, effect.data, settings.data)~nEnd Method~nMethod Cache:Int(font:TVarFont, text:String, w:Int, h:Int, alignment:Int, color:Int, effect:SVarEffect Var, settings:SVarSettings Var)~nReturn 0~nEnd Method~nEnd Type"
Local memberVarParse:TParseResult = TBlitzMaxParser.ParseText(memberVarSource, "member-storage-var-arguments.bmx")
Local memberVarModel:TSemanticModel = TBlitzMaxSemanticAnalyzer.Analyze(memberVarParse.syntaxTree)
TExpressionBinder.Bind(memberVarModel)
Check(memberVarModel.diagnostics.length = 0, "Global and Field member storage can satisfy Var parameters")

Local constantTargetSource:String = "SuperStrict~nType TConstantTarget~nMethod Calc(a:Byte)~nEnd Method~nMethod Calc(a:UInt)~nEnd Method~nEnd Type~nLocal target:TConstantTarget = New TConstantTarget~ntarget.Calc(1)~ntarget.Calc(256)~nLocal byteValue:Byte = 1~nLocal uintValue:UInt = 256"
Local constantTargetParse:TParseResult = TBlitzMaxParser.ParseText(constantTargetSource, "constant-target-overloads.bmx")
Local constantTargetModel:TSemanticModel = TBlitzMaxSemanticAnalyzer.Analyze(constantTargetParse.syntaxTree)
TExpressionBinder.Bind(constantTargetModel)
Check(constantTargetModel.diagnostics.length = 0, "value-aware constant conversion diagnostics")
Local narrowestConstantCall:TCallExpressionSyntax = TCallExpressionSyntax(TCallStatementSyntax(constantTargetParse.syntaxTree.root.members[3]).expression)
Local rangedConstantCall:TCallExpressionSyntax = TCallExpressionSyntax(TCallStatementSyntax(constantTargetParse.syntaxTree.root.members[4]).expression)
Check(constantTargetModel.ResolvedCall(narrowestConstantCall).parameterTypes[0] = constantTargetModel.BuiltinType("Byte"), "Byte is the better compatible constant target than UInt")
Check(constantTargetModel.ResolvedCall(rangedConstantCall).parameterTypes[0] = constantTargetModel.BuiltinType("UInt"), "out-of-Byte-range constant selects UInt")

Local invalidConstantParse:TParseResult = TBlitzMaxParser.ParseText("SuperStrict~nLocal byteValue:Byte = 256", "invalid-constant-range.bmx")
Local invalidConstantModel:TSemanticModel = TBlitzMaxSemanticAnalyzer.Analyze(invalidConstantParse.syntaxTree)
TExpressionBinder.Bind(invalidConstantModel)
Check(invalidConstantModel.diagnostics.length = 0, "numeric narrowing is permitted for variable initialization")

Local constantExpressionTargetSource:String = "SuperStrict~nConst CHARSFORMAT_SCIENTIFIC:ULong = 1 Shl 0~nConst MASK:UInt = (1 Shl 4) | 3~nConst BYTE_LIMIT:Byte = 2 * 100 + 55"
Local constantExpressionTargetParse:TParseResult = TBlitzMaxParser.ParseText(constantExpressionTargetSource, "constant-expression-targets.bmx")
Local constantExpressionTargetModel:TSemanticModel = TBlitzMaxSemanticAnalyzer.Analyze(constantExpressionTargetParse.syntaxTree)
TExpressionBinder.Bind(constantExpressionTargetModel)
Check(constantExpressionTargetModel.diagnostics.length = 0, "integer constant expressions convert to compatible declared types")

Local invalidConstantExpressionParse:TParseResult = TBlitzMaxParser.ParseText("SuperStrict~nConst TOO_LARGE:Byte = 1 Shl 8", "invalid-constant-expression-target.bmx")
Local invalidConstantExpressionModel:TSemanticModel = TBlitzMaxSemanticAnalyzer.Analyze(invalidConstantExpressionParse.syntaxTree)
TExpressionBinder.Bind(invalidConstantExpressionModel)
Check(invalidConstantExpressionModel.diagnostics.length = 0, "numeric narrowing is permitted for Const initialization")

Local externGlobalSource:String = "SuperStrict~nExtern~nGlobal OnDebugStop()=~qbbOnDebugStop~q~nGlobal OnDebugLog(message:String)=~qbbOnDebugLog~q~nGlobal AppDir:String=~qbbAppDir~q~nGlobal AppArgs:String[]=~qbbAppArgs~q~nGlobal CountObjectInstances:Int=~qbbCountInstances~q~nFunction NativeCount:Int()=~qbbNativeCount~q~nEnd Extern"
Local externGlobalParse:TParseResult = TBlitzMaxParser.ParseText(externGlobalSource, "extern-globals.bmx")
Local externGlobalModel:TSemanticModel = TBlitzMaxSemanticAnalyzer.Analyze(externGlobalParse.syntaxTree)
TExpressionBinder.Bind(externGlobalModel)
Check(externGlobalModel.diagnostics.length = 0, "Extern linkage names are not checked as runtime initializers")
Local debugStopSymbol:TSymbol = externGlobalModel.globalScope.LookupLocal("OnDebugStop")[0]
Local appDirSymbol:TSymbol = externGlobalModel.globalScope.LookupLocal("AppDir")[0]
Local appArgsSymbol:TSymbol = externGlobalModel.globalScope.LookupLocal("AppArgs")[0]
Local countInstancesSymbol:TSymbol = externGlobalModel.globalScope.LookupLocal("CountObjectInstances")[0]
Local nativeCountSymbol:TSymbol = externGlobalModel.globalScope.LookupLocal("NativeCount")[0]
Check(debugStopSymbol.isExternal And debugStopSymbol.externalName = "bbOnDebugStop" And debugStopSymbol.declaredType.DisplayName() = "()", "external callable global retains callable type and link name")
Check(appDirSymbol.isExternal And appDirSymbol.externalName = "bbAppDir" And appDirSymbol.declaredType.DisplayName() = "String", "external String global retains declared type and link name")
Check(appArgsSymbol.isExternal And appArgsSymbol.externalName = "bbAppArgs" And appArgsSymbol.declaredType.DisplayName() = "String[]", "external array global retains declared type and link name")
Check(countInstancesSymbol.isExternal And countInstancesSymbol.externalName = "bbCountInstances" And countInstancesSymbol.declaredType.DisplayName() = "Int", "external numeric global retains declared type and link name")
Check(nativeCountSymbol.isExternal And nativeCountSymbol.externalName = "bbNativeCount", "external routine retains link name")
Local externBlockSyntax:TExternBlockSyntax = TExternBlockSyntax(externGlobalParse.syntaxTree.root.members[1])
Local externCallableDeclaration:TVariableDeclarationStatementSyntax = TVariableDeclarationStatementSyntax(externBlockSyntax.body.statements[0])
Local boundExternCallable:TBoundVariableDeclarationStatement = TBoundVariableDeclarationStatement(externGlobalModel.BoundStatement(externCallableDeclaration))
Check(boundExternCallable.variables[0].initializer = Null, "external linkage name does not become a bound runtime initializer")

Local ordinaryStringInitializerParse:TParseResult = TBlitzMaxParser.ParseText("SuperStrict~nGlobal count:Int = ~qbbCount~q", "ordinary-string-initializer.bmx")
Local ordinaryStringInitializerModel:TSemanticModel = TBlitzMaxSemanticAnalyzer.Analyze(ordinaryStringInitializerParse.syntaxTree)
TExpressionBinder.Bind(ordinaryStringInitializerModel)
Check(HasDiagnostic(ordinaryStringInitializerModel.diagnostics, "BMX3310"), "ordinary globals reject implicit String-to-number initialization")

Local implicitStringArgumentAnalysis:TLanguageAnalysis = TBlitzMaxLanguage.AnalyzeText("SuperStrict~nFunction Accept(value:Int)~nEnd Function~nAccept(~qhello~q)", "implicit-string-argument.bmx")
Check(HasDiagnostic(implicitStringArgumentAnalysis.model.diagnostics, "BMX3302"), "ordinary calls reject implicit String-to-number arguments")

Local genericStringConstructorSource:String = "SuperStrict~nType TBox<T>~nField value:T~nMethod New(value:T)~nSelf.value=value~nEnd Method~nEnd Type~nLocal value:TBox<Int>=New TBox<Int>(~qhello~q)"
Local genericStringConstructorAnalysis:TLanguageAnalysis = TBlitzMaxLanguage.AnalyzeText(genericStringConstructorSource, "implicit-string-generic-constructor.bmx")
Check(HasDiagnostic(genericStringConstructorAnalysis.model.diagnostics, "BMX3302"), "closed generic constructors reject implicit String-to-number arguments")

Local nestedGenericStringAssignmentSource:String = "SuperStrict~nType TBox<T>~nField value:T~nEnd Type~nType TPair<A,B>~nField first:A~nField second:B~nEnd Type~nLocal pair:TPair<String,TBox<Int>>~npair.second.value=~qhello~q"
Local nestedGenericStringAssignmentAnalysis:TLanguageAnalysis = TBlitzMaxLanguage.AnalyzeText(nestedGenericStringAssignmentSource, "implicit-string-nested-generic-member.bmx")
Check(HasDiagnostic(nestedGenericStringAssignmentAnalysis.model.diagnostics, "BMX3310"), "nested closed generic fields reject implicit String-to-number assignment")

Local explicitCastCallSource:String = "SuperStrict~nExtern~nFunction bbFloatAbs:Double(a:Double)=~qdouble bbFloatAbs(double)!~q~nEnd Extern~nFunction Abs:Float(a:Float) Inline~nReturn bbFloatAbs(Double(a))~nEnd Function"
Local explicitCastCallParse:TParseResult = TBlitzMaxParser.ParseText(explicitCastCallSource, "builtin-cast-call.bmx")
Local explicitCastCallModel:TSemanticModel = TBlitzMaxSemanticAnalyzer.Analyze(explicitCastCallParse.syntaxTree)
TExpressionBinder.Bind(explicitCastCallModel)
Check(explicitCastCallModel.diagnostics.length = 0, "explicit cast supplies the external call argument type")
Local absRoutineSyntax:TRoutineDeclarationSyntax = TRoutineDeclarationSyntax(explicitCastCallParse.syntaxTree.root.members[2])
Local absReturnSyntax:TReturnStatementSyntax = TReturnStatementSyntax(absRoutineSyntax.body.statements[0])
Local floatAbsCall:TCallExpressionSyntax = TCallExpressionSyntax(absReturnSyntax.expression)
Local doubleCast:TCastExpressionSyntax = TCastExpressionSyntax(floatAbsCall.arguments[0])
Check(doubleCast <> Null And explicitCastCallModel.ExpressionType(doubleCast) = explicitCastCallModel.BuiltinType("Double"), "explicit Double cast has the target semantic type")
Check(explicitCastCallModel.ResolvedCall(floatAbsCall) <> Null And explicitCastCallModel.ResolvedCall(floatAbsCall).parameterTypes[0] = explicitCastCallModel.BuiltinType("Double"), "external call resolves using explicit cast type")
Local boundDoubleCast:TBoundConversionExpression = TBoundConversionExpression(explicitCastCallModel.BoundExpression(doubleCast))
Check(boundDoubleCast <> Null And Not boundDoubleCast.implicitConversion And boundDoubleCast.operand.semanticType = explicitCastCallModel.BuiltinType("Float"), "explicit cast is retained in the bound model")

Local legacyStringConversionSource:String = "SuperStrict~nType TTextStream~nMethod ReadLine:String()~nReturn ~q12~q~nEnd Method~nMethod WriteLine(value:String)~nEnd Method~nMethod ReadByte:Int()~nReturn Int(ReadLine())~nEnd Method~nMethod WriteDouble(n:Double)~nWriteLine n~nEnd Method~nEnd Type"
Local legacyStringConversionParse:TParseResult = TBlitzMaxParser.ParseText(legacyStringConversionSource, "textstream-conversions.bmx")
Local legacyStringConversionModel:TSemanticModel = TBlitzMaxSemanticAnalyzer.Analyze(legacyStringConversionParse.syntaxTree)
TExpressionBinder.Bind(legacyStringConversionModel)
Check(legacyStringConversionModel.diagnostics.length = 0, "explicit String parsing and implicit numeric formatting bind in their supported directions")
Local textStreamSymbol:TSymbol = legacyStringConversionModel.globalScope.LookupLocal("TTextStream")[0]
Local readByteSymbol:TSymbol = textStreamSymbol.memberScope.LookupLocal("ReadByte")[0]
Local writeDoubleSymbol:TSymbol = textStreamSymbol.memberScope.LookupLocal("WriteDouble")[0]
Local boundReadByte:TBoundReturnStatement = TBoundReturnStatement(legacyStringConversionModel.BoundRoutineBody(readByteSymbol).statements[0])
Local boundStringToInt:TBoundConversionExpression = TBoundConversionExpression(boundReadByte.expression)
Check(boundStringToInt <> Null And boundStringToInt.conversionKind = CONVERSION_STRING_TO_NUMERIC And Not boundStringToInt.implicitConversion, "Int(String) is an explicit runtime String conversion")
Local boundWriteDouble:TBoundExpressionStatement = TBoundExpressionStatement(legacyStringConversionModel.BoundRoutineBody(writeDoubleSymbol).statements[0])
Local boundWriteLine:TBoundCallExpression = TBoundCallExpression(boundWriteDouble.expression)
Local boundDoubleToString:TBoundConversionExpression = TBoundConversionExpression(boundWriteLine.arguments[0])
Check(boundDoubleToString <> Null And boundDoubleToString.conversionKind = CONVERSION_NUMERIC_TO_STRING And boundDoubleToString.implicitConversion, "numeric WriteLine argument receives an implicit runtime String conversion")

Local stringPointerSource:String = "SuperStrict~nStruct RImage~nEnd Struct~nStruct RColor~nEnd Struct~nExtern~nFunction bmx_raylib_ImageDrawText(dst:RImage Var, txt:Byte Ptr, posX:Int, posY:Int, fontSize:Int, color:RColor)=~qImageDrawText~q~nEnd Extern~nFunction ImageDrawText(dst:RImage Var, txt:String, posX:Int, posY:Int, fontSize:Int, color:RColor)~nbmx_raylib_ImageDrawText(dst, txt, posX, posY, fontSize, color)~nEnd Function"
Local stringPointerParse:TParseResult = TBlitzMaxParser.ParseText(stringPointerSource, "string-byte-pointer-conversion.bmx")
Local stringPointerModel:TSemanticModel = TBlitzMaxSemanticAnalyzer.Analyze(stringPointerParse.syntaxTree)
TExpressionBinder.Bind(stringPointerModel)
Check(stringPointerModel.diagnostics.length = 0, "String argument implicitly converts to Byte Ptr for an external call")
Local imageDrawTextSymbol:TSymbol = stringPointerModel.globalScope.LookupLocal("ImageDrawText")[0]
Local imageDrawTextBody:TBoundBlockStatement = stringPointerModel.BoundRoutineBody(imageDrawTextSymbol)
Local imageDrawTextCall:TBoundCallExpression = TBoundCallExpression(TBoundExpressionStatement(imageDrawTextBody.statements[0]).expression)
Local stringPointerConversion:TBoundConversionExpression = TBoundConversionExpression(imageDrawTextCall.arguments[1])
Check(stringPointerConversion <> Null And stringPointerConversion.conversionKind = CONVERSION_STRING_TO_BYTE_POINTER And stringPointerConversion.implicitConversion, "bound call records the temporary UTF-8 String-to-Byte-Ptr conversion")

Local nativeStringsParse:TParseResult = TBlitzMaxParser.ParseText("SuperStrict~nExtern~nFunction NativeText:Int(utf8$z,utf16$w)=~qbcc2_native_text~q~nEnd Extern~nLocal value:Int=NativeText(~qhello~q,~qworld~q)", "native-string-parameters.bmx")
Local nativeStringsModel:TSemanticModel = TBlitzMaxSemanticAnalyzer.Analyze(nativeStringsParse.syntaxTree)
TExpressionBinder.Bind(nativeStringsModel)
Local nativeStringsSymbol:TSymbol = nativeStringsModel.globalScope.LookupLocal("NativeText")[0]
Check(nativeStringsModel.diagnostics.length = 0 And nativeStringsSymbol.parameters[0].semanticType = nativeStringsModel.BuiltinType("String") And nativeStringsSymbol.parameters[1].semanticType = nativeStringsModel.BuiltinType("String"), "$z and $w retain String source semantics")
Check(nativeStringsSymbol.parameters[0].nativeStringEncoding = NATIVE_STRING_UTF8 And nativeStringsSymbol.parameters[1].nativeStringEncoding = NATIVE_STRING_UTF16, "$z and $w retain distinct native encodings")
Check(TBoundDumper.Dump(stringPointerConversion).Contains("string-to-byte-pointer"), "bound dumper exposes String-to-Byte-Ptr lowering intent")

Local contextualFloatSource:String = "SuperStrict~nStruct RMatrix~nEnd Struct~nStruct RVector3~nEnd Struct~nFunction bmx_raymath_MatrixRotate:RMatrix(axis:RVector3, angle:Float)~nReturn New RMatrix~nEnd Function~nFunction MatrixRotate:RMatrix(axis:RVector3, angle:Float)~nReturn bmx_raymath_MatrixRotate(axis, angle * 0.0174533)~nEnd Function"
Local contextualFloatParse:TParseResult = TBlitzMaxParser.ParseText(contextualFloatSource, "contextual-float-expression.bmx")
Local contextualFloatModel:TSemanticModel = TBlitzMaxSemanticAnalyzer.Analyze(contextualFloatParse.syntaxTree)
TExpressionBinder.Bind(contextualFloatModel)
Check(contextualFloatModel.diagnostics.length = 0, "Float arithmetic with an unsuffixed fitting literal is contextually typed for a Float parameter")
Local matrixRotateSymbol:TSymbol = contextualFloatModel.globalScope.LookupLocal("MatrixRotate")[0]
Local matrixRotateBody:TBoundBlockStatement = contextualFloatModel.BoundRoutineBody(matrixRotateSymbol)
Local matrixRotateCall:TBoundCallExpression = TBoundCallExpression(TBoundReturnStatement(matrixRotateBody.statements[0]).expression)
Local contextualProduct:TBoundBinaryExpression = TBoundBinaryExpression(matrixRotateCall.arguments[1])
Check(contextualProduct <> Null And contextualProduct.semanticType = contextualFloatModel.BuiltinType("Float"), "bound arithmetic result adopts the contextual Float type")
Check(contextualProduct.left.semanticType = contextualFloatModel.BuiltinType("Float") And contextualProduct.right.semanticType = contextualFloatModel.BuiltinType("Float"), "contextual Float typing flows into both arithmetic operands")

Local nestedContextualFloatSource:String = "SuperStrict~nType TColor~nMethod FromHSL(h:Float, s:Float, l:Float)~nEnd Method~nMethod AdjustSaturation:TColor(percentage:Float = 1.0)~nLocal h:Float, s:Float, l:Float~nFromHSL(h, s * (1.0 + percentage), l)~nReturn Self~nEnd Method~nEnd Type"
Local nestedContextualFloatParse:TParseResult = TBlitzMaxParser.ParseText(nestedContextualFloatSource, "nested-contextual-float-expression.bmx")
Local nestedContextualFloatModel:TSemanticModel = TBlitzMaxSemanticAnalyzer.Analyze(nestedContextualFloatParse.syntaxTree)
TExpressionBinder.Bind(nestedContextualFloatModel)
Check(nestedContextualFloatModel.diagnostics.length = 0, "Float context reaches an unsuffixed literal through nested parenthesized arithmetic")
Local colorSymbol:TSymbol = nestedContextualFloatModel.globalScope.LookupLocal("TColor")[0]
Local adjustSaturationSymbol:TSymbol = colorSymbol.memberScope.LookupLocal("AdjustSaturation")[0]
Local adjustSaturationBody:TBoundBlockStatement = nestedContextualFloatModel.BoundRoutineBody(adjustSaturationSymbol)
Local fromHslCall:TBoundCallExpression = TBoundCallExpression(TBoundExpressionStatement(adjustSaturationBody.statements[1]).expression)
Local saturationProduct:TBoundBinaryExpression = TBoundBinaryExpression(fromHslCall.arguments[1])
Local saturationParentheses:TBoundPassthroughExpression = TBoundPassthroughExpression(saturationProduct.right)
Local saturationSum:TBoundBinaryExpression = TBoundBinaryExpression(saturationParentheses.operand)
Check(saturationProduct.semanticType = nestedContextualFloatModel.BuiltinType("Float") And saturationParentheses.semanticType = nestedContextualFloatModel.BuiltinType("Float") And saturationSum.semanticType = nestedContextualFloatModel.BuiltinType("Float"), "bound Float context propagates through the parenthesized sum")
Check(saturationSum.left.semanticType = nestedContextualFloatModel.BuiltinType("Float") And saturationSum.right.semanticType = nestedContextualFloatModel.BuiltinType("Float"), "nested Float arithmetic converts the literal but preserves the Float variable")

Local receiverSource:String = "SuperStrict~nType TReceiver~nField value:Int~nMethod Read:Int()~nReturn value~nEnd Method~nMethod Twice:Int()~nReturn Self.Read() + Read()~nEnd Method~nEnd Type~nLocal receiver:TReceiver = New TReceiver~nLocal result:Int = receiver.Read()"
Local receiverParse:TParseResult = TBlitzMaxParser.ParseText(receiverSource, "bound-receiver.bmx")
Local receiverModel:TSemanticModel = TBlitzMaxSemanticAnalyzer.Analyze(receiverParse.syntaxTree)
TExpressionBinder.Bind(receiverModel)
Check(receiverModel.diagnostics.length = 0, "explicit and implicit instance receiver fixture binds")
Local receiverTypeSymbol:TSymbol = receiverModel.globalScope.LookupLocal("TReceiver")[0]
Local readBody:TBoundBlockStatement = receiverModel.BoundRoutineBody(receiverTypeSymbol.memberScope.LookupLocal("Read")[0])
Local boundImplicitField:TBoundSymbolExpression = TBoundSymbolExpression(TBoundReturnStatement(readBody.statements[0]).expression)
Check(boundImplicitField <> Null And TBoundSelfExpression(boundImplicitField.receiver) <> Null And boundImplicitField.receiver.isSynthetic, "unqualified instance fields retain an implicit Self receiver")
Local twiceBody:TBoundBlockStatement = receiverModel.BoundRoutineBody(receiverTypeSymbol.memberScope.LookupLocal("Twice")[0])
Local boundReceiverCalls:TBoundBinaryExpression = TBoundBinaryExpression(TBoundReturnStatement(twiceBody.statements[0]).expression)
Local explicitSelfCall:TBoundCallExpression = TBoundCallExpression(boundReceiverCalls.left)
Local implicitSelfCall:TBoundCallExpression = TBoundCallExpression(boundReceiverCalls.right)
Check(TBoundSelfExpression(explicitSelfCall.receiver) <> Null And Not explicitSelfCall.receiver.isSynthetic, "Self.Method retains its explicit receiver")
Check(TBoundSelfExpression(implicitSelfCall.receiver) <> Null And implicitSelfCall.receiver.isSynthetic, "unqualified method calls retain a synthetic Self receiver")
Local receiverResultDeclaration:TVariableDeclarationStatementSyntax = TVariableDeclarationStatementSyntax(receiverParse.syntaxTree.root.members[3])
Local explicitObjectCall:TBoundCallExpression = TBoundCallExpression(TBoundVariableDeclarationStatement(receiverModel.BoundStatement(receiverResultDeclaration)).variables[0].initializer)
Check(TBoundSymbolExpression(explicitObjectCall.receiver) <> Null And TBoundSymbolExpression(explicitObjectCall.receiver).symbol.name = "receiver", "object.Method retains the explicit object receiver independently from its routine reference")
Local receiverDump:String = TBoundDumper.Dump(implicitSelfCall)
Check(receiverDump.Contains("BoundSelf") And receiverDump.Contains("implicit-receiver"), "bound dumps expose implicit instance receiver provenance")

Local realDoubleSource:String = "SuperStrict~nFunction NeedFloat(value:Float)~nEnd Function~nLocal measured:Double = 1.0~nNeedFloat(measured * 0.5)"
Local realDoubleParse:TParseResult = TBlitzMaxParser.ParseText(realDoubleSource, "genuine-double-expression.bmx")
Local realDoubleModel:TSemanticModel = TBlitzMaxSemanticAnalyzer.Analyze(realDoubleParse.syntaxTree)
TExpressionBinder.Bind(realDoubleModel)
Check(realDoubleModel.diagnostics.length = 0, "ordinary value arguments permit a genuine Double expression to narrow to Float")
Local realDoubleStatement:TCallStatementSyntax = TCallStatementSyntax(realDoubleParse.syntaxTree.root.members[realDoubleParse.syntaxTree.root.members.length - 1])
Local realDoubleCall:TCallExpressionSyntax = TCallExpressionSyntax(realDoubleStatement.expression)
Local boundRealDoubleCall:TBoundCallExpression = TBoundCallExpression(realDoubleModel.BoundExpression(realDoubleCall))
Check(TBoundConversionExpression(boundRealDoubleCall.arguments[0]).conversionKind = CONVERSION_NUMERIC_NARROWING, "Double-to-Float argument narrowing remains explicit in the bound model")

Local objectReferenceSource:String = "SuperStrict~nType TObjectStream~nEnd Type~nFunction OpenStream:TObjectStream(url:Object, readable:Int = True, writeMode:Int = 0)~nReturn Null~nEnd Function~nLocal path:String = ~qdata.txt~q~nLocal opened:TObjectStream = OpenStream(path, True, 0)~nLocal values:Int[]~nLocal arrayOpened:TObjectStream = OpenStream(values)~nLocal url:Object~nLocal casted:TObjectStream = TObjectStream(url)"
Local objectReferenceParse:TParseResult = TBlitzMaxParser.ParseText(objectReferenceSource, "object-reference-conversions.bmx")
Local objectReferenceModel:TSemanticModel = TBlitzMaxSemanticAnalyzer.Analyze(objectReferenceParse.syntaxTree)
TExpressionBinder.Bind(objectReferenceModel)
Check(objectReferenceModel.diagnostics.length = 0, "String and Array Object conversions plus named reference cast diagnostics")
Local openedDeclaration:TVariableDeclarationStatementSyntax = TVariableDeclarationStatementSyntax(objectReferenceParse.syntaxTree.root.members[4])
Local openStringCall:TCallExpressionSyntax = TCallExpressionSyntax(openedDeclaration.declarators[0].initializer)
Local boundOpenStringCall:TBoundCallExpression = TBoundCallExpression(objectReferenceModel.BoundExpression(openStringCall))
Check(objectReferenceModel.ResolvedCall(openStringCall) <> Null And TBoundConversionExpression(boundOpenStringCall.arguments[0]).conversionKind = CONVERSION_REFERENCE, "String argument implicitly converts to Object")
Local arrayOpenedDeclaration:TVariableDeclarationStatementSyntax = TVariableDeclarationStatementSyntax(objectReferenceParse.syntaxTree.root.members[6])
Local openArrayCall:TCallExpressionSyntax = TCallExpressionSyntax(arrayOpenedDeclaration.declarators[0].initializer)
Local boundOpenArrayCall:TBoundCallExpression = TBoundCallExpression(objectReferenceModel.BoundExpression(openArrayCall))
Check(objectReferenceModel.ResolvedCall(openArrayCall) <> Null And TBoundConversionExpression(boundOpenArrayCall.arguments[0]).conversionKind = CONVERSION_REFERENCE, "Array argument implicitly converts to Object")
Local castedDeclaration:TVariableDeclarationStatementSyntax = TVariableDeclarationStatementSyntax(objectReferenceParse.syntaxTree.root.members[8])
Local namedCastCall:TCallExpressionSyntax = TCallExpressionSyntax(castedDeclaration.declarators[0].initializer)
Local boundNamedCast:TBoundConversionExpression = TBoundConversionExpression(objectReferenceModel.BoundExpression(namedCastCall))
Check(objectReferenceModel.NamedCastTarget(namedCastCall).DisplayName() = "TObjectStream" And boundNamedCast <> Null And boundNamedCast.conversionKind = CONVERSION_EXPLICIT, "named type call syntax binds as an explicit downcast")

Local pointerModelSource:String = "SuperStrict~nStruct SPointerPosition~nField x:Int~nEnd Struct~nFunction Mutate(value:Int Var)~nvalue :+ 1~nEnd Function~nLocal b:Int Ptr[] = New Int Ptr[10]~nLocal a:Int Ptr[] Ptr = VarPtr b~nLocal positions:SPointerPosition Ptr~nLocal indexedValue:Int = positions[4].x~nLocal directValue:Int = positions.x~nLocal element:Int Ptr = b[0]~nMutate(positions.x)"
Local pointerModelParse:TParseResult = TBlitzMaxParser.ParseText(pointerModelSource, "pointer-model.bmx")
Local pointerModel:TSemanticModel = TBlitzMaxSemanticAnalyzer.Analyze(pointerModelParse.syntaxTree)
TExpressionBinder.Bind(pointerModel)
Check(pointerModel.diagnostics.length = 0, "ordered pointer, array, Var, and struct-pointer diagnostics")
Local mutateRoutine:TSymbol = pointerModel.globalScope.LookupLocal("Mutate")[0]
Check(mutateRoutine.parameters.length = 1 And mutateRoutine.parameters[0].passingMode = PARAMETER_PASS_VAR, "routine semantic parameter preserves Var mode")
Check(mutateRoutine.parameters[0].symbol.parameterMode = PARAMETER_PASS_VAR, "parameter symbol preserves Var mode")
Local mutateBody:TBoundBlockStatement = pointerModel.BoundRoutineBody(mutateRoutine)
Check(mutateBody <> Null And TBoundAssignmentStatement(mutateBody.statements[0]) <> Null, "compound assignment is available through the routine bound root")
Local pointerArrayDeclaration:TVariableDeclarationStatementSyntax = TVariableDeclarationStatementSyntax(pointerModelParse.syntaxTree.root.members[3])
Local pointerArrayCreation:TNewExpressionSyntax = TNewExpressionSyntax(pointerArrayDeclaration.declarators[0].initializer)
Check(pointerModel.ExpressionType(pointerArrayCreation).DisplayName() = "Int Ptr[]", "New Int Ptr dimensions construct an array of pointers")
Local boundPointerArrayCreation:TBoundNewExpression = TBoundNewExpression(pointerModel.BoundExpression(pointerArrayCreation))
Check(boundPointerArrayCreation <> Null And boundPointerArrayCreation.dimensionRanks[0] = 1 And boundPointerArrayCreation.semanticType.DisplayName() = "Int Ptr[]", "bound New operation retains array construction shape")
Local arrayPointerDeclaration:TVariableDeclarationStatementSyntax = TVariableDeclarationStatementSyntax(pointerModelParse.syntaxTree.root.members[4])
Check(pointerModel.ExpressionType(arrayPointerDeclaration.declarators[0].initializer).DisplayName() = "Int Ptr[] Ptr", "VarPtr array variable preserves ordered pointee type")
Local indexedPointerDeclaration:TVariableDeclarationStatementSyntax = TVariableDeclarationStatementSyntax(pointerModelParse.syntaxTree.root.members[6])
Local indexedPointerMember:TMemberAccessExpressionSyntax = TMemberAccessExpressionSyntax(indexedPointerDeclaration.declarators[0].initializer)
Local pointerIndex:TIndexExpressionSyntax = TIndexExpressionSyntax(indexedPointerMember.expression)
Check(pointerModel.ResolvedIndex(pointerIndex).accessKind = INDEX_ACCESS_POINTER, "struct pointer indexing is classified as raw pointer access")
Local boundPointerIndex:TBoundIndexExpression = TBoundIndexExpression(pointerModel.BoundExpression(pointerIndex))
Check(boundPointerIndex <> Null And boundPointerIndex.access.accessKind = INDEX_ACCESS_POINTER, "bound pointer index retains raw access operation")
Local directPointerDeclaration:TVariableDeclarationStatementSyntax = TVariableDeclarationStatementSyntax(pointerModelParse.syntaxTree.root.members[7])
Local directPointerMember:TMemberAccessExpressionSyntax = TMemberAccessExpressionSyntax(directPointerDeclaration.declarators[0].initializer)
Check(pointerModel.ResolvedMember(directPointerMember).implicitPointerDereference, "struct pointer direct member access records implicit dereference")
Local boundDirectPointerMember:TBoundMemberExpression = TBoundMemberExpression(pointerModel.BoundExpression(directPointerMember))
Check(boundDirectPointerMember <> Null And boundDirectPointerMember.access.implicitPointerDereference, "bound member makes implicit struct-pointer dereference explicit")
Local arrayElementDeclaration:TVariableDeclarationStatementSyntax = TVariableDeclarationStatementSyntax(pointerModelParse.syntaxTree.root.members[8])
Local arrayElementIndex:TIndexExpressionSyntax = TIndexExpressionSyntax(arrayElementDeclaration.declarators[0].initializer)
Check(pointerModel.ResolvedIndex(arrayElementIndex).accessKind = INDEX_ACCESS_ARRAY, "BlitzMax array indexing remains distinct from pointer indexing")
Local mutatePointerCall:TCallExpressionSyntax = TCallExpressionSyntax(TCallStatementSyntax(pointerModelParse.syntaxTree.root.members[9]).expression)
Check(pointerModel.ResolvedCall(mutatePointerCall) <> Null, "implicitly dereferenced struct field is addressable for Var argument")
Check(TBoundDumper.Dump(boundDirectPointerMember).Contains("implicit-deref"), "bound dumper exposes implicit pointer dereference")
Check(pointerModel.boundGlobalBody <> Null And pointerModel.boundGlobalBody.statements.length = 7, "global bound root contains executable declarations and statements but not source declarations")

Local pointerVarSource:String = "SuperStrict~nFunction CompareAndSwap:Int(target:Int Var,oldValue:Int,newValue:Int)~nReturn target~nEnd Function~nLocal value:Int=40~nLocal pointer:Int Ptr=Varptr value~nLocal changed:Int=CompareAndSwap(pointer,40,42)"
Local pointerVarParse:TParseResult = TBlitzMaxParser.ParseText(pointerVarSource, "pointer-var-argument.bmx")
Local pointerVarModel:TSemanticModel = TBlitzMaxSemanticAnalyzer.Analyze(pointerVarParse.syntaxTree)
TExpressionBinder.Bind(pointerVarModel)
Check(pointerVarModel.diagnostics.length = 0, "a matching typed pointer supplies the pointed storage to a Var parameter")
Local pointerVarDeclaration:TVariableDeclarationStatementSyntax = TVariableDeclarationStatementSyntax(pointerVarParse.syntaxTree.root.members[4])
Local pointerVarCall:TCallExpressionSyntax = TCallExpressionSyntax(pointerVarDeclaration.declarators[0].initializer)
Local boundPointerVarCall:TBoundCallExpression = TBoundCallExpression(pointerVarModel.BoundExpression(pointerVarCall))
Check(TBoundConversionExpression(boundPointerVarCall.arguments[0]).conversionKind = CONVERSION_POINTER_TO_VAR_REFERENCE, "pointer-to-Var storage adaptation remains explicit in the bound model")

Local structSelfVarSource:String = "SuperStrict~nStruct b2AABB~nMethod IsValid:Int()~nReturn bmx_b2abb_isvalid(Self)~nEnd Method~nEnd Struct~nFunction bmx_b2abb_isvalid:Int(handle:b2AABB Var)~nReturn True~nEnd Function"
Local structSelfVarParse:TParseResult = TBlitzMaxParser.ParseText(structSelfVarSource, "struct-self-var.bmx")
Local structSelfVarModel:TSemanticModel = TBlitzMaxSemanticAnalyzer.Analyze(structSelfVarParse.syntaxTree)
TExpressionBinder.Bind(structSelfVarModel)
Check(structSelfVarModel.diagnostics.length = 0, "Struct Self is addressable when passed to a matching Var parameter")
Local structSelfDeclaration:TTypeDeclarationSyntax = TTypeDeclarationSyntax(structSelfVarParse.syntaxTree.root.members[1])
Local structSelfMethod:TRoutineDeclarationSyntax = TRoutineDeclarationSyntax(structSelfDeclaration.body.statements[0])
Local structSelfReturn:TReturnStatementSyntax = TReturnStatementSyntax(structSelfMethod.body.statements[0])
Local structSelfCall:TCallExpressionSyntax = TCallExpressionSyntax(structSelfReturn.expression)
Check(structSelfVarModel.ResolvedCall(structSelfCall) <> Null And structSelfVarModel.ResolvedCall(structSelfCall).routine.parameters[0].passingMode = PARAMETER_PASS_VAR, "Struct Self call retains the selected Var parameter")

Local objectVarSource:String = "SuperStrict~nType TGameBase~nEnd Type~nType THelper~nFunction TakeOverObjectValues:Object(source:Object, target:Object Var, skipFields:String = ~q~q, deepCopy:Int = False)~nReturn target~nEnd Function~nEnd Type~nType TGame~nField instance:TGameBase~nMethod Replace(oldInstance:TGameBase)~nTHelper.TakeOverObjectValues(oldInstance, instance)~nEnd Method~nEnd Type"
Local objectVarParse:TParseResult = TBlitzMaxParser.ParseText(objectVarSource, "object-var-reference.bmx")
Local objectVarModel:TSemanticModel = TBlitzMaxSemanticAnalyzer.Analyze(objectVarParse.syntaxTree)
TExpressionBinder.Bind(objectVarModel)
Check(objectVarModel.diagnostics.length = 0, "derived object storage is accepted by an Object Var parameter with omitted optional arguments")
Local objectVarGame:TTypeDeclarationSyntax = TTypeDeclarationSyntax(objectVarParse.syntaxTree.root.members[3])
Local objectVarReplace:TRoutineDeclarationSyntax = TRoutineDeclarationSyntax(objectVarGame.body.statements[1])
Local objectVarStatement:TCallStatementSyntax = TCallStatementSyntax(objectVarReplace.body.statements[0])
Local objectVarCall:TCallExpressionSyntax = TCallExpressionSyntax(objectVarStatement.expression)
Local resolvedObjectVar:TResolvedCall = objectVarModel.ResolvedCall(objectVarCall)
Check(resolvedObjectVar <> Null And resolvedObjectVar.routine.parameters[1].passingMode = PARAMETER_PASS_VAR, "Object Var overload retains its by-reference parameter mode")
Local boundObjectVar:TBoundCallExpression = TBoundCallExpression(objectVarModel.BoundExpression(objectVarCall))
Check(TBoundConversionExpression(boundObjectVar.arguments[1]).conversionKind = CONVERSION_VAR_REFERENCE, "bound Object Var argument records its reference-storage adaptation")

Local invalidVarPtrParse:TParseResult = TBlitzMaxParser.ParseText("SuperStrict~nLocal pointer:Int Ptr = VarPtr (1 + 2)", "invalid-varptr.bmx")
Local invalidVarPtrModel:TSemanticModel = TBlitzMaxSemanticAnalyzer.Analyze(invalidVarPtrParse.syntaxTree)
TExpressionBinder.Bind(invalidVarPtrModel)
Check(invalidVarPtrModel.diagnostics.length = 1 And invalidVarPtrModel.diagnostics[0].code = "BMX3311", "VarPtr rejects non-addressable temporary expression")

Local narrowingParse:TParseResult = TBlitzMaxParser.ParseText("SuperStrict~nFunction NeedInt(value:Int)~nEnd Function~nLocal wide:Double~nNeedInt(wide)", "invalid-narrowing.bmx")
Local narrowingModel:TSemanticModel = TBlitzMaxSemanticAnalyzer.Analyze(narrowingParse.syntaxTree)
TExpressionBinder.Bind(narrowingModel)
Check(narrowingModel.diagnostics.length = 0, "ordinary value arguments permit numeric narrowing")
Local narrowingStatement:TCallStatementSyntax = TCallStatementSyntax(narrowingParse.syntaxTree.root.members[narrowingParse.syntaxTree.root.members.length - 1])
Local narrowingCall:TCallExpressionSyntax = TCallExpressionSyntax(narrowingStatement.expression)
Local boundNarrowingCall:TBoundCallExpression = TBoundCallExpression(narrowingModel.BoundExpression(narrowingCall))
Check(TBoundConversionExpression(boundNarrowingCall.arguments[0]).conversionKind = CONVERSION_NUMERIC_NARROWING, "wide numeric arguments retain an explicit narrowing conversion")

Local uncalledSource:String = "SuperStrict~nFunction Show(value:String)~nEnd Function~nType TThing~nMethod Something:Int()~nReturn 1~nEnd Method~nEnd Type~nLocal thing:TThing = New TThing~nShow thing.Something"
Local uncalledParse:TParseResult = TBlitzMaxParser.ParseText(uncalledSource, "uncalled-method.bmx")
Local uncalledModel:TSemanticModel = TBlitzMaxSemanticAnalyzer.Analyze(uncalledParse.syntaxTree)
TExpressionBinder.Bind(uncalledModel)
Check(uncalledModel.diagnostics.length = 1 And uncalledModel.diagnostics[0].code = "BMX3314", "uncalled method reference receives a dedicated diagnostic")
Check(uncalledModel.diagnostics[0].message.Contains("Method 'Something' is being used as a value rather than called") And uncalledModel.diagnostics[0].message.Contains("thing.Something()"), "uncalled method diagnostic explains the fix")
Check(Not uncalledModel.diagnostics[0].message.Contains("No applicable overload"), "uncalled method diagnostic replaces generic overload failure")

Local uncalledFunctionSource:String = "SuperStrict~nFunction Show(value:String)~nEnd Function~nFunction Amount:Int()~nReturn 1~nEnd Function~nLocal callback:Int() = Amount~nLocal text:String = Amount"
Local uncalledFunctionParse:TParseResult = TBlitzMaxParser.ParseText(uncalledFunctionSource, "uncalled-function.bmx")
Local uncalledFunctionModel:TSemanticModel = TBlitzMaxSemanticAnalyzer.Analyze(uncalledFunctionParse.syntaxTree)
TExpressionBinder.Bind(uncalledFunctionModel)
Check(uncalledFunctionModel.diagnostics.length = 0, "a zero-argument Function is implicitly invoked in a non-callable assignment context")
Local uncalledFunctionText:TVariableDeclarationStatementSyntax = TVariableDeclarationStatementSyntax(uncalledFunctionParse.syntaxTree.root.members[4])
Local boundUncalledFunctionText:TBoundVariableDeclarationStatement = TBoundVariableDeclarationStatement(uncalledFunctionModel.BoundStatement(uncalledFunctionText))
Local uncalledFunctionTextConversion:TBoundConversionExpression = TBoundConversionExpression(boundUncalledFunctionText.variables[0].initializer)
Check(uncalledFunctionTextConversion <> Null And TBoundCallExpression(uncalledFunctionTextConversion.operand) <> Null, "implicit zero-argument Function invocation is explicit before its contextual result conversion while callable assignment remains a routine reference")

Local implicitSuperSource:String = "SuperStrict~nType TImplicitSuperBase~nMethod Name:String()~nReturn ~qbase~q~nEnd Method~nEnd Type~nType TImplicitSuperDerived Extends TImplicitSuperBase~nMethod Name:String() Override~nReturn Super.Name~nEnd Method~nEnd Type"
Local implicitSuperParse:TParseResult = TBlitzMaxParser.ParseText(implicitSuperSource, "implicit-super-call.bmx")
Local implicitSuperModel:TSemanticModel = TBlitzMaxSemanticAnalyzer.Analyze(implicitSuperParse.syntaxTree)
TExpressionBinder.Bind(implicitSuperModel)
Check(implicitSuperModel.diagnostics.length = 0, "a zero-argument Super method is implicitly invoked in Return value context")
Local implicitSuperDerived:TTypeDeclarationSyntax = TTypeDeclarationSyntax(implicitSuperParse.syntaxTree.root.members[2])
Local implicitSuperMethod:TRoutineDeclarationSyntax = TRoutineDeclarationSyntax(implicitSuperDerived.body.statements[0])
Local implicitSuperSymbol:TSymbol = implicitSuperModel.DeclaredSymbol(implicitSuperMethod)
Local boundImplicitSuperReturn:TBoundReturnStatement = TBoundReturnStatement(implicitSuperModel.BoundRoutineBody(implicitSuperSymbol).statements[0])
Check(TBoundCallExpression(boundImplicitSuperReturn.expression) <> Null And TBoundSelfExpression(TBoundCallExpression(boundImplicitSuperReturn.expression).receiver).isSuper, "implicit Super invocation retains direct base-dispatch receiver identity")

Local typedSuperCallSource:String = "SuperStrict~nType TTypedSuperBase~nMethod Apply:Int(day:Int, hour:Int, minute:Int, value:Object)~nReturn 1~nEnd Method~nEnd Type~nType TTypedSuperDerived Extends TTypedSuperBase~nMethod Apply:Int(day:Int, hour:Int, minute:Int, value:Object) Override~nReturn Super.Apply:Int(day, hour, minute, value)~nEnd Method~nEnd Type"
Local typedSuperCallParse:TParseResult = TBlitzMaxParser.ParseText(typedSuperCallSource, "typed-super-call.bmx")
Local typedSuperCallModel:TSemanticModel = TBlitzMaxSemanticAnalyzer.Analyze(typedSuperCallParse.syntaxTree)
TExpressionBinder.Bind(typedSuperCallModel)
Check(typedSuperCallParse.syntaxTree.diagnostics.length = 1 And typedSuperCallParse.syntaxTree.diagnostics[0].code = "BMX2105", "a type annotation on a call target is rejected as postfix expression syntax")
Check(typedSuperCallParse.syntaxTree.diagnostics[0].message.Contains("Type(expression)"), "the tagged-call diagnostic identifies explicit conversion syntax")
Check(typedSuperCallModel.diagnostics.length = 0, "a rejected postfix call type does not produce duplicate semantic diagnostics")

Local strictUntypedSource:String = "Strict~nFunction Show(value:String)~nEnd Function~nLocal g = 100~nShow g"
Local strictUntypedParse:TParseResult = TBlitzMaxParser.ParseText(strictUntypedSource, "strict-untyped-local.bmx")
Local strictUntypedModel:TSemanticModel = TBlitzMaxSemanticAnalyzer.Analyze(strictUntypedParse.syntaxTree)
TExpressionBinder.Bind(strictUntypedModel)
Local strictUntypedSymbol:TSymbol = strictUntypedModel.globalScope.LookupLocal("g")[0]
Check(strictUntypedSymbol.declaredType = strictUntypedModel.BuiltinType("Int"), "Strict omitted local type defaults to Int")
Check(strictUntypedModel.diagnostics.length = 0, "Strict omitted local type remains usable by later expressions")

Local superStrictUntypedSource:String = "SuperStrict~nFunction Show(value:String)~nEnd Function~nLocal g = 100~nShow g"
Local superStrictUntypedParse:TParseResult = TBlitzMaxParser.ParseText(superStrictUntypedSource, "superstrict-untyped-local.bmx")
Local superStrictUntypedModel:TSemanticModel = TBlitzMaxSemanticAnalyzer.Analyze(superStrictUntypedParse.syntaxTree)
TExpressionBinder.Bind(superStrictUntypedModel)
Local superStrictUntypedSymbol:TSymbol = superStrictUntypedModel.globalScope.LookupLocal("g")[0]
Check(superStrictUntypedSymbol.declaredType = superStrictUntypedModel.BuiltinType("Int"), "SuperStrict missing annotation retains an Int recovery type")
Check(superStrictUntypedModel.diagnostics.length = 1 And superStrictUntypedModel.diagnostics[0].code = "BMX3103", "SuperStrict omitted local type reports one focused diagnostic")
Check(superStrictUntypedModel.diagnostics[0].message.Contains("Local 'g' requires an explicit type"), "SuperStrict omitted local diagnostic explains the requirement")

Local recoveryParse:TParseResult = TBlitzMaxParser.ParseText("SuperStrict~nFunction NeedIntArray(value:Int)~nEnd Function~nNeedIntArray([MissingElement])", "incomplete-array-recovery.bmx")
Local recoveryModel:TSemanticModel = TBlitzMaxSemanticAnalyzer.Analyze(recoveryParse.syntaxTree)
TExpressionBinder.Bind(recoveryModel)
Check(recoveryModel.diagnostics.length >= 2, "unresolved array element and inapplicable call both produce diagnostics")
Local recoveryMessage:String
For Local diagnostic:TDiagnostic = EachIn recoveryModel.diagnostics
	If diagnostic.code = "BMX3302" Then recoveryMessage = diagnostic.message
Next
Check(recoveryMessage.Contains("<unresolved array element>[]"), "inapplicable overload formatting tolerates incomplete array element types")

Local stringIndexSource:String = "SuperStrict~nType TStringWriter~nMethod WriteChar(char:Int)~nEnd Method~nMethod WriteString(str:String)~nFor Local i:Int = 0 Until 1~nWriteChar str[i]~nNext~nEnd Method~nEnd Type~nLocal code:Int = ~qA~q[0]~nLocal piece:String = ~qABC~q[0..1]"
Local stringIndexParse:TParseResult = TBlitzMaxParser.ParseText(stringIndexSource, "string-indexing.bmx")
Local stringIndexModel:TSemanticModel = TBlitzMaxSemanticAnalyzer.Analyze(stringIndexParse.syntaxTree)
TExpressionBinder.Bind(stringIndexModel)
Check(stringIndexModel.diagnostics.length = 0, "String character indexing and slicing diagnostics")
Local codeDeclaration:TVariableDeclarationStatementSyntax = TVariableDeclarationStatementSyntax(stringIndexParse.syntaxTree.root.members[2])
Local characterIndex:TIndexExpressionSyntax = TIndexExpressionSyntax(codeDeclaration.declarators[0].initializer)
Check(stringIndexModel.ExpressionType(characterIndex) = stringIndexModel.BuiltinType("Int") And stringIndexModel.ResolvedIndex(characterIndex).accessKind = INDEX_ACCESS_STRING, "String single index returns an Int character code")
Local pieceDeclaration:TVariableDeclarationStatementSyntax = TVariableDeclarationStatementSyntax(stringIndexParse.syntaxTree.root.members[3])
Local stringSlice:TSliceExpressionSyntax = TSliceExpressionSyntax(pieceDeclaration.declarators[0].initializer)
Check(stringIndexModel.ExpressionType(stringSlice) = stringIndexModel.BuiltinType("String") And TBoundSliceExpression(stringIndexModel.BoundExpression(stringSlice)) <> Null, "String slice returns String and has a bound slice node")

Local numericSliceAnalysis:TLanguageAnalysis = TBlitzMaxLanguage.AnalyzeText("SuperStrict~nFunction Transform(scale:Float = 1:Double)~nEnd Function~nLocal count:Int=4~nLocal values:Int[]~nvalues=values[..((count+4)*1.2)]", "numeric-slice-context.bmx")
Check(numericSliceAnalysis.Succeeded(), "routine defaults use assignment conversion and numeric slice bounds convert contextually to Int")

Local numericIndexAnalysis:TLanguageAnalysis = TBlitzMaxLanguage.AnalyzeText("SuperStrict~nLocal values:Int[]=New Int[2]~nLocal offset:Float=1~nLocal value:Int=values[offset]", "numeric-index-context.bmx")
Check(numericIndexAnalysis.Succeeded(), "built-in indexing retains the production numeric-to-UInt adaptation")
Local numericIndexDeclaration:TVariableDeclarationStatementSyntax = TVariableDeclarationStatementSyntax(numericIndexAnalysis.syntaxTree.root.members[numericIndexAnalysis.syntaxTree.root.members.length - 1])
Local numericIndexSyntax:TIndexExpressionSyntax = TIndexExpressionSyntax(numericIndexDeclaration.declarators[0].initializer)
Local numericIndexBound:TBoundIndexExpression = TBoundIndexExpression(numericIndexAnalysis.model.BoundExpression(numericIndexSyntax))
Local numericIndexConversion:TBoundConversionExpression
If numericIndexBound And numericIndexBound.indexes.length Then numericIndexConversion = TBoundConversionExpression(numericIndexBound.indexes[0])
Check(numericIndexConversion And numericIndexConversion.conversionKind = CONVERSION_NUMERIC_NARROWING And numericIndexConversion.semanticType.DisplayName() = "UInt", "Float array indexes lower through an explicit UInt conversion")

Local staticGenericQualifierAnalysis:TLanguageAnalysis = TBlitzMaxLanguage.AnalyzeText("SuperStrict~nStruct Optional<T>~nFunction FromValue:Optional<T>(value:T)~nLocal result:Optional<T>~nReturn result~nEnd Function~nEnd Struct~nLocal value:Optional<Int> = Optional<Int>.FromValue(7)", "static-generic-qualifier.bmx")
Check(staticGenericQualifierAnalysis.Succeeded(), "a closed generic Struct can explicitly qualify a Type Function call")
Local staticGenericDeclaration:TVariableDeclarationStatementSyntax = TVariableDeclarationStatementSyntax(staticGenericQualifierAnalysis.syntaxTree.root.members[staticGenericQualifierAnalysis.syntaxTree.root.members.length - 1])
Local staticGenericCall:TCallExpressionSyntax = TCallExpressionSyntax(staticGenericDeclaration.declarators[0].initializer)
Local staticGenericBoundCall:TBoundCallExpression = TBoundCallExpression(staticGenericQualifierAnalysis.model.BoundExpression(staticGenericCall))
Check(staticGenericBoundCall And staticGenericBoundCall.staticReceiverType And staticGenericBoundCall.staticReceiverType.DisplayName() = "Optional<Int>", "bound Type Function call retains its closed static receiver")

Local multiGenericQualifierAnalysis:TLanguageAnalysis = TBlitzMaxLanguage.AnalyzeText("SuperStrict~nStruct Result<T,E>~nFunction Ok:Result<T,E>(value:T)~nLocal result:Result<T,E>~nReturn result~nEnd Function~nEnd Struct~nLocal value:Result<Int,String> = Result<Int,String>.Ok(7)", "multi-generic-static-qualifier.bmx")
Check(multiGenericQualifierAnalysis.Succeeded(), "a multi-argument closed generic Struct can qualify a Type Function without splitting its type argument comma")
Local multiGenericDeclaration:TVariableDeclarationStatementSyntax = TVariableDeclarationStatementSyntax(multiGenericQualifierAnalysis.syntaxTree.root.members[multiGenericQualifierAnalysis.syntaxTree.root.members.length - 1])
Check(multiGenericDeclaration.declarators.length = 1, "a multi-argument generic static qualifier remains one variable declarator")
Local multiGenericCall:TCallExpressionSyntax = TCallExpressionSyntax(multiGenericDeclaration.declarators[0].initializer)
Local multiGenericBoundCall:TBoundCallExpression = TBoundCallExpression(multiGenericQualifierAnalysis.model.BoundExpression(multiGenericCall))
Check(multiGenericBoundCall And multiGenericBoundCall.staticReceiverType And multiGenericBoundCall.staticReceiverType.DisplayName() = "Result<Int, String>", "bound multi-argument Type Function call retains its closed static receiver")


Local pointerArithmeticSource:String = "SuperStrict~nType TByteReader~nMethod Read:Long(buf:Byte Ptr, count:Long)~nReturn 0~nEnd Method~nEnd Type~nLocal reader:TByteReader = New TByteReader~nLocal data:Byte[1024]~nLocal size:Int~nsize :+ reader.Read((Byte Ptr data) + size, 1024 - size - 1)"
Local pointerArithmeticParse:TParseResult = TBlitzMaxParser.ParseText(pointerArithmeticSource, "pointer-arithmetic-call.bmx")
Local pointerArithmeticModel:TSemanticModel = TBlitzMaxSemanticAnalyzer.Analyze(pointerArithmeticParse.syntaxTree)
TExpressionBinder.Bind(pointerArithmeticModel)
Check(pointerArithmeticModel.diagnostics.length = 0, "pointer arithmetic call argument diagnostics")
Local pointerReadAssignment:TAssignmentStatementSyntax = TAssignmentStatementSyntax(pointerArithmeticParse.syntaxTree.root.members[5])
Local pointerReadCall:TCallExpressionSyntax = TCallExpressionSyntax(pointerReadAssignment.right)
Local pointerAddition:TBinaryExpressionSyntax = TBinaryExpressionSyntax(pointerReadCall.arguments[0])
Check(pointerArithmeticModel.ExpressionType(pointerAddition).DisplayName() = "Byte Ptr" And pointerArithmeticModel.ResolvedCall(pointerReadCall) <> Null, "Byte Ptr plus Int remains Byte Ptr and resolves Read")

Local pointerDifferenceAnalysis:TLanguageAnalysis = TBlitzMaxLanguage.AnalyzeText("SuperStrict~nLocal first:Byte Ptr~nLocal last:Byte Ptr~nLocal fixed:Byte[16]~nLocal distance:Size_T=last-first~nLocal used:Size_T=last-fixed", "pointer-difference.bmx")
Local pointerDifferenceExpression:TExpressionSyntax
Local pointerStaticDifferenceExpression:TExpressionSyntax
For Local pointerDifferenceMember:TSyntaxNode = EachIn pointerDifferenceAnalysis.syntaxTree.root.members
	Local pointerDifferenceDeclaration:TVariableDeclarationStatementSyntax = TVariableDeclarationStatementSyntax(pointerDifferenceMember)
	If pointerDifferenceDeclaration And pointerDifferenceDeclaration.declarators.length Then
		Select pointerDifferenceDeclaration.declarators[0].nameToken.text.ToLower()
			Case "distance" pointerDifferenceExpression = pointerDifferenceDeclaration.declarators[0].initializer
			Case "used" pointerStaticDifferenceExpression = pointerDifferenceDeclaration.declarators[0].initializer
		End Select
	End If
Next
Check(pointerDifferenceAnalysis.Succeeded() And pointerDifferenceAnalysis.model.ExpressionType(pointerDifferenceExpression) = pointerDifferenceAnalysis.model.BuiltinType("Int"), "pointer subtraction produces the production Int difference and widens to Size_T")
Check(pointerDifferenceAnalysis.Succeeded() And pointerDifferenceAnalysis.model.ExpressionType(pointerStaticDifferenceExpression) = pointerDifferenceAnalysis.model.BuiltinType("Int"), "pointer subtraction decays managed Array storage and produces the production Int difference")

Local legacyMemorySource:String = "SuperStrict~nFunction ReadBytes(buf:Byte Ptr, count:Long)~nEnd Function~nFunction NativeLength:Size_T()~nReturn 0~nEnd Function~nLocal n:Short~nReadBytes VarPtr n, 2~nLocal bytes:Byte Ptr~nReadBytes bytes, NativeLength()~nLocal i:Long~nLocal value:Int = bytes[i]~nLocal text:String~nLocal character:Int = text[i]~nLocal length:Int = NativeLength()~nLocal values:Int[]~nLocal combined:Int = Len(text) + Len(values) + Len(42)"
Local legacyMemoryParse:TParseResult = TBlitzMaxParser.ParseText(legacyMemorySource, "legacy-memory-expressions.bmx")
Local legacyMemoryModel:TSemanticModel = TBlitzMaxSemanticAnalyzer.Analyze(legacyMemoryParse.syntaxTree)
TExpressionBinder.Bind(legacyMemoryModel)
Check(legacyMemoryModel.diagnostics.length = 0, "typed pointer to Byte Ptr, Long indexing, Size_T narrowing, and Len diagnostics")

Local legacyUnsignedWideSource:String = "SuperStrict~nFunction Consume(value:ULong)~nEnd Function~nLocal legacy:ULongInt~nConsume legacy"
Local legacyUnsignedWideModel:TSemanticModel = TBlitzMaxSemanticAnalyzer.Analyze(TBlitzMaxParser.ParseText(legacyUnsignedWideSource, "legacy-unsigned-wide.bmx").syntaxTree)
Check(legacyUnsignedWideModel.diagnostics.length = 0, "legacy ULongInt values bind to an available ULong parameter without erasing their distinct declared ABI")
Local nativeSizeConversions:TConversionClassifier = TConversionClassifier.Create(legacyMemoryModel)
Local sizeToLong:TConversion = nativeSizeConversions.Classify(legacyMemoryModel.BuiltinType("Size_T"), legacyMemoryModel.BuiltinType("Long"))
Check(sizeToLong.Exists() And sizeToLong.kind = CONVERSION_NUMERIC_WIDENING, "Size_T is accepted by native-count APIs using Long")
Local readBytesStatement:TCallStatementSyntax = TCallStatementSyntax(legacyMemoryParse.syntaxTree.root.members[4])
Local boundReadBytesStatement:TBoundExpressionStatement = TBoundExpressionStatement(legacyMemoryModel.BoundStatement(readBytesStatement))
Local boundReadBytes:TBoundCallExpression = TBoundCallExpression(boundReadBytesStatement.expression)
Check(TBoundConversionExpression(boundReadBytes.arguments[0]).conversionKind = CONVERSION_POINTER_TO_BYTE_POINTER, "Short Ptr implicitly converts to raw Byte Ptr argument")
Local pointerValueDeclaration:TVariableDeclarationStatementSyntax = TVariableDeclarationStatementSyntax(legacyMemoryParse.syntaxTree.root.members[8])
Local longPointerIndex:TIndexExpressionSyntax = TIndexExpressionSyntax(pointerValueDeclaration.declarators[0].initializer)
Check(legacyMemoryModel.ExpressionType(longPointerIndex) = legacyMemoryModel.BuiltinType("Byte"), "Long pointer index preserves pointed element type")
Local characterDeclaration:TVariableDeclarationStatementSyntax = TVariableDeclarationStatementSyntax(legacyMemoryParse.syntaxTree.root.members[10])
Check(legacyMemoryModel.ExpressionType(TIndexExpressionSyntax(characterDeclaration.declarators[0].initializer)) = legacyMemoryModel.BuiltinType("Int"), "Long String index returns character code")
Local lengthDeclaration:TVariableDeclarationStatementSyntax = TVariableDeclarationStatementSyntax(legacyMemoryParse.syntaxTree.root.members[11])
Local boundLength:TBoundVariableDeclarationStatement = TBoundVariableDeclarationStatement(legacyMemoryModel.BoundStatement(lengthDeclaration))
Check(TBoundConversionExpression(boundLength.variables[0].initializer).conversionKind = CONVERSION_NUMERIC_NARROWING, "Size_T to Int assignment is retained as an explicit narrowing operation in the bound model")
Local combinedDeclaration:TVariableDeclarationStatementSyntax = TVariableDeclarationStatementSyntax(legacyMemoryParse.syntaxTree.root.members[13])
Check(legacyMemoryModel.ExpressionType(combinedDeclaration.declarators[0].initializer) = legacyMemoryModel.BuiltinType("Int"), "Len accepts String, Array, and legacy scalar operands")

Local rawStorageSource:String = "SuperStrict~nStruct SMetaField~nField value:Int~nEnd Struct~nFunction Register(fields:Byte Ptr)~nEnd Function~nLocal fields:SMetaField[]~nRegister(fields)~nLocal components:Int[]~nLocal ids:ULong Ptr = StackAlloc(8)~nLocal scalarSize:Size_T = SizeOf(0:ULong)~nLocal structSize:Size_T = SizeOf(SMetaField)~nLocal structAlignment:Size_T = AlignOf(SMetaField)"
Local rawStorageParse:TParseResult = TBlitzMaxParser.ParseText(rawStorageSource, "raw-storage-conversions.bmx")
Local rawStorageModel:TSemanticModel = TBlitzMaxSemanticAnalyzer.Analyze(rawStorageParse.syntaxTree)
TExpressionBinder.Bind(rawStorageModel)
Check(rawStorageModel.diagnostics.length = 0, "struct array decay and StackAlloc diagnostics")
Local registerStatement:TCallStatementSyntax = TCallStatementSyntax(rawStorageParse.syntaxTree.root.members[4])
Local boundRegisterStatement:TBoundExpressionStatement = TBoundExpressionStatement(rawStorageModel.BoundStatement(registerStatement))
Local boundRegisterCall:TBoundCallExpression = TBoundCallExpression(boundRegisterStatement.expression)
Check(TBoundConversionExpression(boundRegisterCall.arguments[0]).conversionKind = CONVERSION_ARRAY_TO_POINTER, "struct array decays to raw Byte Ptr argument")
Local regroupedStorageSource:String = "SuperStrict~nStruct SVec2F~nField x:Float~nField y:Float~nEnd Struct~nFunction NativeVectors(values:SVec2F Ptr, count:Int)~nEnd Function~nLocal coordinates:Float[]~nNativeVectors(coordinates, coordinates.Length / 2)"
Local regroupedStorageParse:TParseResult = TBlitzMaxParser.ParseText(regroupedStorageSource, "regrouped-array-storage.bmx")
Local regroupedStorageModel:TSemanticModel = TBlitzMaxSemanticAnalyzer.Analyze(regroupedStorageParse.syntaxTree)
TExpressionBinder.Bind(regroupedStorageModel)
Check(regroupedStorageModel.diagnostics.length = 0, "numeric Array storage may be grouped through a native Struct pointer ABI")
Local regroupedStorageStatement:TCallStatementSyntax = TCallStatementSyntax(regroupedStorageParse.syntaxTree.root.members[4])
Local regroupedBoundStatement:TBoundExpressionStatement = TBoundExpressionStatement(regroupedStorageModel.BoundStatement(regroupedStorageStatement))
Check(regroupedBoundStatement <> Null And regroupedBoundStatement.expression <> Null, "numeric-to-Struct pointer call retains its bound expression statement")
Local boundRegroupedStorage:TBoundCallExpression = TBoundCallExpression(regroupedBoundStatement.expression)
Check(boundRegroupedStorage <> Null, "numeric-to-Struct pointer call retains its bound call expression")
Check(TBoundConversionExpression(boundRegroupedStorage.arguments[0]).conversionKind = CONVERSION_ARRAY_TO_POINTER, "numeric-to-Struct pointer decay remains explicit in the bound model")
Local objectStorageSource:String = "SuperStrict~nType THeader~nField kind:Byte~nField size:Int~nEnd Type~nFunction ReadStorage(buffer:Byte Ptr,count:Long)~nEnd Function~nLocal header:THeader=New THeader~nReadStorage(header,5)"
Local objectStorageParse:TParseResult = TBlitzMaxParser.ParseText(objectStorageSource, "object-field-storage.bmx")
Local objectStorageModel:TSemanticModel = TBlitzMaxSemanticAnalyzer.Analyze(objectStorageParse.syntaxTree)
TExpressionBinder.Bind(objectStorageModel)
Check(objectStorageModel.diagnostics.length = 0, "a managed Type instance exposes its contiguous field region to a raw Byte Ptr parameter")
Local objectStorageStatement:TCallStatementSyntax = TCallStatementSyntax(objectStorageParse.syntaxTree.root.members[4])
Local boundObjectStorage:TBoundCallExpression = TBoundCallExpression(TBoundExpressionStatement(objectStorageModel.BoundStatement(objectStorageStatement)).expression)
Check(TBoundConversionExpression(boundObjectStorage.arguments[0]).conversionKind = CONVERSION_OBJECT_TO_BYTE_POINTER, "managed Type field-storage conversion remains explicit in the bound model")
Local invalidBaseObjectStorageParse:TParseResult = TBlitzMaxParser.ParseText("SuperStrict~nType TStorageOwner~nField storage:Byte Ptr~nMethod SetStorage(value:Object)~nstorage=value~nEnd Method~nEnd Type", "invalid-base-object-field-storage.bmx")
Local invalidBaseObjectStorageModel:TSemanticModel = TBlitzMaxSemanticAnalyzer.Analyze(invalidBaseObjectStorageParse.syntaxTree)
TExpressionBinder.Bind(invalidBaseObjectStorageModel)
Check(HasDiagnostic(invalidBaseObjectStorageModel.diagnostics, "BMX3310"), "an arbitrary Object cannot be assigned as a native field-storage pointer")
Local objectPointerOverloadSource:String = "SuperStrict~nType TStoredObject~nEnd Type~nFunction SelectValue:Int(value:Object)~nReturn 1~nEnd Function~nFunction SelectValue:Int(value:Byte Ptr)~nReturn 2~nEnd Function~nLocal stored:TStoredObject = New TStoredObject~nLocal selected:Int = SelectValue(stored)"
Local objectPointerOverloadParse:TParseResult = TBlitzMaxParser.ParseText(objectPointerOverloadSource, "object-pointer-overload-ranking.bmx")
Local objectPointerOverloadModel:TSemanticModel = TBlitzMaxSemanticAnalyzer.Analyze(objectPointerOverloadParse.syntaxTree)
TExpressionBinder.Bind(objectPointerOverloadModel)
Local objectPointerSelectedDeclaration:TVariableDeclarationStatementSyntax = TVariableDeclarationStatementSyntax(objectPointerOverloadParse.syntaxTree.root.members[5])
Local objectPointerSelectedCall:TCallExpressionSyntax = TCallExpressionSyntax(objectPointerSelectedDeclaration.declarators[0].initializer)
Check(objectPointerOverloadModel.diagnostics.length = 0 And objectPointerOverloadModel.ResolvedCall(objectPointerSelectedCall).routine.parameterTypes[0] = objectPointerOverloadModel.BuiltinType("Object"), "ordinary Object overload outranks the legacy managed-storage Byte Ptr conversion")
Local enumUnderlyingOverloadSource:String = "SuperStrict~nEnum EByteValue:Byte~nZero~nOne~nEnd Enum~nFunction HashValue:Int(value:Object)~nReturn 1~nEnd Function~nFunction HashValue:Int(value:Byte)~nReturn 2~nEnd Function~nLocal value:EByteValue = EByteValue.One~nLocal hash:Int = HashValue(value)"
Local enumUnderlyingOverloadParse:TParseResult = TBlitzMaxParser.ParseText(enumUnderlyingOverloadSource, "enum-underlying-overload.bmx")
Local enumUnderlyingOverloadModel:TSemanticModel = TBlitzMaxSemanticAnalyzer.Analyze(enumUnderlyingOverloadParse.syntaxTree)
TExpressionBinder.Bind(enumUnderlyingOverloadModel)
Check(enumUnderlyingOverloadModel.diagnostics.length = 0, "enum values convert implicitly to their exact underlying primitive type")
Local enumUnderlyingHashDeclaration:TVariableDeclarationStatementSyntax = TVariableDeclarationStatementSyntax(enumUnderlyingOverloadParse.syntaxTree.root.members[5])
Local enumUnderlyingHashCall:TCallExpressionSyntax = TCallExpressionSyntax(enumUnderlyingHashDeclaration.declarators[0].initializer)
Local enumUnderlyingResolved:TResolvedCall = enumUnderlyingOverloadModel.ResolvedCall(enumUnderlyingHashCall)
Local enumUnderlyingBound:TBoundCallExpression = TBoundCallExpression(enumUnderlyingOverloadModel.BoundExpression(enumUnderlyingHashCall))
Check(enumUnderlyingResolved.routine.parameterTypes[0] = enumUnderlyingOverloadModel.BuiltinType("Byte"), "exact enum underlying overload outranks Object boxing")
Check(TBoundConversionExpression(enumUnderlyingBound.arguments[0]).conversionKind = CONVERSION_ENUM_TO_UNDERLYING, "enum overload argument records the underlying conversion")
Local pointerRowsSource:String = "SuperStrict~nExtern~nFunction RegisterRows(rows:Byte Ptr)~nEnd Extern~nLocal rows:Byte Ptr[4]~nRegisterRows(rows)"
Local pointerRowsParse:TParseResult = TBlitzMaxParser.ParseText(pointerRowsSource, "pointer-array-storage.bmx")
Local pointerRowsModel:TSemanticModel = TBlitzMaxSemanticAnalyzer.Analyze(pointerRowsParse.syntaxTree)
TExpressionBinder.Bind(pointerRowsModel)
Check(pointerRowsModel.diagnostics.length = 0, "pointer Array raw-storage decay diagnostics")
Local pointerRowsStatement:TCallStatementSyntax = TCallStatementSyntax(pointerRowsParse.syntaxTree.root.members[3])
Local boundPointerRows:TBoundCallExpression = TBoundCallExpression(TBoundExpressionStatement(pointerRowsModel.BoundStatement(pointerRowsStatement)).expression)
Check(TBoundConversionExpression(boundPointerRows.arguments[0]).conversionKind = CONVERSION_ARRAY_TO_POINTER, "pointer Array decays to raw Byte Ptr argument")
Local idsDeclaration:TVariableDeclarationStatementSyntax = TVariableDeclarationStatementSyntax(rawStorageParse.syntaxTree.root.members[6])
Local boundIdsDeclaration:TBoundVariableDeclarationStatement = TBoundVariableDeclarationStatement(rawStorageModel.BoundStatement(idsDeclaration))
Local idsConversion:TBoundConversionExpression = TBoundConversionExpression(boundIdsDeclaration.variables[0].initializer)
Check(idsConversion.conversionKind = CONVERSION_BYTE_POINTER_TO_POINTER, "StackAlloc raw Byte Ptr converts to requested typed pointer")
Local boundStackAlloc:TBoundUnaryExpression = TBoundUnaryExpression(idsConversion.operand)
Check(boundStackAlloc <> Null And boundStackAlloc.semanticType.DisplayName() = "Byte Ptr", "StackAlloc is represented as a Byte Ptr builtin expression")
Check(TBoundConversionExpression(boundStackAlloc.operand).semanticType = rawStorageModel.BuiltinType("Size_T"), "StackAlloc byte count is converted to Size_T")
Local scalarSizeDeclaration:TVariableDeclarationStatementSyntax = TVariableDeclarationStatementSyntax(rawStorageParse.syntaxTree.root.members[7])
Local boundScalarSize:TBoundUnaryExpression = TBoundUnaryExpression(TBoundVariableDeclarationStatement(rawStorageModel.BoundStatement(scalarSizeDeclaration)).variables[0].initializer)
Check(boundScalarSize <> Null And boundScalarSize.operandSemanticType = rawStorageModel.BuiltinType("ULong") And Not boundScalarSize.isTypeOperand, "SizeOf retains the explicitly typed expression operand")
Local structSizeDeclaration:TVariableDeclarationStatementSyntax = TVariableDeclarationStatementSyntax(rawStorageParse.syntaxTree.root.members[8])
Local boundStructSize:TBoundUnaryExpression = TBoundUnaryExpression(TBoundVariableDeclarationStatement(rawStorageModel.BoundStatement(structSizeDeclaration)).variables[0].initializer)
Check(boundStructSize <> Null And boundStructSize.operandSemanticType.DisplayName() = "SMetaField" And boundStructSize.isTypeOperand, "SizeOf resolves a struct type operand without treating it as a value")
Local structAlignmentDeclaration:TVariableDeclarationStatementSyntax = TVariableDeclarationStatementSyntax(rawStorageParse.syntaxTree.root.members[9])
Local boundStructAlignment:TBoundUnaryExpression = TBoundUnaryExpression(TBoundVariableDeclarationStatement(rawStorageModel.BoundStatement(structAlignmentDeclaration)).variables[0].initializer)
Check(boundStructAlignment <> Null And boundStructAlignment.operandSemanticType.DisplayName() = "SMetaField" And boundStructAlignment.isTypeOperand, "AlignOf resolves and retains its struct type operand")

Local contextualSource:String = "SuperStrict~nStruct SPosition~nField x:Float~nEnd Struct~nFunction RegisterComponent(size:Size_T, alignment:Size_T)~nEnd Function~nFunction Update(deltaTime:Float)~nEnd Function~nFunction GetComponent(output:Byte Ptr Ptr)~nEnd Function~nRegisterComponent(0, 0)~nGlobal radii:Float[] = [24.0, 16.0, 8.0, 4.0]~nGlobal speeds:Float[] = [1, 1.4, 2, 3]~nUpdate(1.0 / 60.0)~nLocal positionPointer:SPosition Ptr~nGetComponent(VarPtr positionPointer)"
Local contextualParse:TParseResult = TBlitzMaxParser.ParseText(contextualSource, "contextual-numeric-and-pointer-calls.bmx")
Local contextualModel:TSemanticModel = TBlitzMaxSemanticAnalyzer.Analyze(contextualParse.syntaxTree)
TExpressionBinder.Bind(contextualModel)
Check(contextualModel.diagnostics.length = 0, "Size_T constants, Float array literals and expressions, and nested raw pointers diagnostics")
Local registerComponentStatement:TCallStatementSyntax = TCallStatementSyntax(contextualParse.syntaxTree.root.members[5])
Local boundRegisterComponent:TBoundCallExpression = TBoundCallExpression(TBoundExpressionStatement(contextualModel.BoundStatement(registerComponentStatement)).expression)
Check(TBoundConversionExpression(boundRegisterComponent.arguments[0]).conversionKind = CONVERSION_CONSTANT And TBoundConversionExpression(boundRegisterComponent.arguments[1]).conversionKind = CONVERSION_CONSTANT, "integer zero arguments are contextually converted to Size_T")
Local radiiDeclaration:TVariableDeclarationStatementSyntax = TVariableDeclarationStatementSyntax(contextualParse.syntaxTree.root.members[6])
Local boundRadii:TBoundArrayLiteralExpression = TBoundArrayLiteralExpression(TBoundVariableDeclarationStatement(contextualModel.BoundStatement(radiiDeclaration)).variables[0].initializer)
Check(boundRadii <> Null And boundRadii.conversionKind = CONVERSION_ARRAY_LITERAL And boundRadii.semanticType.DisplayName() = "Float[]" And boundRadii.contextualElementType = contextualModel.BuiltinType("Float"), "floating array literal is contextually converted to Float elements")
Check(TBoundConversionExpression(boundRadii.elements[0]).semanticType = contextualModel.BuiltinType("Float"), "contextual array retains the conversion of each floating element")
Local updateStatement:TCallStatementSyntax = TCallStatementSyntax(contextualParse.syntaxTree.root.members[8])
Local boundUpdate:TBoundCallExpression = TBoundCallExpression(TBoundExpressionStatement(contextualModel.BoundStatement(updateStatement)).expression)
Check(TBoundConversionExpression(boundUpdate.arguments[0]).conversionKind = CONVERSION_CONSTANT, "floating constant expression is contextually converted to Float")
Local getComponentStatement:TCallStatementSyntax = TCallStatementSyntax(contextualParse.syntaxTree.root.members[10])
Local boundGetComponent:TBoundCallExpression = TBoundCallExpression(TBoundExpressionStatement(contextualModel.BoundStatement(getComponentStatement)).expression)
Check(TBoundConversionExpression(boundGetComponent.arguments[0]).conversionKind = CONVERSION_POINTER_TO_BYTE_POINTER, "typed pointer-to-pointer converts to matching raw pointer-to-pointer")

Local collapsedRawPointerSource:String = "SuperStrict~nFunction ReadRaw(value:Byte Ptr)~nEnd Function~nFunction ReadNested(value:Byte Ptr Ptr)~nEnd Function~nLocal nested:Byte Ptr Ptr~nLocal raw:Byte Ptr~nReadRaw(nested)~nReadNested(raw)"
Local collapsedRawPointerParse:TParseResult = TBlitzMaxParser.ParseText(collapsedRawPointerSource, "collapsed-raw-pointer-calls.bmx")
Local collapsedRawPointerModel:TSemanticModel = TBlitzMaxSemanticAnalyzer.Analyze(collapsedRawPointerParse.syntaxTree)
TExpressionBinder.Bind(collapsedRawPointerModel)
Check(collapsedRawPointerModel.diagnostics.length = 0, "raw Byte pointer bridges may collapse or restore pointer depth")

Local callableStoragePointerSource:String = "SuperStrict~nFunction ConsumeStorage(value:Byte Ptr)~nEnd Function~nLocal callback()~nConsumeStorage(Varptr callback)"
Local callableStoragePointerParse:TParseResult = TBlitzMaxParser.ParseText(callableStoragePointerSource, "callable-storage-pointer.bmx")
Local callableStoragePointerModel:TSemanticModel = TBlitzMaxSemanticAnalyzer.Analyze(callableStoragePointerParse.syntaxTree)
TExpressionBinder.Bind(callableStoragePointerModel)
Check(callableStoragePointerModel.diagnostics.length = 0, "Varptr of callable storage converts to raw Byte Ptr without converting the callable value itself")

Local legacyStoredCallbackSource:String = "SuperStrict~nExtern~nFunction Install(callback:Byte Ptr)~nEnd Extern~nFunction Forward(callback(message:String))~nInstall callback~nEnd Function"
Local legacyStoredCallbackModel:TSemanticModel = TBlitzMaxSemanticAnalyzer.Analyze(TBlitzMaxParser.ParseText(legacyStoredCallbackSource, "legacy-stored-callback.bmx").syntaxTree)
Check(legacyStoredCallbackModel.diagnostics.length = 0, "callable parameters cross legacy Extern Byte Ptr callback boundaries without a source cast")

Local objectArrayCovarianceSource:String = "SuperStrict~nFunction Accept(values:Object[])~nEnd Function~nLocal strings:String[]~nAccept(strings)"
Local objectArrayCovarianceParse:TParseResult = TBlitzMaxParser.ParseText(objectArrayCovarianceSource, "object-array-covariance.bmx")
Local objectArrayCovarianceModel:TSemanticModel = TBlitzMaxSemanticAnalyzer.Analyze(objectArrayCovarianceParse.syntaxTree)
TExpressionBinder.Bind(objectArrayCovarianceModel)
Check(objectArrayCovarianceModel.diagnostics.length = 0, "runtime reference arrays preserve legacy covariant call compatibility")

Local longConstantArraySource:String = "SuperStrict~nType TWorldTime~nConst MINUTELENGTH:Long = 60 * 1000~nEnd Type~nType TSchedule~nField breakTimes:Int[] = [45 * TWorldTime.MINUTELENGTH]~nEnd Type"
Local longConstantArrayParse:TParseResult = TBlitzMaxParser.ParseText(longConstantArraySource, "long-constant-int-array.bmx")
Local longConstantArrayModel:TSemanticModel = TBlitzMaxSemanticAnalyzer.Analyze(longConstantArrayParse.syntaxTree)
TExpressionBinder.Bind(longConstantArrayModel)
Check(longConstantArrayModel.diagnostics.length = 0, "a Long constant expression that fits Int is valid in a contextual Int array literal")
Local scheduleDeclaration:TTypeDeclarationSyntax = TTypeDeclarationSyntax(longConstantArrayParse.syntaxTree.root.members[2])
Local breakTimesDeclaration:TVariableDeclarationStatementSyntax = TVariableDeclarationStatementSyntax(scheduleDeclaration.body.statements[0])
Local boundBreakTimes:TBoundArrayLiteralExpression = TBoundArrayLiteralExpression(longConstantArrayModel.BoundExpression(breakTimesDeclaration.declarators[0].initializer))
Check(boundBreakTimes <> Null And TBoundConversionExpression(boundBreakTimes.elements[0]).conversionKind = CONVERSION_CONSTANT, "the fitting Long constant array element records its contextual Int conversion")

Local invalidLongIntArraySource:String = "SuperStrict~nConst TOO_LARGE:Long = 2147483648~nGlobal badConstant:Int[] = [TOO_LARGE]~nLocal runtimeValue:Long~nGlobal badRuntime:Int[] = [runtimeValue]"
Local invalidLongIntArrayParse:TParseResult = TBlitzMaxParser.ParseText(invalidLongIntArraySource, "invalid-long-int-array.bmx")
Local invalidLongIntArrayModel:TSemanticModel = TBlitzMaxSemanticAnalyzer.Analyze(invalidLongIntArrayParse.syntaxTree)
TExpressionBinder.Bind(invalidLongIntArrayModel)
Check(invalidLongIntArrayModel.diagnostics.length = 2, "out-of-range Long constants and runtime Long values do not narrow to contextual Int array elements")
Local objectPointerParse:TParseResult = TBlitzMaxParser.ParseText("SuperStrict~nType TObjectValue~nEnd Type~nFunction NativeOutput(output:Byte Ptr Ptr)~nEnd Function~nLocal objectPointer:TObjectValue Ptr~nNativeOutput(VarPtr objectPointer)", "object-pointer-is-not-raw-storage.bmx")
Local objectPointerModel:TSemanticModel = TBlitzMaxSemanticAnalyzer.Analyze(objectPointerParse.syntaxTree)
TExpressionBinder.Bind(objectPointerModel)
Check(objectPointerModel.diagnostics.length = 1 And objectPointerModel.diagnostics[0].code = "BMX3302", "pointer-to-Type does not implicitly convert to raw inline storage")

Local namedNumericSource:String = "SuperStrict~nType TPrimitiveSink~nMethod TakeByte(value:Byte)~nEnd Method~nMethod TakeShort(value:Short)~nEnd Method~nMethod TakeUInt(value:UInt)~nEnd Method~nMethod TakeULong(value:ULong)~nEnd Method~nEnd Type~nFunction WantsByte(value:Byte)~nEnd Function~nFunction WantsShort(value:Short)~nEnd Function~nFunction WantsUInt(value:UInt)~nEnd Function~nFunction WantsULong(value:ULong)~nEnd Function~nConst C0:Int = 0~nConst C1:Int = 1~nConst C2:Int = 2~nConst C255:Int = 255~nConst C65535:Int = 65535~nLocal sink:TPrimitiveSink = New TPrimitiveSink~nWantsByte(True)~nWantsByte(False)~nWantsByte(C0)~nWantsByte(C255)~nsink.TakeByte(C1)~nsink.TakeByte(C255)~nWantsShort(C0)~nWantsShort(C65535)~nsink.TakeShort(C1)~nsink.TakeShort(C65535)~nWantsUInt(C0)~nWantsUInt(C65535)~nsink.TakeUInt(C1)~nWantsULong(C0)~nWantsULong(C1)~nsink.TakeULong(C1)~nLocal bytes:Byte[] = [C0, C1, C255]~nLocal shorts:Short[] = [C0, C1, C65535]~nLocal uints:UInt[] = [C0, C1, C2]~nLocal ulongs:ULong[] = [C0, C1, C2]"
Local namedNumericParse:TParseResult = TBlitzMaxParser.ParseText(namedNumericSource, "named-numeric-constant-coercion.bmx")
Local namedNumericModel:TSemanticModel = TBlitzMaxSemanticAnalyzer.Analyze(namedNumericParse.syntaxTree)
TExpressionBinder.Bind(namedNumericModel)
Check(namedNumericModel.diagnostics.length = 0, "Boolean and named Int constants contextually fit primitive arguments and arrays")

Local radixArraySource:String = "SuperStrict~nField bigUnicode:UInt[] = [$10300, $10301, $10302, 0]~nLocal data:Byte[] = [$C2, $A9]"
Local radixArrayParse:TParseResult = TBlitzMaxParser.ParseText(radixArraySource, "contextual-radix-arrays.bmx")
Local radixArrayModel:TSemanticModel = TBlitzMaxSemanticAnalyzer.Analyze(radixArrayParse.syntaxTree)
TExpressionBinder.Bind(radixArrayModel)
Check(radixArrayModel.diagnostics.length = 0, "hexadecimal literals contextually fit UInt and Byte array elements")
Local unicodeDeclaration:TVariableDeclarationStatementSyntax = TVariableDeclarationStatementSyntax(radixArrayParse.syntaxTree.root.members[1])
Local boundUnicode:TBoundArrayLiteralExpression = TBoundArrayLiteralExpression(radixArrayModel.BoundExpression(unicodeDeclaration.declarators[0].initializer))
Check(boundUnicode.semanticType.DisplayName() = "UInt[]" And TBoundConversionExpression(boundUnicode.elements[0]).conversionKind = CONVERSION_CONSTANT, "UInt radix array records contextual element conversions")

Local enumBuiltinSource:String = "SuperStrict~nEnum EByte:Byte~nB0~nB1~nEnd Enum~nLocal values:EByte[] = EByte.Values()~nLocal converted:EByte~nLocal ok:Int = EByte.TryConvert(1, converted)~nLocal parsed:EByte = EByte.FromString(~qB1~q)~nLocal ordinal:Byte = parsed.Ordinal()~nLocal text:String = parsed.ToString()~nFor Local value:EByte = EachIn EByte.Values()~nNext"
Local enumBuiltinParse:TParseResult = TBlitzMaxParser.ParseText(enumBuiltinSource, "enum-generated-api.bmx")
Local enumBuiltinModel:TSemanticModel = TBlitzMaxSemanticAnalyzer.Analyze(enumBuiltinParse.syntaxTree)
TExpressionBinder.Bind(enumBuiltinModel)
Check(enumBuiltinModel.diagnostics.length = 0, "generated enum instance and static APIs bind for typed enums")
Local enumValuesDeclaration:TVariableDeclarationStatementSyntax = TVariableDeclarationStatementSyntax(enumBuiltinParse.syntaxTree.root.members[2])
Local enumValuesCall:TCallExpressionSyntax = TCallExpressionSyntax(enumValuesDeclaration.declarators[0].initializer)
Check(enumBuiltinModel.ResolvedCall(enumValuesCall).returnType.DisplayName() = "EByte[]", "Enum.Values returns an array of the declaring enum")

Local enumCastSource:String = "SuperStrict~nEnum EByte:Byte~nB0~nB1~nEnd Enum~nEnum EOther:Byte~nO0~nEnd Enum~nLocal raw:Int=1~nLocal value:EByte=EByte(raw)~nLocal ordinal:Int=Int(value)~nLocal text:String=value"
Local enumCastAnalysis:TLanguageAnalysis = TBlitzMaxLanguage.AnalyzeText(enumCastSource, "enum-casts.bmx")
Check(enumCastAnalysis.Succeeded(), "explicit integral and Enum boundary conversions bind")
Local enumCastDeclaration:TVariableDeclarationStatementSyntax = TVariableDeclarationStatementSyntax(enumCastAnalysis.syntaxTree.root.members[4])
Local boundEnumCast:TBoundConversionExpression = TBoundConversionExpression(enumCastAnalysis.model.BoundExpression(enumCastDeclaration.declarators[0].initializer))
Local enumOrdinalDeclaration:TVariableDeclarationStatementSyntax = TVariableDeclarationStatementSyntax(enumCastAnalysis.syntaxTree.root.members[5])
Local boundEnumOrdinalCast:TBoundConversionExpression = TBoundConversionExpression(enumCastAnalysis.model.BoundExpression(enumOrdinalDeclaration.declarators[0].initializer))
Check(boundEnumCast <> Null And boundEnumCast.conversionKind = CONVERSION_EXPLICIT And Not boundEnumCast.implicitConversion, "integral-to-Enum cast remains an explicit bound conversion")
Check(boundEnumOrdinalCast <> Null And boundEnumOrdinalCast.conversionKind = CONVERSION_EXPLICIT And Not boundEnumOrdinalCast.implicitConversion, "Enum-to-integral cast remains an explicit bound conversion")
Local enumTextDeclaration:TVariableDeclarationStatementSyntax = TVariableDeclarationStatementSyntax(enumCastAnalysis.syntaxTree.root.members[6])
Local boundEnumTextDeclaration:TBoundVariableDeclarationStatement = TBoundVariableDeclarationStatement(enumCastAnalysis.model.BoundStatement(enumTextDeclaration))
Check(boundEnumTextDeclaration <> Null And TBoundConversionExpression(boundEnumTextDeclaration.variables[0].initializer).conversionKind = CONVERSION_ENUM_TO_STRING, "Enum-to-String coercion retains its descriptor-backed conversion kind")
Local rejectedEnumCast:TLanguageAnalysis = TBlitzMaxLanguage.AnalyzeText("SuperStrict~nEnum EFirst~nA~nEnd Enum~nEnum ESecond~nB~nEnd Enum~nLocal value:ESecond=ESecond(EFirst.A)", "rejected-enum-cast.bmx")
Check(HasDiagnostic(rejectedEnumCast.model.diagnostics, "BMX3312"), "direct cross-Enum casts remain invalid")
Local enumConstantCast:TLanguageAnalysis = TBlitzMaxLanguage.AnalyzeText("SuperStrict~nEnum EState~nUnknown=5~nReady~nEnd Enum~nEnum EAccess Flags~nNone=0~nRead~nWrite~nEnd Enum~nLocal state:EState=EState(6)~nLocal access:EAccess=EAccess(3)", "enum-constant-casts.bmx")
Check(enumConstantCast.Succeeded(), "declared Enum constants and declared Flags combinations are accepted")
Local invalidEnumConstantCast:TLanguageAnalysis = TBlitzMaxLanguage.AnalyzeText("SuperStrict~nEnum EState~nUnknown=5~nReady~nEnd Enum~nEnum EAccess Flags~nRead~nWrite~nEnd Enum~nLocal state:EState=EState(7)~nLocal zero:EAccess=EAccess(0)~nLocal unknown:EAccess=EAccess(8)", "invalid-enum-constant-casts.bmx")
Check(invalidEnumConstantCast.model.diagnostics.length = 3 And HasDiagnostic(invalidEnumConstantCast.model.diagnostics, "BMX3630"), "invalid ordinary Enum values, undeclared Flags zero, and unknown Flags bits are rejected")

Local outOfRangeParse:TParseResult = TBlitzMaxParser.ParseText("SuperStrict~nFunction WantsByte(value:Byte)~nEnd Function~nFunction WantsShort(value:Short)~nEnd Function~nFunction WantsUInt(value:UInt)~nEnd Function~nFunction WantsULong(value:ULong)~nEnd Function~nWantsByte(256)~nWantsShort(65536)~nWantsUInt(-1)~nWantsULong(-1)", "out-of-range-numeric-constants.bmx")
Local outOfRangeModel:TSemanticModel = TBlitzMaxSemanticAnalyzer.Analyze(outOfRangeParse.syntaxTree)
TExpressionBinder.Bind(outOfRangeModel)
Check(outOfRangeModel.diagnostics.length = 4, "contextual primitive coercion still rejects out-of-range constants")

Local conversionUseParse:TParseResult = TBlitzMaxParser.ParseText("SuperStrict~nType TAssignmentBase~nEnd Type~nType TAssignmentChild Extends TAssignmentBase~nEnd Type~nFunction Upcast:TAssignmentBase(value:TAssignmentChild)~nReturn value~nEnd Function~nLocal integer:Int~nLocal widened:Long = integer~nLocal childValue:TAssignmentChild = New TAssignmentChild~nLocal baseValue:TAssignmentBase = childValue~nbaseValue = Null~nLocal handle:Byte Ptr~nhandle = 0", "assignment-conversions.bmx")
Local conversionUseModel:TSemanticModel = TBlitzMaxSemanticAnalyzer.Analyze(conversionUseParse.syntaxTree)
TExpressionBinder.Bind(conversionUseModel)
Check(conversionUseModel.diagnostics.length = 0, "initializer, assignment, and return widening conversions")
Local zeroPointerAssignment:TAssignmentStatementSyntax = TAssignmentStatementSyntax(conversionUseParse.syntaxTree.root.members[10])
Local boundZeroPointerAssignment:TBoundAssignmentStatement = TBoundAssignmentStatement(conversionUseModel.BoundStatement(zeroPointerAssignment))
Check(TBoundConversionExpression(boundZeroPointerAssignment.value).conversionKind = CONVERSION_NULL, "integer constant zero is retained as a pointer-null conversion")

Local defaultValueSource:String = "SuperStrict~nType TDefaults<T>~nField data:T[]~nMethod Clear(index:Int)~ndata[index] = Null~nEnd Method~nMethod Value:T()~nReturn Null~nEnd Method~nEnd Type~nEnum EChoice~nNone~nSome~nEnd Enum~nStruct SValue~nField amount:Int~nEnd Struct~nLocal number:Int = Null~nLocal real:Double = Null~nLocal text:String = Null~nLocal objectValue:Object = Null~nLocal pointer:Byte Ptr = Null~nLocal choice:EChoice = Null~nLocal structure:SValue = Null~nLocal numbers:Int[] = Null"
Local defaultValueParse:TParseResult = TBlitzMaxParser.ParseText(defaultValueSource, "null-default-values.bmx")
Local defaultValueModel:TSemanticModel = TBlitzMaxSemanticAnalyzer.Analyze(defaultValueParse.syntaxTree)
TExpressionBinder.Bind(defaultValueModel)
Check(defaultValueModel.diagnostics.length = 0, "Null default values for generic, primitive, enum, struct, pointer, array, and reference types")
Local defaultsType:TTypeDeclarationSyntax = TTypeDeclarationSyntax(defaultValueParse.syntaxTree.root.members[1])
Local clearDefaults:TRoutineDeclarationSyntax = TRoutineDeclarationSyntax(defaultsType.body.statements[1])
Local clearDefaultAssignment:TAssignmentStatementSyntax = TAssignmentStatementSyntax(clearDefaults.body.statements[0])
Local boundClearDefault:TBoundAssignmentStatement = TBoundAssignmentStatement(defaultValueModel.BoundStatement(clearDefaultAssignment))
Check(TBoundConversionExpression(boundClearDefault.value).conversionKind = CONVERSION_DEFAULT_VALUE And TBoundConversionExpression(boundClearDefault.value).semanticType.DisplayName() = "T", "generic Null assignment retains an explicit contextual default-value conversion")

Local invalidUseParse:TParseResult = TBlitzMaxParser.ParseText("SuperStrict~nFunction BadReturn:Int(value:Double)~nReturn value~nEnd Function~nLocal wideValue:Double~nLocal narrowValue:Int = wideValue~nLocal targetValue:Int~ntargetValue = wideValue", "invalid-assignment-conversions.bmx")
Local invalidUseModel:TSemanticModel = TBlitzMaxSemanticAnalyzer.Analyze(invalidUseParse.syntaxTree)
TExpressionBinder.Bind(invalidUseModel)
Check(invalidUseModel.diagnostics.length = 0, "BlitzMax permits numeric narrowing in return, initializer, and assignment contexts")
Local badReturnSyntax:TRoutineDeclarationSyntax = TRoutineDeclarationSyntax(invalidUseParse.syntaxTree.root.members[1])
Local badReturnSymbol:TSymbol = invalidUseModel.DeclaredSymbol(badReturnSyntax)
Local boundBadReturn:TBoundReturnStatement = TBoundReturnStatement(invalidUseModel.BoundRoutineBody(badReturnSymbol).statements[0])
Check(TBoundConversionExpression(boundBadReturn.expression).conversionKind = CONVERSION_NUMERIC_NARROWING, "numeric return narrowing is explicit in the bound model")

Local voidReturnParse:TParseResult = TBlitzMaxParser.ParseText("SuperStrict~nType TCalculator~nMethod Calc(a:Int)~nReturn ~q100~q~nEnd Method~nEnd Type", "value-from-void-method.bmx")
Local voidReturnModel:TSemanticModel = TBlitzMaxSemanticAnalyzer.Analyze(voidReturnParse.syntaxTree)
TExpressionBinder.Bind(voidReturnModel)
Check(voidReturnModel.diagnostics.length = 1 And voidReturnModel.diagnostics[0].code = "BMX3310", "value return from non-value method diagnostic count")
Check(voidReturnModel.diagnostics[0].message = "Method 'Calc' does not return a value, so Return cannot include an expression.", "value return diagnostic uses BlitzMax source terminology")

Local structuredSource:String = "SuperStrict~nType TStructuredResource~nEnd Type~nType TStructuredProblem~nEnd Type~nFunction Echo:Int(value:Int)~nReturn value~nEnd Function~nFunction Exercise(value:Int)~nRepeat~nvalue = Echo(value)~nUntil Echo(value)~nSelect Echo(value)~nCase Echo(1)~nvalue = Echo(value)~nDefault~nvalue = Echo(value)~nEnd Select~nTry~nvalue = Echo(value)~nCatch problem:TStructuredProblem~nvalue = Echo(value)~nFinally~nvalue = Echo(value)~nEnd Try~nUsing~nLocal resource:TStructuredResource = New TStructuredResource~nDo~nvalue = Echo(value)~nEnd Using~n?win32~nvalue = Echo(value)~n?not win32~nvalue = Echo(value)~n?~nAssert Echo(value), ~qok~q~nDefData Echo(value)~nReadData value~nRestoreData values~nThrow New TStructuredProblem~nEnd Function"
Local structuredParse:TParseResult = TBlitzMaxParser.ParseText(structuredSource, "structured-expression-binding.bmx")
Local structuredModel:TSemanticModel = TBlitzMaxSemanticAnalyzer.Analyze(structuredParse.syntaxTree)
TExpressionBinder.Bind(structuredModel)
Check(structuredModel.diagnostics.length = 0, "structured statement expression diagnostics")
Local exercise:TRoutineDeclarationSyntax = TRoutineDeclarationSyntax(structuredParse.syntaxTree.root.members[4])
Local exerciseSymbol:TSymbol = structuredModel.DeclaredSymbol(exercise)
Local exerciseBody:TBoundBlockStatement = structuredModel.BoundRoutineBody(exerciseSymbol)
Check(exerciseBody <> Null And exerciseBody.statements.length = 10, "structured routine has a complete bound body")
Local repeatRegion:TRepeatStatementSyntax = TRepeatStatementSyntax(exercise.body.statements[0])
Check(structuredModel.ResolvedCall(TCallExpressionSyntax(repeatRegion.condition)) <> Null, "Repeat condition is bound")
Check(TBoundRepeatStatement(structuredModel.BoundStatement(repeatRegion)) <> Null, "Repeat region has a bound statement node")
Local selectRegion:TSelectStatementSyntax = TSelectStatementSyntax(exercise.body.statements[1])
Check(structuredModel.ResolvedCall(TCallExpressionSyntax(selectRegion.expression)) <> Null, "Select expression is bound")
Check(structuredModel.ResolvedCall(TCallExpressionSyntax(selectRegion.cases[0].values[0])) <> Null, "Case value is bound")
Check(TBoundSelectStatement(exerciseBody.statements[1]).cases.length = 1, "Select cases are represented in the bound tree")
Local tryRegion:TTryStatementSyntax = TTryStatementSyntax(exercise.body.statements[2])
Local catchAssignment:TAssignmentStatementSyntax = TAssignmentStatementSyntax(tryRegion.catches[0].body.statements[0])
Check(structuredModel.ResolvedCall(TCallExpressionSyntax(catchAssignment.right)) <> Null, "Catch body uses catch scope and is bound")
Check(TBoundTryStatement(exerciseBody.statements[2]).catches[0].parameter.name = "problem", "bound catch retains its declared parameter")
Local usingRegion:TUsingStatementSyntax = TUsingStatementSyntax(exercise.body.statements[3])
Check(structuredModel.ExpressionType(usingRegion.resources[0].declarators[0].initializer).DisplayName() = "TStructuredResource", "Using resource initializer is bound")
Check(TBoundUsingStatement(exerciseBody.statements[3]).resources.length = 1, "Using resources are explicit bound declarations")
Local conditionalRegion:TConditionalRegionSyntax = TConditionalRegionSyntax(exercise.body.statements[4])
Local conditionalAssignment:TAssignmentStatementSyntax = TAssignmentStatementSyntax(conditionalRegion.branches[0].body.statements[0])
Check(structuredModel.ResolvedCall(TCallExpressionSyntax(conditionalAssignment.right)) <> Null, "conditional branch expression is bound")
Check(TBoundConditionalStatement(exerciseBody.statements[4]).branches.length = 2, "all compile-time conditional branches remain available to tools")
Local assertRegion:TAssertStatementSyntax = TAssertStatementSyntax(exercise.body.statements[5])
Check(structuredModel.ResolvedCall(TCallExpressionSyntax(assertRegion.condition)) <> Null, "Assert condition is bound")
Local defDataRegion:TDefDataStatementSyntax = TDefDataStatementSyntax(exercise.body.statements[6])
Check(structuredModel.ResolvedCall(TCallExpressionSyntax(defDataRegion.values[0])) <> Null, "DefData value is bound")
Local readDataRegion:TReadDataStatementSyntax = TReadDataStatementSyntax(exercise.body.statements[7])
Check(structuredModel.ExpressionType(readDataRegion.targets[0]) = structuredModel.BuiltinType("Int"), "ReadData target is bound")
Local throwRegion:TThrowStatementSyntax = TThrowStatementSyntax(exercise.body.statements[9])
Check(structuredModel.ExpressionType(throwRegion.expression).DisplayName() = "TStructuredProblem", "Throw expression is bound")
Local structuredDump:String = TBoundDumper.DumpRoutine(structuredModel, exerciseSymbol)
Check(structuredDump.Contains("BoundSelect") And structuredDump.Contains("BoundTry") And structuredDump.Contains("BoundUsing") And structuredDump.Contains("BoundConditional"), "bound dumper traverses structured regions")

Local statementCallParse:TParseResult = TBlitzMaxParser.ParseText("SuperStrict~nFunction Emit(value:Int)~nEnd Function~nEmit 1", "statement-call-binding.bmx")
Local statementCallModel:TSemanticModel = TBlitzMaxSemanticAnalyzer.Analyze(statementCallParse.syntaxTree)
TExpressionBinder.Bind(statementCallModel)
Check(statementCallModel.diagnostics.length = 0, "statement-style call diagnostics")
Local statementCallSyntax:TCallStatementSyntax = TCallStatementSyntax(statementCallParse.syntaxTree.root.members[2])
Local boundStatementCall:TBoundExpressionStatement = TBoundExpressionStatement(statementCallModel.BoundStatement(statementCallSyntax))
Check(boundStatementCall <> Null And TBoundCallExpression(boundStatementCall.expression).isSynthetic, "optional-parentheses statement call becomes an explicit bound call")

Local receiverCallSource:String = "SuperStrict~nType TSystemDriver~nMethod SetMouseVisible(visible:Int)~nEnd Method~nMethod Notify(text:String, serious:Int)~nEnd Method~nEnd Type~nFunction SystemDriver:TSystemDriver()~nReturn New TSystemDriver~nEnd Function~nSystemDriver().SetMouseVisible True~nSystemDriver().SetMouseVisible False~nSystemDriver().Notify ~qmessage~q, True"
Local receiverCallParse:TParseResult = TBlitzMaxParser.ParseText(receiverCallSource, "receiver-statement-call.bmx")
Check(receiverCallParse.syntaxTree.diagnostics.length = 0, "optional-parentheses calls on invoked receivers parse without diagnostics")
Local receiverCallModel:TSemanticModel = TBlitzMaxSemanticAnalyzer.Analyze(receiverCallParse.syntaxTree)
TExpressionBinder.Bind(receiverCallModel)
Check(receiverCallModel.diagnostics.length = 0, "optional-parentheses calls on invoked receivers bind without diagnostics")
Local setVisibleStatement:TCallStatementSyntax = TCallStatementSyntax(receiverCallParse.syntaxTree.root.members[3])
Local setVisibleMember:TMemberAccessExpressionSyntax = TMemberAccessExpressionSyntax(setVisibleStatement.expression)
Check(setVisibleMember <> Null And TCallExpressionSyntax(setVisibleMember.expression) <> Null, "statement callee retains its invoked receiver expression")
Check(setVisibleStatement.argumentExpressions.length = 1 And receiverCallModel.ExpressionType(setVisibleStatement.argumentExpressions[0]) = receiverCallModel.BuiltinType("Int"), "True is parsed as the method argument")
Local newReceiverCallSource:String = "SuperStrict~nType TNewReceiver~nMethod Apply(value:Int)~nEnd Method~nEnd Type~nNew TNewReceiver().Apply(1)"
Local newReceiverCallParse:TParseResult = TBlitzMaxParser.ParseText(newReceiverCallSource, "new-receiver-call.bmx")
Local newReceiverCallModel:TSemanticModel = TBlitzMaxSemanticAnalyzer.Analyze(newReceiverCallParse.syntaxTree)
TExpressionBinder.Bind(newReceiverCallModel)
Local newReceiverCallStatement:TCallStatementSyntax = TCallStatementSyntax(newReceiverCallParse.syntaxTree.root.members[2])
Local newReceiverBoundStatement:TBoundExpressionStatement = TBoundExpressionStatement(newReceiverCallModel.BoundStatement(newReceiverCallStatement))
Check(newReceiverCallModel.diagnostics.length = 0 And newReceiverBoundStatement <> Null And TBoundCallExpression(newReceiverBoundStatement.expression) <> Null, "New receiver method call statement binds as a typed expression statement")

Local parenthesizedArgumentSource:String = "SuperStrict~nType TTextWriter~nMethod _WriteByte(n:Int)~nEnd Method~nMethod Write()~nLocal c:Int = $10000~n_WriteByte (c Shr 18) | $f0~n_WriteByte ((c Shr 12) & $3f) | $80~n_WriteByte ((c Shr 6) & $3f) | $80~n_WriteByte (c & $3f) | $80~nEnd Method~nEnd Type"
Local parenthesizedArgumentParse:TParseResult = TBlitzMaxParser.ParseText(parenthesizedArgumentSource, "parenthesized-statement-argument.bmx")
Check(parenthesizedArgumentParse.syntaxTree.diagnostics.length = 0, "parenthesized braceless call arguments parse without diagnostics")
Local parenthesizedArgumentModel:TSemanticModel = TBlitzMaxSemanticAnalyzer.Analyze(parenthesizedArgumentParse.syntaxTree)
TExpressionBinder.Bind(parenthesizedArgumentModel)
Check(parenthesizedArgumentModel.diagnostics.length = 0, "parenthesized braceless call arguments bind as Int expressions")
Local textWriterType:TTypeDeclarationSyntax = TTypeDeclarationSyntax(parenthesizedArgumentParse.syntaxTree.root.members[1])
Local writeMethod:TRoutineDeclarationSyntax = TRoutineDeclarationSyntax(textWriterType.body.statements[1])
Local writeByteStatement:TCallStatementSyntax = TCallStatementSyntax(writeMethod.body.statements[1])
Check(Not writeByteStatement.hasParentheses And writeByteStatement.argumentExpressions.length = 1, "outer parentheses belong to the argument rather than the call")
Check(parenthesizedArgumentModel.ResolvedCall(writeByteStatement) <> Null And parenthesizedArgumentModel.ExpressionType(writeByteStatement.argumentExpressions[0]) = parenthesizedArgumentModel.BuiltinType("Int"), "_WriteByte resolves with one Int argument")

Local superSource:String = "SuperStrict~nType TSuperBase~nMethod ReadByte:Int()~nEnd Method~nMethod WriteByte(value:Int)~nEnd Method~nEnd Type~nType TSuperDerived Extends TSuperBase~nMethod Read:Int()~nReturn Super.ReadByte()~nEnd Method~nMethod Write(value:Int)~nSuper.WriteByte value~nEnd Method~nEnd Type"
Local superParse:TParseResult = TBlitzMaxParser.ParseText(superSource, "super-binding.bmx")
Local superModel:TSemanticModel = TBlitzMaxSemanticAnalyzer.Analyze(superParse.syntaxTree)
TExpressionBinder.Bind(superModel)
Check(superModel.diagnostics.length = 0, "Super expression and statement call diagnostics")
Local superDerived:TTypeDeclarationSyntax = TTypeDeclarationSyntax(superParse.syntaxTree.root.members[2])
Local superRead:TRoutineDeclarationSyntax = TRoutineDeclarationSyntax(superDerived.body.statements[0])
Local superReturn:TReturnStatementSyntax = TReturnStatementSyntax(superRead.body.statements[0])
Local superCall:TCallExpressionSyntax = TCallExpressionSyntax(superReturn.expression)
Local superMember:TMemberAccessExpressionSyntax = TMemberAccessExpressionSyntax(superCall.callee)
Check(superModel.ExpressionType(superMember.expression).DisplayName() = "TSuperBase", "Super has the substituted superclass type")
Check(superModel.ResolvedCall(superCall) <> Null And superModel.ResolvedCall(superCall).routine.name = "ReadByte", "Super method call resolves against base members")

Local inheritedOverloadSource:String = "SuperStrict~nType TOverloadTeam~nEnd Type~nType TOverloadBase~nMethod GenerateRandomTeamMembers:Int(team:TOverloadTeam)~nReturn 1~nEnd Method~nMethod GenerateRandomTeamMembers:Int(team:TOverloadTeam, playerCount:Int, reservePlayerCount:Int)~nReturn playerCount + reservePlayerCount~nEnd Method~nEnd Type~nType TOverloadDerived Extends TOverloadBase~nMethod GenerateRandomTeamMembers:Int(team:TOverloadTeam) Override~nGenerateRandomTeamMembers(team, 6, 3)~nEnd Method~nEnd Type~nLocal overloadTeam:TOverloadTeam = New TOverloadTeam~nLocal overloadDerived:TOverloadDerived = New TOverloadDerived~noverloadDerived.GenerateRandomTeamMembers(overloadTeam, 6, 3)"
Local inheritedOverloadParse:TParseResult = TBlitzMaxParser.ParseText(inheritedOverloadSource, "inherited-overload-binding.bmx")
Local inheritedOverloadModel:TSemanticModel = TBlitzMaxSemanticAnalyzer.Analyze(inheritedOverloadParse.syntaxTree)
TExpressionBinder.Bind(inheritedOverloadModel)
Check(inheritedOverloadModel.diagnostics.length = 0, "derived and inherited method overloads bind without diagnostics")
Local overloadDerivedType:TTypeDeclarationSyntax = TTypeDeclarationSyntax(inheritedOverloadParse.syntaxTree.root.members[3])
Local overloadMethod:TRoutineDeclarationSyntax = TRoutineDeclarationSyntax(overloadDerivedType.body.statements[0])
Local unqualifiedOverloadStatement:TCallStatementSyntax = TCallStatementSyntax(overloadMethod.body.statements[0])
Local unqualifiedOverloadCall:TCallExpressionSyntax = TCallExpressionSyntax(unqualifiedOverloadStatement.expression)
Check(inheritedOverloadModel.ResolvedCall(unqualifiedOverloadCall) <> Null And inheritedOverloadModel.ResolvedCall(unqualifiedOverloadCall).routine.containingScope.owner.name = "TOverloadBase", "unqualified call selects an inherited overload hidden by the derived method name")
Local qualifiedOverloadStatement:TCallStatementSyntax = TCallStatementSyntax(inheritedOverloadParse.syntaxTree.root.members[6])
Local qualifiedOverloadCall:TCallExpressionSyntax = TCallExpressionSyntax(qualifiedOverloadStatement.expression)
Check(inheritedOverloadModel.ResolvedCall(qualifiedOverloadCall) <> Null And inheritedOverloadModel.ResolvedCall(qualifiedOverloadCall).routine.containingScope.owner.name = "TOverloadBase", "receiver call includes inherited overloads alongside derived methods")

Local inheritedTypeFunctionSource:String = "SuperStrict~nType TSportMatch~nEnd Type~nType TSoccerMatch Extends TSportMatch~nEnd Type~nType TSportBase~nFunction CreateMatchSets(createMatchFunc:TSportMatch())~nEnd Function~nEnd Type~nType TSoccer Extends TSportBase~nFunction CreateMatch:TSoccerMatch()~nReturn New TSoccerMatch~nEnd Function~nEnd Type~nTSoccer.CreateMatchSets(TSoccer.CreateMatch)~nType TMission~nEnd Type~nType TSimpleMission Extends TMission~nEnd Type~nType TMissionScore~nEnd Type~nType TMissions~nInternal~nFunction AddHighscoreEntry(mission:TMission, score:TMissionScore)~nEnd Function~nEnd Type~nLocal mission:TSimpleMission = New TSimpleMission~nLocal score:TMissionScore = New TMissionScore~nTMissions.AddHighscoreEntry(mission, score)"
Local inheritedTypeFunctionParse:TParseResult = TBlitzMaxParser.ParseText(inheritedTypeFunctionSource, "inherited-type-function-binding.bmx")
Local inheritedTypeFunctionModel:TSemanticModel = TBlitzMaxSemanticAnalyzer.Analyze(inheritedTypeFunctionParse.syntaxTree)
TExpressionBinder.Bind(inheritedTypeFunctionModel)
Check(inheritedTypeFunctionModel.diagnostics.length = 0, "type-qualified functions include inherited routines and accept subtype arguments and callable returns")
Local inheritedTypeFunctionStatement:TCallStatementSyntax = TCallStatementSyntax(inheritedTypeFunctionParse.syntaxTree.root.members[5])
Local inheritedTypeFunctionCall:TCallExpressionSyntax = TCallExpressionSyntax(inheritedTypeFunctionStatement.expression)
Check(inheritedTypeFunctionModel.ResolvedCall(inheritedTypeFunctionCall) <> Null And inheritedTypeFunctionModel.ResolvedCall(inheritedTypeFunctionCall).routine.containingScope.owner.name = "TSportBase", "child type qualification resolves a function declared by its parent type")
Local boundInheritedTypeFunction:TBoundCallExpression = TBoundCallExpression(TBoundExpressionStatement(inheritedTypeFunctionModel.BoundStatement(inheritedTypeFunctionStatement)).expression)
Check(TBoundConversionExpression(boundInheritedTypeFunction.arguments[0]).conversionKind = CONVERSION_CALLABLE_VARIANCE, "derived callback return is retained as an explicit callable-variance conversion")

Local objectTypeFunctionAnalysis:TLanguageAnalysis = TBlitzMaxLanguage.AnalyzeText("SuperStrict~nType TObjectFactoryBase~nFunction Create:TObjectFactoryBase()~nReturn Null~nEnd Function~nFunction Forward:TObjectFactoryBase()~nReturn Self.Create()~nEnd Function~nEnd Type~nType TObjectFactoryDerived Extends TObjectFactoryBase~nFunction Create:TObjectFactoryDerived()~nReturn New TObjectFactoryDerived~nEnd Function~nEnd Type~nLocal prototype:TObjectFactoryBase=New TObjectFactoryDerived~nLocal staticCreated:TObjectFactoryBase=TObjectFactoryBase.Create()~nLocal dynamicCreated:TObjectFactoryBase=prototype.Create()", "object-type-function-binding.bmx")
Check(objectTypeFunctionAnalysis.model.diagnostics.length = 0, "object- and type-qualified Type Function calls bind without diagnostics")
Local staticTypeFunctionDeclaration:TVariableDeclarationStatementSyntax = TVariableDeclarationStatementSyntax(objectTypeFunctionAnalysis.syntaxTree.root.members[4])
Local dynamicTypeFunctionDeclaration:TVariableDeclarationStatementSyntax = TVariableDeclarationStatementSyntax(objectTypeFunctionAnalysis.syntaxTree.root.members[5])
Local staticTypeFunctionCall:TBoundCallExpression = TBoundCallExpression(TBoundVariableDeclarationStatement(objectTypeFunctionAnalysis.model.BoundStatement(staticTypeFunctionDeclaration)).variables[0].initializer)
Local dynamicTypeFunctionCall:TBoundCallExpression = TBoundCallExpression(TBoundVariableDeclarationStatement(objectTypeFunctionAnalysis.model.BoundStatement(dynamicTypeFunctionDeclaration)).variables[0].initializer)
Check(staticTypeFunctionCall And Not staticTypeFunctionCall.receiver And dynamicTypeFunctionCall And TBoundSymbolExpression(dynamicTypeFunctionCall.receiver) And TBoundSymbolExpression(dynamicTypeFunctionCall.receiver).symbol.name = "prototype", "Type qualification remains static while object qualification retains the receiver for class-table Type Function dispatch")

Local methodTypeFunctionAnalysis:TLanguageAnalysis = TBlitzMaxLanguage.AnalyzeText("SuperStrict~nType TTargetBase~nField value:Object~nMethod Resolve:Int()~nReturn Resolve(value)~nEnd Method~nFunction Resolve:Int(value:Object)~nReturn 1~nEnd Function~nEnd Type~nType TTargetDerived Extends TTargetBase~nFunction Resolve:Int(value:Object)~nReturn 2~nEnd Function~nEnd Type", "method-type-function-binding.bmx")
Check(methodTypeFunctionAnalysis.model.diagnostics.length = 0, "a Method may call a same-Type Type Function without qualification")
Local methodTypeFunctionType:TTypeDeclarationSyntax = TTypeDeclarationSyntax(methodTypeFunctionAnalysis.syntaxTree.root.members[1])
Local methodTypeFunctionMethod:TRoutineDeclarationSyntax = TRoutineDeclarationSyntax(methodTypeFunctionType.body.statements[1])
Local methodTypeFunctionReturn:TReturnStatementSyntax = TReturnStatementSyntax(methodTypeFunctionMethod.body.statements[0])
Local methodTypeFunctionCall:TBoundCallExpression = TBoundCallExpression(methodTypeFunctionAnalysis.model.BoundExpression(methodTypeFunctionReturn.expression))
Check(methodTypeFunctionCall And TBoundSelfExpression(methodTypeFunctionCall.receiver) And TBoundSelfExpression(methodTypeFunctionCall.receiver).implicitReceiver, "an unqualified same-Type Type Function call from a Method retains an implicit Self receiver for polymorphic dispatch")

Local invalidSuperSource:String = "SuperStrict~nType TInvalidSuperBase~nMethod ReadByte:Int()~nEnd Method~nEnd Type~nType TInvalidSuperDerived Extends TInvalidSuperBase~nField invalidField:Int = Super.ReadByte()~nEnd Type~nLocal invalidGlobal:Int = Super.ReadByte()"
Local invalidSuperParse:TParseResult = TBlitzMaxParser.ParseText(invalidSuperSource, "invalid-super-scope.bmx")
Local invalidSuperModel:TSemanticModel = TBlitzMaxSemanticAnalyzer.Analyze(invalidSuperParse.syntaxTree)
TExpressionBinder.Bind(invalidSuperModel)
Local invalidSuperCount:Int
For Local diagnostic:TDiagnostic = EachIn invalidSuperModel.diagnostics
	If diagnostic.code = "BMX3300" And diagnostic.message.Contains("Super") Then invalidSuperCount :+ 1
Next
Check(invalidSuperCount >= 2, "Super is rejected outside a type routine, including field and global initializers")

Local prefixCastSource:String = "SuperStrict~nStruct SPair~nField x:Int~nField y:Int~nEnd Struct~nLocal data:Byte[1024]~nLocal bytePointer:Byte Ptr = (Byte Ptr data) + 1~nLocal pairs:SPair[2]~nLocal integerPointer:Int Ptr = (Int Ptr pairs)"
Local prefixCastParse:TParseResult = TBlitzMaxParser.ParseText(prefixCastSource, "parenthesized-pointer-cast.bmx")
Check(prefixCastParse.syntaxTree.diagnostics.length = 0, "parenthesized pointer cast syntax diagnostics")
Local prefixCastModel:TSemanticModel = TBlitzMaxSemanticAnalyzer.Analyze(prefixCastParse.syntaxTree)
TExpressionBinder.Bind(prefixCastModel)
Check(prefixCastModel.diagnostics.length = 0, "numeric and struct array pointer cast diagnostics")
Local bytePointerDeclaration:TVariableDeclarationStatementSyntax = TVariableDeclarationStatementSyntax(prefixCastParse.syntaxTree.root.members[3])
Local bytePointerAddition:TBinaryExpressionSyntax = TBinaryExpressionSyntax(bytePointerDeclaration.declarators[0].initializer)
Local bytePointerCast:TCastExpressionSyntax = TCastExpressionSyntax(bytePointerAddition.left)
Check(bytePointerCast <> Null And prefixCastModel.ExpressionType(bytePointerCast).DisplayName() = "Byte Ptr", "parenthesized prefix cast builds a typed cast expression")

Local unparenthesizedCastSource:String = "SuperStrict~nFunction GetValue:Int()~nReturn 42~nEnd Function~nLocal base:Byte Ptr~nLocal offset:Int~nLocal direct:Byte Ptr = Byte Ptr GetValue()~nLocal numeric:Int = Int base~nLocal nested:Byte Ptr = Byte Ptr Int Ptr(base + offset)[0]"
Local unparenthesizedCastParse:TParseResult = TBlitzMaxParser.ParseText(unparenthesizedCastSource, "unparenthesized-prefix-casts.bmx")
Local unparenthesizedCastModel:TSemanticModel = TBlitzMaxSemanticAnalyzer.Analyze(unparenthesizedCastParse.syntaxTree)
TExpressionBinder.Bind(unparenthesizedCastModel)
Check(unparenthesizedCastModel.diagnostics.length = 0, "unparenthesized numeric and nested pointer casts bind successfully")
Local nestedCastDeclaration:TVariableDeclarationStatementSyntax = TVariableDeclarationStatementSyntax(unparenthesizedCastParse.syntaxTree.root.members[6])
Local outerPointerCast:TCastExpressionSyntax = TCastExpressionSyntax(nestedCastDeclaration.declarators[0].initializer)
Check(outerPointerCast <> Null And unparenthesizedCastModel.ExpressionType(outerPointerCast).DisplayName() = "Byte Ptr" And TIndexExpressionSyntax(outerPointerCast.expression) <> Null, "outer pointer cast receives the indexed inner pointer cast value")

Local integralDimensionSource:String = "SuperStrict~nLocal length:Size_T = 32~nLocal bytes:Byte[] = New Byte[length]"
Local integralDimensionParse:TParseResult = TBlitzMaxParser.ParseText(integralDimensionSource, "integral-array-dimension.bmx")
Local integralDimensionModel:TSemanticModel = TBlitzMaxSemanticAnalyzer.Analyze(integralDimensionParse.syntaxTree)
TExpressionBinder.Bind(integralDimensionModel)
Check(integralDimensionModel.diagnostics.length = 0, "Size_T is accepted as an array dimension")

Local readOnlySource:String = "SuperStrict~nType TReadOnlyBuffer~nField ReadOnly _size:Int~nMethod New(size:Int)~n_size = size~nEnd Method~nMethod New(mark:Int, capacity:Int)~n_size = capacity~nEnd Method~nMethod Size:Int()~nReturn _size~nEnd Method~nMethod Mutate()~n_size = 1~nEnd Method~nEnd Type"
Local readOnlyParse:TParseResult = TBlitzMaxParser.ParseText(readOnlySource, "readonly-field-binding.bmx")
Local readOnlyModel:TSemanticModel = TBlitzMaxSemanticAnalyzer.Analyze(readOnlyParse.syntaxTree)
TExpressionBinder.Bind(readOnlyModel)
Local readOnlyField:TSymbol = readOnlyModel.globalScope.LookupLocal("TReadOnlyBuffer")[0].memberScope.LookupLocal("_size")[0]
Check(readOnlyField <> Null And readOnlyField.isReadOnly, "ReadOnly field modifier is retained on the symbol")
Local readOnlyDiagnostics:Int
For Local diagnostic:TDiagnostic = EachIn readOnlyModel.diagnostics
	If diagnostic.code = "BMX3315" Then readOnlyDiagnostics :+ 1
Next
Check(readOnlyDiagnostics = 1, "ReadOnly field assignments are allowed in constructor overloads and rejected elsewhere")

Local enumOrdinalSource:String = "SuperStrict~nEnum EByteOrder~nLittleEndian~nBigEndian~nEnd Enum~nEnum ESmall : Byte~nZero~nOne~nEnd Enum~nLocal order:EByteOrder = EByteOrder.LittleEndian~nLocal ordinal:Int = order.Ordinal()~nLocal text:String = order.ToString()~nLocal small:ESmall = ESmall.One~nLocal smallOrdinal:Byte = small.Ordinal()"
Local enumOrdinalParse:TParseResult = TBlitzMaxParser.ParseText(enumOrdinalSource, "enum-ordinal-binding.bmx")
Local enumOrdinalModel:TSemanticModel = TBlitzMaxSemanticAnalyzer.Analyze(enumOrdinalParse.syntaxTree)
TExpressionBinder.Bind(enumOrdinalModel)
Check(enumOrdinalModel.diagnostics.length = 0, "generated enum instance methods bind without diagnostics")
Local ordinalDeclaration:TVariableDeclarationStatementSyntax = TVariableDeclarationStatementSyntax(enumOrdinalParse.syntaxTree.root.members[4])
Local ordinalCall:TCallExpressionSyntax = TCallExpressionSyntax(ordinalDeclaration.declarators[0].initializer)
Check(enumOrdinalModel.ExpressionType(ordinalCall) = enumOrdinalModel.BuiltinType("Int"), "Enum.Ordinal returns the default Int underlying type")
Local smallOrdinalDeclaration:TVariableDeclarationStatementSyntax = TVariableDeclarationStatementSyntax(enumOrdinalParse.syntaxTree.root.members[7])
Local smallOrdinalCall:TCallExpressionSyntax = TCallExpressionSyntax(smallOrdinalDeclaration.declarators[0].initializer)
Check(enumOrdinalModel.ExpressionType(smallOrdinalCall) = enumOrdinalModel.BuiltinType("Byte"), "Enum.Ordinal preserves an explicitly selected underlying type")

Local strictReturnSource:String = "Strict~nFunction AllocHookId()~nGlobal id = -1~nid :+ 1~nReturn id~nEnd Function~nLocal value:Int = AllocHookId()"
Local strictReturnParse:TParseResult = TBlitzMaxParser.ParseText(strictReturnSource, "strict-default-return.bmx")
Local strictReturnModel:TSemanticModel = TBlitzMaxSemanticAnalyzer.Analyze(strictReturnParse.syntaxTree)
TExpressionBinder.Bind(strictReturnModel)
Check(strictReturnModel.diagnostics.length = 0, "Strict routine with an omitted return type returns Int")
Check(strictReturnModel.globalScope.LookupLocal("AllocHookId")[0].declaredType = strictReturnModel.BuiltinType("Int"), "Strict omitted routine return type is modeled as Int")

Local strictGlobalReturn:TLanguageAnalysis = TBlitzMaxLanguage.AnalyzeText("Strict~nIf True Then Return", "strict-global-return.bmx")
Check(strictGlobalReturn.model.diagnostics.length = 0, "Strict module entry permits a bare Return")
Local superStrictGlobalReturn:TLanguageAnalysis = TBlitzMaxLanguage.AnalyzeText("SuperStrict~nIf True Then Return", "superstrict-global-return.bmx")
Check(HasDiagnostic(superStrictGlobalReturn.model.diagnostics, "BMX3311"), "SuperStrict module entry requires an explicit Return value")
Local explicitGlobalReturnValue:TLanguageAnalysis = TBlitzMaxLanguage.AnalyzeText("SuperStrict~nIf True Then Return 0", "explicit-global-return.bmx")
Check(explicitGlobalReturnValue.model.diagnostics.length = 0, "SuperStrict module entry accepts an explicit Int Return value")

Local longIntWideningSource:String = "SuperStrict~nType TRandom~nMethod RandomLong:Long(minValue:Long, maxValue:Long)~nReturn minValue~nEnd Method~nMethod RandomLongInt:LongInt(minValue:LongInt, maxValue:LongInt = 1)~nReturn LongInt(RandomLong(minValue, maxValue))~nEnd Method~nEnd Type"
Local longIntWideningParse:TParseResult = TBlitzMaxParser.ParseText(longIntWideningSource, "longint-to-long.bmx")
Local longIntWideningModel:TSemanticModel = TBlitzMaxSemanticAnalyzer.Analyze(longIntWideningParse.syntaxTree)
TExpressionBinder.Bind(longIntWideningModel)
Check(longIntWideningModel.diagnostics.length = 0, "LongInt arguments widen to Long parameters")

Local constructorSource:String = "SuperStrict~nStruct b2Vec2~nField x:Float~nField y:Float~nMethod New(x:Float, y:Float)~nSelf.x = x~nSelf.y = y~nEnd Method~nMethod Subtract:b2Vec2(vec:b2Vec2)~nReturn New b2Vec2(x - vec.x, y - vec.y)~nEnd Method~nEnd Struct~nLocal explicit:b2Vec2 = New b2Vec2(1.0, 2.0)~nLocal implicitDefault:b2Vec2 = New b2Vec2"
Local constructorParse:TParseResult = TBlitzMaxParser.ParseText(constructorSource, "constructor-binding.bmx")
Local constructorModel:TSemanticModel = TBlitzMaxSemanticAnalyzer.Analyze(constructorParse.syntaxTree)
TExpressionBinder.Bind(constructorModel)
Check(constructorModel.diagnostics.length = 0, "declared constructor overload and implicit default constructor diagnostics")
Local constructorType:TTypeDeclarationSyntax = TTypeDeclarationSyntax(constructorParse.syntaxTree.root.members[1])
Local subtractRoutine:TRoutineDeclarationSyntax = TRoutineDeclarationSyntax(constructorType.body.statements[3])
Local subtractCreation:TNewExpressionSyntax = TNewExpressionSyntax(TReturnStatementSyntax(subtractRoutine.body.statements[0]).expression)
Local resolvedConstructor:TResolvedCall = constructorModel.ResolvedCall(subtractCreation)
Check(resolvedConstructor <> Null And resolvedConstructor.routine.name.ToLower() = "new" And resolvedConstructor.parameterTypes.length = 2, "New expression resolves the matching two-argument constructor")
Check(TBoundNewExpression(constructorModel.BoundExpression(subtractCreation)).resolvedConstructor = resolvedConstructor, "bound New expression retains the selected constructor")

Local inheritedConstructorSource:String = "SuperStrict~nType TMessageBase~nMethod New(message:String)~nEnd Method~nEnd Type~nType TMessageMiddle Extends TMessageBase~nEnd Type~nType TMessageLeaf Extends TMessageMiddle~nEnd Type~nLocal value:TMessageLeaf = New TMessageLeaf(~qmessage~q)"
Local inheritedConstructorParse:TParseResult = TBlitzMaxParser.ParseText(inheritedConstructorSource, "inherited-constructor-binding.bmx")
Local inheritedConstructorModel:TSemanticModel = TBlitzMaxSemanticAnalyzer.Analyze(inheritedConstructorParse.syntaxTree)
TExpressionBinder.Bind(inheritedConstructorModel)
Local inheritedConstructorDeclaration:TVariableDeclarationStatementSyntax = TVariableDeclarationStatementSyntax(inheritedConstructorParse.syntaxTree.root.members[4])
Local inheritedConstructorCreation:TNewExpressionSyntax = TNewExpressionSyntax(inheritedConstructorDeclaration.declarators[0].initializer)
Local inheritedConstructorCall:TResolvedCall = inheritedConstructorModel.ResolvedCall(inheritedConstructorCreation)
Check(inheritedConstructorModel.diagnostics.length = 0 And inheritedConstructorCall And inheritedConstructorCall.routine.containingScope.owner.name = "TMessageBase" And inheritedConstructorCall.parameterTypes[0] = inheritedConstructorModel.BuiltinType("String"), "New resolves an inherited constructor through an otherwise constructor-free derived hierarchy")

Local superConstructorSource:String = "SuperStrict~nType TBase~nMethod New(value:Int)~nEnd Method~nEnd Type~nType TDerived Extends TBase~nMethod New(value:Int)~nSuper.New(value)~nEnd Method~nEnd Type"
Local superConstructorParse:TParseResult = TBlitzMaxParser.ParseText(superConstructorSource, "super-constructor-binding.bmx")
Local superConstructorModel:TSemanticModel = TBlitzMaxSemanticAnalyzer.Analyze(superConstructorParse.syntaxTree)
TExpressionBinder.Bind(superConstructorModel)
Local derivedConstructorType:TSymbol = superConstructorModel.globalScope.LookupLocal("TDerived")[0]
Local derivedConstructor:TSymbol = derivedConstructorType.memberScope.LookupLocal("New")[0]
Local derivedConstructorBody:TBoundBlockStatement = superConstructorModel.BoundRoutineBody(derivedConstructor)
Local superConstructorCall:TBoundCallExpression = TBoundCallExpression(TBoundExpressionStatement(derivedConstructorBody.statements[0]).expression)
Local superConstructorReceiver:TBoundSelfExpression = TBoundSelfExpression(superConstructorCall.receiver)
Check(superConstructorModel.diagnostics.length = 0 And superConstructorReceiver And superConstructorReceiver.isSuper And superConstructorReceiver.semanticType.DisplayName() = "TBase", "bound Super.New retains an explicit base-typed Super receiver")

Local delegatedConstructorSource:String = "SuperStrict~nType TDelegating~nMethod New()~nNew(4)~nEnd Method~nMethod New(value:Int)~nEnd Method~nEnd Type"
Local delegatedConstructorParse:TParseResult = TBlitzMaxParser.ParseText(delegatedConstructorSource, "delegated-constructor-binding.bmx")
Local delegatedConstructorModel:TSemanticModel = TBlitzMaxSemanticAnalyzer.Analyze(delegatedConstructorParse.syntaxTree)
TExpressionBinder.Bind(delegatedConstructorModel)
Local delegatedType:TSymbol = delegatedConstructorModel.globalScope.LookupLocal("TDelegating")[0]
Local defaultDelegatingConstructor:TSymbol = delegatedType.memberScope.LookupLocal("New")[0]
Local defaultDelegatingBody:TBoundBlockStatement = delegatedConstructorModel.BoundRoutineBody(defaultDelegatingConstructor)
Local delegatedCall:TBoundCallExpression = TBoundCallExpression(TBoundExpressionStatement(defaultDelegatingBody.statements[0]).expression)
Check(delegatedConstructorModel.diagnostics.length = 0 And delegatedCall And delegatedCall.resolvedCall.parameterTypes.length = 1 And TBoundSelfExpression(delegatedCall.receiver) And delegatedCall.receiver.isSynthetic, "bare New(args) binds as same-Type constructor delegation with an implicit Self receiver")

Local misplacedDelegationParse:TParseResult = TBlitzMaxParser.ParseText("SuperStrict~nType TBad~nMethod New()~nLocal value:Int~nNew(1)~nEnd Method~nMethod New(value:Int)~nEnd Method~nEnd Type", "misplaced-constructor-delegation.bmx")
Local misplacedDelegationModel:TSemanticModel = TBlitzMaxSemanticAnalyzer.Analyze(misplacedDelegationParse.syntaxTree)
TExpressionBinder.Bind(misplacedDelegationModel)
Check(HasDiagnostic(misplacedDelegationModel.diagnostics, "BMX3322"), "constructor delegation is rejected unless it is the first constructor statement")

Local outsideDelegationParse:TParseResult = TBlitzMaxParser.ParseText("SuperStrict~nType TBad~nMethod New(value:Int)~nEnd Method~nMethod Build()~nNew(1)~nEnd Method~nEnd Type", "outside-constructor-delegation.bmx")
Local outsideDelegationModel:TSemanticModel = TBlitzMaxSemanticAnalyzer.Analyze(outsideDelegationParse.syntaxTree)
TExpressionBinder.Bind(outsideDelegationModel)
Check(HasDiagnostic(outsideDelegationModel.diagnostics, "BMX3321"), "constructor delegation is rejected outside a New method")

Local recursiveDelegationParse:TParseResult = TBlitzMaxParser.ParseText("SuperStrict~nType TBad~nMethod New()~nNew()~nEnd Method~nEnd Type", "recursive-constructor-delegation.bmx")
Local recursiveDelegationModel:TSemanticModel = TBlitzMaxSemanticAnalyzer.Analyze(recursiveDelegationParse.syntaxTree)
TExpressionBinder.Bind(recursiveDelegationModel)
Check(HasDiagnostic(recursiveDelegationModel.diagnostics, "BMX3323"), "direct recursive constructor delegation is diagnosed")

Local invalidConstructorSource:String = constructorSource + "~nLocal invalid:b2Vec2 = New b2Vec2(1.0)"
Local invalidConstructorParse:TParseResult = TBlitzMaxParser.ParseText(invalidConstructorSource, "invalid-constructor-binding.bmx")
Local invalidConstructorModel:TSemanticModel = TBlitzMaxSemanticAnalyzer.Analyze(invalidConstructorParse.syntaxTree)
TExpressionBinder.Bind(invalidConstructorModel)
Check(HasDiagnostic(invalidConstructorModel.diagnostics, "BMX3302"), "constructor invocation rejects an unsupported argument count")

Local privateConstructorSource:String = "SuperStrict~nType TClosed~nPrivate~nMethod New()~nEnd Method~nPublic~nFunction Create:TClosed()~nReturn New TClosed~nEnd Function~nEnd Type~nLocal allowed:TClosed = TClosed.Create()~nLocal direct:TClosed = New TClosed"
Local privateConstructorParse:TParseResult = TBlitzMaxParser.ParseText(privateConstructorSource, "private-default-constructor.bmx")
Local privateConstructorModel:TSemanticModel = TBlitzMaxSemanticAnalyzer.Analyze(privateConstructorParse.syntaxTree)
TExpressionBinder.Bind(privateConstructorModel)
Check(HasDiagnostic(privateConstructorModel.diagnostics, "BMX3317"), "a private constructor is callable by its declaring Type but not elsewhere in the same compilation unit")

Local visibilitySource:String = "SuperStrict~nType TAccessBase~nPrivate~nMethod Hidden:Int()~nReturn 1~nEnd Method~nProtected~nMethod ForDerived:Int()~nReturn 2~nEnd Method~nInternal~nMethod ModuleOnly:Int()~nReturn 3~nEnd Method~nEnd Type~nType TAccessDerived Extends TAccessBase~nMethod Read:Int()~nReturn ForDerived() + ModuleOnly()~nEnd Method~nEnd Type~nType TAccessPeer~nMethod Read:Int(value:TAccessBase)~nLocal allowed:Int = value.ModuleOnly()~nLocal deniedPrivate:Int = value.Hidden()~nReturn value.ForDerived()~nEnd Method~nEnd Type"
Local visibilityParse:TParseResult = TBlitzMaxParser.ParseText(visibilitySource, "/sdk/mod/example.mod/access.mod/access.bmx")
Local visibilityModel:TSemanticModel = TBlitzMaxSemanticAnalyzer.Analyze(visibilityParse.syntaxTree)
TExpressionBinder.Bind(visibilityModel)
Local inaccessibleMembers:Int
For Local diagnostic:TDiagnostic = EachIn visibilityModel.diagnostics
	If diagnostic.code = "BMX3318" Then inaccessibleMembers :+ 1
Next
Check(inaccessibleMembers = 2, "private members remain Type-scoped, internal members remain module-visible, and protected retains its derived-Type boundary")
Check(Not HasDiagnostic(visibilityModel.diagnostics, "BMX3301") And Not HasDiagnostic(visibilityModel.diagnostics, "BMX3302"), "inaccessible members do not produce misleading lookup or overload diagnostics")

Local inheritedPrivateFieldSource:String = "SuperStrict~nType TPrivateBase~nPrivate~nField hidden:Int~nEnd Type~nType TPrivateDerived Extends TPrivateBase~nMethod Read:Int()~nReturn hidden~nEnd Method~nEnd Type"
Local inheritedPrivateFieldParse:TParseResult = TBlitzMaxParser.ParseText(inheritedPrivateFieldSource, "inherited-private-field.bmx")
Local inheritedPrivateFieldModel:TSemanticModel = TBlitzMaxSemanticAnalyzer.Analyze(inheritedPrivateFieldParse.syntaxTree)
TExpressionBinder.Bind(inheritedPrivateFieldModel)
Check(HasDiagnostic(inheritedPrivateFieldModel.diagnostics, "BMX3318"), "private inherited fields remain inaccessible to a derived Type in the same compilation unit")

Local privateTypeFunctionSource:String = "SuperStrict~nType TMission~nEnd Type~nType TMissionScore~nEnd Type~nType TMissions~nPrivate~nFunction AddHighscoreEntry(mission:TMission, score:TMissionScore)~nEnd Function~nEnd Type~nLocal mission:TMission = New TMission~nLocal score:TMissionScore = New TMissionScore~nTMissions.AddHighscoreEntry(mission, score)"
Local privateTypeFunctionParse:TParseResult = TBlitzMaxParser.ParseText(privateTypeFunctionSource, "private-type-function-access.bmx")
Local privateTypeFunctionModel:TSemanticModel = TBlitzMaxSemanticAnalyzer.Analyze(privateTypeFunctionParse.syntaxTree)
TExpressionBinder.Bind(privateTypeFunctionModel)
Check(HasDiagnostic(privateTypeFunctionModel.diagnostics, "BMX3318"), "private Type functions remain inaccessible outside their declaring Type in the same compilation unit")
Local privateTypeFunctionStatement:TCallStatementSyntax = TCallStatementSyntax(privateTypeFunctionParse.syntaxTree.root.members[6])
Local privateTypeFunctionCall:TCallExpressionSyntax = TCallExpressionSyntax(privateTypeFunctionStatement.expression)
Check(privateTypeFunctionModel.ReferencedSymbol(privateTypeFunctionCall.callee).name = "AddHighscoreEntry", "inaccessible private Type function calls retain their declaration reference for editor features")

Local internalConstructorSource:String = "SuperStrict~nType TInternalValue~nInternal~nMethod New()~nEnd Method~nEnd Type~nType TInternalFactory~nFunction Create:TInternalValue()~nReturn New TInternalValue~nEnd Function~nEnd Type"
Local internalConstructorParse:TParseResult = TBlitzMaxParser.ParseText(internalConstructorSource, "/sdk/mod/example.mod/access.mod/factory.bmx")
Local internalConstructorModel:TSemanticModel = TBlitzMaxSemanticAnalyzer.Analyze(internalConstructorParse.syntaxTree)
TExpressionBinder.Bind(internalConstructorModel)
Check(Not HasDiagnostic(internalConstructorModel.diagnostics, "BMX3317"), "internal constructors are callable by another type in the same module")

Local importedInternal:TSymbol = New TSymbol
importedInternal.visibility = VISIBILITY_INTERNAL
importedInternal.isImported = True
importedInternal.originModule = "example.access"
Local outsideModel:TSemanticModel = New TSemanticModel
outsideModel.moduleName = "example.consumer"
Local insideModel:TSemanticModel = New TSemanticModel
insideModel.moduleName = "example.access"
Check(Not TSymbolAccessibility.IsAccessible(importedInternal, Null, outsideModel), "imported internal symbols are hidden from another module")
Check(Not TSymbolAccessibility.IsAccessible(importedInternal, Null, insideModel), "a separately compiled import does not gain internal access by sharing a logical module name")
Check(TSymbolAccessibility.ModuleNameForPath("/sdk/mod/collections.mod/queue.mod/queue.bmx") = "collections.queue", "primary module source path identifies its module")
Check(TSymbolAccessibility.ModuleNameForPath("/sdk/mod/collections.mod/queue.mod/tests/test.bmx") = "", "a test application beneath a module directory is not treated as that module")
Check(TSymbolAccessibility.ModuleNameForPath("/sdk/mod/One.mod/Two.mod/Three.mod/three.bmx") = "one.two.three", "nested primary module source paths contribute every .mod segment case-insensitively")
Check(TSymbolAccessibility.ModuleNameForPath("C:\SDK\mod\One.mod\Two.mod\Three.mod\.bmx\three.bmx.release.win32.x64.i") = "one.two.three", "Windows-style nested compiler-interface paths retain the complete module identity")
Check(TSymbolAccessibility.ModuleNameForPath("/sdk/mod/one.mod/two.mod/three.mod/tests/three.bmx") = "", "nested module subdirectories do not become module compilation units")
Check(TSymbolAccessibility.ModuleNameForPath("/sdk/mod/one.two.mod/three.mod/three.bmx") = "", "a dotted .mod basename is not treated as multiple logical namespace components")

Local combinedAccessSource:String = "SuperStrict~nType TCombinedBase~nPrivate Internal~nField family:Int~nProtected Internal~nField shared:Int~nEnd Type~nType TCombinedDerived Extends TCombinedBase~nMethod Read:Int()~nReturn family + shared~nEnd Method~nEnd Type~nType TCombinedPeer~nMethod Read:Int(value:TCombinedBase)~nLocal allowed:Int = value.shared~nReturn value.family~nEnd Method~nEnd Type"
Local combinedAccessParse:TParseResult = TBlitzMaxParser.ParseText(combinedAccessSource, "/sdk/mod/example.mod/access.mod/combined-access.bmx")
Local combinedAccessModel:TSemanticModel = TBlitzMaxSemanticAnalyzer.Analyze(combinedAccessParse.syntaxTree)
TExpressionBinder.Bind(combinedAccessModel)
Local combinedAccessDiagnostics:Int
For Local diagnostic:TDiagnostic = EachIn combinedAccessModel.diagnostics
	If diagnostic.code = "BMX3318" Then combinedAccessDiagnostics :+ 1
Next
Check(combinedAccessDiagnostics = 0, "peers and derived types in one compilation unit can access Private Internal and Protected Internal members")

Local externalCombinedParse:TParseResult = TBlitzMaxParser.ParseText(combinedAccessSource, "/sdk/mod/example.mod/consumer.mod/external-access.bmx")
Local externalCombinedModel:TSemanticModel = TBlitzMaxSemanticAnalyzer.Analyze(externalCombinedParse.syntaxTree)
externalCombinedModel.moduleName = "example.consumer"
Local externalBase:TSymbol = externalCombinedModel.globalScope.LookupLocal("TCombinedBase")[0]
For Local member:TSymbol = EachIn externalBase.memberScope.declaredSymbols
	member.originPath = "/sdk/mod/example.mod/access.mod/combined-access.bmx"
	member.originModule = "example.access"
	member.isImported = True
Next
TExpressionBinder.Bind(externalCombinedModel)
Local externalCombinedDiagnostics:Int
For Local diagnostic:TDiagnostic = EachIn externalCombinedModel.diagnostics
	If diagnostic.code = "BMX3318" Then externalCombinedDiagnostics :+ 1
Next
Check(externalCombinedDiagnostics = 3, "external derived types retain Protected Internal access but not Private Internal access")

Local abstractCreationSource:String = "SuperStrict~nType TCipherFactory~nMethod Find:Int(index:Int) Abstract~nEnd Type~nType TIncompleteFactory Extends TCipherFactory~nEnd Type~nType TConcreteFactory Extends TCipherFactory~nMethod Find:Int(index:Int)~nReturn index~nEnd Method~nEnd Type~nType TExplicitAbstract Abstract~nEnd Type~nLocal invalidBase:TCipherFactory = New TCipherFactory~nLocal invalidChild:TIncompleteFactory = New TIncompleteFactory~nLocal validChild:TConcreteFactory = New TConcreteFactory~nLocal invalidExplicit:TExplicitAbstract = New TExplicitAbstract~nLocal abstractArray:TCipherFactory[] = New TCipherFactory[4]"
Local abstractCreationParse:TParseResult = TBlitzMaxParser.ParseText(abstractCreationSource, "abstract-type-creation.bmx")
Local abstractCreationModel:TSemanticModel = TBlitzMaxSemanticAnalyzer.Analyze(abstractCreationParse.syntaxTree)
TExpressionBinder.Bind(abstractCreationModel)
Local abstractCreationDiagnostics:Int
For Local diagnostic:TDiagnostic = EachIn abstractCreationModel.diagnostics
	If diagnostic.code = "BMX3316" Then abstractCreationDiagnostics :+ 1
Next
Check(abstractCreationDiagnostics = 3, "abstract types and children with unimplemented abstract methods cannot be instantiated")
Check(abstractCreationModel.IsAbstractType(abstractCreationModel.globalScope.LookupLocal("TCipherFactory")[0]), "a type declaring an abstract method is modeled as abstract")
Check(abstractCreationModel.IsAbstractType(abstractCreationModel.globalScope.LookupLocal("TIncompleteFactory")[0]), "an inherited abstract method keeps a child abstract")
Check(Not abstractCreationModel.IsAbstractType(abstractCreationModel.globalScope.LookupLocal("TConcreteFactory")[0]), "implementing every abstract method makes a child concrete")

Local abstractTypeFunctionSource:String = "SuperStrict~nType TAbstractFunctions~nFunction Required:Int(value:Int) Abstract~nFunction Zero:Int() Abstract~nFunction Invoke:Int(value:Int)~nReturn Required(value)~nEnd Function~nEnd Type~nType TConcreteFunctions Extends TAbstractFunctions~nFunction Required:Int(value:Int)~nReturn value~nEnd Function~nFunction Zero:Int()~nReturn 42~nEnd Function~nEnd Type~nLocal invalidDirect:Int=TAbstractFunctions.Required(1)~nLocal invalidImplicit:Int=TAbstractFunctions.Zero~nLocal validDirect:Int=TConcreteFunctions.Required(2)~nLocal validImplicit:Int=TConcreteFunctions.Zero~nType TAbstractMethod~nMethod Required:Int(value:Int) Abstract~nEnd Type~nType TConcreteMethod Extends TAbstractMethod~nMethod Required:Int(value:Int)~nReturn value~nEnd Method~nEnd Type~nLocal methodValue:TAbstractMethod=New TConcreteMethod~nLocal validVirtual:Int=methodValue.Required(3)"
Local abstractTypeFunctionParse:TParseResult = TBlitzMaxParser.ParseText(abstractTypeFunctionSource, "abstract-type-function-call.bmx")
Local abstractTypeFunctionModel:TSemanticModel = TBlitzMaxSemanticAnalyzer.Analyze(abstractTypeFunctionParse.syntaxTree)
TExpressionBinder.Bind(abstractTypeFunctionModel)
Local abstractTypeFunctionDiagnostics:Int
For Local diagnostic:TDiagnostic = EachIn abstractTypeFunctionModel.diagnostics
	If diagnostic.code = "BMX3319" Then abstractTypeFunctionDiagnostics :+ 1
Next
Check(abstractTypeFunctionDiagnostics = 3, "direct, command-internal, and implicit zero-argument calls reject abstract Type Functions")
Local invalidAbstractTypeFunctionDeclaration:TVariableDeclarationStatementSyntax = TVariableDeclarationStatementSyntax(abstractTypeFunctionParse.syntaxTree.root.members[3])
Local invalidAbstractTypeFunctionCall:TCallExpressionSyntax = TCallExpressionSyntax(invalidAbstractTypeFunctionDeclaration.declarators[0].initializer)
Local invalidAbstractTypeFunctionSymbol:TSymbol = abstractTypeFunctionModel.ReferencedSymbol(invalidAbstractTypeFunctionCall.callee)
Check(invalidAbstractTypeFunctionSymbol And invalidAbstractTypeFunctionSymbol.QualifiedName() = "TAbstractFunctions.Required", "an invalid abstract Type Function call retains its resolved symbol for editor navigation")
Check(Not HasDiagnostic(abstractTypeFunctionModel.diagnostics, "BMX3316"), "abstract Method dispatch through a concrete instance remains valid")

Local dynamicAbstractTypeFunctionSource:String = "SuperStrict~nType TAbstractDriver~nFunction Create:Int(value:Int) Abstract~nMethod Forward:Int(value:Int)~nReturn Create(value)~nEnd Method~nEnd Type~nType TConcreteDriver Extends TAbstractDriver~nFunction Create:Int(value:Int)~nReturn value + 1~nEnd Function~nEnd Type~nLocal driver:TAbstractDriver=New TConcreteDriver~nLocal explicitResult:Int=driver.Create(40)~nLocal implicitResult:Int=driver.Forward(41)"
Local dynamicAbstractTypeFunctionAnalysis:TLanguageAnalysis = TBlitzMaxLanguage.AnalyzeText(dynamicAbstractTypeFunctionSource, "dynamic-abstract-type-function-call.bmx")
Check(dynamicAbstractTypeFunctionAnalysis.model.diagnostics.length = 0, "an abstract Type Function may dispatch through a concrete object receiver")
Local dynamicAbstractExplicitDeclaration:TVariableDeclarationStatementSyntax = TVariableDeclarationStatementSyntax(dynamicAbstractTypeFunctionAnalysis.syntaxTree.root.members[4])
Local dynamicAbstractExplicitCall:TBoundCallExpression = TBoundCallExpression(TBoundVariableDeclarationStatement(dynamicAbstractTypeFunctionAnalysis.model.BoundStatement(dynamicAbstractExplicitDeclaration)).variables[0].initializer)
Local dynamicAbstractDriverType:TTypeDeclarationSyntax = TTypeDeclarationSyntax(dynamicAbstractTypeFunctionAnalysis.syntaxTree.root.members[1])
Local dynamicAbstractForward:TRoutineDeclarationSyntax = TRoutineDeclarationSyntax(dynamicAbstractDriverType.body.statements[1])
Local dynamicAbstractImplicitReturn:TReturnStatementSyntax = TReturnStatementSyntax(dynamicAbstractForward.body.statements[0])
Local dynamicAbstractImplicitCall:TBoundCallExpression = TBoundCallExpression(dynamicAbstractTypeFunctionAnalysis.model.BoundExpression(dynamicAbstractImplicitReturn.expression))
Check(dynamicAbstractExplicitCall And dynamicAbstractExplicitCall.receiver And dynamicAbstractImplicitCall And TBoundSelfExpression(dynamicAbstractImplicitCall.receiver), "explicit and implicit abstract Type Function calls retain their dynamic receivers")

Local dynamicNewSource:String = "SuperStrict~nType TDynamicBase~nEnd Type~nType TDynamicChild Extends TDynamicBase~nEnd Type~nGlobal prototype:TDynamicBase=New TDynamicChild~nLocal copy:TDynamicBase=New prototype~nFunction Clone:Object(value:Object)~nReturn New value~nEnd Function"
Local dynamicNewParse:TParseResult = TBlitzMaxParser.ParseText(dynamicNewSource, "dynamic-new-instance.bmx")
Local dynamicNewModel:TSemanticModel = TBlitzMaxSemanticAnalyzer.Analyze(dynamicNewParse.syntaxTree)
TExpressionBinder.Bind(dynamicNewModel)
Local dynamicNewWarnings:Int
For Local diagnostic:TDiagnostic = EachIn dynamicNewModel.diagnostics
	If diagnostic.code = "BMX3410" And diagnostic.severity = DIAGNOSTIC_WARNING Then dynamicNewWarnings :+ 1
Next
Local dynamicCopyDeclaration:TVariableDeclarationStatementSyntax = TVariableDeclarationStatementSyntax(dynamicNewParse.syntaxTree.root.members[4])
Local dynamicCopyCreation:TNewExpressionSyntax = TNewExpressionSyntax(dynamicCopyDeclaration.declarators[0].initializer)
Check(dynamicNewWarnings = 2 And dynamicNewModel.ExpressionType(dynamicCopyCreation).DisplayName() = "TDynamicBase", "New <Object instance> retains production's deprecated dynamic-class allocation semantics and warning")
Check(dynamicCopyCreation.instanceExpression <> Null And dynamicNewModel.BoundExpression(dynamicCopyCreation.instanceExpression) <> Null, "dynamic New retains an explicitly bound prototype expression")

Local stringObjectOverloadSource:String = "SuperStrict~nFunction AssertEquals(value:Object, other:Object, message:String)~nEnd Function~nFunction AssertEquals(value:Int, other:Int, message:String)~nEnd Function~nFunction AssertEquals(value:Long, other:Long, message:String)~nEnd Function~nAssertEquals(~quntouched~q, ~quntouched~q, ~qmessage~q)"
Local stringObjectOverloadParse:TParseResult = TBlitzMaxParser.ParseText(stringObjectOverloadSource, "string-object-overload.bmx")
Local stringObjectOverloadModel:TSemanticModel = TBlitzMaxSemanticAnalyzer.Analyze(stringObjectOverloadParse.syntaxTree)
TExpressionBinder.Bind(stringObjectOverloadModel)
Check(stringObjectOverloadModel.diagnostics.length = 0, "String arguments prefer Object overload over legacy numeric coercions")
Local stringObjectCall:TCallExpressionSyntax = TCallExpressionSyntax(TCallStatementSyntax(stringObjectOverloadParse.syntaxTree.root.members[4]).expression)
Check(stringObjectOverloadModel.ResolvedCall(stringObjectCall).parameterTypes[0] = stringObjectOverloadModel.BuiltinType("Object"), "String overload selection chooses the normal reference conversion")

Local eachInProtocolSource:String = "SuperStrict~nInterface IIterable<T>~nMethod GetIterator:IIterator<T>()~nEnd Interface~nInterface IIterator<T>~nMethod Current:T()~nMethod MoveNext:Int()~nEnd Interface~nType TIntIterator Implements IIterator<Int>~nMethod Current:Int()~nReturn 7~nEnd Method~nMethod MoveNext:Int()~nReturn False~nEnd Method~nEnd Type~nType TIntValues Implements IIterable<Int>~nMethod GetIterator:IIterator<Int>()~nReturn New TIntIterator~nEnd Method~nEnd Type~nType TLegacyIterator~nMethod HasNext:Int()~nReturn False~nEnd Method~nMethod NextObject:Object()~nReturn Null~nEnd Method~nEnd Type~nType TLegacyValues~nMethod ObjectEnumerator:TLegacyIterator()~nReturn New TLegacyIterator~nEnd Method~nEnd Type~nLocal values:TIntValues = New TIntValues~nFor Local value:Int = EachIn values~nNext~nLocal iterator:TIntIterator = New TIntIterator~nFor Local value:Int = EachIn iterator~nNext~nLocal legacy:TLegacyValues = New TLegacyValues~nFor Local value:Object = EachIn legacy~nNext~nLocal array:Int[] = [1]~nFor Local value:Int = EachIn array~nNext~nFor Local code:Int = EachIn ~qx~q~nNext~nLocal StaticArray fixed:Int[2]~nFor Local value:Int = EachIn fixed~nNext"
Local eachInProtocolParse:TParseResult = TBlitzMaxParser.ParseText(eachInProtocolSource, "eachin-protocols.bmx")
Local eachInProtocolModel:TSemanticModel = TBlitzMaxSemanticAnalyzer.Analyze(eachInProtocolParse.syntaxTree)
TExpressionBinder.Bind(eachInProtocolModel)
Check(eachInProtocolModel.diagnostics.length = 0, "built-in, generic interface and legacy EachIn protocols bind without diagnostics")
Local eachInLoops:TBoundForStatement[]
For Local member:TSyntaxNode = EachIn eachInProtocolParse.syntaxTree.root.members
	Local loopSyntax:TForStatementSyntax = TForStatementSyntax(member)
	If loopSyntax Then eachInLoops :+ [TBoundForStatement(eachInProtocolModel.BoundStatement(loopSyntax))]
Next
Check(eachInLoops.length = 6, "all EachIn loops publish bound iteration contracts")
Check(eachInLoops[0].iteration.protocolKind = EACH_IN_PROTOCOL_ITERABLE And eachInLoops[0].iteration.iteratorFactory.routine.name = "GetIterator" And eachInLoops[0].iteration.advance.routine.name = "MoveNext" And eachInLoops[0].iteration.current.routine.name = "Current" And eachInLoops[0].iteration.elementType = eachInProtocolModel.BuiltinType("Int"), "IIterable<T> resolves factory, iterator operations and substituted element type")
Check(eachInLoops[1].iteration.protocolKind = EACH_IN_PROTOCOL_ITERATOR And eachInLoops[1].iteration.iteratorFactory = Null And eachInLoops[1].iteration.elementType = eachInProtocolModel.BuiltinType("Int"), "direct IIterator<T> skips the iterator factory")
Check(eachInLoops[2].iteration.protocolKind = EACH_IN_PROTOCOL_OBJECT_ENUMERATOR And eachInLoops[2].iteration.iteratorFactory.routine.name = "ObjectEnumerator" And eachInLoops[2].iteration.advance.routine.name = "HasNext" And eachInLoops[2].iteration.current.routine.name = "NextObject" And eachInLoops[2].iteration.elementType = eachInProtocolModel.BuiltinType("Object"), "legacy ObjectEnumerator publishes its complete operation set")
Check(eachInLoops[3].iteration.protocolKind = EACH_IN_PROTOCOL_ARRAY And eachInLoops[4].iteration.protocolKind = EACH_IN_PROTOCOL_STRING And eachInLoops[5].iteration.protocolKind = EACH_IN_PROTOCOL_STATIC_ARRAY, "built-in iteration forms use the shared protocol contract")

Local deconstructEachInSource:String = "SuperStrict~nInterface IDeconstruct2<A, B>~nMethod Deconstruct(first:A Var, second:B Var)~nEnd Interface~nType TPair Implements IDeconstruct2<String, Int>~nField key:String~nField value:Int~nMethod Deconstruct(first:String Var, second:Int Var)~nfirst = key~nsecond = value~nEnd Method~nEnd Type~nLocal pairs:TPair[] = [New TPair]~nFor Local key:String, value:Int = EachIn pairs~nLocal text:String = key + value~nNext~nFor Local inferredKey, inferredValue = EachIn pairs~nLocal inferredText:String = inferredKey + inferredValue~nNext"
Local deconstructEachInAnalysis:TLanguageAnalysis = TBlitzMaxLanguage.AnalyzeText(deconstructEachInSource, "/sdk/mod/brl.mod/blitz.mod/blitz.bmx")
Check(deconstructEachInAnalysis.model.diagnostics.length = 0, "explicit and inferred IDeconstruct2 EachIn bindings analyze without diagnostics")
Local explicitDeconstructSyntax:TForStatementSyntax = TForStatementSyntax(deconstructEachInAnalysis.syntaxTree.root.members[4])
Local explicitDeconstructBound:TBoundForStatement = TBoundForStatement(deconstructEachInAnalysis.model.BoundStatement(explicitDeconstructSyntax))
Check(explicitDeconstructBound And explicitDeconstructBound.iteration.deconstructionType.typeArguments.length = 2 And explicitDeconstructBound.iteration.deconstruct.routine.name = "Deconstruct", "EachIn retains its resolved two-component deconstruction contract")
Check(explicitDeconstructBound.deconstructionVariables.length = 2 And explicitDeconstructBound.loopVariable.name.StartsWith("$deconstruct") And explicitDeconstructBound.body.statements.length = 4, "bound deconstruction uses one hidden yielded element followed by two declarations and one call before the source body")
Local inferredDeconstructSyntax:TForStatementSyntax = TForStatementSyntax(deconstructEachInAnalysis.syntaxTree.root.members[5])
Local inferredKeySymbol:TSymbol = deconstructEachInAnalysis.model.DeclaredSymbol(inferredDeconstructSyntax.header.declarations[0])
Local inferredValueSymbol:TSymbol = deconstructEachInAnalysis.model.DeclaredSymbol(inferredDeconstructSyntax.header.declarations[1])
Check(inferredKeySymbol.declaredType.DisplayName() = "String" And inferredValueSymbol.declaredType.DisplayName() = "Int", "omitted EachIn binding types are inferred independently from IDeconstruct2 arguments")

Local missingDeconstruct:TLanguageAnalysis = TBlitzMaxLanguage.AnalyzeText("SuperStrict~nType TPair~nEnd Type~nLocal pairs:TPair[]~nFor Local first:TPair, second:TPair = EachIn pairs~nNext", "missing-deconstruct.bmx")
Check(HasDiagnostic(missingDeconstruct.model.diagnostics, "BMX3336"), "two-binding EachIn requires its yielded element to implement IDeconstruct2")
Local impostorDeconstruct:TLanguageAnalysis = TBlitzMaxLanguage.AnalyzeText("SuperStrict~nInterface IDeconstruct2<A, B>~nMethod Deconstruct(first:A Var, second:B Var)~nEnd Interface~nType TPair Implements IDeconstruct2<String, Int>~nMethod Deconstruct(first:String Var, second:Int Var)~nEnd Method~nEnd Type~nLocal pairs:TPair[]~nFor Local first, second = EachIn pairs~nNext", "impostor-deconstruct.bmx")
Check(HasDiagnostic(impostorDeconstruct.model.diagnostics, "BMX3336"), "a same-named application Interface does not satisfy the canonical BRL.Blitz deconstruction contract")
Local mismatchedDeconstruct:TLanguageAnalysis = TBlitzMaxLanguage.AnalyzeText("SuperStrict~nInterface IDeconstruct2<A, B>~nMethod Deconstruct(first:A Var, second:B Var)~nEnd Interface~nType TPair Implements IDeconstruct2<String, Int>~nMethod Deconstruct(first:String Var, second:Int Var)~nEnd Method~nEnd Type~nLocal pairs:TPair[]~nFor Local first:Object, second:Int = EachIn pairs~nNext", "/sdk/mod/brl.mod/blitz.mod/blitz.bmx")
Check(HasDiagnostic(mismatchedDeconstruct.model.diagnostics, "BMX3338"), "explicit EachIn binding types must match their IDeconstruct2 components")

Local invalidEachInParse:TParseResult = TBlitzMaxParser.ParseText("SuperStrict~nType TNotIterable~nEnd Type~nLocal value:TNotIterable = New TNotIterable~nFor Local item:Object = EachIn value~nNext", "invalid-eachin.bmx")
Local invalidEachInModel:TSemanticModel = TBlitzMaxSemanticAnalyzer.Analyze(invalidEachInParse.syntaxTree)
TExpressionBinder.Bind(invalidEachInModel)
Check(HasDiagnostic(invalidEachInModel.diagnostics, "BMX3330"), "non-iterable EachIn collections receive a semantic diagnostic")

Local intrinsicArrayMemberParse:TParseResult = TBlitzMaxParser.ParseText("SuperStrict~nLocal values:Int[] = New Int[2]~nLocal count:Int = values.length", "intrinsic-array-member.bmx")
Local intrinsicArrayMemberModel:TSemanticModel = TBlitzMaxSemanticAnalyzer.Analyze(intrinsicArrayMemberParse.syntaxTree)
TExpressionBinder.Bind(intrinsicArrayMemberModel)
Check(intrinsicArrayMemberModel.diagnostics.length = 0, "Array.length binds without requiring an imported BRL.Classes snapshot")

Local declaredArrayDimensionParse:TParseResult = TBlitzMaxParser.ParseText("SuperStrict~nLocal amount:Int = 4~nLocal values:String[amount]", "declared-array-dimension.bmx")
Local declaredArrayDimensionModel:TSemanticModel = TBlitzMaxSemanticAnalyzer.Analyze(declaredArrayDimensionParse.syntaxTree)
TExpressionBinder.Bind(declaredArrayDimensionModel)
Local declaredArrayDimensionSyntax:TVariableDeclarationStatementSyntax
For Local declaredArrayMember:TSyntaxNode = EachIn declaredArrayDimensionParse.syntaxTree.root.members
	Local declaredArrayCandidate:TVariableDeclarationStatementSyntax = TVariableDeclarationStatementSyntax(declaredArrayMember)
	If declaredArrayCandidate And declaredArrayCandidate.declarators.length And declaredArrayCandidate.declarators[0].nameToken.text.ToLower() = "values" Then
		declaredArrayDimensionSyntax = declaredArrayCandidate
		Exit
	End If
Next
Local declaredArrayDimensionBound:TBoundVariableDeclarationStatement = TBoundVariableDeclarationStatement(declaredArrayDimensionModel.BoundStatement(declaredArrayDimensionSyntax))
Check(declaredArrayDimensionModel.diagnostics.length = 0 And declaredArrayDimensionSyntax.declarators[0].arrayDimensions.length = 1, "declaration-style heap Array dimensions remain explicit syntax rather than becoming StaticArray bounds")
Check(declaredArrayDimensionBound.variables[0].arrayDimensions.length = 1 And declaredArrayDimensionBound.variables[0].arrayDimensions[0].semanticType = declaredArrayDimensionModel.BuiltinType("Int"), "declaration-style heap Array dimensions retain their bound semantic expressions for later IR lowering")

Local ascCaseParse:TParseResult = TBlitzMaxParser.ParseText("SuperStrict~nLocal tag:Short~nSelect tag~nCase Asc(~qb~q), Asc(~q/~q)~nEnd Select", "asc-short-case.bmx")
Local ascCaseModel:TSemanticModel = TBlitzMaxSemanticAnalyzer.Analyze(ascCaseParse.syntaxTree)
TExpressionBinder.Bind(ascCaseModel)
Check(ascCaseModel.diagnostics.length = 0, "folded Asc values use range-checked constant conversion in a narrower Select")

Local functionLiteralSource:String = "SuperStrict~nLocal add:Int(value:Int) = Function(value)~nReturn value + 1~nEnd Function~nLocal answer:Int = add(41)"
Local functionLiteralAnalysis:TLanguageAnalysis = TBlitzMaxLanguage.AnalyzeText(functionLiteralSource, "function-literal-binding.bmx")
Check(functionLiteralAnalysis.model.diagnostics.length = 0, "contextually typed non-capturing Function literal binds without diagnostics")
Local functionLiteralDeclaration:TVariableDeclarationStatementSyntax = TVariableDeclarationStatementSyntax(functionLiteralAnalysis.syntaxTree.root.members[1])
Local functionLiteralSyntax:TFunctionLiteralExpressionSyntax = TFunctionLiteralExpressionSyntax(functionLiteralDeclaration.declarators[0].initializer)
Local functionLiteralType:TCallableSemanticType = TCallableSemanticType(functionLiteralAnalysis.model.ExpressionType(functionLiteralSyntax))
Local boundFunctionLiteral:TBoundFunctionLiteralExpression = TBoundFunctionLiteralExpression(functionLiteralAnalysis.model.BoundExpression(functionLiteralSyntax))
Check(functionLiteralType And functionLiteralType.DisplayName() = "Int(Int)", "Function literal adopts its explicit callable target")
Check(boundFunctionLiteral And boundFunctionLiteral.routine And boundFunctionLiteral.body And boundFunctionLiteral.body.statements.length = 1, "Function literal publishes a synthetic routine and bound body")
Local functionLiteralParameter:TSymbol = functionLiteralAnalysis.model.DeclaredSymbol(functionLiteralSyntax.parameters[0])
Check(functionLiteralParameter And functionLiteralParameter.declaredType = functionLiteralAnalysis.model.BuiltinType("Int"), "omitted Function literal parameter type is supplied contextually")

Local capturedFunctionLiteral:TLanguageAnalysis = TBlitzMaxLanguage.AnalyzeText("SuperStrict~nLocal offset:Int = 1~nLocal add:Int(value:Int) = Function(value)~nReturn value + offset~nEnd Function", "captured-function-literal.bmx")
Check(HasDiagnostic(capturedFunctionLiteral.model.diagnostics, "BMX3346"), "thin Function literal rejects lexical capture")
Local strictFunctionLiteral:TLanguageAnalysis = TBlitzMaxLanguage.AnalyzeText("Strict~nLocal add:Int(value:Int) = Function(value)~nReturn value + 1~nEnd Function", "strict-function-literal.bmx")
Check(HasDiagnostic(strictFunctionLiteral.model.diagnostics, "BMX3341"), "Function literal requires SuperStrict mode")
Local untypedFunctionLiteral:TLanguageAnalysis = TBlitzMaxLanguage.AnalyzeText("SuperStrict~nLocal add = Function(value)~nReturn value + 1~nEnd Function", "untyped-function-literal.bmx")
Check(HasDiagnostic(untypedFunctionLiteral.model.diagnostics, "BMX3340"), "Function literal requires an explicit callable context")
Local functionLiteralArgument:TLanguageAnalysis = TBlitzMaxLanguage.AnalyzeText("SuperStrict~nFunction Apply:Int(transform:Int(value:Int), input:Int)~nReturn transform(input)~nEnd Function~nLocal answer:Int = Apply(Function(value)~nReturn value + 1~nEnd Function, 41)", "function-literal-argument.bmx")
Check(functionLiteralArgument.model.diagnostics.length = 0, "an unambiguous routine parameter context types a Function literal argument")
Local genericCallableInvocation:TLanguageAnalysis = TBlitzMaxLanguage.AnalyzeText("SuperStrict~nType TInvoker<T>~nMethod Invoke:T(callback:T(value:T), value:T)~nReturn callback(value)~nEnd Method~nEnd Type", "generic-callable-invocation.bmx")
Check(genericCallableInvocation.model.diagnostics.length = 0, "an indirect callable invocation in a generic Method binds without inventing a same-Type dispatch receiver")
Local voidFunctionLiteral:TLanguageAnalysis = TBlitzMaxLanguage.AnalyzeText("SuperStrict~nLocal action() = Function()~nEnd Function~naction()", "void-function-literal.bmx")
Check(voidFunctionLiteral.model.diagnostics.length = 0, "a no-return Function literal adopts the target's implicit Void return")
Local globalFunctionLiteral:TLanguageAnalysis = TBlitzMaxLanguage.AnalyzeText("SuperStrict~nGlobal offset:Int = 1~nLocal add:Int(value:Int) = Function(value)~nReturn value + offset~nEnd Function", "global-function-literal.bmx")
Check(globalFunctionLiteral.model.diagnostics.length = 0, "thin Function literal may read static Global state without capture")
Local selfFunctionLiteral:TLanguageAnalysis = TBlitzMaxLanguage.AnalyzeText("SuperStrict~nType TCounter~nField amount:Int~nMethod Make:Int(value:Int)()~nReturn Function(value)~nReturn value + amount~nEnd Function~nEnd Method~nEnd Type", "self-function-literal.bmx")
Check(HasDiagnostic(selfFunctionLiteral.model.diagnostics, "BMX3346"), "thin Function literal rejects implicit Self field capture")

Local managedClosureAnalysis:TLanguageAnalysis = TBlitzMaxLanguage.AnalyzeText("SuperStrict~nLocal add:Closure<Int(value:Int)> = Function(value)~nReturn value + 1~nEnd Function~nLocal answer:Int = add(41)~nLocal notify:Closure<()> = Function()~nEnd Function~nnotify()", "managed-closure-binding.bmx")
Check(managedClosureAnalysis.model.diagnostics.length = 0, "non-capturing Function literals bind against explicit managed Closure targets")
Local managedClosureDeclaration:TVariableDeclarationStatementSyntax = TVariableDeclarationStatementSyntax(managedClosureAnalysis.syntaxTree.root.members[1])
Local managedClosureLiteral:TFunctionLiteralExpressionSyntax = TFunctionLiteralExpressionSyntax(managedClosureDeclaration.declarators[0].initializer)
Local managedClosureType:TClosureSemanticType = TClosureSemanticType(managedClosureAnalysis.model.ExpressionType(managedClosureLiteral))
Check(managedClosureType And managedClosureType.DisplayName() = "Closure<Int(value:Int)>", "managed Closure preserves its explicit named signature as the expression type")
Local boundMethodAnalysis:TLanguageAnalysis = TBlitzMaxLanguage.AnalyzeText("SuperStrict~nType TThreshold~nField limit:Int~nMethod Below:Int(value:Int)~nReturn value < limit~nEnd Method~nEnd Type~nLocal threshold:TThreshold = New TThreshold~nLocal predicate:Closure<Int(value:Int)> = threshold.Below", "bound-method-reference.bmx")
Check(boundMethodAnalysis.model.diagnostics.length = 0, "a Type instance Method binds as a managed Closure reference")
Local boundMethodDeclaration:TVariableDeclarationStatementSyntax = TVariableDeclarationStatementSyntax(boundMethodAnalysis.syntaxTree.root.members[3])
Local boundMethodSyntax:TMemberAccessExpressionSyntax = TMemberAccessExpressionSyntax(boundMethodDeclaration.declarators[0].initializer)
Local boundMethodReference:TBoundRoutineReferenceExpression = TBoundRoutineReferenceExpression(boundMethodAnalysis.model.BoundExpression(boundMethodSyntax))
Check(boundMethodReference And boundMethodReference.receiver And boundMethodReference.routine.name = "Below" And TClosureSemanticType(boundMethodReference.semanticType), "bound Method reference retains its object receiver and managed signature")
Local implicitBoundMethod:TLanguageAnalysis = TBlitzMaxLanguage.AnalyzeText("SuperStrict~nType TCounter~nMethod Add:Int(value:Int)~nReturn value + 1~nEnd Method~nMethod Callback:Closure<Int(value:Int)>()~nReturn Add~nEnd Method~nEnd Type", "implicit-bound-method-reference.bmx")
Check(implicitBoundMethod.model.diagnostics.length = 0, "an unqualified Method reference binds implicit Self as its receiver")
Local structBoundMethod:TLanguageAnalysis = TBlitzMaxLanguage.AnalyzeText("SuperStrict~nStruct SValue~nMethod Read:Int()~nReturn 1~nEnd Method~nEnd Struct~nLocal value:SValue~nLocal callback:Closure<Int()> = value.Read", "struct-bound-method-reference.bmx")
Check(HasDiagnostic(structBoundMethod.model.diagnostics, "BMX3348"), "Struct Method references receive a targeted capture-semantics diagnostic")
Local overloadedBoundMethod:TLanguageAnalysis = TBlitzMaxLanguage.AnalyzeText("SuperStrict~nType TConverter~nMethod Convert:Int(value:Int)~nReturn value~nEnd Method~nMethod Convert:String(value:String)~nReturn value~nEnd Method~nEnd Type~nLocal converter:TConverter = New TConverter~nLocal convert:Closure<String(value:String)> = converter.Convert", "overloaded-bound-method-reference.bmx")
Check(overloadedBoundMethod.model.diagnostics.length = 0, "a target Closure signature selects a unique instance Method overload")
Local overloadedBoundDeclaration:TVariableDeclarationStatementSyntax = TVariableDeclarationStatementSyntax(overloadedBoundMethod.syntaxTree.root.members[3])
Local overloadedBoundSyntax:TMemberAccessExpressionSyntax = TMemberAccessExpressionSyntax(overloadedBoundDeclaration.declarators[0].initializer)
Local overloadedBoundReference:TBoundRoutineReferenceExpression = TBoundRoutineReferenceExpression(overloadedBoundMethod.model.BoundExpression(overloadedBoundSyntax))
Check(overloadedBoundReference And overloadedBoundReference.routine.declaredType.DisplayName() = "String", "the selected bound Method overload retains its String return signature")
Local capturedManagedClosure:TLanguageAnalysis = TBlitzMaxLanguage.AnalyzeText("SuperStrict~nFunction Make:Closure<Int(value:Int)>()~nLocal offset:Int = 1~nLocal add:Closure<Int(value:Int)> = Function(value)~nReturn value + offset~nEnd Function~nReturn add~nEnd Function", "captured-managed-closure.bmx")
Check(capturedManagedClosure.model.diagnostics.length = 0, "managed Closure captures an ordinary lexical Local")
Local capturedManagedRoutine:TRoutineDeclarationSyntax = TRoutineDeclarationSyntax(capturedManagedClosure.syntaxTree.root.members[1])
Local capturedManagedDeclaration:TVariableDeclarationStatementSyntax = TVariableDeclarationStatementSyntax(capturedManagedRoutine.body.statements[1])
Local capturedManagedLiteral:TFunctionLiteralExpressionSyntax = TFunctionLiteralExpressionSyntax(capturedManagedDeclaration.declarators[0].initializer)
Local capturedManagedBound:TBoundFunctionLiteralExpression = TBoundFunctionLiteralExpression(capturedManagedClosure.model.BoundExpression(capturedManagedLiteral))
Check(capturedManagedBound And capturedManagedBound.captures.length = 1 And capturedManagedBound.captures[0].name = "offset", "bound managed Closure publishes its captured lexical identity")
Local capturedSelfClosure:TLanguageAnalysis = TBlitzMaxLanguage.AnalyzeText("SuperStrict~nType TCounter~nField amount:Int~nMethod Make:Closure<Int(value:Int)>()~nReturn Function(value)~nReturn Self.Add(value) + amount~nEnd Function~nEnd Method~nMethod Add:Int(value:Int)~nReturn value~nEnd Method~nEnd Type", "captured-self-closure.bmx")
Local capturedSelfType:TTypeDeclarationSyntax = TTypeDeclarationSyntax(capturedSelfClosure.syntaxTree.root.members[1])
Local capturedSelfMethod:TRoutineDeclarationSyntax = TRoutineDeclarationSyntax(capturedSelfType.body.statements[1])
Local capturedSelfReturn:TReturnStatementSyntax = TReturnStatementSyntax(capturedSelfMethod.body.statements[0])
Local capturedSelfLiteral:TFunctionLiteralExpressionSyntax = TFunctionLiteralExpressionSyntax(capturedSelfReturn.expression)
Local capturedSelfBound:TBoundFunctionLiteralExpression = TBoundFunctionLiteralExpression(capturedSelfClosure.model.BoundExpression(capturedSelfLiteral))
Check(capturedSelfClosure.model.diagnostics.length = 0 And capturedSelfBound And capturedSelfBound.capturesSelf And capturedSelfBound.capturedSelfType.DisplayName() = "TCounter", "managed Closure publishes a distinct captured Self identity for explicit and implicit instance access")
Local capturedReadOnlyField:TLanguageAnalysis = TBlitzMaxLanguage.AnalyzeText("SuperStrict~nType TReadOnlyOwner~nField ReadOnly value:Int~nMethod New(value:Int)~nSelf.value = value~nEnd Method~nMethod Reader:Closure<Int()>()~nReturn Function()~nReturn value~nEnd Function~nEnd Method~nEnd Type", "captured-readonly-field.bmx")
Check(capturedReadOnlyField.model.diagnostics.length = 0, "managed Closure may read a ReadOnly field through captured Self")
Local mutatedReadOnlyField:TLanguageAnalysis = TBlitzMaxLanguage.AnalyzeText("SuperStrict~nType TReadOnlyOwner~nField ReadOnly value:Int~nMethod Mutator:Closure<()>()~nReturn Function()~nvalue :+ 1~nEnd Function~nEnd Method~nEnd Type", "mutated-captured-readonly-field.bmx")
Check(HasDiagnostic(mutatedReadOnlyField.model.diagnostics, "BMX3315"), "managed Closure cannot assign a ReadOnly field through captured Self")
Local constructorReadOnlyEscape:TLanguageAnalysis = TBlitzMaxLanguage.AnalyzeText("SuperStrict~nType TReadOnlyOwner~nField ReadOnly value:Int~nField mutator:Closure<()>~nMethod New()~nvalue = 1~nmutator = Function()~nvalue :+ 1~nEnd Function~nEnd Method~nEnd Type", "constructor-readonly-escape.bmx")
Check(HasDiagnostic(constructorReadOnlyEscape.model.diagnostics, "BMX3315"), "an escaping Closure declared in a constructor cannot retain constructor-only ReadOnly assignment privilege")
Local staticTypeClosure:TLanguageAnalysis = TBlitzMaxLanguage.AnalyzeText("SuperStrict~nType TFactory~nFunction Value:Int()~nReturn 42~nEnd Function~nFunction Make:Closure<Int()>()~nReturn Function()~nReturn Value()~nEnd Function~nEnd Function~nEnd Type", "static-type-closure.bmx")
Check(staticTypeClosure.model.diagnostics.length = 0, "a Closure inside a Type Function keeps same-Type Function calls static without inventing Self capture")
Local capturedSuperClosure:TLanguageAnalysis = TBlitzMaxLanguage.AnalyzeText("SuperStrict~nType TBase~nMethod Value:Int()~nReturn 1~nEnd Method~nEnd Type~nType TDerived Extends TBase~nMethod Make:Closure<Int()>()~nReturn Function()~nReturn Super.Value()~nEnd Function~nEnd Method~nEnd Type", "captured-super-closure.bmx")
Local capturedSuperType:TTypeDeclarationSyntax = TTypeDeclarationSyntax(capturedSuperClosure.syntaxTree.root.members[2])
Local capturedSuperMethod:TRoutineDeclarationSyntax = TRoutineDeclarationSyntax(capturedSuperType.body.statements[0])
Local capturedSuperReturn:TReturnStatementSyntax = TReturnStatementSyntax(capturedSuperMethod.body.statements[0])
Local capturedSuperLiteral:TFunctionLiteralExpressionSyntax = TFunctionLiteralExpressionSyntax(capturedSuperReturn.expression)
Local capturedSuperBound:TBoundFunctionLiteralExpression = TBoundFunctionLiteralExpression(capturedSuperClosure.model.BoundExpression(capturedSuperLiteral))
Check(capturedSuperClosure.model.diagnostics.length = 0 And capturedSuperBound And capturedSuperBound.capturesSelf And capturedSuperBound.capturedSelfType.DisplayName() = "TDerived", "managed Closure retains Self for a bound Super call without inventing a distinct Super value")
Local capturedStructSelf:TLanguageAnalysis = TBlitzMaxLanguage.AnalyzeText("SuperStrict~nStruct TValue~nField amount:Int~nMethod Make:Closure<Int()>()~nReturn Function()~nReturn Self.amount~nEnd Function~nEnd Method~nEnd Struct", "captured-struct-self.bmx")
Check(HasDiagnostic(capturedStructSelf.model.diagnostics, "BMX3346"), "managed Closure rejects escaping borrowed Struct Self capture")
Local strictManagedClosure:TLanguageAnalysis = TBlitzMaxLanguage.AnalyzeText("Strict~nLocal action:Closure<()> = Null", "strict-managed-closure.bmx")
Check(HasDiagnostic(strictManagedClosure.model.diagnostics, "BMX3120"), "Closure types require SuperStrict mode")
Local bareManagedClosure:TLanguageAnalysis = TBlitzMaxLanguage.AnalyzeText("SuperStrict~nLocal action:Closure", "bare-managed-closure.bmx")
Check(HasDiagnostic(bareManagedClosure.model.diagnostics, "BMX3121"), "Closure requires an explicit callable signature")
Local thinManagedMismatch:TLanguageAnalysis = TBlitzMaxLanguage.AnalyzeText("SuperStrict~nFunction AddOne:Int(value:Int)~nReturn value + 1~nEnd Function~nLocal managed:Closure<Int(value:Int)> = AddOne", "thin-managed-mismatch.bmx")
Check(thinManagedMismatch.model.diagnostics.length > 0, "thin callable references do not implicitly convert to managed Closure values")
Local genericManagedClosure:TLanguageAnalysis = TBlitzMaxLanguage.AnalyzeText("SuperStrict~nType TClosureBox<T>~nField value:T~nEnd Type~nLocal box:TClosureBox<Closure<Int(value:Int)>> = New TClosureBox<Closure<Int(value:Int)>>", "generic-managed-closure.bmx")
Check(genericManagedClosure.model.diagnostics.length = 0, "Closure signatures remain nested generic type arguments rather than being parsed as thin callable types")
Local genericManagedDeclaration:TVariableDeclarationStatementSyntax = TVariableDeclarationStatementSyntax(genericManagedClosure.syntaxTree.root.members[2])
Local genericManagedSymbol:TSymbol = genericManagedClosure.model.DeclaredSymbol(genericManagedDeclaration.declarators[0])
Local genericManagedType:TNamedSemanticType = TNamedSemanticType(genericManagedSymbol.declaredType)
Check(genericManagedType And genericManagedType.typeArguments.length = 1 And TClosureSemanticType(genericManagedType.typeArguments[0]), "constructed generic types retain a structural Closure type argument")
Local capturedVarParameter:TLanguageAnalysis = TBlitzMaxLanguage.AnalyzeText("SuperStrict~nFunction Bad:Closure<()>(value:Int Var)~nReturn Function()~nvalue :+ 1~nEnd Function~nEnd Function", "captured-var-parameter.bmx")
Check(HasDiagnostic(capturedVarParameter.model.diagnostics, "BMX3346"), "captured Var parameters remain a lifetime-safe staged diagnostic")
Local nestedManagedCapture:TLanguageAnalysis = TBlitzMaxLanguage.AnalyzeText("SuperStrict~nFunction Bad:Closure<()>()~nLocal value:Int~nReturn Function()~nLocal inner:Closure<Int()> = Function()~nReturn value~nEnd Function~nEnd Function~nEnd Function", "nested-managed-capture.bmx")
Check(nestedManagedCapture.model.diagnostics.length = 0, "nested managed Closures propagate inherited capture requirements through their enclosing literal")
Local returnedManagedClosure:TLanguageAnalysis = TBlitzMaxLanguage.AnalyzeText("SuperStrict~nFunction Make:Closure<Closure<Int()>()>()~nLocal value:Int = 41~nReturn Function()~nReturn Function()~nReturn value + 1~nEnd Function~nEnd Function~nEnd Function", "returned-managed-closure.bmx")
Check(returnedManagedClosure.model.diagnostics.length = 0, "a managed Closure literal may contextually return another managed Closure literal")
Local loopManagedCapture:TLanguageAnalysis = TBlitzMaxLanguage.AnalyzeText("SuperStrict~nFunction Bad:Closure<Int()>[]()~nLocal values:Closure<Int()>[]~nFor Local index:Int = 0 Until 1~nLocal action:Closure<Int()> = Function()~nReturn index~nEnd Function~nNext~nReturn values~nEnd Function", "loop-managed-capture.bmx")
Check(loopManagedCapture.model.diagnostics.length = 0, "managed Closures accept explicitly declared loop-scoped values for per-iteration lowering")
Local topLevelManagedCapture:TLanguageAnalysis = TBlitzMaxLanguage.AnalyzeText("SuperStrict~nLocal value:Int~nLocal action:Closure<Int()> = Function()~nReturn value~nEnd Function", "top-level-managed-capture.bmx")
Check(topLevelManagedCapture.model.diagnostics.length = 0, "top-level Local capture binds through the managed module environment")
Local catchManagedCapture:TLanguageAnalysis = TBlitzMaxLanguage.AnalyzeText("SuperStrict~nFunction CatchValue:Closure<String()>()~nTry~nThrow ~qvalue~q~nCatch problem:String~nReturn Function()~nReturn problem~nEnd Function~nEnd Try~nEnd Function", "catch-managed-capture.bmx")
Check(catchManagedCapture.model.diagnostics.length = 0, "Catch parameters bind as managed per-activation captures")
Local capturedStaticArray:TLanguageAnalysis = TBlitzMaxLanguage.AnalyzeText("SuperStrict~nFunction Bad:Closure<Int()>()~nLocal StaticArray values:Int[2]~nReturn Function()~nReturn values[0]~nEnd Function~nEnd Function", "captured-static-array.bmx")
Check(HasDiagnostic(capturedStaticArray.model.diagnostics, "BMX3346"), "StaticArray capture remains an explicit aggregate-environment diagnostic")

Local iteratorDeclarations:String = "Interface IIterator<T>~nMethod Current:T()~nMethod MoveNext:Int()~nEnd Interface~nInterface ICloseableIterator<T> Extends IIterator<T>~nMethod Close()~nEnd Interface~n"
Local yieldingAnalysis:TLanguageAnalysis = TBlitzMaxLanguage.AnalyzeText("SuperStrict~n" + iteratorDeclarations + "Function Values:ICloseableIterator<Int>()~nYield 1~nReturn~nEnd Function", "yielding-routine.bmx")
Local yieldingSymbol:TSymbol = yieldingAnalysis.model.globalScope.LookupLocal("Values")[0]
Local yieldingDeclaration:TRoutineDeclarationSyntax = TRoutineDeclarationSyntax(yieldingSymbol.declaration)
Local yieldingSyntax:TYieldStatementSyntax = TYieldStatementSyntax(yieldingDeclaration.body.statements[0])
Local yieldingBound:TBoundYieldStatement = TBoundYieldStatement(yieldingAnalysis.model.BoundStatement(yieldingSyntax))
Check(yieldingAnalysis.model.diagnostics.length = 0 And yieldingSymbol.isIteratorRoutine And yieldingSymbol.iteratorElementType.DisplayName() = "Int" And yieldingBound And yieldingBound.expression.semanticType.DisplayName() = "Int", "Yield is a contextual statement whose value binds to the iterator element type")
Local yieldFromAnalysis:TLanguageAnalysis = TBlitzMaxLanguage.AnalyzeText("SuperStrict~n" + iteratorDeclarations + "Function Values:ICloseableIterator<Int>()~nLocal values:Int[] = [1, 2]~nYield From values~nEnd Function", "yield-from-array.bmx")
Local yieldFromSymbol:TSymbol = yieldFromAnalysis.model.globalScope.LookupLocal("Values")[0]
Local yieldFromDeclaration:TRoutineDeclarationSyntax = TRoutineDeclarationSyntax(yieldFromSymbol.declaration)
Local yieldFromSyntax:TYieldStatementSyntax = TYieldStatementSyntax(yieldFromDeclaration.body.statements[1])
Local yieldFromBound:TBoundForStatement = TBoundForStatement(yieldFromAnalysis.model.BoundStatement(yieldFromSyntax))
Local yieldFromBody:TBoundYieldStatement
If yieldFromBound And yieldFromBound.body And yieldFromBound.body.statements.length = 1 Then yieldFromBody = TBoundYieldStatement(yieldFromBound.body.statements[0])
Check(yieldFromAnalysis.model.diagnostics.length = 0 And yieldFromSyntax.fromToken And yieldFromBound And yieldFromBound.isEachIn And yieldFromBound.iteration.protocolKind = EACH_IN_PROTOCOL_ARRAY And yieldFromBound.loopVariable.declaredType.DisplayName() = "Int" And yieldFromBody, "Yield From desugars to a typed EachIn loop containing an ordinary Yield")
Local missingYieldFrom:TLanguageAnalysis = TBlitzMaxLanguage.AnalyzeText("SuperStrict~n" + iteratorDeclarations + "Function Values:ICloseableIterator<Int>()~nYield From~nEnd Function", "yield-from-missing.bmx")
Check(HasDiagnostic(missingYieldFrom.syntaxTree.diagnostics, "BMX2328"), "Yield From requires a source expression")
Local invalidYieldFrom:TLanguageAnalysis = TBlitzMaxLanguage.AnalyzeText("SuperStrict~n" + iteratorDeclarations + "Function Values:ICloseableIterator<Int>()~nYield From 1~nEnd Function", "yield-from-invalid-source.bmx")
Check(HasDiagnostic(invalidYieldFrom.model.diagnostics, "BMX3330"), "Yield From requires an EachIn-compatible source")
Local yieldIdentifier:TLanguageAnalysis = TBlitzMaxLanguage.AnalyzeText("SuperStrict~nLocal yield:Int = 1", "yield-identifier.bmx")
Check(yieldIdentifier.model.diagnostics.length = 0 And yieldIdentifier.model.globalScope.LookupLocal("yield").length = 1, "Yield remains available as an identifier outside statement position")
Local invalidYieldReturn:TLanguageAnalysis = TBlitzMaxLanguage.AnalyzeText("SuperStrict~n" + iteratorDeclarations + "Function Values:ICloseableIterator<Int>()~nYield 1~nReturn 2~nEnd Function", "yield-return-value.bmx")
Check(HasDiagnostic(invalidYieldReturn.model.diagnostics, "BMX3334"), "yielding routines reject Return values while retaining bare Return completion")
Local invalidYieldRoutine:TLanguageAnalysis = TBlitzMaxLanguage.AnalyzeText("SuperStrict~nFunction Value:Int()~nYield 1~nEnd Function", "yield-return-contract.bmx")
Check(HasDiagnostic(invalidYieldRoutine.model.diagnostics, "BMX3332"), "Yield requires an iterator-compatible routine return contract")
Local topLevelYield:TLanguageAnalysis = TBlitzMaxLanguage.AnalyzeText("SuperStrict~nYield 1", "yield-top-level.bmx")
Check(HasDiagnostic(topLevelYield.model.diagnostics, "BMX3333"), "Yield is rejected outside a Function or Method")
Local keywordReceiver:TLanguageAnalysis = TBlitzMaxLanguage.AnalyzeText("SuperStrict~nType TBox~nField value:Int~nEnd Type~nFunction SetValue:Int()~nLocal field:TBox = New TBox~nfield.value = 7~nReturn field.value~nEnd Function", "keyword-field-receiver.bmx")
Check(keywordReceiver.model.diagnostics.length = 0, "A Local named Field remains an expression receiver for member assignment")

Print "bcc2 expression-binding tests passed"
