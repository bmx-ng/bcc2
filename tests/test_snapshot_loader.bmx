SuperStrict

Framework BRL.StandardIO

Import BRL.Map

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

Type TMemorySnapshotResolver Extends TSnapshotResolver
	Field includes:TMap = New TMap
	Field interfaces:TMap = New TMap
	Field contextualInterfaces:TMap = New TMap
	Field genericTemplates:TMap = New TMap
	Field core:TSnapshotText

	Method AddInclude(path:String, text:String)
		includes.Insert(path.ToLower(), TSnapshotText.Create(path, text))
	End Method

	Method AddInterface(name:String, path:String, text:String)
		interfaces.Insert(name.ToLower(), TSnapshotText.Create(path, text))
	End Method

	Method AddInterfaceFile(name:String, path:String, file:TInterfaceFile)
		interfaces.Insert(name.ToLower(), TSnapshotText.CreateInterface(path, file))
	End Method

	Method AddContextualInterface(importingPath:String, name:String, path:String, text:String)
		contextualInterfaces.Insert(importingPath.Replace("\", "/").ToLower() + "|" + name.ToLower(), TSnapshotText.Create(path, text))
	End Method

	Method AddGenericTemplate(reference:String, path:String, text:String)
		genericTemplates.Insert(reference.ToLower(), TSnapshotText.Create(path, text))
	End Method

	Method AddDecodedGenericTemplate(reference:String, path:String, artifact:TGenericTemplateArtifact, diagnostics:String[] = Null)
		genericTemplates.Insert(reference.ToLower(), TSnapshotText.CreateGenericTemplate(path, artifact, diagnostics))
	End Method

	Method ResolveInclude:TSnapshotText(includingPath:String, includePath:String)
		Return TSnapshotText(includes.ValueForKey(includePath.ToLower()))
	End Method

	Method ResolveInterface:TSnapshotText(importingPath:String, target:String, isFileImport:Int, isFramework:Int)
		Local contextual:TSnapshotText = TSnapshotText(contextualInterfaces.ValueForKey(importingPath.Replace("\", "/").ToLower() + "|" + target.ToLower()))
		If contextual Then Return contextual
		Return TSnapshotText(interfaces.ValueForKey(target.ToLower()))
	End Method

	Method ResolveCoreInterface:TSnapshotText(targetPlatform:String)
		Return core
	End Method

	Method ResolveGenericTemplate:TSnapshotText(interfacePath:String, artifactReference:String)
		Return TSnapshotText(genericTemplates.ValueForKey(artifactReference.ToLower()))
	End Method
End Type

Local resolver:TMemorySnapshotResolver = New TMemorySnapshotResolver
resolver.core = TSnapshotText.Create("sdk/blitz_classes.i", "Object^Null{~n-New()=~qbbObjectCtor~q~n-ToString:String()=~qbbObjectToString~q~n}=~qbbObjectClass~q~nString^Object{~n}AF=~qbbStringClass~q~n___Array^Object{~n}AF=~qbbArrayClass~q")
resolver.AddInclude("shared.bmx", "Import support.api~nConst SharedValue:Int = 1")
resolver.AddInclude("win.bmx", "Const WindowsValue:Int = 2")
resolver.AddInterface("example.api", "sdk/example.api.i", "superstrict~nimport support.api~nTExample^Object{~n.value%&~n~~buffer@&[16]&~n-Get:TExample(other:TExample Var,value%)=~qexample_TExample_Get~q~n-Map<T>:T(value:T) Where T Extends Object~n-~q[]~q%(index%)O=~qexample_TExample__iget_i~q~n-~q[]=~q(index%,value%)O=~qexample_TExample__iset_ii~q~n}F=~qexample_TExample~q~nFileType%(path$)=~qexample_FileType~q~nUseDefaults%(value:Object=~qbbNullObject~q,items%&[]=~qbbEmptyArray~q)=~qexample_UseDefaults~q")
resolver.AddInterface("support.api", "sdk/support.api.i", "superstrict~nSUPPORT_VERSION%=1%")
resolver.AddInterface("brl.blitz", "sdk/brl.blitz.i", "superstrict~nMemCopy(dst@*,src@*,size%z)=~qbbMemCopy~q")

Local options:TCompilationSnapshotOptions = New TCompilationSnapshotOptions
options.targetPlatform = "win32"
options.conditionalSymbols = ["win32", "ptr64"]

Local rootSource:String = "SuperStrict~nInclude ~qshared.bmx~q~nImport example.api~nImport ~qglue.c~q~nGlobal direct:TExample~nGlobal qualified:example.api.TExample~nLocal selected:Int = direct[0]~ndirect[0] = selected~n?win32~nInclude ~qwin.bmx~q~n?~n?bmxng~nGlobal CurrentCompiler:Int = True~n?Not bmxng~nImport absent.legacy~nGlobal LegacyCompiler:Int = True~n?~n?bmxng2~nGlobal CurrentLanguageGeneration:Int = True~n?Not bmxng2~nImport absent.previousgeneration~n?~nLocal fileKind:Int = example.api.FileType(~qpath~q)~nMemCopy(Null, Null, Size_T(1))~nType TOverrideObjectMethod Extends TExample~nMethod ToString:String() Override~nReturn ~qexample~q~nEnd Method~nEnd Type~n"
Local snapshot:TCompilationSnapshot = TCompilationSnapshotBuilder.Build("src/main.bmx", rootSource, resolver, options)
Check(snapshot.succeeded, "complete snapshot succeeds")
Check(snapshot.rootDocument <> Null And snapshot.rootDocument.path = "src/main.bmx", "snapshot root document")
Check(snapshot.documents.length = 3, "root and active included documents")
Check(snapshot.rootDocument.includes.length = 2, "root include edges")
Check(snapshot.rootDocument.imports.length = 2, "written and implicit runtime import edges")
Check(snapshot.interfaces.length = 4, "core, runtime, and transitive imported interfaces")
Check(snapshot.coreInterface <> Null And snapshot.coreInterface.isCore, "core interface dependency")
Check(snapshot.rootDocument.imports[0].target.logicalName = "example.api", "resolved module import")
Check(snapshot.rootDocument.imports[1].target.logicalName = "brl.blitz" And snapshot.rootDocument.imports[1].syntax = Null, "implicit brl.blitz import")
Check(snapshot.rootDocument.imports[0].target.imports.length = 1, "transitive interface import")
Check(snapshot.documents[1].imports.length = 1, "import from included source")

Local configuredResolver:TMemorySnapshotResolver = New TMemorySnapshotResolver
configuredResolver.core = resolver.core
configuredResolver.AddInterface("brl.blitz", "sdk/brl.blitz.i", "superstrict")
configuredResolver.AddInclude("configured-child.bmx", "Local childValue:Int = 10 + ..~n?debug~n2~n?Not debug~n3~n?")
Local configuredOptions:TCompilationSnapshotOptions = New TCompilationSnapshotOptions
configuredOptions.targetPlatform = "win32"
configuredOptions.conditionalSymbols = ["debug"]
configuredOptions.parseConfiguredConditionals = True
Local configuredRootSource:String = "SuperStrict~nInclude ~qconfigured-child.bmx~q~nLocal rootValue:Int = 20 + ..~n?debug~n2~n?Not debug~n3~n?"
Local configuredSnapshot:TCompilationSnapshot = TCompilationSnapshotBuilder.Build("src/configured-root.bmx", configuredRootSource, configuredResolver, configuredOptions)
Check(configuredSnapshot.succeeded And configuredSnapshot.documents.length = 2, "configured snapshots select root and included source before grammar parsing")
Local configuredRootDeclaration:TVariableDeclarationStatementSyntax
For Local configuredRootMember:TSyntaxNode = EachIn configuredSnapshot.rootDocument.tree.root.members
	configuredRootDeclaration = TVariableDeclarationStatementSyntax(configuredRootMember)
	If configuredRootDeclaration Then Exit
Next
Local configuredChildDeclaration:TVariableDeclarationStatementSyntax = TVariableDeclarationStatementSyntax(configuredSnapshot.documents[1].tree.root.members[0])
Check(TLiteralExpressionSyntax(TBinaryExpressionSyntax(configuredRootDeclaration.declarators[0].initializer).right).literalToken.text = "2", "configured root source retains the selected expression line")
Check(TLiteralExpressionSyntax(TBinaryExpressionSyntax(configuredChildDeclaration.declarators[0].initializer).right).literalToken.text = "2", "configured included source retains the selected expression line")
Check(configuredRootDeclaration.span.start = configuredRootSource.Find("Local rootValue"), "configured syntax retains original-source offsets")
Local invalidConfiguredSnapshot:TCompilationSnapshot = TCompilationSnapshotBuilder.Build("src/invalid-location.bmx", "SuperStrict~nLocal value:Int = 1 => 0", configuredResolver, configuredOptions)
Check(invalidConfiguredSnapshot.diagnostics.length > 0 And invalidConfiguredSnapshot.diagnostics[0].Format(invalidConfiguredSnapshot).StartsWith("src/invalid-location.bmx:2:"), "snapshot parser diagnostics format their original source line and column")
configuredResolver.AddInclude("semantic-location-child.bmx", "Function ChildValue:Int()~nReturn MissingChildValue()~nEnd Function")
Local includedSemanticAnalysis:TLanguageAnalysis = TBlitzMaxLanguage.BuildAndAnalyze("src/semantic-location-root.bmx", "SuperStrict~nInclude ~qsemantic-location-child.bmx~q", configuredResolver, configuredOptions)
Local includedSemanticLocationFound:Int
For Local diagnostic:TDiagnostic = EachIn includedSemanticAnalysis.model.diagnostics
	If diagnostic.path = "semantic-location-child.bmx" And diagnostic.Format(includedSemanticAnalysis.snapshot.SourceForPath(diagnostic.path)).StartsWith("semantic-location-child.bmx:2:") Then includedSemanticLocationFound = True
Next
Check(includedSemanticLocationFound, "semantic diagnostics from included source format against that document rather than the root source")

resolver.AddInterface("implicit.application", "sdk/implicit.application.i", "superstrict~nImplicitApplicationValue%=42%")
Local implicitApplicationOptions:TCompilationSnapshotOptions = New TCompilationSnapshotOptions
implicitApplicationOptions.targetPlatform = options.targetPlatform
implicitApplicationOptions.conditionalSymbols = options.conditionalSymbols
implicitApplicationOptions.implicitImports = ["implicit.application", "brl.blitz"]
Local implicitApplication:TLanguageAnalysis = TBlitzMaxLanguage.BuildAndAnalyze("src/implicit-application.bmx", "SuperStrict~nLocal value:Int=ImplicitApplicationValue", resolver, implicitApplicationOptions)
Check(implicitApplication.Succeeded(), "build-driver implicit application imports participate in semantic analysis")
Check(implicitApplication.snapshot.rootDocument.imports.length = 2 And implicitApplication.snapshot.rootDocument.imports[0].target.logicalName = "brl.blitz" And implicitApplication.snapshot.rootDocument.imports[1].target.logicalName = "implicit.application", "implicit runtime and application imports are deterministic and deduplicated")

Local runtimeModuleOptions:TCompilationSnapshotOptions = New TCompilationSnapshotOptions
runtimeModuleOptions.targetPlatform = options.targetPlatform
runtimeModuleOptions.conditionalSymbols = options.conditionalSymbols
runtimeModuleOptions.sourceModuleName = "brl.blitz"
Local runtimeModuleSnapshot:TCompilationSnapshot = TCompilationSnapshotBuilder.Build("src/runtime-common.bmx", "SuperStrict~nFunction RuntimeValue:Int()~nReturn 1~nEnd Function", resolver, runtimeModuleOptions)
Check(runtimeModuleSnapshot.succeeded And runtimeModuleSnapshot.rootDocument.imports.length = 0, "build-driver runtime module identity suppresses its implicit self-import without scanning source text")

Local collisionResolver:TMemorySnapshotResolver = New TMemorySnapshotResolver
collisionResolver.core = resolver.core
collisionResolver.AddInterface("brl.blitz", "sdk/brl.blitz.i", "superstrict")
collisionResolver.AddInterface("acme.owner", "sdk/acme.owner.i", "superstrict~nimport ~qdriver.bmx~q")
collisionResolver.AddContextualInterface("sdk/acme.owner.i", "driver.bmx", "sdk/acme/.bmx/driver.bmx.release.test.i", "superstrict~nTOwnerDriver^Object{~n}=~qacme_owner_TOwnerDriver~q")
collisionResolver.AddContextualInterface("src/collision.bmx", "driver.bmx", "src/.bmx/driver.bmx.release.test.i", "superstrict~nTLocalDriver^Object{~n}=~qlocal_TLocalDriver~q")
Local collisionAnalysis:TLanguageAnalysis = TBlitzMaxLanguage.BuildAndAnalyze("src/collision.bmx", "SuperStrict~nImport acme.owner~nImport ~qdriver.bmx~q~nLocal driver:TLocalDriver~nLocal owner:TOwnerDriver", collisionResolver, options)
Check(collisionAnalysis.Succeeded() And TNamedSemanticType(collisionAnalysis.model.globalScope.LookupLocal("driver")[0].declaredType).symbol.name = "TLocalDriver", "same-named quoted interfaces retain path identity across unrelated owners")
Check(TNamedSemanticType(collisionAnalysis.model.globalScope.LookupLocal("owner")[0].declaredType).symbol.originModule = "acme.owner", "owned quoted declarations have one visible nominal-module identity")
Local ownerDriverSymbols:TSymbol[] = collisionAnalysis.model.ImportedScope("acme.owner").LookupLocal("TOwnerDriver")
Check(ownerDriverSymbols.length = 1 And ownerDriverSymbols[0].originModule = "acme.owner" And ownerDriverSymbols[0].originPath = "sdk/acme/.bmx/driver.bmx.release.test.i", "quoted module source declarations merge into their owning public module scope with source provenance")

Local aggregateResolver:TMemorySnapshotResolver = New TMemorySnapshotResolver
aggregateResolver.core = resolver.core
aggregateResolver.AddInterface("brl.blitz", "sdk/brl.blitz.i", "superstrict")
aggregateResolver.AddInterface("acme.aggregate", "sdk/mod/acme.mod/aggregate.mod/aggregate.release.test.i", "superstrict~n'@source-aggregate 1~nimport ~qcommon.bmx~q~nSGlyphPosition^Null{ '@source ~qcommon.bmx~q,42,0~n.glyphIndex%& '@source ~qcommon.bmx~q,43,7~n}S=~qacme_aggregate_SGlyphPosition~q")
aggregateResolver.AddContextualInterface("sdk/mod/acme.mod/aggregate.mod/aggregate.release.test.i", "common.bmx", "sdk/mod/acme.mod/aggregate.mod/.bmx/common.bmx.release.test.i", "superstrict~nSGlyphPosition^Null{ '@source ~qcommon.bmx~q,42,0~n.glyphIndex%& '@source ~qcommon.bmx~q,43,7~n}S=~qacme_aggregate_SGlyphPosition~q")
Local aggregateAnalysis:TLanguageAnalysis = TBlitzMaxLanguage.BuildAndAnalyze("src/aggregate-consumer.bmx", "SuperStrict~nImport acme.aggregate~nLocal glyph:SGlyphPosition", aggregateResolver, options)
Local aggregateSymbols:TSymbol[] = aggregateAnalysis.model.ImportedScope("acme.aggregate").LookupLocal("SGlyphPosition")
Check(aggregateAnalysis.Succeeded() And aggregateSymbols.length = 1, "an aggregate module interface suppresses duplicate quoted-source declaration merging")
Check(aggregateSymbols[0].originModule = "acme.aggregate" And aggregateSymbols[0].originPath.EndsWith("/common.bmx"), "aggregate declarations retain module ownership and quoted-source navigation provenance")

Local uintDefaultResolver:TMemorySnapshotResolver = New TMemorySnapshotResolver
uintDefaultResolver.core = resolver.core
uintDefaultResolver.AddInterface("brl.blitz", "sdk/brl.blitz.i", "superstrict")
uintDefaultResolver.AddInterface("acme.uintdefaults", "sdk/acme.uintdefaults.i", "superstrict~nClear(r|=0|,g|=0|,b|=0|)=~qacme_Clear~q")
Local uintDefaultAnalysis:TLanguageAnalysis = TBlitzMaxLanguage.BuildAndAnalyze("src/uint-default.bmx", "SuperStrict~nImport acme.uintdefaults~nClear()", uintDefaultResolver, options)
Check(uintDefaultAnalysis.Succeeded(), "compact UInt defaults discard their trailing representation marker before constant evaluation")

Local snapshotAnalysis:TLanguageAnalysis = TBlitzMaxLanguage.AnalyzeSnapshot(snapshot)
Local includedView:TLanguageAnalysis = snapshotAnalysis.ViewForDocument("shared.bmx")
Check(includedView <> Null And includedView.syntaxTree.source.path = "shared.bmx", "analysis exposes a document-local view for an included source")
Check(includedView.model = snapshotAnalysis.model And includedView.snapshot = snapshotAnalysis.snapshot, "included document view shares its compilation-unit semantic model")
Check(snapshotAnalysis.ViewForDocument("absent.bmx") = Null, "analysis does not guess document membership outside its snapshot")

Local modeResolver:TMemorySnapshotResolver = New TMemorySnapshotResolver
modeResolver.core = resolver.core
modeResolver.AddInterface("brl.blitz", "sdk/brl.blitz.i", "superstrict")
modeResolver.AddInclude("mode-child.bmx", "Include ~qmode-grandchild.bmx~q~nFunction ChildProcedure()~nEnd Function")
modeResolver.AddInclude("mode-grandchild.bmx", "Function GrandchildProcedure()~nEnd Function")
Local superModeAnalysis:TLanguageAnalysis = TBlitzMaxLanguage.BuildAndAnalyze("super-root.bmx", "SuperStrict~nInclude ~qmode-child.bmx~q", modeResolver, options)
Local childProcedure:TSymbol = superModeAnalysis.model.globalScope.LookupLocal("ChildProcedure")[0]
Local grandchildProcedure:TSymbol = superModeAnalysis.model.globalScope.LookupLocal("GrandchildProcedure")[0]
Check(superModeAnalysis.snapshot.documents[1].tree.root.sourceMode = SOURCE_MODE_STRICT, "included syntax retains its independently parsed implicit mode")
Check(superModeAnalysis.snapshot.documents[1].effectiveSourceMode = SOURCE_MODE_SUPERSTRICT And superModeAnalysis.snapshot.documents[2].effectiveSourceMode = SOURCE_MODE_SUPERSTRICT, "direct and transitive includes inherit the root SuperStrict mode")
Check(childProcedure.declaredType = superModeAnalysis.model.BuiltinType("Void") And grandchildProcedure.declaredType = superModeAnalysis.model.BuiltinType("Void"), "included routines use inherited SuperStrict return defaults")
Local strictModeAnalysis:TLanguageAnalysis = TBlitzMaxLanguage.BuildAndAnalyze("strict-root.bmx", "Strict~nInclude ~qmode-child.bmx~q", modeResolver, options)
Check(strictModeAnalysis.model.globalScope.LookupLocal("ChildProcedure")[0].declaredType = strictModeAnalysis.model.BuiltinType("Int"), "included routines retain Strict implicit Int returns under a Strict root")

Local ownedSourceOptions:TCompilationSnapshotOptions = New TCompilationSnapshotOptions
ownedSourceOptions.targetPlatform = options.targetPlatform
ownedSourceOptions.conditionalSymbols = options.conditionalSymbols
ownedSourceOptions.sourceModuleName = "Acme.MultiSource"
Local ownedSourceAnalysis:TLanguageAnalysis = TBlitzMaxLanguage.BuildAndAnalyze("src/common.bmx", "SuperStrict~nFunction SharedValue:Int()~nReturn 42~nEnd Function", resolver, ownedSourceOptions)
Local ownedSourceSymbol:TSymbol = ownedSourceAnalysis.model.globalScope.LookupLocal("SharedValue")[0]
Check(ownedSourceAnalysis.Succeeded() And ownedSourceAnalysis.model.moduleName = "acme.multisource", "snapshot module override gives a quoted source its owning module identity")
Check(ownedSourceSymbol.originModule = "acme.multisource" And ownedSourceSymbol.originPath = "src/common.bmx", "module override preserves per-source provenance on owned declarations")

Local importedOwnedSourceResolver:TMemorySnapshotResolver = New TMemorySnapshotResolver
importedOwnedSourceResolver.core = resolver.core
importedOwnedSourceResolver.AddInterface("brl.blitz", "sdk/brl.blitz.i", "superstrict")
importedOwnedSourceResolver.AddInterface("common.bmx", "sdk/mod/acme.mod/multisource.mod/.bmx/common.bmx.release.test.i", "superstrict~nSGlyphPosition^Null{ '@source ~q../../common.bmx~q,42,0~n.glyphIndex%& '@source ~q../../common.bmx~q,43,7~n}S=~qacme_multisource_SGlyphPosition~q")
Local importedOwnedSource:TLanguageAnalysis = TBlitzMaxLanguage.BuildAndAnalyze("sdk/mod/acme.mod/multisource.mod/multisource.bmx", "SuperStrict~nImport ~qcommon.bmx~q~nLocal glyph:SGlyphPosition", importedOwnedSourceResolver, ownedSourceOptions)
Local importedGlyph:TSymbol = TNamedSemanticType(importedOwnedSource.model.globalScope.LookupLocal("glyph")[0].declaredType).symbol
Check(importedOwnedSource.Succeeded() And importedGlyph.originModule = "acme.multisource", "a quoted source interface contributes declarations to its importing module rather than a filename-shaped nominal module")
Check(importedGlyph.originPath.EndsWith("/common.bmx") And importedGlyph.originLine = 42, "an imported owned declaration retains its quoted-source provenance")

Local resolutionOptions:TTypeResolutionOptions = New TTypeResolutionOptions
resolutionOptions.reportUnresolvedTypes = True
Local semanticModel:TSemanticModel = TBlitzMaxSemanticAnalyzer.AnalyzeSnapshot(snapshot, resolutionOptions)
Check(semanticModel.diagnostics.length = 0, "snapshot semantic diagnostics")
Check(Not HasDiagnostic(semanticModel.diagnostics, "BMX3211"), "Override resolves through an imported base type to implicit Object")
Check(semanticModel.globalScope.LookupLocal("direct").length = 1, "direct declaration collected")
Check(semanticModel.globalScope.LookupLocal("qualified").length = 1, "qualified declaration collected")
Check(semanticModel.globalScope.LookupLocal("CurrentCompiler").length = 1 And semanticModel.globalScope.LookupLocal("LegacyCompiler").length = 0, "bmxng is always active and Not bmxng is inactive")
Check(semanticModel.globalScope.LookupLocal("CurrentLanguageGeneration").length = 1, "bmxng2 is always active for bcc2 snapshots")
Local directSymbol:TSymbol = semanticModel.globalScope.LookupLocal("direct")[0]
Local qualifiedSymbol:TSymbol = semanticModel.globalScope.LookupLocal("qualified")[0]
Check(TNamedSemanticType(directSymbol.declaredType) <> Null, "unqualified imported type resolution")
Check(TNamedSemanticType(directSymbol.declaredType).symbol.originModule = "example.api", "unqualified imported type origin")
Check(TNamedSemanticType(directSymbol.declaredType).symbol.originPath = "sdk/example.api.i", "imported symbol retains interface path")
Check(semanticModel.globalScope.LookupLocal("SharedValue")[0].originPath = "shared.bmx", "included symbol retains source path")
Check(TNamedSemanticType(qualifiedSymbol.declaredType) <> Null, "qualified imported type resolution")
Check(semanticModel.globalScope.LookupLocal("SharedValue").length = 1, "included declaration contributes to compilation scope")
Local exampleTypeSymbol:TSymbol = semanticModel.ImportedScope("example.api").LookupLocal("TExample")[0]
Local importedField:TSymbol = exampleTypeSymbol.memberScope.LookupLocal("value")[0]
Local importedStaticField:TSymbol = exampleTypeSymbol.memberScope.LookupLocal("buffer")[0]
Local importedMethod:TSymbol = exampleTypeSymbol.memberScope.LookupLocal("Get")[0]
Local importedGenericMethod:TSymbol = exampleTypeSymbol.memberScope.LookupLocal("Map")[0]
Check(importedField.declaredType = semanticModel.BuiltinType("Int"), "imported compact field type binding")
Check(TStaticArraySemanticType(importedStaticField.declaredType) <> Null, "imported StaticArray field type binding")
Check(TNamedSemanticType(importedMethod.declaredType).symbol = exampleTypeSymbol, "imported routine return type binding")
Check(importedMethod.parameterTypes.length = 2, "imported routine parameter count")
Check(TNamedSemanticType(importedMethod.parameterTypes[0]).symbol = exampleTypeSymbol, "imported named parameter type")
Check(importedMethod.parameterTypes[1] = semanticModel.BuiltinType("Int"), "imported compact parameter type")
Check(importedMethod.parameters[0].passingMode = PARAMETER_PASS_VAR And importedMethod.parameters[0].symbol.parameterMode = PARAMETER_PASS_VAR, "imported Var parameter semantic mode")
Check(importedGenericMethod.genericArity = 1 And importedGenericMethod.memberScope.LookupLocal("T")[0].kind = SYMBOL_TYPE_PARAMETER, "imported generic routine scope")
Check(importedGenericMethod.declaredType = importedGenericMethod.memberScope.LookupLocal("T")[0].declaredType, "imported generic routine return type")
Check(importedGenericMethod.parameterTypes[0] = importedGenericMethod.memberScope.LookupLocal("T")[0].declaredType, "imported generic routine parameter type")
Check(importedGenericMethod.genericConstraints.length = 1 And importedGenericMethod.genericConstraints[0].bounds[0] = semanticModel.BuiltinType("Object"), "imported generic routine constraint")
Check(semanticModel.InheritanceInfo(exampleTypeSymbol).baseEdges[0].semanticType = semanticModel.BuiltinType("Object"), "imported base type binding")
Check(semanticModel.BuiltinType("Object").runtimeSymbol.name = "Object", "Object core runtime definition")
Check(semanticModel.BuiltinType("Object").runtimeSymbol.memberScope.LookupLocal("New")[0].declaredType = semanticModel.BuiltinType("Void"), "imported omitted routine return is Void")
Check(semanticModel.BuiltinType("String").runtimeSymbol.name = "String", "String core runtime definition")
Check(semanticModel.arrayRuntimeSymbol.name = "___Array", "array core runtime definition")
TExpressionBinder.Bind(semanticModel)
TCompileTimeAnalyzer.Analyze(semanticModel)
Check(semanticModel.diagnostics.length = 0, "imported operator expression diagnostics")
Local supportVersion:TSymbol = semanticModel.ImportedScope("support.api").LookupLocal("SUPPORT_VERSION")[0]
Check(semanticModel.SymbolConstantValue(supportVersion).integerValue = 1, "imported interface constant value")
Local importedDefaults:TSymbol = semanticModel.ImportedScope("example.api").LookupLocal("UseDefaults")[0]
Check(importedDefaults.parameters.length = 2, "imported managed default parameter count")
Check(importedDefaults.parameters[0].defaultValue.kind = CONSTANT_VALUE_NULL And importedDefaults.parameters[1].defaultValue.kind = CONSTANT_VALUE_NULL, "imported ABI sentinels become semantic Null defaults")
resolver.AddInterface("callable.api", "sdk/callable.api.i", "superstrict~nTCallableList^Object{~n-Sort%(ascending%=1%,compareFunc%(left:Object,right:Object)=~qcallable_api_CompareObjects~q)=~qcallable_api_TCallableList_Sort_iF_TObjectTObject_i_~q~n}=~qcallable_api_TCallableList~q~nCompareObjects%(left:Object,right:Object)=~qcallable_api_CompareObjects~q~nSortList%(list:TCallableList,ascending%=1%,compareFunc%(left:Object,right:Object)=~qcallable_api_CompareObjects~q)=~qcallable_api_SortList~q")
Local callableInterfaceAnalysis:TLanguageAnalysis = TBlitzMaxLanguage.BuildAndAnalyze("src/callable-default-import.bmx", "SuperStrict~nImport callable.api", resolver, options)
Check(callableInterfaceAnalysis.model.diagnostics.length = 0, "imported callable defaults resolve their serialized ABI names")
Local callableList:TSymbol = callableInterfaceAnalysis.model.ImportedScope("callable.api").LookupLocal("TCallableList")[0]
Local importedSort:TSymbol = callableList.memberScope.LookupLocal("Sort")[0]
Local importedSortList:TSymbol = callableInterfaceAnalysis.model.ImportedScope("callable.api").LookupLocal("SortList")[0]
Check(importedSort.parameters[1].defaultValue.kind = CONSTANT_VALUE_CALLABLE And importedSort.parameters[1].defaultValue.callableSymbol.externalName = "callable_api_CompareObjects", "imported method callable default retains its ABI target symbol")
Check(importedSortList.parameters[2].defaultValue.kind = CONSTANT_VALUE_CALLABLE And importedSortList.parameters[2].defaultValue.callableSymbol.name = "CompareObjects", "imported free-routine callable default shares the canonical routine symbol")
resolver.AddInterface("callable.globals", "sdk/callable.globals.i", "superstrict~nActiveCompare%(left:Object,right:Object)&=mem:p(~qcallable_globals_ActiveCompare~q)")
Local callableGlobalInterfaceAnalysis:TLanguageAnalysis = TBlitzMaxLanguage.BuildAndAnalyze("src/callable-global-import.bmx", "SuperStrict~nImport callable.globals", resolver, options)
Check(callableGlobalInterfaceAnalysis.model.diagnostics.length = 0, "imported callable Global diagnostics")
Local importedCallableGlobal:TSymbol = callableGlobalInterfaceAnalysis.model.ImportedScope("callable.globals").LookupLocal("ActiveCompare")[0]
Check(importedCallableGlobal.kind = SYMBOL_GLOBAL And TCallableSemanticType(importedCallableGlobal.declaredType) <> Null And importedCallableGlobal.externalName = "callable_globals_ActiveCompare", "imported callable Global retains storage kind, callable type, and ABI name")
resolver.AddInterface("bad-callable.api", "sdk/bad-callable.api.i", "superstrict~nSortList%(compareFunc%(left:Object,right:Object)=~qmissing_CompareObjects~q)=~qbad_callable_SortList~q")
Local badCallableInterfaceAnalysis:TLanguageAnalysis = TBlitzMaxLanguage.BuildAndAnalyze("src/bad-callable-default-import.bmx", "SuperStrict~nImport bad-callable.api", resolver, options)
Check(HasDiagnostic(badCallableInterfaceAnalysis.model.diagnostics, "BMX3611"), "an unresolved quoted ABI name is not accepted as an imported callable default")
Check(TStaticArraySemanticType(importedStaticField.declaredType).length = 16, "imported StaticArray field length")
resolver.AddInterface("fixed.api", "sdk/fixed.api.i", "superstrict~nSCell^Null{~n.value%&~n}S=~qfixed_api_SCell~q~nFill%(values%&[4],cells:SCell&[2])=~qfixed_api_Fill~q~nTStaticOwner^Object{~n-Size%(values%&[4])=~qfixed_api_TStaticOwner_Size~q~n}=~qfixed_api_TStaticOwner~q")
Local fixedParameterAnalysis:TLanguageAnalysis = TBlitzMaxLanguage.BuildAndAnalyze("src/fixed-parameter-import.bmx", "SuperStrict~nImport fixed.api", resolver, options)
Local importedFill:TSymbol = fixedParameterAnalysis.model.ImportedScope("fixed.api").LookupLocal("Fill")[0]
Local importedStaticOwner:TSymbol = fixedParameterAnalysis.model.ImportedScope("fixed.api").LookupLocal("TStaticOwner")[0]
Local importedStaticSize:TSymbol = importedStaticOwner.memberScope.LookupLocal("Size")[0]
Check(fixedParameterAnalysis.model.diagnostics.length = 0, "imported StaticArray parameter semantic diagnostics")
Check(TStaticArraySemanticType(importedFill.parameterTypes[0]).length = 4 And TStaticArraySemanticType(importedFill.parameterTypes[1]).length = 2, "imported free routine StaticArray parameters retain fixed extents")
Check(TStaticArraySemanticType(importedStaticSize.parameterTypes[0]).length = 4, "imported method StaticArray parameter retains its fixed extent")
resolver.AddInterface("fixed.callable", "sdk/fixed.callable.i", "superstrict~nApplyFixed%(callback%(values%&[4]),values%&[4])=~qfixed_callable_ApplyFixed~q")
Local fixedCallableAnalysis:TLanguageAnalysis = TBlitzMaxLanguage.BuildAndAnalyze("src/fixed-callable-import.bmx", "SuperStrict~nImport fixed.callable", resolver, options)
Local importedApplyFixed:TSymbol = fixedCallableAnalysis.model.ImportedScope("fixed.callable").LookupLocal("ApplyFixed")[0]
Local importedFixedCallback:TCallableSemanticType = TCallableSemanticType(importedApplyFixed.parameterTypes[0])
Check(fixedCallableAnalysis.model.diagnostics.length = 0, "imported callable StaticArray parameter semantic diagnostics")
Check(importedFixedCallback <> Null And TStaticArraySemanticType(importedFixedCallback.parameterTypes[0]).length = 4, "imported callable parameter retains its nested StaticArray extent")
Local importedGetDeclaration:TVariableDeclarationStatementSyntax = TVariableDeclarationStatementSyntax(snapshot.rootDocument.tree.root.members[6])
Local importedGetIndex:TIndexExpressionSyntax = TIndexExpressionSyntax(importedGetDeclaration.declarators[0].initializer)
Check(semanticModel.ResolvedCall(importedGetIndex).routine.name = "[]" And semanticModel.ExpressionType(importedGetIndex) = semanticModel.BuiltinType("Int"), "imported index getter binding")
Local importedSetStatement:TAssignmentStatementSyntax = TAssignmentStatementSyntax(snapshot.rootDocument.tree.root.members[7])
Check(semanticModel.ResolvedCall(importedSetStatement).routine.name = "[]=", "imported index setter binding")
Local fileKindSymbol:TSymbol = semanticModel.globalScope.LookupLocal("fileKind")[0]
Local fileKindCall:TCallExpressionSyntax = TCallExpressionSyntax(TVariableDeclaratorSyntax(fileKindSymbol.declaration).initializer)
Check(semanticModel.ResolvedCall(fileKindCall) <> Null And semanticModel.ResolvedCall(fileKindCall).routine.originModule = "example.api", "module-qualified function call resolves through imported module scope")

' Parsed compiler interfaces do not have a source declaration node. Generic
' inheritance must therefore obtain the owner's type parameters from the
' imported member scope, rather than relying on declaration identity.
Local genericInterfaceFile:TInterfaceFile = TBlitzMaxSourceInterfaceBuilder.Build("sdk/generic.api.bmx", "SuperStrict~nInterface ICollection<T>~nEnd Interface~nInterface IList<T> Extends ICollection<T>~nEnd Interface~nType TEmptyImmutableList<T> Implements IList<T>~nEnd Type")
For Local genericRecord:TInterfaceRecord = EachIn genericInterfaceFile.declarations
	genericRecord.declarationSyntax = Null
Next
resolver.AddInterfaceFile("generic.api", "sdk/generic.api.i", genericInterfaceFile)
Local genericInterfaceAnalysis:TLanguageAnalysis = TBlitzMaxLanguage.BuildAndAnalyze("src/generic-interface-return.bmx", "SuperStrict~nImport generic.api~nFunction Keys:ICollection<Int>()~nReturn New TEmptyImmutableList<Int>~nEnd Function", resolver, options)
Check(genericInterfaceAnalysis.model.diagnostics.length = 0, "imported constructed generic interface inheritance satisfies return conversion")

' Production bcc embeds generic source because its compact interface format
' cannot publish generic declarations directly. Expanding that source must
' preserve every Interface named by a multi-parent Extends clause.
Local closeableIteratorFile:TInterfaceFile = TBlitzMaxSourceInterfaceBuilder.Build("sdk/closeable.iterator.bmx", "SuperStrict~nInterface ICloseable~nMethod Close()~nEnd Interface~nInterface IIterator<T>~nMethod Current:T()~nMethod MoveNext:Int()~nEnd Interface~nInterface ICloseableIterator<T> Extends IIterator<T>, ICloseable~nEnd Interface")
For Local closeableIteratorRecord:TInterfaceRecord = EachIn closeableIteratorFile.declarations
	closeableIteratorRecord.declarationSyntax = Null
Next
resolver.AddInterfaceFile("closeable.iterator", "sdk/closeable.iterator.i", closeableIteratorFile)
Local closeableIteratorAnalysis:TLanguageAnalysis = TBlitzMaxLanguage.BuildAndAnalyze("src/closeable-iterator-override.bmx", "SuperStrict~nImport closeable.iterator~nType TCloseableIterator Implements ICloseableIterator<String>~nMethod Current:String() Override~nReturn String()~nEnd Method~nMethod MoveNext:Int() Override~nReturn False~nEnd Method~nMethod Close() Override~nEnd Method~nEnd Type", resolver, options)
Check(closeableIteratorAnalysis.model.diagnostics.length = 0, "Override validation follows every parent of an imported generic Interface")
Local importedCloseableIterator:TSymbol = closeableIteratorAnalysis.model.ImportedScope("closeable.iterator").LookupLocal("ICloseableIterator")[0]
Local importedCloseableIteratorInfo:TTypeInheritanceInfo = closeableIteratorAnalysis.model.InheritanceInfo(importedCloseableIterator)
Check(importedCloseableIteratorInfo.baseEdges.length = 1 And importedCloseableIteratorInfo.interfaceEdges.length = 1, "source-built generic Interface records retain their primary and additional inherited Interfaces")

' Old bcc interfaces can carry generated gimpl copies of public generic types.
' Those implementation records must not compete with the canonical declaration
' during source name lookup.
Local canonicalMapNode:TInterfaceFile = TBlitzMaxSourceInterfaceBuilder.Build("sdk/imap.bmx", "SuperStrict~nInterface IMapNode<K,V>~nEnd Interface")
Local firstMapNodeSpecialization:TInterfaceFile = TBlitzMaxSourceInterfaceBuilder.Build("sdk/imap.bmx", "SuperStrict~nInterface IMapNode<K,V>~nEnd Interface~nType TLegacyMapNode Implements IMapNode<String,String>~nEnd Type")
firstMapNodeSpecialization.declarations[0].externalName = "legacy.one|gimpl_IMapNodeSTObject"
Local secondMapNodeSpecialization:TInterfaceFile = TBlitzMaxSourceInterfaceBuilder.Build("sdk/imap.bmx", "SuperStrict~nInterface IMapNode<K,V>~nEnd Interface")
secondMapNodeSpecialization.declarations[0].externalName = "legacy.two|gimpl_IMapNodepbTObject"
Local mapConsumer:TInterfaceFile = TBlitzMaxSourceInterfaceBuilder.Build("sdk/map-consumer.bmx", "SuperStrict~nImport canonical.imap~nImport legacy.one~nImport legacy.two")
resolver.AddInterfaceFile("canonical.imap", "sdk/canonical.imap.i", canonicalMapNode)
resolver.AddInterfaceFile("legacy.one", "sdk/legacy.one.i", firstMapNodeSpecialization)
resolver.AddInterfaceFile("legacy.two", "sdk/legacy.two.i", secondMapNodeSpecialization)
resolver.AddInterfaceFile("map.consumer", "sdk/map.consumer.i", mapConsumer)
Local canonicalMapNodeAnalysis:TLanguageAnalysis = TBlitzMaxLanguage.BuildAndAnalyze("src/map-node-use.bmx", "SuperStrict~nImport map.consumer~nLocal node:IMapNode<String,String> = New TLegacyMapNode", resolver, options)
Check(canonicalMapNodeAnalysis.model.diagnostics.length = 0, "compiler generic specializations do not make a canonical imported type ambiguous")
Local mapNodeLocal:TSymbol = canonicalMapNodeAnalysis.model.globalScope.LookupLocal("node")[0]
Check(TNamedSemanticType(mapNodeLocal.declaredType).symbol.originModule = "canonical.imap", "canonical public generic declaration wins over gimpl artifacts")
Local legacyMapNode:TSymbol = canonicalMapNodeAnalysis.model.ImportedScope("legacy.one").LookupLocal("TLegacyMapNode")[0]
Local legacyMapNodeInterface:TNamedSemanticType = TNamedSemanticType(canonicalMapNodeAnalysis.model.InheritanceInfo(legacyMapNode).interfaceEdges[0].semanticType)
Check(legacyMapNodeInterface.symbol.originModule = "canonical.imap", "an imported Type's generic Interface edge bypasses its module-local linker-only gimpl copy")

' Imported interfaces may refer to a type before its declaration later in the
' same file. Array wrappers must retain the resolved element type just as a
' scalar reference does.
resolver.AddInterface("forward.api", "sdk/forward.api.i", "superstrict~nTForwardCollection^Object{~n-AddTeams(teams:TForwardTeam&[])=~qforward_AddTeams~q~n}F=~qforward_TForwardCollection~q~nTForwardTeam^Object{~n}F=~qforward_TForwardTeam~q")
Local forwardArrayAnalysis:TLanguageAnalysis = TBlitzMaxLanguage.BuildAndAnalyze("src/forward-array.bmx", "SuperStrict~nImport forward.api~nLocal collection:TForwardCollection = New TForwardCollection~nLocal teams:TForwardTeam[] = New TForwardTeam[1]~ncollection.AddTeams(teams)", resolver, options)
Check(forwardArrayAnalysis.model.diagnostics.length = 0, "forward-declared imported element types resolve inside array parameters")
Local forwardCollectionSymbol:TSymbol = forwardArrayAnalysis.model.ImportedScope("forward.api").LookupLocal("TForwardCollection")[0]
Local forwardAddTeams:TSymbol = forwardCollectionSymbol.memberScope.LookupLocal("AddTeams")[0]
Local forwardTeamsType:TArraySemanticType = TArraySemanticType(forwardAddTeams.parameterTypes[0])
Check(forwardTeamsType <> Null And TNamedSemanticType(forwardTeamsType.elementType).symbol.name = "TForwardTeam", "compact interface array reference marker is excluded from the named element type")

Local importedTemplateIdentity:TGenericTemplateIdentity = New TGenericTemplateIdentity
importedTemplateIdentity.moduleName = "collections.api"
importedTemplateIdentity.qualifiedName = "TBox"
importedTemplateIdentity.arity = 1
Local importedTemplateParameter:TGenericTemplateParameter = New TGenericTemplateParameter
importedTemplateParameter.name = "T"
importedTemplateParameter.ordinal = 0
Local importedTemplateParameterType:TTemplateTypeReference = New TTemplateTypeReference
importedTemplateParameterType.kind = TEMPLATE_TYPE_PARAMETER
importedTemplateParameterType.parameterIndex = 0
Local importedTemplateField:TGenericTemplateMember = New TGenericTemplateMember
importedTemplateField.kind = TEMPLATE_MEMBER_FIELD
importedTemplateField.identity = "field:value"
importedTemplateField.name = "value"
importedTemplateField.visibility = VISIBILITY_PUBLIC
importedTemplateField.semanticType = importedTemplateParameterType
Local importedTemplateFieldNode:TGenericTemplateNode = New TGenericTemplateNode
importedTemplateFieldNode.kind = TEMPLATE_NODE_MEMBER
importedTemplateFieldNode.valueText = "value"
importedTemplateFieldNode.semanticType = importedTemplateParameterType
Local importedTemplateReturn:TGenericTemplateNode = New TGenericTemplateNode
importedTemplateReturn.kind = TEMPLATE_NODE_RETURN
importedTemplateReturn.semanticType = importedTemplateParameterType
importedTemplateReturn.children = [importedTemplateFieldNode]
Local importedTemplateBody:TGenericTemplateNode = New TGenericTemplateNode
importedTemplateBody.kind = TEMPLATE_NODE_BLOCK
importedTemplateBody.children = [importedTemplateReturn]
Local importedTemplateMethod:TGenericTemplateMember = New TGenericTemplateMember
importedTemplateMethod.kind = TEMPLATE_MEMBER_METHOD
importedTemplateMethod.identity = "method:first/0"
importedTemplateMethod.name = "First"
importedTemplateMethod.visibility = VISIBILITY_PUBLIC
importedTemplateMethod.semanticType = importedTemplateParameterType
importedTemplateMethod.body = importedTemplateBody
Local importedTemplateArtifact:TGenericTemplateArtifact = New TGenericTemplateArtifact
importedTemplateArtifact.identity = importedTemplateIdentity
importedTemplateArtifact.languageLinkageRevision = "bmx-language-1"
importedTemplateArtifact.parameters = [importedTemplateParameter]
importedTemplateArtifact.members = [importedTemplateField, importedTemplateMethod]
Local importedRevisionDiagnostics:String[]
importedTemplateArtifact.contentRevision = TGenericTemplateArtifactCodec.ComputeContentRevision(importedTemplateArtifact, importedRevisionDiagnostics)
Local importedEncodeDiagnostics:String[]
Local importedTemplateText:String = TGenericTemplateArtifactCodec.Encode(importedTemplateArtifact, importedEncodeDiagnostics)
Check(importedRevisionDiagnostics.length = 0 And importedEncodeDiagnostics.length = 0, "cross-module generic fixture artifact encoding")
Local importedTemplateInterface:String = "superstrict~nTBox<T>^Object{~n.value:T&~n-First:T()=~qcollections_api_TBox_First~q~n}=~qcollections_api_TBox~q~n'@generic-template 1,~q" + importedTemplateIdentity.StableName() + "~q,~q" + importedTemplateArtifact.contentRevision + "~q,~qtbox.bmxgt~q,~qbmx-language-1~q"
resolver.AddInterface("collections.api", "sdk/collections.api.i", importedTemplateInterface)
resolver.AddGenericTemplate("tbox.bmxgt", "sdk/tbox.bmxgt", importedTemplateText)
Local importedTemplateAnalysis:TLanguageAnalysis = TBlitzMaxLanguage.BuildAndAnalyze("src/imported-template.bmx", "SuperStrict~nImport collections.api~nGlobal box:TBox<String>", resolver, options)
Check(importedTemplateAnalysis.Succeeded(), "canonical generic template companion loads with its compact interface")
Local importedBoxSymbol:TSymbol = importedTemplateAnalysis.model.ImportedScope("collections.api").LookupLocal("TBox")[0]
Check(importedBoxSymbol.genericArity = 1 And importedBoxSymbol.memberScope.LookupLocal("T").length = 1, "generic public signature is decoded without source expansion")
Check(importedBoxSymbol.genericTemplateArtifact <> Null And importedBoxSymbol.genericTemplateArtifact.EffectiveContentRevision() = importedTemplateArtifact.contentRevision, "validated companion artifact is attached to the imported semantic identity")
Check(importedBoxSymbol.interfaceRecord.genericSource.length = 0, "canonical interface ingestion does not manufacture a legacy source payload")

Local decodedTemplateResolver:TMemorySnapshotResolver = New TMemorySnapshotResolver
decodedTemplateResolver.core = resolver.core
decodedTemplateResolver.AddInterface("brl.blitz", "sdk/brl.blitz.i", "superstrict")
decodedTemplateResolver.AddInterface("collections.api", "sdk/collections.api.i", importedTemplateInterface)
decodedTemplateResolver.AddDecodedGenericTemplate("tbox.bmxgt", "sdk/tbox.bmxgt", importedTemplateArtifact)
Local decodedTemplateAnalysis:TLanguageAnalysis = TBlitzMaxLanguage.BuildAndAnalyze("src/decoded-template.bmx", "SuperStrict~nImport collections.api~nGlobal box:TBox<String>", decodedTemplateResolver, options)
Check(decodedTemplateAnalysis.Succeeded(), "a resolver-supplied immutable decoded generic template follows the ordinary snapshot validation path")

Local staleTemplateResolver:TMemorySnapshotResolver = New TMemorySnapshotResolver
staleTemplateResolver.core = resolver.core
staleTemplateResolver.AddInterface("brl.blitz", "sdk/brl.blitz.i", "superstrict")
Local staleTemplateInterface:String = importedTemplateInterface.Replace(importedTemplateArtifact.contentRevision, "0000000000000000000000000000000000000000000000000000000000000000")
staleTemplateResolver.AddInterface("collections.api", "sdk/collections.api.i", staleTemplateInterface)
staleTemplateResolver.AddDecodedGenericTemplate("tbox.bmxgt", "sdk/tbox.bmxgt", importedTemplateArtifact)
Local staleTemplateSnapshot:TCompilationSnapshot = TCompilationSnapshotBuilder.Build("src/stale-template.bmx", "SuperStrict~nImport collections.api", staleTemplateResolver, options)
Check(Not staleTemplateSnapshot.succeeded And staleTemplateSnapshot.diagnostics[0].code = "BMX4012", "interface revision invalidates a stale predecoded generic template companion")

resolver.AddInterface("abstract.api", "sdk/abstract.api.i", "superstrict~nTAbstractFactory^Object{~n-Find%(index%)A=~qabstract_Find_i~q~n}A=~qabstract_TAbstractFactory~q")
Local abstractImportSource:String = "SuperStrict~nImport abstract.api~nType TIncompleteFactory Extends TAbstractFactory~nEnd Type~nType TConcreteFactory Extends TAbstractFactory~nMethod Find:Int(index:Int)~nReturn index~nEnd Method~nEnd Type~nLocal invalidBase:TAbstractFactory = New TAbstractFactory~nLocal invalidChild:TIncompleteFactory = New TIncompleteFactory~nLocal validChild:TConcreteFactory = New TConcreteFactory"
Local abstractImportAnalysis:TLanguageAnalysis = TBlitzMaxLanguage.BuildAndAnalyze("src/abstract-import.bmx", abstractImportSource, resolver, options)
Local abstractImportDiagnostics:Int
For Local diagnostic:TDiagnostic = EachIn abstractImportAnalysis.model.diagnostics
	If diagnostic.code = "BMX3316" Then abstractImportDiagnostics :+ 1
Next
Check(abstractImportDiagnostics = 2, "imported abstract types and their incomplete children cannot be instantiated")

' An imported-interface semantic failure must retain the interface path rather
' than being projected onto the importing root document.
resolver.AddInterface("bad.api", "sdk/bad.api.i", "superstrict~nEFormat\%{~nLATIN1=0~n}=~qbad_EFormat~q~nSave%(format/EFormat=1.5!)=~qbad_Save~q")
Local badAnalysis:TLanguageAnalysis = TBlitzMaxLanguage.BuildAndAnalyze("src/bad-root.bmx", "SuperStrict~nImport bad.api", resolver, options)
Local badDefaultDiagnostic:TDiagnostic
For Local diagnostic:TDiagnostic = EachIn badAnalysis.model.diagnostics
	If diagnostic.code = "BMX3611" Then badDefaultDiagnostic = diagnostic
Next
Check(badDefaultDiagnostic <> Null, "imported incompatible default diagnostic fixture")
Check(badDefaultDiagnostic.path = "sdk/bad.api.i", "imported semantic diagnostic retains interface path")

Local linuxOptions:TCompilationSnapshotOptions = New TCompilationSnapshotOptions
linuxOptions.targetPlatform = "linux"
Local linuxSnapshot:TCompilationSnapshot = TCompilationSnapshotBuilder.Build("src/main.bmx", rootSource, resolver, linuxOptions)
Check(linuxSnapshot.succeeded And linuxSnapshot.documents.length = 2, "inactive conditional include is not loaded")

Local missingImport:TCompilationSnapshot = TCompilationSnapshotBuilder.Build("missing.bmx", "Import absent.module", resolver, options)
Check(Not missingImport.succeeded, "missing interface fails snapshot")
Check(missingImport.diagnostics.length = 1 And missingImport.diagnostics[0].code = "BMX4003", "missing interface diagnostic")

Local missingInclude:TCompilationSnapshot = TCompilationSnapshotBuilder.Build("missing-include.bmx", "Include ~qabsent.bmx~q", resolver, options)
Check(Not missingInclude.succeeded, "missing include fails snapshot")
Check(missingInclude.diagnostics.length = 1 And missingInclude.diagnostics[0].code = "BMX4002", "missing include diagnostic")

Local noCoreResolver:TMemorySnapshotResolver = New TMemorySnapshotResolver
Local missingCore:TCompilationSnapshot = TCompilationSnapshotBuilder.Build("no-core.bmx", "SuperStrict", noCoreResolver, options)
Check(Not missingCore.succeeded, "missing core interface fails snapshot")
Check(missingCore.diagnostics.length = 1 And missingCore.diagnostics[0].code = "BMX4001", "missing core diagnostic")

Local cycleResolver:TMemorySnapshotResolver = New TMemorySnapshotResolver
cycleResolver.core = resolver.core
cycleResolver.AddInterface("brl.blitz", "sdk/brl.blitz.i", "superstrict")
cycleResolver.AddInclude("a.bmx", "Include ~qb.bmx~q")
cycleResolver.AddInclude("b.bmx", "Include ~qa.bmx~q")
Local cycle:TCompilationSnapshot = TCompilationSnapshotBuilder.Build("a.bmx", "Include ~qb.bmx~q", cycleResolver, options)
Check(Not cycle.succeeded, "include cycle fails snapshot")
Check(cycle.diagnostics.length = 1 And cycle.diagnostics[0].code = "BMX4004", "include cycle diagnostic")

Print "bcc2 snapshot-loader tests passed"
