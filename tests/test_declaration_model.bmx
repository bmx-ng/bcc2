SuperStrict

Framework BRL.StandardIO

Import BlitzMax.Language

Function Check(condition:Int, message:String)
	If Not condition Then Throw message
End Function

Local source:String = "SuperStrict~nPrivate~nGlobal ModuleValue:Int~nPublic~nType TBox<T, t>~nPrivate Field Item:Int~nField item:String~nProtected~nField inherited:Int~nInternal~nMethod ModuleOnly:Int()~nReturn inherited~nEnd Method~nPublic~nMethod Get:Int(a:Int)~nLocal temp:Int~nIf a Then~nLocal branch:Int~nEnd If~nFor Local i:Int = 0 Until 2~nLocal loopValue:Int~nNext~nFunction Nested:Int()~nReturn 1~nEnd Function~nReturn temp~nEnd Method~nEnd Type~nFunction Convert:Int(value:Int)~nReturn value~nEnd Function~nFunction Convert:String(value:String)~nReturn value~nEnd Function~nFunction Bad:Int(a:Int, A:String)~nReturn a~nEnd Function~n?win32~nFunction Platform:Int()~nReturn 1~nEnd Function~n?linux~nFunction Platform:Int()~nReturn 2~nEnd Function~n?"
Local parsed:TParseResult = TBlitzMaxParser.ParseText(source, "declarations.bmx")
Check(parsed.syntaxTree.diagnostics.length = 0, "declaration-model parser diagnostics")

Local model:TSemanticModel = TDeclarationCollector.Collect(parsed.syntaxTree)
Check(model <> Null And model.globalScope <> Null, "semantic model and global scope")
Check(model.globalScope.kind = SCOPE_COMPILATION_UNIT, "compilation-unit scope kind")
Check(model.diagnostics.length = 3, "duplicate declaration diagnostics")
For Local diagnostic:TDiagnostic = EachIn model.diagnostics
	Check(diagnostic.code = "BMX3000", "duplicate diagnostic code")
Next

Local moduleValues:TSymbol[] = model.globalScope.LookupLocal("modulevalue")
Check(moduleValues.length = 1 And moduleValues[0].kind = SYMBOL_GLOBAL, "module global symbol")
Check(moduleValues[0].visibility = VISIBILITY_PRIVATE, "module visibility section")

Local boxSymbols:TSymbol[] = model.globalScope.Lookup("TBOX")
Check(boxSymbols.length = 1 And boxSymbols[0].kind = SYMBOL_TYPE, "case-insensitive type lookup")
Local boxDeclaration:TTypeDeclarationSyntax = TTypeDeclarationSyntax(boxSymbols[0].declaration)
Local boxScope:TScope = model.ScopeFor(boxDeclaration)
Check(boxScope <> Null And boxScope.owner = boxSymbols[0], "type-owned scope")
Check(boxScope.LookupLocal("T").length = 2, "generic parameter symbols and case-insensitive duplicate")
Check(boxScope.LookupLocal("item").length = 2, "field symbols")
Check(boxScope.LookupLocal("item")[0].visibility = VISIBILITY_PRIVATE, "type member visibility")
Check(boxScope.LookupLocal("inherited")[0].visibility = VISIBILITY_PROTECTED, "protected member visibility")
Check(boxScope.LookupLocal("moduleonly")[0].visibility = VISIBILITY_INTERNAL, "internal member visibility")

Local combinedParsed:TParseResult = TBlitzMaxParser.ParseText("SuperStrict~nType TCombined~nPrivate Internal~nField family:Int~nProtected Internal~nField shared:Int~nEnd Type", "/sdk/mod/example.mod/access.mod/combined.bmx")
Local combinedModel:TSemanticModel = TDeclarationCollector.Collect(combinedParsed.syntaxTree)
Local combinedScope:TScope = combinedModel.globalScope.LookupLocal("TCombined")[0].memberScope
Check(combinedScope.LookupLocal("family")[0].visibility = VISIBILITY_PRIVATE_INTERNAL, "Private Internal member visibility")
Check(combinedScope.LookupLocal("shared")[0].visibility = VISIBILITY_PROTECTED_INTERNAL, "Protected Internal member visibility")
Local combinedDump:String = TSemanticDumper.Dump(combinedModel)
Check(combinedDump.Contains("Field family [private internal]") And combinedDump.Contains("Field shared [protected internal]"), "semantic dump combined visibility")

