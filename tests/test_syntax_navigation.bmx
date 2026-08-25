SuperStrict

Framework BRL.StandardIO

Import BlitzMax.Language

Function Check(condition:Int, message:String)
	If Not condition Then Throw message
End Function

Local source:String = "SuperStrict~nConst Answer:Int = 42~nFunction Add:Int(left:Int, right:Int)~nReturn left + right~nEnd Function~nLocal value:Int = Add(Answer, 1)"
Local analysis:TLanguageAnalysis = TBlitzMaxLanguage.AnalyzeText(source, "navigation.bmx")
Local navigator:TSyntaxNavigator = TSyntaxNavigator.Create(analysis.syntaxTree)
Check(navigator <> Null, "syntax navigator is created independently of analysis")

Local answerDeclaration:Int = source.Find("Answer")
Local answerUse:Int = source.Find("Answer", answerDeclaration + 1)
Check(navigator.TokenAt(answerUse).text = "Answer", "token lookup at source offset")
Local answerLocation:TSemanticLocation = TSemanticLocation.Query(analysis.model, navigator, answerUse)
Check(answerLocation.symbol <> Null And answerLocation.symbol.name = "Answer" And answerLocation.symbol.kind = SYMBOL_CONST, "reference resolves to constant symbol")
Check(answerLocation.semanticType.DisplayName() = "Int", "semantic location exposes symbol type")
Check(answerLocation.constantValue <> Null And answerLocation.constantValue.integerValue = 42, "semantic location exposes constant value")
Check(answerLocation.resolvedCall <> Null And answerLocation.resolvedCall.routine.name = "Add", "argument parent chain reaches containing resolved call")

Local addDeclaration:Int = source.Find("Add")
Local addUse:Int = source.Find("Add", addDeclaration + 1)
Local addLocation:TSemanticLocation = TSemanticLocation.Query(analysis.model, navigator, addUse)
Check(addLocation.symbol <> Null And addLocation.symbol.name = "Add", "call target resolves to routine symbol")
Check(addLocation.resolvedCall <> Null And addLocation.resolvedCall.returnType.DisplayName() = "Int", "semantic location exposes selected call")
Check(addLocation.syntax.expression <> Null And addLocation.syntax.parents.length > 1, "syntax location exposes expression and parent chain")

Local valueOffset:Int = source.Find("value")
Local valueLocation:TSemanticLocation = TSemanticLocation.Query(analysis.model, navigator, valueOffset)
Check(valueLocation.symbol <> Null And valueLocation.symbol.name = "value" And valueLocation.symbol.kind = SYMBOL_LOCAL, "declaration name resolves to declared symbol")

Local valuePosition:TSourcePosition = analysis.syntaxTree.source.Position(valueOffset)
Check(analysis.syntaxTree.source.Offset(valuePosition.line, valuePosition.column) = valueOffset, "source position reverses to offset")
Check(navigator.TokenAt(source.Find("Local value") + 5) = Null, "whitespace does not select a token")

Local methodSource:String = "SuperStrict~nType TReader~nMethod _FlushRead()~nEnd Method~nMethod ReadString:String(length:Int)~n_FlushRead~nLocal buf:Short[length]~nEnd Method~nEnd Type"
Local methodAnalysis:TLanguageAnalysis = TBlitzMaxLanguage.AnalyzeText(methodSource, "method_navigation.bmx")
Local methodNavigator:TSyntaxNavigator = TSyntaxNavigator.Create(methodAnalysis.syntaxTree)
Local flushUse:Int = methodSource.Find("_FlushRead", methodSource.Find("_FlushRead") + 1)
Local flushLocation:TSemanticLocation = TSemanticLocation.Query(methodAnalysis.model, methodNavigator, flushUse)
Check(flushLocation.symbol <> Null And flushLocation.symbol.name = "_FlushRead", "method-body call resolves to the called method rather than the containing method")
Local localKeyword:Int = methodSource.Find("Local buf")
Local localLocation:TSemanticLocation = TSemanticLocation.Query(methodAnalysis.model, methodNavigator, localKeyword)
Check(localLocation.symbol = Null, "Local keyword does not inherit the containing method symbol")
Local bufOffset:Int = methodSource.Find("buf")
Local bufLocation:TSemanticLocation = TSemanticLocation.Query(methodAnalysis.model, methodNavigator, bufOffset)
Check(bufLocation.symbol <> Null And bufLocation.symbol.name = "buf", "local declaration name still resolves to its symbol")

Local abstractCallSource:String = "SuperStrict~nType TStationBase~nField _cachePopulationShare:Float~nMethod GetPopulationShare:Float(exclusiveToOwnChannel:Int=False, exclusiveToOtherChannels:Int=False) Abstract~nMethod GetPopulation:Int()~nIf Self._cachePopulationShare < 0~nSelf._cachePopulationShare = GetPopulationShare(False, False)~nEnd If~nReturn Self._cachePopulationShare~nEnd Method~nEnd Type"
Local abstractCallAnalysis:TLanguageAnalysis = TBlitzMaxLanguage.AnalyzeText(abstractCallSource, "abstract_method_navigation.bmx")
Local abstractCallNavigator:TSyntaxNavigator = TSyntaxNavigator.Create(abstractCallAnalysis.syntaxTree)
Local abstractCallOffset:Int = abstractCallSource.Find("GetPopulationShare", abstractCallSource.Find("GetPopulationShare") + 1)
Local abstractCallLocation:TSemanticLocation = TSemanticLocation.Query(abstractCallAnalysis.model, abstractCallNavigator, abstractCallOffset)
Check(abstractCallAnalysis.syntaxTree.diagnostics.length = 0, "Self-qualified assignment containing abstract method call parses without diagnostics")
Check(abstractCallLocation.symbol <> Null And abstractCallLocation.symbol.name = "GetPopulationShare" And abstractCallLocation.symbol.isAbstract, "abstract method call in Self-qualified assignment resolves to its declaration for hover and navigation")

