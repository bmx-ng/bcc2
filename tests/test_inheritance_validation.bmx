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

Local validSource:String = "SuperStrict~nInterface ITag~nEnd Interface~nInterface IMore Extends ITag~nEnd Interface~nType TBase Implements IMore~nEnd Type~nType TChild Extends TBase~nEnd Type~nType TBox<T> Where T Extends ITag~nEnd Type~nType TObjectBox<T> Where T Extends Object~nEnd Type~nGlobal direct:TBox<TBase>~nGlobal inherited:TBox<TChild>~nGlobal objectBound:TObjectBox<TBase>~nType TGenericBase<T> Implements ITag~nEnd Type~nType TGenericChild<T> Extends TGenericBase<T>~nEnd Type~nGlobal generic:TBox<TGenericChild<Int>>"
Local validParse:TParseResult = TBlitzMaxParser.ParseText(validSource, "valid-inheritance.bmx")
Check(validParse.syntaxTree.diagnostics.length = 0, "valid inheritance parser diagnostics")
Local validModel:TSemanticModel = TBlitzMaxSemanticAnalyzer.Analyze(validParse.syntaxTree)
Check(validModel.diagnostics.length = 0, "valid inheritance semantic diagnostics")

Local box:TSymbol = validModel.globalScope.LookupLocal("tbox")[0]
Local boxInfo:TTypeInheritanceInfo = validModel.InheritanceInfo(box)
Check(boxInfo <> Null And boxInfo.constraints.length = 1, "generic constraint information")
Check(boxInfo.constraints[0].parameterSymbol.name = "T", "constraint parameter symbol")
Check(boxInfo.constraints[0].bounds[0].DisplayName() = "ITag", "constraint bound type")
Local child:TSymbol = validModel.globalScope.LookupLocal("tchild")[0]
Check(validModel.InheritanceInfo(child).baseEdges[0].semanticType.DisplayName() = "TBase", "base inheritance edge")
Local base:TSymbol = validModel.globalScope.LookupLocal("tbase")[0]
Check(validModel.InheritanceInfo(base).interfaceEdges[0].semanticType.DisplayName() = "IMore", "implemented interface edge")
Local validDump:String = TSemanticDumper.Dump(validModel)
Check(validDump.Contains("Where T Extends ITag"), "constraint semantic dump")
Check(validDump.Contains("Implements IMore"), "interface semantic dump")

Local invalidSource:String = "Interface ITag~nEnd Interface~nType TBase~nEnd Type~nType TFinal Final~nEnd Type~nType TWrongBase Extends ITag~nEnd Type~nInterface IWrong Extends TBase~nEnd Interface~nStruct SBad Implements ITag~nEnd Struct~nType TWrongImpl Implements TBase~nEnd Type~nType TFinalChild Extends TFinal~nEnd Type~nType TDup Implements ITag, ITag~nEnd Type~nType TA Extends TB~nEnd Type~nType TB Extends TA~nEnd Type~nType TUnknown<T> Where X Extends ITag~nEnd Type~nType TRepeat<T> Where T Extends ITag, T Extends ITag~nEnd Type~nType TValue<T> Where T Extends Int~nEnd Type~nType TBox<T> Where T Extends ITag~nEnd Type~nGlobal bad:TBox<TBase>"
Local invalidParse:TParseResult = TBlitzMaxParser.ParseText(invalidSource, "invalid-inheritance.bmx")
Check(invalidParse.syntaxTree.diagnostics.length = 0, "invalid inheritance remains syntactically valid")
Local invalidModel:TSemanticModel = TBlitzMaxSemanticAnalyzer.Analyze(invalidParse.syntaxTree)
Check(HasDiagnostic(invalidModel.diagnostics, "BMX3200"), "invalid type base diagnostic")
Check(HasDiagnostic(invalidModel.diagnostics, "BMX3201"), "invalid interface base diagnostic")
Check(HasDiagnostic(invalidModel.diagnostics, "BMX3202"), "struct inheritance diagnostic")
Check(HasDiagnostic(invalidModel.diagnostics, "BMX3203"), "invalid Implements target diagnostic")
Check(HasDiagnostic(invalidModel.diagnostics, "BMX3204"), "inheritance cycle diagnostic")
Check(HasDiagnostic(invalidModel.diagnostics, "BMX3205"), "Final base diagnostic")
Check(HasDiagnostic(invalidModel.diagnostics, "BMX3206"), "duplicate interface diagnostic")
Check(HasDiagnostic(invalidModel.diagnostics, "BMX3207"), "undeclared constraint parameter diagnostic")
Check(HasDiagnostic(invalidModel.diagnostics, "BMX3208"), "duplicate constraint clause diagnostic")
Check(HasDiagnostic(invalidModel.diagnostics, "BMX3209"), "unsatisfied generic constraint diagnostic")
Check(HasDiagnostic(invalidModel.diagnostics, "BMX3210"), "invalid generic bound diagnostic")