Local getSymbols:TSymbol[] = boxScope.LookupLocal("get")
Check(getSymbols.length = 1 And getSymbols[0].kind = SYMBOL_ROUTINE, "method symbol")
Local getDeclaration:TRoutineDeclarationSyntax = TRoutineDeclarationSyntax(getSymbols[0].declaration)
Local getScope:TScope = model.ScopeFor(getDeclaration)
Check(model.ScopeFor(getDeclaration.body) = getScope, "routine body scope association")
Check(getScope.LookupLocal("a").length = 1, "parameter symbol")
Check(getScope.LookupLocal("temp").length = 1, "routine local symbol")
Check(getScope.LookupLocal("nested").length = 1, "embedded routine symbol")

Local ifStatement:TIfStatementSyntax = TIfStatementSyntax(getDeclaration.body.statements[1])
Local branchScope:TScope = model.ScopeFor(ifStatement.thenBlock)
Check(branchScope.LookupLocal("branch").length = 1, "branch-local symbol")
Check(branchScope.Lookup("temp").length = 1, "parent-scope lookup")
Check(getScope.LookupLocal("branch").length = 0, "branch local does not leak")

Local forStatement:TForStatementSyntax = TForStatementSyntax(getDeclaration.body.statements[2])
Local loopScope:TScope = model.ScopeFor(forStatement)
Check(loopScope.kind = SCOPE_LOOP, "loop scope kind")
Check(model.ScopeFor(forStatement.body) = loopScope, "loop body scope association")
Check(loopScope.LookupLocal("i").length = 1, "For Local symbol")
Check(loopScope.LookupLocal("loopvalue").length = 1, "loop body local symbol")

Local overloads:TSymbol[] = model.globalScope.LookupLocal("convert")
Check(overloads.length = 2, "routine overload group")
Check(overloads[0].NamespaceKind() = SYMBOL_NAMESPACE_ROUTINE, "routine namespace")

Local badSymbols:TSymbol[] = model.globalScope.LookupLocal("bad")
Local badScope:TScope = model.ScopeFor(badSymbols[0].declaration)
Check(badScope.LookupLocal("a").length = 2, "duplicate parameter symbols retained")

Local genericParsed:TParseResult = TBlitzMaxParser.ParseText("Function Pair<T, U>:U(value:T, fallback:U) Where T Extends Object~nReturn fallback~nEnd Function", "generic-declaration.bmx")
Local genericModel:TSemanticModel = TDeclarationCollector.Collect(genericParsed.syntaxTree)
Check(genericModel.diagnostics.length = 0, "generic routine declaration diagnostics")
Local pairSymbol:TSymbol = genericModel.globalScope.LookupLocal("pair")[0]
Local pairScope:TScope = genericModel.ScopeFor(pairSymbol.declaration)
Check(pairSymbol.genericArity = 2, "generic routine symbol arity")
Check(pairScope.LookupLocal("T")[0].kind = SYMBOL_TYPE_PARAMETER And pairScope.LookupLocal("U")[0].kind = SYMBOL_TYPE_PARAMETER, "routine-owned type parameter symbols")
Check(pairScope.LookupLocal("value")[0].kind = SYMBOL_PARAMETER, "generic routine value parameter symbol")

Local invalidVisibility:TParseResult = TBlitzMaxParser.ParseText("Internal~nGlobal Value:Int~nPrivate Internal~nGlobal Other:Int~nInterface IHidden~nProtected~nMethod Read:Int()~nEnd Method~nEnd Interface", "invalid-visibility.bmx")
Local invalidVisibilitySections:Int
For Local diagnostic:TDiagnostic = EachIn invalidVisibility.syntaxTree.diagnostics
	If diagnostic.code = "BMX2326" Or diagnostic.code = "BMX2327" Then invalidVisibilitySections :+ 1
Next
Check(invalidVisibilitySections = 3, "Internal combinations are type-only and interface members remain public")

Local interfaceBody:TParseResult = TBlitzMaxParser.ParseText("Interface IDefault~nMethod Value:Object()~nReturn Null~nEnd Method~nEnd Interface", "interface-method-body.bmx")
Local interfaceBodyDiagnostic:Int
For Local diagnostic:TDiagnostic = EachIn interfaceBody.syntaxTree.diagnostics
	If diagnostic.code = "BMX2332" Then interfaceBodyDiagnostic = True
Next
Check(interfaceBodyDiagnostic, "Interface method bodies receive an explicit language diagnostic")