Local nestedTypeSource:String = "SuperStrict~nInterface IMapNode<K,V>~nEnd Interface~nInterface IIterator<T>~nEnd Interface~nGlobal iterator:IIterator<IMapNode<String,String>>"
Local nestedTypeAnalysis:TLanguageAnalysis = TBlitzMaxLanguage.AnalyzeText(nestedTypeSource, "nested_type_navigation.bmx")
Local nestedTypeNavigator:TSyntaxNavigator = TSyntaxNavigator.Create(nestedTypeAnalysis.syntaxTree)
Local mapNodeOffset:Int = nestedTypeSource.Find("IMapNode", nestedTypeSource.Find("IMapNode") + 1)
Local mapNodeLocation:TSemanticLocation = TSemanticLocation.Query(nestedTypeAnalysis.model, nestedTypeNavigator, mapNodeOffset)
Check(mapNodeLocation.symbol <> Null And mapNodeLocation.symbol.name = "IMapNode", "nested generic type navigation selects the inner type")
Check(mapNodeLocation.semanticType.DisplayName() = "IMapNode<String, String>", "nested generic hover retains the inner constructed type")

Local arrayTypeSource:String = "SuperStrict~nType TNewsEventSportTeam~nEnd Type~nType TNewsEventSportCollection~nMethod AddTeams(teams:TNewsEventSportTeam[])~nEnd Method~nEnd Type"
Local arrayTypeAnalysis:TLanguageAnalysis = TBlitzMaxLanguage.AnalyzeText(arrayTypeSource, "array_type_navigation.bmx")
Local arrayTypeNavigator:TSyntaxNavigator = TSyntaxNavigator.Create(arrayTypeAnalysis.syntaxTree)
Local arrayTeamOffset:Int = arrayTypeSource.Find("TNewsEventSportTeam", arrayTypeSource.Find("TNewsEventSportTeam") + 1)
Local arrayTeamLocation:TSemanticLocation = TSemanticLocation.Query(arrayTypeAnalysis.model, arrayTypeNavigator, arrayTeamOffset)
Check(arrayTeamLocation.symbol <> Null And arrayTeamLocation.symbol.name = "TNewsEventSportTeam", "array type navigation targets its named element declaration")
Check(arrayTeamLocation.semanticType.DisplayName() = "TNewsEventSportTeam[]", "array type navigation retains the complete wrapped semantic type")

Local indexHoverSource:String = "SuperStrict~nType TMap<K,V>~nMethod Operator []=(key:K, value:V)~nEnd Method~nEnd Type~nLocal map:TMap<String,String> = New TMap<String,String>~nmap[~qa~q] = ~qalpha~q"
Local indexHoverAnalysis:TLanguageAnalysis = TBlitzMaxLanguage.AnalyzeText(indexHoverSource, "index_argument_navigation.bmx")
Local indexHoverNavigator:TSyntaxNavigator = TSyntaxNavigator.Create(indexHoverAnalysis.syntaxTree)
Local keyLiteralOffset:Int = indexHoverSource.Find("~qa~q") + 1
Local keyLiteralLocation:TSemanticLocation = TSemanticLocation.Query(indexHoverAnalysis.model, indexHoverNavigator, keyLiteralOffset)
Check(keyLiteralLocation.symbol = Null And keyLiteralLocation.semanticType = indexHoverAnalysis.model.BuiltinType("String"), "index argument hover describes the literal rather than the setter operator")
Local bracketOffset:Int = indexHoverSource.Find("[~qa~q]")
Local bracketLocation:TSemanticLocation = TSemanticLocation.Query(indexHoverAnalysis.model, indexHoverNavigator, bracketOffset)
Check(bracketLocation.symbol <> Null And bracketLocation.symbol.name = "[]=", "index brackets retain navigation to the resolved setter operator")

Local qualifiedSuperSource:String = "SuperStrict~nInterface IBase<T>~nMethod Value:T(value:T) Default~nReturn value~nEnd Method~nEnd Interface~nInterface IDerived<T> Extends IBase<T>~nMethod Value:T(value:T) Override Default~nReturn Super<IBase<T>>.Value(value)~nEnd Method~nEnd Interface"
Local qualifiedSuperAnalysis:TLanguageAnalysis = TBlitzMaxLanguage.AnalyzeText(qualifiedSuperSource, "qualified_super_navigation.bmx")
Local qualifiedSuperNavigator:TSyntaxNavigator = TSyntaxNavigator.Create(qualifiedSuperAnalysis.syntaxTree)
Local qualifiedSuperTypeOffset:Int = qualifiedSuperSource.Find("IBase", qualifiedSuperSource.Find("IBase") + 1)
qualifiedSuperTypeOffset = qualifiedSuperSource.Find("IBase", qualifiedSuperTypeOffset + 1)
Local qualifiedSuperLocation:TSemanticLocation = TSemanticLocation.Query(qualifiedSuperAnalysis.model, qualifiedSuperNavigator, qualifiedSuperTypeOffset)
Check(qualifiedSuperLocation.symbol <> Null And qualifiedSuperLocation.symbol.name = "IBase" And qualifiedSuperLocation.semanticType.DisplayName() = "IBase<T>", "qualified Interface Super indexes its nested constructed type for navigation and hover")

Print "bcc2 syntax-navigation tests passed"