Local bad:TSymbol = invalidModel.globalScope.LookupLocal("bad")[0]
Check(bad.declaredType.DisplayName() = "TBox<TBase>", "invalid generic construction remains modeled")

Local overrideSource:String = "SuperStrict~nType TOverrideBase~nMethod DoSomething(a:Float)~nEnd Method~nEnd Type~nType TOverrideChild Extends TOverrideBase~nMethod DoSomething(a:Float) Override~nEnd Method~nMethod SomethingElse:Int() Override~nReturn 20~nEnd Method~nEnd Type"
Local overrideParse:TParseResult = TBlitzMaxParser.ParseText(overrideSource, "override-validation.bmx")
Check(overrideParse.syntaxTree.diagnostics.length = 0, "Override validation fixture parses")
Local overrideModel:TSemanticModel = TBlitzMaxSemanticAnalyzer.Analyze(overrideParse.syntaxTree)
Local overrideDiagnosticCount:Int
For Local diagnostic:TDiagnostic = EachIn overrideModel.diagnostics
	If diagnostic.code = "BMX3211" Then overrideDiagnosticCount :+ 1
Next
Check(overrideDiagnosticCount = 1, "valid inherited method Override is accepted and unrelated Override is rejected")

Local structObjectOverrideSource:String = "SuperStrict~nStruct SPrintable~nMethod ToString:String() Override~nReturn ~qprintable~q~nEnd Method~nEnd Struct"
Local structObjectOverrideModel:TSemanticModel = TBlitzMaxSemanticAnalyzer.Analyze(TBlitzMaxParser.ParseText(structObjectOverrideSource, "struct-object-override.bmx").syntaxTree)
Check(Not HasDiagnostic(structObjectOverrideModel.diagnostics, "BMX3211"), "Struct boxing hooks may override the corresponding implicit Object method without acquiring an Object layout")

Local genericOverrideSource:String = "SuperStrict~nType TGenericOverrideBase<T>~nMethod Get:T(value:T)~nReturn value~nEnd Method~nEnd Type~nType TStringOverrideChild Extends TGenericOverrideBase<String>~nMethod Get:String(value:String) Override~nReturn value~nEnd Method~nEnd Type"
Local genericOverrideParse:TParseResult = TBlitzMaxParser.ParseText(genericOverrideSource, "generic-override-validation.bmx")
Local genericOverrideModel:TSemanticModel = TBlitzMaxSemanticAnalyzer.Analyze(genericOverrideParse.syntaxTree)
Check(genericOverrideModel.diagnostics.length = 0, "Override matching substitutes constructed generic base arguments")

Local covariantObjectOverrideSource:String = "SuperStrict~nType TProduct~nEnd Type~nType TProductFactory~nMethod Create:Object() Abstract~nEnd Type~nType TConcreteProductFactory Extends TProductFactory~nMethod Create:TProduct() Override~nReturn New TProduct~nEnd Method~nEnd Type~nGlobal Factory:TProductFactory = New TConcreteProductFactory"
Local covariantObjectOverrideParse:TParseResult = TBlitzMaxParser.ParseText(covariantObjectOverrideSource, "covariant-object-override-validation.bmx")
Local covariantObjectOverrideModel:TSemanticModel = TBlitzMaxSemanticAnalyzer.Analyze(covariantObjectOverrideParse.syntaxTree)
Check(covariantObjectOverrideModel.diagnostics.length = 0, "a concrete reference return covariantly satisfies an abstract Object result")