Local defaultInterface:TParseResult = TBlitzMaxParser.ParseText("Interface IDefault~nMethod Value:Object() Default~nReturn Null~nEnd Method~nEnd Interface", "default-interface-method-body.bmx")
Check(defaultInterface.syntaxTree.diagnostics.length = 0, "an explicitly Default Interface method accepts a body")
Local defaultInterfaceDeclaration:TTypeDeclarationSyntax = TTypeDeclarationSyntax(defaultInterface.syntaxTree.root.members[0])
Local defaultRoutine:TRoutineDeclarationSyntax = TRoutineDeclarationSyntax(defaultInterfaceDeclaration.body.statements[0])
Check(defaultRoutine.body.statements.length = 1 And defaultRoutine.terminator.actualBlockKind = "method", "Default Interface method retains its typed body boundary")
Local defaultModel:TSemanticModel = TBlitzMaxSemanticAnalyzer.Analyze(defaultInterface.syntaxTree)
Local defaultSymbol:TSymbol = defaultModel.globalScope.LookupLocal("IDefault")[0].memberScope.LookupLocal("Value")[0]
Check(defaultModel.diagnostics.length = 0 And defaultSymbol.interfaceMethodKind = INTERFACE_METHOD_DEFAULT And Not defaultSymbol.isAbstract, "Default Interface method has a distinct concrete semantic kind")

Local qualifiedSuperParse:TParseResult = TBlitzMaxParser.ParseText("Interface IBase~nMethod Value:Int() Default~nReturn 1~nEnd Method~nEnd Interface~nInterface IDerived Extends IBase~nMethod Value:Int() Override Default~nReturn Super<IBase>.Value()~nEnd Method~nEnd Interface", "qualified-interface-super.bmx")
Local qualifiedSuperModel:TSemanticModel = TBlitzMaxSemanticAnalyzer.Analyze(qualifiedSuperParse.syntaxTree)
Check(qualifiedSuperParse.syntaxTree.diagnostics.length = 0 And qualifiedSuperModel.diagnostics.length = 0, "qualified Interface Super syntax binds an inherited default body")

Local invalidQualifiedSuperSource:String = "SuperStrict~nType TNotInterface~nEnd Type~nInterface IBaseDefault~nMethod Value:Int() Default~nReturn 1~nEnd Method~nMethod Required:Int()~nEnd Interface~nInterface IOtherDefault~nMethod Value:Int() Default~nReturn 2~nEnd Method~nEnd Interface~nInterface IInvalidQualified Extends IBaseDefault~nMethod BadTarget:Int() Default~nReturn Super<TNotInterface>.Value()~nEnd Method~nMethod NotInherited:Int() Default~nReturn Super<IOtherDefault>.Value()~nEnd Method~nMethod AbstractTarget:Int() Default~nReturn Super<IBaseDefault>.Required()~nEnd Method~nEnd Interface"
Local invalidQualifiedSuperModel:TSemanticModel = TBlitzMaxLanguage.AnalyzeText(invalidQualifiedSuperSource, "invalid-qualified-interface-super.bmx").model
Local invalidSuperTarget:Int
Local nonInheritedSuperTarget:Int
Local abstractSuperTarget:Int
For Local diagnostic:TDiagnostic = EachIn invalidQualifiedSuperModel.diagnostics
	If diagnostic.code = "BMX3324" Then invalidSuperTarget = True
	If diagnostic.code = "BMX3325" Then nonInheritedSuperTarget = True
	If diagnostic.code = "BMX3326" Then abstractSuperTarget = True
Next
Check(invalidSuperTarget And nonInheritedSuperTarget And abstractSuperTarget, "qualified Interface Super rejects non-Interfaces, unrelated Interfaces, and abstract targets: " + invalidSuperTarget + "," + nonInheritedSuperTarget + "," + abstractSuperTarget)

Local conditional:TConditionalRegionSyntax
For Local member:TSyntaxNode = EachIn parsed.syntaxTree.root.members
	If TConditionalRegionSyntax(member) Then conditional = TConditionalRegionSyntax(member)
Next
Check(conditional <> Null And conditional.branches.length = 2, "conditional declaration test region")
Local firstBranch:TScope = model.ScopeFor(conditional.branches[0])
Local secondBranch:TScope = model.ScopeFor(conditional.branches[1])
Check(firstBranch.LookupLocal("platform").length = 1 And secondBranch.LookupLocal("platform").length = 1, "conditional branch declarations isolated")

Local dump:String = TSemanticDumper.Dump(model)
Check(dump.Contains("Scope Type TBox"), "semantic dump type scope")
Check(dump.Contains("Global ModuleValue [private]"), "semantic dump visibility")
Check(dump.Contains("Routine Convert"), "semantic dump overloads")

Print "bcc2 declaration-model tests passed"