Local callableOverrideSource:String = "SuperStrict~nType TCallableOverrideBase<T>~nMethod Apply:T(value:T, operation:T(left:T, right:T))~nReturn operation(value, value)~nEnd Method~nEnd Type~nType TIntCallableOverride Extends TCallableOverrideBase<Int>~nMethod Apply:Int(value:Int, operation:Int(left:Int, right:Int)) Override~nReturn operation(value, value)~nEnd Method~nEnd Type"
Local callableOverrideParse:TParseResult = TBlitzMaxParser.ParseText(callableOverrideSource, "callable-override-validation.bmx")
Local callableOverrideModel:TSemanticModel = TBlitzMaxSemanticAnalyzer.Analyze(callableOverrideParse.syntaxTree)
Check(callableOverrideModel.diagnostics.length = 0, "Override matching compares callable signatures and substitutes their nested generic types")

Local visibilityOverrideSource:String = "SuperStrict~nType TVisibilityBase~nProtected Internal~nMethod Shared()~nEnd Method~nPrivate Internal~nMethod Family()~nEnd Method~nEnd Type~nType TVisibilityChild Extends TVisibilityBase~nInternal~nMethod Shared() Override~nEnd Method~nPrivate~nMethod Family() Override~nEnd Method~nEnd Type"
Local visibilityOverrideParse:TParseResult = TBlitzMaxParser.ParseText(visibilityOverrideSource, "visibility-override-validation.bmx")
Local visibilityOverrideModel:TSemanticModel = TBlitzMaxSemanticAnalyzer.Analyze(visibilityOverrideParse.syntaxTree)
Local visibilityOverrideDiagnosticCount:Int
For Local diagnostic:TDiagnostic = EachIn visibilityOverrideModel.diagnostics
	If diagnostic.code = "BMX3212" Then visibilityOverrideDiagnosticCount :+ 1
Next
Check(visibilityOverrideDiagnosticCount = 2, "combined visibility cannot be narrowed by an override")

Local invalidDefaultSource:String = "SuperStrict~nType TInvalid~nMethod Value:Int() Default~nReturn 1~nEnd Method~nEnd Type~nInterface IInvalid~nMethod Value:Int() Default Abstract~nEnd Interface"
Local invalidDefaultParse:TParseResult = TBlitzMaxParser.ParseText(invalidDefaultSource, "invalid-interface-defaults.bmx")
Local invalidDefaultModel:TSemanticModel = TBlitzMaxSemanticAnalyzer.Analyze(invalidDefaultParse.syntaxTree)
Check(HasDiagnostic(invalidDefaultModel.diagnostics, "BMX3213"), "Default outside an Interface instance Method is rejected")
Check(HasDiagnostic(invalidDefaultModel.diagnostics, "BMX3214"), "Default and Abstract cannot be combined")

Local defaultConflictSource:String = "SuperStrict~nInterface ILeft~nMethod Value:Int() Default~nReturn 1~nEnd Method~nEnd Interface~nInterface IRight~nMethod Value:Int() Default~nReturn 2~nEnd Method~nEnd Interface~nType TConflict Implements ILeft, IRight~nEnd Type"
Local defaultConflictModel:TSemanticModel = TBlitzMaxSemanticAnalyzer.Analyze(TBlitzMaxParser.ParseText(defaultConflictSource, "default-conflict.bmx").syntaxTree)
Check(HasDiagnostic(defaultConflictModel.diagnostics, "BMX3215"), "unrelated Interface defaults require an explicit Type override")

Local resolvedDefaultsSource:String = "SuperStrict~nInterface IBaseDefault~nMethod Value:Int() Default~nReturn 1~nEnd Method~nEnd Interface~nInterface ILeftDefault Extends IBaseDefault~nEnd Interface~nInterface IRightDefault Extends IBaseDefault~nEnd Interface~nType TDiamond Implements ILeftDefault, IRightDefault~nEnd Type~nInterface IDerivedDefault Extends IBaseDefault~nMethod Value:Int() Override Default~nReturn 2~nEnd Method~nEnd Interface~nType TDerivedDefault Implements IDerivedDefault~nEnd Type~nType TConcreteWins Implements ILeftDefault, IRightDefault~nMethod Value:Int()~nReturn 3~nEnd Method~nEnd Type"
Local resolvedDefaultsModel:TSemanticModel = TBlitzMaxSemanticAnalyzer.Analyze(TBlitzMaxParser.ParseText(resolvedDefaultsSource, "resolved-defaults.bmx").syntaxTree)
Check(Not HasDiagnostic(resolvedDefaultsModel.diagnostics, "BMX3215"), "same-origin diamonds, most-derived defaults, and concrete Type methods resolve deterministically")

Local incompatibleInterfaceSlotsSource:String = "SuperStrict~nInterface INumericValue~nMethod Value:Int()~nEnd Interface~nInterface ITextValue~nMethod Value:String()~nEnd Interface~nInterface IInvalidCombined Extends INumericValue, ITextValue~nEnd Interface~nType TInvalidCombined Implements INumericValue, ITextValue~nEnd Type"
Local incompatibleInterfaceSlotsModel:TSemanticModel = TBlitzMaxSemanticAnalyzer.Analyze(TBlitzMaxParser.ParseText(incompatibleInterfaceSlotsSource, "incompatible-interface-slots.bmx").syntaxTree)
Check(HasDiagnostic(incompatibleInterfaceSlotsModel.diagnostics, "BMX3216"), "unrelated Interface selectors with incompatible return ABIs are rejected before layout")

Local pairwiseInterfaceSlotsSource:String = "SuperStrict~nInterface IWideValue~nMethod Value:Object()~nEnd Interface~nInterface IStringBranch~nMethod Value:String()~nEnd Interface~nInterface IArrayBranch~nMethod Value:Int[]()~nEnd Interface~nInterface IInvalidBranches Extends IWideValue, IStringBranch, IArrayBranch~nEnd Interface"
Local pairwiseInterfaceSlotsModel:TSemanticModel = TBlitzMaxSemanticAnalyzer.Analyze(TBlitzMaxParser.ParseText(pairwiseInterfaceSlotsSource, "pairwise-interface-slots.bmx").syntaxTree)
Check(HasDiagnostic(pairwiseInterfaceSlotsModel.diagnostics, "BMX3216"), "Interface return compatibility is checked pairwise rather than only against a wide first parent")

Local compatibleInterfaceSlotsSource:String = "SuperStrict~nInterface IObjectValue~nMethod Value:Object()~nEnd Interface~nInterface IStringValue~nMethod Value:String()~nEnd Interface~nInterface ICompatibleCombined Extends IObjectValue, IStringValue~nEnd Interface"
Local compatibleInterfaceSlotsModel:TSemanticModel = TBlitzMaxSemanticAnalyzer.Analyze(TBlitzMaxParser.ParseText(compatibleInterfaceSlotsSource, "compatible-interface-slots.bmx").syntaxTree)
Check(Not HasDiagnostic(compatibleInterfaceSlotsModel.diagnostics, "BMX3216"), "covariant Interface return selectors retain one compatible logical ABI")

Local openGenericInterfaceSlotsSource:String = "SuperStrict~nInterface IGenericValue<T>~nMethod Value:T()~nEnd Interface~nInterface IGenericText<T>~nMethod Value:String()~nEnd Interface~nInterface IOpenCombined<T> Extends IGenericValue<T>, IGenericText<T>~nEnd Interface"
Local openGenericInterfaceSlotsModel:TSemanticModel = TBlitzMaxSemanticAnalyzer.Analyze(TBlitzMaxParser.ParseText(openGenericInterfaceSlotsSource, "open-generic-interface-slots.bmx").syntaxTree)
Check(Not HasDiagnostic(openGenericInterfaceSlotsModel.diagnostics, "BMX3216"), "open generic Interface return compatibility is deferred until canonical arguments are known")

Local externalInterfaceInheritanceSource:String = "SuperStrict~nExtern ~qWin32~q~nInterface IUnknown_~nMethod AddRef:Int()~nEnd Interface~nInterface IDispatch_ Extends IUnknown_~nMethod Invoke:Int()~nEnd Interface~nEnd Extern~nInterface IManaged~nEnd Interface~nInterface IInvalidManaged Extends IUnknown_~nEnd Interface~nExtern ~qWin32~q~nInterface IInvalidNative Extends IManaged~nEnd Interface~nEnd Extern"
Local externalInterfaceInheritanceModel:TSemanticModel = TBlitzMaxSemanticAnalyzer.Analyze(TBlitzMaxParser.ParseText(externalInterfaceInheritanceSource, "external-interface-inheritance.bmx").syntaxTree)
Local nativeUnknown:TSymbol = externalInterfaceInheritanceModel.globalScope.LookupLocal("IUnknown_")[0]
Local nativeDispatch:TSymbol = externalInterfaceInheritanceModel.globalScope.LookupLocal("IDispatch_")[0]
Check(nativeUnknown.isExternal And nativeDispatch.isExternal, "Extern Interface declarations retain native ownership in the semantic model")
Local externalMixDiagnosticCount:Int
For Local diagnostic:TDiagnostic = EachIn externalInterfaceInheritanceModel.diagnostics
	If diagnostic.code = "BMX3218" Then externalMixDiagnosticCount :+ 1
Next
Check(externalMixDiagnosticCount = 2, "native and managed Interface inheritance cannot be mixed in either direction")

Local privateContractSource:String = "SuperStrict~nModule acme.privateapi~nPrivate~nType THidden~nEnd Type~nStruct SHidden~nField value:Int~nEnd Struct~nInterface IHidden~nEnd Interface~nPublic~nType TAllowedLayout~nPrivate~nField state:SHidden~nMethod Consume(value:THidden)~nEnd Method~nEnd Type~nType TBadBase Extends THidden~nEnd Type~nType TBadFields~nField direct:THidden~nField ranked:THidden[,]~nField callback:Int(value:THidden)~nMethod Create:THidden()~nReturn Null~nEnd Method~nMethod Accept(value:SHidden Ptr)~nEnd Method~nEnd Type~nGlobal HiddenValues:SHidden[]~nFunction Transform:SHidden(value:THidden)~nEnd Function~nFunction PublicEntry:Int()~nFunction HiddenHelper:THidden()~nReturn Null~nEnd Function~nReturn 0~nEnd Function~nType TConstrained<T> Where T Extends THidden~nEnd Type~nInterface IPublic Extends IHidden~nEnd Interface"
Local privateContractModel:TSemanticModel = TBlitzMaxSemanticAnalyzer.Analyze(TBlitzMaxParser.ParseText(privateContractSource, "/sdk/mod/acme.mod/privateapi.mod/privateapi.bmx").syntaxTree)
Check(HasDiagnostic(privateContractModel.diagnostics, "BMX3217"), "public module declarations cannot expose private types")
Local privateContractDiagnosticCount:Int
For Local diagnostic:TDiagnostic = EachIn privateContractModel.diagnostics
	If diagnostic.code = "BMX3217" Then privateContractDiagnosticCount :+ 1
Next
Check(privateContractDiagnosticCount = 11, "private-type contract validation covers bases, Interface inheritance, constraints, fields, arrays, callables, pointers, Globals, parameters, and returns without treating nested routines as module API")
Local allowedLayout:TSymbol = privateContractModel.globalScope.LookupLocal("TAllowedLayout")[0]
Check(allowedLayout <> Null And allowedLayout.memberScope.LookupLocal("state")[0].declaredType.DisplayName() = "SHidden", "private members may retain private types for physical layout and implementation")

Local reabstractSource:String = "SuperStrict~nInterface IBaseDefault~nMethod Value:Int() Default~nReturn 1~nEnd Method~nEnd Interface~nInterface IReabstract Extends IBaseDefault~nMethod Value:Int() Override~nEnd Interface~nType TMustImplement Implements IReabstract~nEnd Type"
Local reabstractModel:TSemanticModel = TBlitzMaxSemanticAnalyzer.Analyze(TBlitzMaxParser.ParseText(reabstractSource, "reabstract-default.bmx").syntaxTree)
Local reabstractMethod:TSymbol = reabstractModel.globalScope.LookupLocal("IReabstract")[0].memberScope.LookupLocal("Value")[0]
Check(reabstractMethod.interfaceMethodKind = INTERFACE_METHOD_REABSTRACT And reabstractModel.IsAbstractType(reabstractModel.globalScope.LookupLocal("TMustImplement")[0]), "bodyless Override reabstracts an inherited default")

Print "bcc2 inheritance-validation tests passed"
